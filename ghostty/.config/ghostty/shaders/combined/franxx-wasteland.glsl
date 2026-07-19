// FRANXX Wasteland — combined scenery and cursor shader for Ghostty
//
// An original fan-made procedural scene inspired by the scorched exterior
// world of Darling in the Franxx: layered dunes, a distant fortified
// plantation, coherent airborne dust, and two articulated FRANXX-like mecha.
// Every visible object belongs to the scene; there are no decorative floating
// primitives or particle confetti.
//
// The animation is deliberately restrained: atmospheric dust drifts slowly,
// beacons breathe, and the mecha shift their gait by only a few pixels. The
// cursor receives a short red-to-cyan energy trace only while it is moving.
//
// Uses Ghostty's iChannel0, iResolution, iTime, and cursor uniforms.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_FBM_OCTAVES 3
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_FBM_OCTAVES 4
#else
#define PERF_FBM_OCTAVES 5
#endif

const float PI = 3.14159265359;
const vec3 SKY_ZENITH = vec3(0.035, 0.045, 0.095);
const vec3 SKY_MID = vec3(0.205, 0.105, 0.135);
const vec3 SKY_HORIZON = vec3(0.680, 0.285, 0.160);
const vec3 SUN_CORE = vec3(1.000, 0.660, 0.315);
const vec3 DUST_GOLD = vec3(0.760, 0.405, 0.215);
const vec3 DUNE_FAR = vec3(0.255, 0.125, 0.105);
const vec3 DUNE_MID = vec3(0.165, 0.077, 0.075);
const vec3 DUNE_NEAR = vec3(0.080, 0.038, 0.052);
const vec3 ARMOR_RED = vec3(0.660, 0.075, 0.115);
const vec3 ARMOR_IVORY = vec3(0.720, 0.690, 0.625);
const vec3 METAL_DARK = vec3(0.035, 0.043, 0.070);
const vec3 ENERGY_RED = vec3(1.000, 0.105, 0.190);
const vec3 ENERGY_CYAN = vec3(0.220, 0.850, 0.930);

float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * point;
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
        point = rotate2d(point * 2.03, 0.41) + vec2(13.7, 7.9);
        amplitude *= 0.48;
    }
    return result;
}

