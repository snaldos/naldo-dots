// FRANXX Golden City — combined scenery and cursor shader for Ghostty
//
// An original fan-made interior-city scene inspired by the sheltered,
// ceremonial settlements of Darling in the Franxx. A true perspective camera
// looks down a lamp-lined canal toward a central palace. Ray-marched buildings,
// attached window bays, architectural cornices, a vaulted shell, wet stone,
// and coherent amber haze all share one vanishing point.
//
// Randomness is used only to vary fixed building heights and inhabited window
// bays; it never creates free-floating shapes. Motion is limited to slow haze,
// water reflections, and a brief architectural-gold cursor trace.
//
// Uses Ghostty's iChannel0, iResolution, iTime, and cursor uniforms.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_FBM_OCTAVES 3
#define PERF_MARCH_STEPS 46
#define PERF_AO_STEPS 2
#define PERF_LAMP_COUNT 5
#define PERF_CITY_BLOCKS 7
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_FBM_OCTAVES 4
#define PERF_MARCH_STEPS 58
#define PERF_AO_STEPS 3
#define PERF_LAMP_COUNT 6
#define PERF_CITY_BLOCKS 8
#elif GHOSTTY_GPU_PROFILE == 2
#define PERF_FBM_OCTAVES 5
#define PERF_MARCH_STEPS 72
#define PERF_AO_STEPS 4
#define PERF_LAMP_COUNT 7
#define PERF_CITY_BLOCKS 8
#else
#define PERF_FBM_OCTAVES 5
#define PERF_MARCH_STEPS 88
#define PERF_AO_STEPS 5
#define PERF_LAMP_COUNT 8
#define PERF_CITY_BLOCKS 8
#endif

const float PI = 3.14159265359;
const float MAX_DISTANCE = 44.0;
const vec3 NIGHT_BRONZE = vec3(0.030, 0.021, 0.035);
const vec3 CITY_HAZE = vec3(0.190, 0.092, 0.055);
const vec3 STONE_DARK = vec3(0.075, 0.042, 0.040);
const vec3 STONE_WARM = vec3(0.175, 0.092, 0.054);
const vec3 BRONZE = vec3(0.390, 0.205, 0.090);
const vec3 GOLD = vec3(1.000, 0.575, 0.205);
const vec3 GOLD_HOT = vec3(1.000, 0.855, 0.480);
const vec3 CANAL_BLUE = vec3(0.025, 0.050, 0.075);

float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * point;
}

float hash11(float value) {
    value = fract(value * 0.1031);
    value *= value + 33.33;
    value *= value + value;
    return fract(value);
}