float sdBox(vec2 point, vec2 halfSize) {
    vec2 q = abs(point) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float sdRoundBox(vec2 point, vec2 halfSize, float radius) {
    return sdBox(point, max(halfSize - radius, vec2(0.0))) - radius;
}

float negativeDot(vec2 a, vec2 b) {
    return a.x * b.x - a.y * b.y;
}

float sdRhombus(vec2 point, vec2 diagonal) {
    point = abs(point);
    float h = clamp(
        negativeDot(diagonal - 2.0 * point, diagonal)
            / max(dot(diagonal, diagonal), 0.000001),
        -1.0,
        1.0
    );
    float distanceValue = length(
        point - 0.5 * diagonal * vec2(1.0 - h, 1.0 + h)
    );
    return distanceValue * sign(
        point.x * diagonal.y + point.y * diagonal.x
            - diagonal.x * diagonal.y
    );
}

float sdCapsule(vec2 point, vec2 startPoint, vec2 endPoint, float radius) {
    vec2 pa = point - startPoint;
    vec2 ba = endPoint - startPoint;
    float along = clamp(dot(pa, ba) / max(dot(ba, ba), 0.000001), 0.0, 1.0);
    return length(pa - ba * along) - radius;
}

float sdEllipse(vec2 point, vec2 radii) {
    // A stable signed approximation; exactness is unnecessary at pixel-scale
    // because all edges are analytically antialiased below.
    float normalizedRadius = length(point / max(radii, vec2(0.0001)));
    return (normalizedRadius - 1.0) * min(radii.x, radii.y);
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

float duneHeight(float x, float base, float amplitude, float scale, float seed) {
    float broad = fbm(vec2(x * scale + seed, seed * 1.73)) - 0.48;
    float ridge = sin(x * scale * 1.47 + seed) * 0.22;
    return base + amplitude * (broad + ridge);
}

void renderFortress(inout vec3 color, vec2 point, float aa) {
    // The structure is fixed to the horizon. Its concentric shell, central
    // command tower, side habitation blocks, and beacon form one coherent
    // piece of architecture rather than unrelated geometric decoration.
    vec2 q = point - vec2(-0.105, -0.145);

    float shellDistance = sdEllipse(q - vec2(0.0, 0.205), vec2(0.315, 0.165));
    float shell = strokeMask(shellDistance, 0.010, aa) * smoothstep(-0.01, 0.07, q.y);
    float innerShellDistance = sdEllipse(q - vec2(0.0, 0.205), vec2(0.255, 0.125));
    float innerShell = strokeMask(innerShellDistance, 0.0045, aa)
        * smoothstep(0.01, 0.08, q.y);

    blendLayer(color, vec3(0.105, 0.070, 0.075), shell * 0.92);
    blendLayer(color, vec3(0.560, 0.280, 0.145), innerShell * 0.48);

    float baseDistance = sdRoundBox(q - vec2(0.0, 0.030), vec2(0.350, 0.045), 0.012);
    float centerDistance = sdRoundBox(q - vec2(0.0, 0.135), vec2(0.095, 0.145), 0.018);
    float leftDistance = sdRoundBox(q - vec2(-0.205, 0.085), vec2(0.100, 0.095), 0.015);
    float rightDistance = sdRoundBox(q - vec2(0.205, 0.085), vec2(0.100, 0.095), 0.015);
    float shoulderDistance = sdRoundBox(q - vec2(0.0, 0.085), vec2(0.275, 0.045), 0.014);
    float domeDistance = sdEllipse(q - vec2(0.0, 0.270), vec2(0.125, 0.064));
    float spireDistance = sdCapsule(q, vec2(0.0, 0.305), vec2(0.0, 0.415), 0.007);

    float structureDistance = min(
        min(min(baseDistance, centerDistance), min(leftDistance, rightDistance)),
        min(min(shoulderDistance, domeDistance), spireDistance)
    );
    float structure = fillMask(structureDistance, aa);
    float edge = strokeMask(structureDistance, 0.0035, aa);

    blendLayer(color, vec3(0.052, 0.043, 0.058), structure * 0.98);
    blendLayer(color, vec3(0.315, 0.160, 0.105), edge * 0.60);

    // Regular window bays follow the building surfaces. A slow common power
    // cycle keeps them alive without independent flicker.
    vec2 windowCell = abs(fract((q + vec2(0.36, 0.01)) * vec2(29.0, 34.0)) - 0.5);
    float windows = (1.0 - smoothstep(0.145, 0.225, windowCell.x))
        * (1.0 - smoothstep(0.155, 0.245, windowCell.y))
        * structure;
    float powerBreath = 0.88 + 0.08 * sin(iTime * 0.20 + q.x * 4.0);
    blendLayer(color, vec3(1.000, 0.515, 0.205), windows * 0.60 * powerBreath);

    float beaconDistance = length(q - vec2(0.0, 0.420));
    float beaconCore = 1.0 - smoothstep(0.002, 0.008, beaconDistance);
    float beaconHalo = exp(-beaconDistance * beaconDistance / 0.00055)
        * (0.72 + 0.12 * sin(iTime * 0.45));
    color += ENERGY_RED * (beaconCore * 0.72 + beaconHalo * 0.22);
}

void renderMecha(
    inout vec3 color,
    vec2 point,
    vec2 footPosition,
    float scale,
    float facing,
    float phase,
    float aa
) {
    vec2 q = (point - footPosition) / scale;
    q.x *= facing;
    float localAa = aa / max(scale, 0.0001);

    // Both legs share one mechanically consistent, very slow walking cycle.
    float gait = 0.055 * sin(iTime * 0.34 + phase);
    vec2 hipFront = vec2(0.105, 0.86);
    vec2 kneeFront = vec2(0.145 + gait, 0.48);
    vec2 ankleFront = vec2(0.055 - gait * 0.65, 0.08);
    vec2 hipBack = vec2(-0.105, 0.86);
    vec2 kneeBack = vec2(-0.155 - gait, 0.49);
    vec2 ankleBack = vec2(-0.080 + gait * 0.65, 0.08);

    float frontThigh = sdCapsule(q, hipFront, kneeFront, 0.105);
    float frontShin = sdCapsule(q, kneeFront, ankleFront, 0.090);
    float backThigh = sdCapsule(q, hipBack, kneeBack, 0.100);
    float backShin = sdCapsule(q, kneeBack, ankleBack, 0.085);
    float frontFoot = sdRoundBox(q - (ankleFront + vec2(0.075, -0.020)), vec2(0.145, 0.050), 0.025);
    float backFoot = sdRoundBox(q - (ankleBack + vec2(0.060, -0.018)), vec2(0.135, 0.048), 0.023);

    float waist = sdRhombus(q - vec2(0.0, 0.900), vec2(0.185, 0.155));
    float torso = sdRoundBox(q - vec2(0.0, 1.205), vec2(0.235, 0.300), 0.045);
    float chest = sdRhombus(q - vec2(0.055, 1.305), vec2(0.365, 0.245));
    float shoulderPlateFront = sdRhombus(q - vec2(0.285, 1.345), vec2(0.195, 0.125));
    float shoulderPlateBack = sdRhombus(q - vec2(-0.260, 1.335), vec2(0.180, 0.115));
    float neck = sdCapsule(q, vec2(0.055, 1.445), vec2(0.080, 1.555), 0.065);
    float head = sdRhombus(q - vec2(0.105, 1.665), vec2(0.205, 0.175));
    float muzzle = sdRoundBox(q - vec2(0.245, 1.620), vec2(0.120, 0.066), 0.020);
    float helmetCrest = sdCapsule(q, vec2(-0.015, 1.745), vec2(-0.105, 1.900), 0.025);
    float horn = sdCapsule(q, vec2(0.055, 1.785), vec2(0.315, 1.995), 0.021);

    vec2 shoulderFront = vec2(0.285, 1.330);
    vec2 elbowFront = vec2(0.405, 1.035);
    vec2 handFront = vec2(0.355, 0.795);
    float upperArmFront = sdCapsule(q, shoulderFront, elbowFront, 0.085);
    float lowerArmFront = sdCapsule(q, elbowFront, handFront, 0.070);
    float hand = sdEllipse(q - handFront, vec2(0.095, 0.075));

    vec2 shoulderBack = vec2(-0.255, 1.315);
    vec2 elbowBack = vec2(-0.375, 1.105);
    vec2 handBack = vec2(-0.325, 0.915);
    float upperArmBack = sdCapsule(q, shoulderBack, elbowBack, 0.080);
    float lowerArmBack = sdCapsule(q, elbowBack, handBack, 0.066);

    // Back fins and a grounded lance establish the machine's silhouette.
    float upperFin = sdCapsule(q, vec2(-0.210, 1.390), vec2(-0.565, 1.675), 0.045);
    float lowerFin = sdCapsule(q, vec2(-0.225, 1.225), vec2(-0.570, 1.020), 0.040);
    float lance = sdCapsule(q, handFront + vec2(0.020, 0.010), vec2(1.190, 1.115), 0.018);
    float lanceGuard = sdCapsule(q, vec2(0.390, 0.865), vec2(0.485, 0.735), 0.023);

    float machineDistance = frontThigh;
    machineDistance = min(machineDistance, frontShin);
    machineDistance = min(machineDistance, backThigh);
    machineDistance = min(machineDistance, backShin);
    machineDistance = min(machineDistance, min(frontFoot, backFoot));
    machineDistance = min(machineDistance, min(waist, min(torso, chest)));
    machineDistance = min(machineDistance, min(shoulderPlateFront, shoulderPlateBack));
    machineDistance = min(machineDistance, min(neck, min(head, muzzle)));
    machineDistance = min(machineDistance, min(helmetCrest, min(horn, min(upperArmFront, lowerArmFront))));
    machineDistance = min(machineDistance, min(hand, min(upperArmBack, lowerArmBack)));
    machineDistance = min(machineDistance, min(upperFin, min(lowerFin, min(lance, lanceGuard))));

    float machine = fillMask(machineDistance, localAa);
    float silhouetteGlow = exp(-max(machineDistance, 0.0) * 10.0) * 0.10;
    blendLayer(color, ENERGY_RED, silhouetteGlow * 0.24);
    blendLayer(color, METAL_DARK, machine * 0.99);

    float redArmorDistance = min(
        min(chest, min(waist, min(shoulderPlateFront, shoulderPlateBack))),
        min(
            sdCapsule(q, hipFront, kneeFront, 0.078),
            sdCapsule(q, shoulderFront, elbowFront, 0.061)
        )
    );
    float redArmor = fillMask(redArmorDistance, localAa) * machine;
    blendLayer(color, ARMOR_RED, redArmor * 0.92);

    float faceplate = sdRoundBox(q - vec2(0.235, 1.625), vec2(0.115, 0.052), 0.015);
    float ivoryArmorDistance = min(
        min(faceplate, helmetCrest),
        min(
            sdCapsule(q, kneeFront, ankleFront, 0.060),
            sdCapsule(q, kneeBack, ankleBack, 0.055)
        )
    );
    float ivoryArmor = fillMask(ivoryArmorDistance, localAa) * machine;
    blendLayer(color, ARMOR_IVORY, ivoryArmor * 0.82);

    float panelEdges = strokeMask(torso, 0.015, localAa)
        + strokeMask(chest, 0.012, localAa)
        + strokeMask(shoulderPlateFront, 0.010, localAa)
        + strokeMask(shoulderPlateBack, 0.010, localAa)
        + strokeMask(frontThigh, 0.010, localAa)
        + strokeMask(frontShin, 0.010, localAa)
        + strokeMask(backThigh, 0.009, localAa)
        + strokeMask(backShin, 0.009, localAa);
    blendLayer(color, vec3(0.850, 0.265, 0.235), saturate(panelEdges) * machine * 0.34);

    float chestSeam = sdCapsule(q, vec2(0.055, 1.105), vec2(0.055, 1.410), 0.012);
    float waistSeam = sdCapsule(q, vec2(-0.125, 0.930), vec2(0.125, 0.930), 0.010);
    float seamMask = fillMask(min(chestSeam, waistSeam), localAa) * machine;
    blendLayer(color, vec3(0.020, 0.024, 0.045), seamMask * 0.82);

    float jointMask = fillMask(sdEllipse(q - kneeFront, vec2(0.075)), localAa)
        + fillMask(sdEllipse(q - kneeBack, vec2(0.070)), localAa)
        + fillMask(sdEllipse(q - shoulderFront, vec2(0.070)), localAa);
    blendLayer(color, vec3(0.018, 0.022, 0.040), saturate(jointMask) * 0.92);

    float coreDistance = length(q - vec2(0.125, 1.305));
    float core = 1.0 - smoothstep(0.020, 0.062, coreDistance);
    float eyeDistance = sdCapsule(q, vec2(0.175, 1.675), vec2(0.275, 1.665), 0.012);
    float eye = fillMask(eyeDistance, localAa);
    float coreHalo = exp(-coreDistance * coreDistance / 0.018) * 0.25;
    color += ENERGY_CYAN * (core * 0.65 + coreHalo * 0.22);
    color += ENERGY_RED * eye * 0.80;
}

vec3 renderWasteland(vec2 uv, vec2 point, float aspect, float aa) {
    float horizonBlend = smoothstep(0.12, 0.72, uv.y);
    vec3 sky = mix(SKY_HORIZON, SKY_MID, smoothstep(0.16, 0.55, uv.y));
    sky = mix(sky, SKY_ZENITH, horizonBlend);

    // A dust-muted sun anchors the lighting direction for the whole scene.
    vec2 sunPoint = (uv - vec2(0.205, 0.690)) * vec2(aspect, 1.0);
    float sunDistance = length(sunPoint);
    float sunDisc = 1.0 - smoothstep(0.070, 0.076, sunDistance);
    float sunHalo = exp(-sunDistance * sunDistance / 0.030);
    sky += SUN_CORE * (sunDisc * 0.80 + sunHalo * 0.24);

    // Coherent horizontal dust sheets. Noise only shapes the atmosphere; it
    // never places independent objects.
    vec2 dustPoint = vec2(point.x * 1.15 - iTime * 0.010, point.y * 5.2);
    float dustNoise = fbm(dustPoint + vec2(4.1, 9.7));
    float horizonDust = exp(-pow((uv.y - 0.405) * 5.2, 2.0));
    float highVeil = exp(-pow((uv.y - 0.575) * 7.0, 2.0));
    float dust = horizonDust * smoothstep(0.34, 0.78, dustNoise)
        + highVeil * smoothstep(0.55, 0.82, dustNoise) * 0.32;
    blendLayer(sky, DUST_GOLD, dust * 0.25);

    vec3 color = sky;
    renderFortress(color, point, aa);

    float farHeight = duneHeight(point.x, -0.185, 0.070, 0.80, 2.3);
    float farMask = 1.0 - smoothstep(farHeight - aa, farHeight + aa, point.y);
    float farTexture = fbm(vec2(point.x * 2.0, point.y * 7.0) + 17.0);
    vec3 farColor = DUNE_FAR * mix(0.78, 1.15, farTexture);
    blendLayer(color, farColor, farMask);

    // A distant escort is scaled and placed on the same far ridge.
    renderMecha(
        color,
        point,
        vec2(-0.315 * aspect, farHeight + 0.004),
        0.105,
        1.0,
        PI,
        aa
    );

    float midHeight = duneHeight(point.x, -0.315, 0.095, 1.05, 7.6);
    float midMask = 1.0 - smoothstep(midHeight - aa, midHeight + aa, point.y);
    float midTexture = fbm(vec2(point.x * 2.7 + 3.0, point.y * 9.0));
    vec3 midColor = DUNE_MID * mix(0.76, 1.18, midTexture);
    blendLayer(color, midColor, midMask);

    // Dust remains attached to the foreground machine's feet and follows its
    // tiny gait instead of spawning as free particles.
    vec2 mainFoot = vec2(0.285 * aspect, -0.405);
    vec2 footDustPoint = point - mainFoot;
    float footDustNoise = fbm(vec2(footDustPoint.x * 5.0 - iTime * 0.035, footDustPoint.y * 12.0));
    float footDust = exp(-pow(footDustPoint.x / 0.30, 2.0))
        * exp(-pow((footDustPoint.y + 0.010) / 0.065, 2.0))
        * smoothstep(0.32, 0.75, footDustNoise);
    blendLayer(color, DUST_GOLD, footDust * 0.25);

    renderMecha(color, point, mainFoot, 0.245, -1.0, 0.0, aa);

    float nearHeight = duneHeight(point.x, -0.435, 0.082, 1.45, 13.1);
    float nearMask = 1.0 - smoothstep(nearHeight - aa, nearHeight + aa, point.y);
    float nearTexture = fbm(vec2(point.x * 3.4 - 7.0, point.y * 12.0));
    vec3 nearColor = DUNE_NEAR * mix(0.76, 1.22, nearTexture);
    blendLayer(color, nearColor, nearMask);

    // Warm rim light consistently comes from the sun on the left.
    float rim = exp(-pow((point.y - farHeight) / 0.012, 2.0));
    color += vec3(0.650, 0.220, 0.105) * rim * 0.08;

    float vignette = 1.0 - 0.27 * smoothstep(0.30, 0.82, length((uv - 0.5) * vec2(0.78, 1.0)));
    return clamp(color * vignette, 0.0, 1.0);
}

vec4 compositeBehindTerminal(vec3 scene, vec4 terminalColor) {
    // Ghostty's cell alpha is the layer boundary. Opaque glyphs remain the
    // exact terminal color; transparent background cells reveal the scenery.
    float terminalCoverage = saturate(terminalColor.a);
    return vec4(mix(scene, terminalColor.rgb, terminalCoverage), terminalColor.a);
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition) / iResolution.y;
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

void applyEnergyCursor(inout vec4 color, vec2 fragCoord) {
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
    float age = saturate((iTime - iTimeCursorChange) / 0.24);
    if (moved <= cursorSize * 0.02 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.2);
    vec2 movement = head - tail;
    float along = clamp(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001),
        0.0,
        1.0
    );
    float trailDistance = sdCapsule(point, tail, head, cursorSize * 0.105);
    float trail = exp(-max(trailDistance, 0.0) / max(cursorSize * 0.31, 0.0001))
        * smoothstep(0.0, 0.22, along) * life;
    float core = fillMask(trailDistance, 2.4 / iResolution.y) * life;

    float headDistance = distance(point, head);
    float ringRadius = cursorSize * mix(0.80, 1.55, sin(age * PI));
    float ring = strokeMask(headDistance - ringRadius, cursorSize * 0.085, 2.2 / iResolution.y)
        * life;

    vec3 energy = mix(ENERGY_RED, ENERGY_CYAN, smoothstep(0.18, 0.92, along));
    color.rgb += energy * trail * 0.13;
    color.rgb += energy * core * 0.20;
    color.rgb += mix(ENERGY_RED, ENERGY_CYAN, age) * ring * 0.12;

    float cursorDistance = sdBox(point - head, current.zw * 0.5);
    color = mix(color, original, fillMask(cursorDistance, 1.5 / iResolution.y));
    color.a = original.a;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    float aspect = resolution.x / resolution.y;
    vec2 point = (fragCoord - 0.5 * resolution) / resolution.y;
    float aa = 1.35 / resolution.y;

    vec4 terminalColor = texture(iChannel0, uv);
    vec3 scene = renderWasteland(uv, point, aspect, aa);
    fragColor = compositeBehindTerminal(scene, terminalColor);
    applyEnergyCursor(fragColor, fragCoord);
}