float hash12(vec2 point) {
    vec3 p3 = fract(vec3(point.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float valueNoise(vec2 point) {
    vec2 cell = floor(point);
    vec2 local = fract(point);
    local = local * local * (3.0 - 2.0 * local);
    float a = hash12(cell);
    float b = hash12(cell + vec2(1.0, 0.0));
    float c = hash12(cell + vec2(0.0, 1.0));
    float d = hash12(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fbm(vec2 point) {
    float result = 0.0;
    float amplitude = 0.52;
    for (int octave = 0; octave < PERF_FBM_OCTAVES; octave++) {
        result += amplitude * valueNoise(point);
        point = rotate2d(point * 2.02, 0.37) + vec2(7.1, 13.9);
        amplitude *= 0.48;
    }
    return result;
}

float sdBox2(vec2 point, vec2 halfSize) {
    vec2 q = abs(point) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float sdBox3(vec3 point, vec3 halfSize) {
    vec3 q = abs(point) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdRoundedBox3(vec3 point, vec3 halfSize, float radius) {
    return sdBox3(point, max(halfSize - radius, vec3(0.0))) - radius;
}

float sdCappedCylinderY(vec3 point, float halfHeight, float radius) {
    vec2 d = abs(vec2(length(point.xz), point.y)) - vec2(radius, halfHeight);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdEllipsoid(vec3 point, vec3 radii) {
    float k0 = length(point / radii);
    float k1 = length(point / (radii * radii));
    return k0 * (k0 - 1.0) / max(k1, 0.0001);
}

float sdCapsule2(vec2 point, vec2 startPoint, vec2 endPoint, float radius) {
    vec2 pa = point - startPoint;
    vec2 ba = endPoint - startPoint;
    float along = clamp(dot(pa, ba) / max(dot(ba, ba), 0.000001), 0.0, 1.0);
    return length(pa - ba * along) - radius;
}

float fillMask(float distanceValue, float aa) {
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float strokeMask(float distanceValue, float width, float aa) {
    return 1.0 - smoothstep(width - aa, width + aa, abs(distanceValue));
}

void blendLayer(inout vec3 base, vec3 layer, float opacity) {
    base = mix(base, layer, saturate(opacity));
}

void updateMap(inout vec2 result, float distanceValue, float material) {
    if (distanceValue < result.x) {
        result = vec2(distanceValue, material);
    }
}

vec2 mapCity(vec3 point) {
    // Material 1: floor; 2: habitation; 3: cornice/column; 4: palace.
    vec2 result = vec2(point.y, 1.0);

    // Explicit blocks keep the distance field globally conservative. A
    // varying modulo repetition can jump between differently sized buildings
    // at cell boundaries, causing ray-march holes; fixed world-space blocks
    // preserve clean silhouettes on every GPU profile.
    for (int block = 0; block < PERF_CITY_BLOCKS; block++) {
        float blockIndex = float(block);
        float blockCenterZ = 0.70 + blockIndex * 3.55;
        float variation = hash11(blockIndex * 7.31 + 2.7);
        float height = 3.05 + variation * 1.65;
        float centerOffset = 2.96 + (variation - 0.5) * 0.16;
        float halfWidth = 1.08 + 0.12 * hash11(blockIndex * 3.17 + 8.2);
        float halfDepth = 1.34;

        vec3 leftLocal = point - vec3(-centerOffset, height * 0.5, blockCenterZ);
        vec3 rightLocal = point - vec3(centerOffset, height * 0.5, blockCenterZ);
        float habitation = min(
            sdRoundedBox3(leftLocal, vec3(halfWidth, height * 0.5, halfDepth), 0.08),
            sdRoundedBox3(rightLocal, vec3(halfWidth, height * 0.5, halfDepth), 0.08)
        );
        updateMap(result, habitation, 2.0);

        // Cornices are physically attached to each block at the roof and at a
        // shared civic balcony level.
        float roofLeft = sdBox3(
            point - vec3(-centerOffset, height + 0.015, blockCenterZ),
            vec3(halfWidth + 0.10, 0.075, halfDepth + 0.10)
        );
        float roofRight = sdBox3(
            point - vec3(centerOffset, height + 0.015, blockCenterZ),
            vec3(halfWidth + 0.10, 0.075, halfDepth + 0.10)
        );
        float balconyY = min(1.52, height * 0.48);
        float balconyLeft = sdBox3(
            point - vec3(-centerOffset, balconyY, blockCenterZ),
            vec3(halfWidth + 0.075, 0.055, halfDepth + 0.075)
        );
        float balconyRight = sdBox3(
            point - vec3(centerOffset, balconyY, blockCenterZ),
            vec3(halfWidth + 0.075, 0.055, halfDepth + 0.075)
        );
        updateMap(result, min(min(roofLeft, roofRight), min(balconyLeft, balconyRight)), 3.0);

        // Paired inner columns support the balconies and make the street wall
        // read as architecture even when windows are hidden by terminal text.
        float columnX = centerOffset - halfWidth - 0.035;
        float columnLeft = sdCappedCylinderY(
            point - vec3(-columnX, balconyY * 0.5, blockCenterZ - halfDepth * 0.72),
            balconyY * 0.5,
            0.085
        );
        float columnRight = sdCappedCylinderY(
            point - vec3(columnX, balconyY * 0.5, blockCenterZ - halfDepth * 0.72),
            balconyY * 0.5,
            0.085
        );
        updateMap(result, min(columnLeft, columnRight), 3.0);
    }

    // The palace terminates the perspective corridor instead of leaving the
    // repeated street to vanish into procedural fog.
    float palaceBase = sdRoundedBox3(
        point - vec3(0.0, 2.05, 28.2),
        vec3(4.25, 2.05, 1.25),
        0.14
    );
    float palaceShoulder = sdRoundedBox3(
        point - vec3(0.0, 4.25, 28.0),
        vec3(2.20, 1.15, 1.00),
        0.15
    );
    float palaceTower = sdRoundedBox3(
        point - vec3(0.0, 6.10, 27.85),
        vec3(0.82, 1.35, 0.78),
        0.12
    );
    float palaceDome = sdEllipsoid(
        point - vec3(0.0, 7.42, 27.85),
        vec3(1.18, 0.72, 0.90)
    );
    float palace = min(min(palaceBase, palaceShoulder), min(palaceTower, palaceDome));
    updateMap(result, palace, 4.0);

    float palaceCrown = sdCappedCylinderY(
        point - vec3(0.0, 8.30, 27.85),
        0.42,
        0.055
    );
    updateMap(result, palaceCrown, 3.0);

    return result;
}

vec3 cityNormal(vec3 point) {
    // Tetrahedral normal: four map evaluations instead of six.
    const float epsilon = 0.0025;
    vec2 e = vec2(1.0, -1.0) * 0.5773;
    return normalize(
        e.xyy * mapCity(point + e.xyy * epsilon).x
        + e.yyx * mapCity(point + e.yyx * epsilon).x
        + e.yxy * mapCity(point + e.yxy * epsilon).x
        + e.xxx * mapCity(point + e.xxx * epsilon).x
    );
}

float cityOcclusion(vec3 point, vec3 normal) {
    float occlusion = 0.0;
    float weight = 1.0;
    for (int index = 0; index < PERF_AO_STEPS; index++) {
        float distanceAlongNormal = 0.055 + float(index) * 0.095;
        float sceneDistance = mapCity(point + normal * distanceAlongNormal).x;
        occlusion += (distanceAlongNormal - sceneDistance) * weight;
        weight *= 0.58;
    }
    return saturate(1.0 - occlusion * 1.45);
}

vec3 renderVault(vec2 uv, vec2 point, float aspect) {
    vec3 color = mix(
        vec3(0.105, 0.047, 0.052),
        NIGHT_BRONZE,
        smoothstep(0.18, 0.92, uv.y)
    );

    // Elliptical shell bands and radial ribs share the central street's
    // vanishing point, making them read as a vaulted enclosure.
    vec2 vaultPoint = vec2(
        point.x / max(aspect * 0.58, 0.001),
        (point.y + 0.105) / 0.66
    );
    float vaultRadius = length(vaultPoint);
    float upperMask = smoothstep(-0.12, 0.04, point.y);
    float bandCoordinate = abs(fract(vaultRadius * 7.0 + 0.04) - 0.5);
    float bands = (1.0 - smoothstep(0.455, 0.495, bandCoordinate)) * upperMask;

    float vaultAngle = atan(vaultPoint.x, max(vaultPoint.y, -0.18));
    float ribCoordinate = abs(sin(vaultAngle * 8.0));
    float ribs = (1.0 - smoothstep(0.00, 0.055, ribCoordinate))
        * smoothstep(0.18, 0.62, vaultRadius)
        * upperMask;

    color += BRONZE * bands * 0.20;
    color += GOLD * ribs * 0.085;

    vec2 oculusPoint = vec2(point.x / max(aspect, 0.001), point.y - 0.415);
    float oculusDistance = length(oculusPoint / vec2(0.090, 0.042));
    float oculus = 1.0 - smoothstep(0.85, 1.08, oculusDistance);
    float oculusHalo = exp(-oculusDistance * oculusDistance * 0.95);
    color += GOLD_HOT * (oculus * 0.26 + oculusHalo * 0.08);

    float hazeNoise = fbm(vec2(point.x * 0.72 - iTime * 0.004, point.y * 2.8) + 4.7);
    float haze = exp(-pow((point.y + 0.08) * 3.2, 2.0))
        * smoothstep(0.30, 0.78, hazeNoise);
    return mix(color, CITY_HAZE, haze * 0.16);
}

void cameraBasis(
    out vec3 camera,
    out vec3 right,
    out vec3 up,
    out vec3 forward
) {
    camera = vec3(0.0, 1.28, -5.2);
    vec3 target = vec3(0.0, 1.88, 17.0);
    forward = normalize(target - camera);
    right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    up = normalize(cross(forward, right));
}

vec3 renderSurface(vec3 point, vec3 normal, float material, float travel) {
    vec3 baseColor = STONE_DARK;
    vec3 emission = vec3(0.0);

    if (material < 1.5) {
        float canal = 1.0 - smoothstep(0.82, 0.93, abs(point.x));
        baseColor = mix(vec3(0.065, 0.043, 0.043), CANAL_BLUE, canal * 0.88);

        float canalEdge = exp(-pow((abs(point.x) - 0.93) / 0.035, 2.0));
        emission += GOLD * canalEdge * 0.28;

        // Perspective floor joints are fixed in world space. Only the water's
        // reflected light undulates, and it does so continuously.
        float longitudinalJoint = exp(-pow(abs(fract((point.x + 5.0) * 0.42) - 0.5) / 0.035, 2.0));
        float crossJoint = exp(-pow(abs(fract(point.z * 0.29) - 0.5) / 0.045, 2.0));
        baseColor += vec3(0.055, 0.028, 0.020) * (longitudinalJoint + crossJoint) * (1.0 - canal);

        float wave = 0.5 + 0.5 * sin(point.z * 2.15 + sin(point.x * 5.0) + iTime * 0.24);
        float palaceReflection = exp(-abs(point.x) * 1.75)
            * exp(-max(26.0 - point.z, 0.0) * 0.035)
            * mix(0.42, 1.0, wave);
        emission += mix(GOLD, GOLD_HOT, wave) * palaceReflection * canal * 0.26;
    } else if (material < 2.5) {
        baseColor = mix(STONE_DARK, STONE_WARM, 0.36 + 0.28 * max(normal.y, 0.0));

        vec2 facadeCoordinate;
        if (abs(normal.x) > abs(normal.z)) {
            facadeCoordinate = vec2(point.z * 0.72, point.y * 1.08);
        } else {
            facadeCoordinate = vec2(point.x * 0.72, point.y * 1.08);
        }
        vec2 windowCell = abs(fract(facadeCoordinate) - 0.5);
        float aperture = (1.0 - smoothstep(0.255, 0.335, windowCell.x))
            * (1.0 - smoothstep(0.285, 0.390, windowCell.y));
        vec2 windowIndex = floor(facadeCoordinate);
        float inhabited = step(0.22, hash12(windowIndex + vec2(17.0, 43.0)));
        float facadeFacing = smoothstep(0.34, 0.72, max(abs(normal.x), abs(normal.z)));
        float windows = aperture * inhabited * facadeFacing;
        emission += mix(GOLD, GOLD_HOT, hash12(windowIndex + 8.7)) * windows * 0.82;

        float frame = (1.0 - smoothstep(0.015, 0.055, abs(windowCell.x - 0.36)))
            + (1.0 - smoothstep(0.018, 0.060, abs(windowCell.y - 0.415)));
        baseColor += BRONZE * saturate(frame) * facadeFacing * 0.17;
    } else if (material < 3.5) {
        baseColor = BRONZE * (0.66 + 0.34 * max(normal.y, 0.0));
        emission += GOLD * pow(max(normal.y, 0.0), 5.0) * 0.08;
    } else {
        baseColor = mix(vec3(0.105, 0.050, 0.045), STONE_WARM, 0.58);
        vec2 palaceCoordinate = vec2(point.x * 0.55, point.y * 0.86);
        vec2 palaceCell = abs(fract(palaceCoordinate) - 0.5);
        float palaceWindow = (1.0 - smoothstep(0.24, 0.32, palaceCell.x))
            * (1.0 - smoothstep(0.27, 0.39, palaceCell.y))
            * smoothstep(0.25, 0.70, abs(normal.z));
        emission += GOLD_HOT * palaceWindow * 0.90;

        float verticalGold = exp(-pow(abs(fract(point.x * 0.55) - 0.5) / 0.055, 2.0));
        emission += GOLD * verticalGold * 0.16;
    }

    vec3 palaceLightPosition = vec3(0.0, 6.7, 24.0);
    vec3 lightDirection = normalize(palaceLightPosition - point);
    float diffuse = max(dot(normal, lightDirection), 0.0);
    float distanceToLight = length(palaceLightPosition - point);
    float attenuation = 1.0 / (1.0 + 0.014 * distanceToLight * distanceToLight);
    float ambient = 0.24 + 0.20 * max(normal.y, 0.0);
    float occlusion = cityOcclusion(point, normal);

    vec3 lit = baseColor * (ambient + diffuse * attenuation * 2.1) * occlusion;
    lit += BRONZE * pow(1.0 - max(dot(normal, normalize(-point)), 0.0), 3.0) * 0.055;
    lit += emission;

    float fog = 1.0 - exp(-travel * 0.026);
    return mix(lit, CITY_HAZE * 0.76, fog * 0.70);
}

vec2 projectPoint(
    vec3 worldPoint,
    vec3 camera,
    vec3 right,
    vec3 up,
    vec3 forward,
    out float depth
) {
    vec3 relative = worldPoint - camera;
    depth = dot(relative, forward);
    return vec2(dot(relative, right), dot(relative, up)) / max(depth, 0.001);
}

void renderStreetLamps(
    inout vec3 color,
    vec2 screenPoint,
    vec3 camera,
    vec3 right,
    vec3 up,
    vec3 forward,
    float aa
) {
    for (int lampIndex = 0; lampIndex < PERF_LAMP_COUNT; lampIndex++) {
        float z = 1.65 + float(lampIndex) * 3.75;
        for (int sideIndex = 0; sideIndex < 2; sideIndex++) {
            float side = sideIndex == 0 ? -1.0 : 1.0;
            float baseDepth;
            float bulbDepth;
            vec2 base = projectPoint(
                vec3(side * 1.40, 0.02, z),
                camera, right, up, forward,
                baseDepth
            );
            vec2 bulb = projectPoint(
                vec3(side * 1.40, 0.86, z),
                camera, right, up, forward,
                bulbDepth
            );
            if (bulbDepth <= 0.0) {
                continue;
            }

            float poleWidth = max(0.00065, 0.010 / bulbDepth);
            float poleDistance = sdCapsule2(screenPoint, base, bulb, poleWidth);
            float pole = fillMask(poleDistance, aa);
            blendLayer(color, vec3(0.145, 0.075, 0.040), pole * 0.85);

            float bulbRadius = 0.006 + 0.085 / bulbDepth;
            float bulbDistance = distance(screenPoint, bulb);
            float bulbCore = 1.0 - smoothstep(bulbRadius * 0.22, bulbRadius * 0.48, bulbDistance);
            float bulbGlow = exp(-bulbDistance * bulbDistance / max(bulbRadius * bulbRadius * 2.6, 0.000001));
            color += GOLD_HOT * (bulbCore * 0.62 + bulbGlow * 0.16);
        }
    }
}

vec3 renderGoldenCity(vec2 uv, vec2 screenPoint, float aspect, float aa) {
    vec3 camera;
    vec3 right;
    vec3 up;
    vec3 forward;
    cameraBasis(camera, right, up, forward);

    vec3 rayDirection = normalize(forward + screenPoint.x * right + screenPoint.y * up);
    float travel = 0.045;
    float material = -1.0;
    bool hit = false;

    for (int stepIndex = 0; stepIndex < PERF_MARCH_STEPS; stepIndex++) {
        vec3 samplePoint = camera + rayDirection * travel;
        vec2 sceneSample = mapCity(samplePoint);
        float hitThreshold = 0.0012 * (1.0 + travel * 0.035);
        if (sceneSample.x < hitThreshold) {
            material = sceneSample.y;
            hit = true;
            break;
        }
        travel += max(sceneSample.x * 0.78, 0.0025);
        if (travel > MAX_DISTANCE) {
            break;
        }
    }

    vec3 color = renderVault(uv, screenPoint, aspect);
    if (hit && travel <= MAX_DISTANCE) {
        vec3 worldPoint = camera + rayDirection * travel;
        vec3 normal = cityNormal(worldPoint);
        color = renderSurface(worldPoint, normal, material, travel);
    }

    renderStreetLamps(color, screenPoint, camera, right, up, forward, aa);

    // A grounded amber haze gathers along the boulevard's vanishing line.
    float streetHazeNoise = fbm(vec2(screenPoint.x * 1.4 - iTime * 0.005, screenPoint.y * 4.0) + 21.0);
    float streetHaze = exp(-pow((screenPoint.y + 0.09) * 4.0, 2.0))
        * smoothstep(0.42, 0.80, streetHazeNoise);
    blendLayer(color, CITY_HAZE, streetHaze * 0.10);

    float vignette = 1.0 - 0.30 * smoothstep(
        0.30,
        0.86,
        length((uv - 0.5) * vec2(0.76, 1.0))
    );
    return clamp(color * vignette, 0.0, 1.0);
}

vec4 compositeBehindTerminal(vec3 scene, vec4 terminalColor) {
    float terminalCoverage = saturate(terminalColor.a);
    return vec4(mix(scene, terminalColor.rgb, terminalCoverage), terminalColor.a);
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition) / iResolution.y;
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

void applyGoldenCursor(inout vec4 color, vec2 fragCoord) {
    vec4 original = color;
    vec2 point = normalizeScreen(fragCoord, 1.0);
    vec4 current = vec4(
        normalizeScreen(iCurrentCursor.xy, 1.0),
        normalizeScreen(iCurrentCursor.zw, 0.0)
    );
    vec4 previous = vec4(
        normalizeScreen(iPreviousCursor.xy, 1.0),
        normalizeScreen(iPreviousCursor.zw, 0.0)
    );
    vec2 head = cursorCenter(current);
    vec2 tail = cursorCenter(previous);
    float cursorSize = max(current.z, current.w);
    float moved = distance(head, tail);
    float age = saturate((iTime - iTimeCursorChange) / 0.25);
    if (moved <= cursorSize * 0.02 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.25);
    vec2 movement = head - tail;
    float along = clamp(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001),
        0.0,
        1.0
    );
    float trailDistance = sdCapsule2(point, tail, head, cursorSize * 0.095);
    float glow = exp(-max(trailDistance, 0.0) / max(cursorSize * 0.34, 0.0001))
        * smoothstep(0.0, 0.24, along) * life;
    float core = fillMask(trailDistance, 2.2 / iResolution.y) * life;

    // Two parallel rails make the trace echo the city's illuminated boulevard.
    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float railOffset = cursorSize * 0.22;
    float railA = fillMask(
        sdCapsule2(point, tail + normal * railOffset, head + normal * railOffset, cursorSize * 0.030),
        2.0 / iResolution.y
    );
    float railB = fillMask(
        sdCapsule2(point, tail - normal * railOffset, head - normal * railOffset, cursorSize * 0.030),
        2.0 / iResolution.y
    );

    color.rgb += GOLD * glow * 0.12;
    color.rgb += GOLD_HOT * core * 0.22;
    color.rgb += GOLD * (railA + railB) * life * smoothstep(0.0, 0.24, along) * 0.10;

    float headDistance = distance(point, head);
    float halo = exp(-headDistance * headDistance / max(cursorSize * cursorSize * 1.8, 0.000001));
    color.rgb += GOLD_HOT * halo * life * 0.08;

    float cursorDistance = sdBox2(point - head, current.zw * 0.5);
    color = mix(color, original, fillMask(cursorDistance, 1.5 / iResolution.y));
    color.a = original.a;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    float aspect = resolution.x / resolution.y;
    vec2 screenPoint = (fragCoord - 0.5 * resolution) / resolution.y;
    float aa = 1.35 / resolution.y;

    vec4 terminalColor = texture(iChannel0, uv);
    vec3 scene = renderGoldenCity(uv, screenPoint, aspect, aa);
    fragColor = compositeBehindTerminal(scene, terminalColor);
    applyGoldenCursor(fragColor, fragCoord);
}
