// FRANXX Underground City — diagonal elevator flight + holographic capsule cursor
//
// This scene is viewed from a capsule descending diagonally through a dark
// subterranean city. Window clusters and sparse structural lights live in 3D
// depth layers: they emerge at an upper-right vanishing point, accelerate past
// the camera, grow, and leave the frame. Shared camera drift and roll make the
// city move coherently rather than as independent floating dots. Other elevator
// capsules occasionally pass on converging rails.
//
// Cursor movement becomes a compact gold/cyan elevator capsule riding two
// perspective rails with scan rungs and a rose navigation fin. The actual
// Ghostty cursor block is preserved exactly.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_CITY_CLUSTER_COUNT 8
#define PERF_WINDOW_ROWS 2
#define PERF_PASSING_CAPSULES 1
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_CITY_CLUSTER_COUNT 12
#define PERF_WINDOW_ROWS 3
#define PERF_PASSING_CAPSULES 1
#elif GHOSTTY_GPU_PROFILE == 2
#define PERF_CITY_CLUSTER_COUNT 16
#define PERF_WINDOW_ROWS 3
#define PERF_PASSING_CAPSULES 2
#else
#define PERF_CITY_CLUSTER_COUNT 20
#define PERF_WINDOW_ROWS 3
#define PERF_PASSING_CAPSULES 2
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float CITY_FAR_DEPTH = 6.2;
const float CITY_NEAR_DEPTH = 0.42;
const vec2 CITY_FOCAL_UV = vec2(0.62, 0.67);
const float CITY_CAMERA_ROLL = -0.17;
const vec3 AMBER = vec3(0.880, 0.410, 0.090);
const vec3 GOLD = vec3(1.000, 0.675, 0.235);
const vec3 GOLD_HOT = vec3(1.000, 0.900, 0.590);
const vec3 CITY_ROSE = vec3(0.880, 0.125, 0.255);
const vec3 HOLOGRAM_CYAN = vec3(0.205, 0.700, 0.830);
const vec3 CITY_DARK = vec3(0.045, 0.035, 0.052);

float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * point;
}

float hash13(vec3 value) {
    value = fract(value * 0.1031);
    value += dot(value, value.yzx + 33.33);
    return fract((value.x + value.y) * value.z);
}

vec2 hash23(vec3 value) {
    return vec2(
        hash13(value + vec3(17.7, 3.1, 41.3)),
        hash13(value + vec3(7.3, 53.9, 11.7))
    );
}

float sdBox(vec2 point, vec2 halfSize) {
    vec2 q = abs(point) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float sdCapsule(vec2 point, vec2 startPoint, vec2 endPoint, float radius) {
    vec2 pa = point - startPoint;
    vec2 ba = endPoint - startPoint;
    float along = clamp(dot(pa, ba) / max(dot(ba, ba), 0.000001), 0.0, 1.0);
    return length(pa - ba * along) - radius;
}

float sdEllipse(vec2 point, vec2 radii) {
    return (length(point / max(radii, vec2(0.0001))) - 1.0)
        * min(radii.x, radii.y);
}

float fillMask(float distanceValue, float aa) {
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float strokeMask(float distanceValue, float width, float aa) {
    return 1.0 - smoothstep(width - aa, width + aa, abs(distanceValue));
}

float smoothEvent(float phase, float start, float peak, float end) {
    return smoothstep(start, peak, phase)
        * (1.0 - smoothstep(peak, end, phase));
}

float backgroundProtection(vec4 terminalColor) {
    float dark = 1.0 - smoothstep(0.14, 0.68, luminance(terminalColor.rgb));
    float transparentCell = 1.0 - smoothstep(0.76, 0.98, terminalColor.a);
    return dark * mix(0.38, 1.0, transparentCell);
}

vec2 perspectiveFocal(float aspect) {
    return (CITY_FOCAL_UV - 0.5) * vec2(aspect, 1.0);
}

vec2 projectCityPoint(vec2 planePoint, float depth, vec2 focal) {
    return focal + rotate2d(planePoint, CITY_CAMERA_ROLL)
        / max(depth, 0.001);
}

float cityNearFactor(float depth) {
    return saturate(
        (CITY_FAR_DEPTH - depth)
            / max(CITY_FAR_DEPTH - CITY_NEAR_DEPTH, 0.001)
    );
}

vec2 cityPlanePosition(vec2 basePlane, float travel, float phase) {
    // The world streams up-left as the observer's capsule descends down-right.
    // Applying this displacement before projection keeps every object on the
    // same camera trajectory and makes the flow feel architectural.
    vec2 cameraTravel = vec2(-0.125, 0.082) * travel;
    vec2 suspensionSway = vec2(
        sin(iTime * 0.16 + phase),
        cos(iTime * 0.11 + phase * 0.7)
    ) * 0.007 * travel;
    return basePlane + cameraTravel + suspensionSway;
}

vec3 cityLightColor(float colorSeed) {
    if (colorSeed < 0.70) {
        return mix(AMBER, GOLD, colorSeed / 0.70);
    }
    if (colorSeed < 0.91) {
        return mix(GOLD, GOLD_HOT, (colorSeed - 0.70) / 0.21);
    }
    return mix(GOLD, CITY_ROSE, 0.40);
}

vec3 renderWindowPair(
    vec2 world,
    vec2 center,
    vec2 horizontalAxis,
    vec2 verticalAxis,
    float halfWidth,
    float halfHeight,
    float spacing,
    float intensity,
    vec3 tint,
    float aa
) {
    vec2 delta = world - center;
    vec2 local = vec2(dot(delta, horizontalAxis), dot(delta, verticalAxis));
    float leftDistance = sdBox(
        local - vec2(-spacing * 0.5, 0.0),
        vec2(halfWidth, halfHeight)
    );
    float rightDistance = sdBox(
        local - vec2(spacing * 0.5, 0.0),
        vec2(halfWidth, halfHeight)
    );
    float core = fillMask(min(leftDistance, rightDistance), aa);
    float glowRadiusX = max(spacing * 1.35, halfWidth * 5.0);
    float glowRadiusY = max(halfHeight * 4.5, aa);
    float glow = exp(
        -local.x * local.x / max(glowRadiusX * glowRadiusX, 0.000001)
        -local.y * local.y / max(glowRadiusY * glowRadiusY, 0.000001)
    );
    float horizontalFlare = exp(
        -local.y * local.y / max(halfHeight * halfHeight * 5.0, 0.000001)
    ) * exp(-abs(local.x) / max(glowRadiusX * 2.5, 0.000001));
    return tint * intensity
        * (core * 0.54 + glow * 0.130 + horizontalFlare * 0.021);
}

vec3 renderPerspectiveCity(vec2 world, float aspect, float aa) {
    vec3 effect = vec3(0.0);
    vec2 focal = perspectiveFocal(aspect);
    vec2 horizontalAxis = rotate2d(vec2(1.0, 0.0), CITY_CAMERA_ROLL);
    vec2 verticalAxis = rotate2d(vec2(0.0, 1.0), CITY_CAMERA_ROLL);
    float pixel = 1.0 / max(iResolution.y, 1.0);

    for (int clusterIndex = 0; clusterIndex < PERF_CITY_CLUSTER_COUNT; clusterIndex++) {
        int columnIndex = clusterIndex - (clusterIndex / 5) * 5;
        int rowIndex = clusterIndex / 5;
        float index = float(clusterIndex);
        float column = float(columnIndex);
        float row = float(rowIndex);
        float layerOffset = (index + 0.5) / float(PERF_CITY_CLUSTER_COUNT);
        float identity = hash13(vec3(index, 31.7, 8.9));
        float clock = iTime * mix(0.065, 0.050, layerOffset)
            * mix(0.90, 1.12, identity)
            + layerOffset + identity * 2.5;
        float travel = fract(clock);
        float generation = floor(clock);
        float depth = mix(CITY_FAR_DEPTH, CITY_NEAR_DEPTH, travel);
        float nearFactor = cityNearFactor(depth);
        float lifecycle = smoothstep(0.0, 0.075, travel)
            * (1.0 - smoothstep(0.88, 1.0, travel));

        vec2 jitter = hash23(vec3(index, generation, 73.1)) - 0.5;
        vec2 basePlane = vec2(
            mix(-0.39, 0.39, (column + 0.5) / 5.0) * aspect
                + jitter.x * 0.075 * aspect,
            mix(-0.29, 0.25, (row + 0.5) / 4.0)
                + jitter.y * 0.065
        );
        float phase = TAU * hash13(vec3(index, generation, 19.7));
        vec2 plane = cityPlanePosition(basePlane, travel, phase);
        vec2 center = projectCityPoint(plane, depth, focal);

        float previousTravel = max(travel - 0.014, 0.0);
        float previousDepth = mix(CITY_FAR_DEPTH, CITY_NEAR_DEPTH, previousTravel);
        vec2 previousCenter = projectCityPoint(
            cityPlanePosition(basePlane, previousTravel, phase),
            previousDepth,
            focal
        );
        vec2 motion = center - previousCenter;
        float motionLength = length(motion);
        vec2 motionDirection = motionLength > 0.00001
            ? motion / motionLength
            : normalize(center - focal + vec2(0.0001));

        float powerPeriod = mix(9.0, 18.0, hash13(vec3(index, 47.7, 3.1)));
        float powerPhase = fract(iTime / powerPeriod + identity * 2.7);
        float powerEnvelope = smoothEvent(powerPhase, 0.05, 0.22, 0.68);
        float inhabited = step(0.14, hash13(vec3(index, generation, 5.7)));
        float breathing = 0.92 + 0.08 * sin(iTime * 0.31 + phase);
        float distanceGain = mix(0.22, 1.0, pow(nearFactor, 0.72));
        float clusterIntensity = lifecycle * powerEnvelope * inhabited
            * breathing * distanceGain;
        vec3 tint = cityLightColor(hash13(vec3(index, generation, 23.9)));

        float inverseDepth = 1.0 / max(depth, 0.001);
        float halfWidth = mix(1.35, 1.95, identity) * pixel * inverseDepth;
        float halfHeight = mix(0.68, 1.00, identity) * pixel * inverseDepth;
        float pairSpacing = mix(4.4, 6.6, identity) * pixel * inverseDepth;
        float rowSpacing = mix(7.5, 10.5, identity) * pixel * inverseDepth;

        for (int windowRow = 0; windowRow < PERF_WINDOW_ROWS; windowRow++) {
            float rowValue = float(windowRow)
                - 0.5 * float(PERF_WINDOW_ROWS - 1);
            vec2 rowCenter = center + verticalAxis * rowValue * rowSpacing;
            float rowPresent = step(
                0.24,
                hash13(vec3(index, generation, float(windowRow) + 41.3))
            );
            float rowVariation = mix(
                0.55,
                1.0,
                hash13(vec3(index, generation, float(windowRow) + 81.7))
            );
            effect += renderWindowPair(
                world,
                rowCenter,
                horizontalAxis,
                verticalAxis,
                halfWidth,
                halfHeight,
                pairSpacing,
                clusterIntensity * rowPresent * rowVariation,
                tint,
                aa
            );
        }

        float facadeHalfLength = rowSpacing * float(PERF_WINDOW_ROWS) * 0.72;
        float facadeDistance = sdCapsule(
            world,
            center - verticalAxis * facadeHalfLength,
            center + verticalAxis * facadeHalfLength,
            max(0.26 * pixel * inverseDepth, 0.16 * pixel)
        );
        float crossBeamDistance = sdCapsule(
            world,
            center - horizontalAxis * pairSpacing * 0.85,
            center + horizontalAxis * pairSpacing * 0.85,
            max(0.22 * pixel * inverseDepth, 0.14 * pixel)
        );
        float structure = max(
            fillMask(facadeDistance, aa),
            fillMask(crossBeamDistance, aa)
        );
        effect += mix(CITY_DARK, tint, 0.38)
            * structure * lifecycle * distanceGain * 0.075;

        float streakLength = mix(0.0, 38.0, nearFactor * nearFactor) * pixel;
        vec2 streakTail = center - motionDirection * streakLength;
        float streakDistance = sdCapsule(
            world,
            streakTail,
            center,
            max(0.30 * pixel * inverseDepth, 0.18 * pixel)
        );
        float streak = fillMask(streakDistance, aa)
            * smoothstep(0.55, 1.0, nearFactor);
        effect += tint * streak * clusterIntensity * 0.120;
    }

    return effect;
}

vec3 renderPassingElevators(vec2 world, float aspect, float aa) {
    vec3 effect = vec3(0.0);
    vec2 focal = perspectiveFocal(aspect);
    float pixel = 1.0 / max(iResolution.y, 1.0);

    for (int capsuleIndex = 0; capsuleIndex < PERF_PASSING_CAPSULES; capsuleIndex++) {
        float index = float(capsuleIndex);
        float layerOffset = (index + 0.5) / float(PERF_PASSING_CAPSULES);
        float speed = capsuleIndex == 0 ? 0.042 : 0.031;
        float clock = iTime * speed + layerOffset * 0.71;
        float travel = fract(clock);
        float generation = floor(clock);
        float depth = mix(5.5, 0.48, travel);
        float nearFactor = saturate((5.5 - depth) / (5.5 - 0.48));
        float presentThreshold = capsuleIndex == 0 ? 0.30 : 0.48;
        float present = step(
            presentThreshold,
            hash13(vec3(index, generation, 81.7))
        );
        float lifecycle = smoothstep(0.0, 0.08, travel)
            * (1.0 - smoothstep(0.84, 1.0, travel)) * present;
        vec2 seed = hash23(vec3(index, generation, 37.1));
        vec2 basePlane = vec2(
            mix(-0.29, 0.29, seed.x) * aspect,
            mix(-0.20, 0.19, seed.y)
        );
        float phase = TAU * hash13(vec3(index, generation, 13.7));
        vec2 center = projectCityPoint(
            cityPlanePosition(basePlane, travel, phase),
            depth,
            focal
        );
        float previousTravel = max(travel - 0.018, 0.0);
        float previousDepth = mix(5.5, 0.48, previousTravel);
        vec2 previousCenter = projectCityPoint(
            cityPlanePosition(basePlane, previousTravel, phase),
            previousDepth,
            focal
        );
        vec2 motion = center - previousCenter;
        float motionLength = length(motion);
        vec2 direction = motionLength > 0.00001
            ? motion / motionLength
            : normalize(center - focal + vec2(0.0001));
        vec2 normal = vec2(-direction.y, direction.x);
        vec2 delta = world - center;
        vec2 local = vec2(dot(delta, direction), dot(delta, normal));

        float inverseDepth = 1.0 / max(depth, 0.001);
        float halfLength = mix(9.0, 13.0, seed.x) * pixel * inverseDepth;
        float radius = mix(3.2, 4.8, seed.y) * pixel * inverseDepth;
        float capsuleDistance = sdCapsule(
            local,
            vec2(-halfLength * 0.55, 0.0),
            vec2(halfLength * 0.55, 0.0),
            radius
        );
        float shell = strokeMask(
            capsuleDistance,
            max(0.62 * pixel * inverseDepth, 0.25 * pixel),
            aa
        );
        float interior = fillMask(capsuleDistance, aa);
        float windowDistance = sdEllipse(
            local - vec2(halfLength * 0.30, 0.0),
            vec2(halfLength * 0.30, radius * 0.52)
        );
        float window = fillMask(windowDistance, aa);
        float scan = pow(
            0.5 + 0.5 * sin(local.x / max(pixel, 0.00001) * depth * 0.72 - iTime * 7.0),
            10.0
        ) * interior;
        float bloom = exp(
            -local.x * local.x / max(halfLength * halfLength * 2.5, 0.000001)
            -local.y * local.y / max(radius * radius * 5.0, 0.000001)
        );

        vec2 farPoint = projectCityPoint(basePlane, 5.5, focal);
        float railOffset = max(radius * 1.28, pixel);
        float railA = fillMask(
            sdCapsule(
                world,
                farPoint + normal * railOffset * 0.15,
                center + normal * railOffset,
                max(0.28 * pixel, aa * 0.20)
            ),
            aa
        );
        float railB = fillMask(
            sdCapsule(
                world,
                farPoint - normal * railOffset * 0.15,
                center - normal * railOffset,
                max(0.28 * pixel, aa * 0.20)
            ),
            aa
        );
        vec3 tint = capsuleIndex == 0 ? GOLD : HOLOGRAM_CYAN;
        float brightness = lifecycle * mix(0.34, 1.0, nearFactor);
        effect += tint * (railA + railB) * brightness * 0.035;
        effect += CITY_DARK * interior * brightness * 0.18;
        effect += tint * brightness
            * (shell * 0.34 + window * 0.18 + scan * 0.095 + bloom * 0.045);
        effect += GOLD_HOT * shell * brightness * 0.055;
    }

    return effect;
}

vec3 renderUndergroundCity(vec2 world, float aspect, float aa) {
    return renderPerspectiveCity(world, aspect, aa)
        + renderPassingElevators(world, aspect, aa);
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition)
        / max(iResolution.y, 1.0);
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

void applyElevatorCapsuleCursor(inout vec4 color, vec2 fragCoord) {
    vec4 untouched = color;
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
    vec2 movement = head - tail;
    float moved = length(movement);
    float cursorSize = max(current.z, current.w);
    float age = saturate((iTime - iTimeCursorChange) / 0.34);
    if (moved <= cursorSize * 0.025 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.10);
    float movementFactor = smoothstep(cursorSize * 0.08, cursorSize * 8.0, moved);
    float effectRadius = cursorSize * 3.5;
    if (
        any(lessThan(point, min(head, tail) - vec2(effectRadius)))
        || any(greaterThan(point, max(head, tail) + vec2(effectRadius)))
    ) {
        return;
    }

    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float aa = 2.0 / max(iResolution.y, 1.0);
    float along = saturate(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001)
    );
    vec2 pathCenter = mix(tail, head, along);
    float across = dot(point - pathCenter, normal);
    float railSeparation = cursorSize * mix(0.07, 0.38, along);
    float railWidth = cursorSize * 0.050;
    float railA = 1.0 - smoothstep(
        railWidth,
        railWidth + aa,
        abs(across - railSeparation)
    );
    float railB = 1.0 - smoothstep(
        railWidth,
        railWidth + aa,
        abs(across + railSeparation)
    );
    float railGlow = exp(
        -min(abs(across - railSeparation), abs(across + railSeparation))
            / max(cursorSize * 0.36, 0.0001)
    );
    float trailWindow = smoothstep(0.0, 0.18, along) * life;
    float rungPhase = abs(fract(along * 8.0 - age * 2.4) - 0.5);
    float rungPulse = 1.0 - smoothstep(0.055, 0.11, rungPhase);
    float betweenRails = 1.0 - smoothstep(
        railSeparation,
        railSeparation + aa,
        abs(across)
    );
    color.rgb += HOLOGRAM_CYAN * railGlow * trailWindow * 0.055;
    color.rgb += GOLD * (railA + railB) * trailWindow * 0.23;
    color.rgb += mix(GOLD, HOLOGRAM_CYAN, along)
        * rungPulse * betweenRails * trailWindow * 0.13;

    vec2 relative = point - head;
    vec2 local = vec2(dot(relative, direction), dot(relative, normal));
    float halfLength = cursorSize * mix(0.88, 1.24, movementFactor);
    float radius = cursorSize * 0.55;
    float capsuleDistance = sdCapsule(
        local,
        vec2(-halfLength * 0.52, 0.0),
        vec2(halfLength * 0.52, 0.0),
        radius
    );
    float capsuleFill = fillMask(capsuleDistance, aa) * life;
    float shell = strokeMask(capsuleDistance, cursorSize * 0.082, aa) * life;
    float innerShell = strokeMask(
        capsuleDistance + cursorSize * 0.14,
        cursorSize * 0.030,
        aa
    ) * life;
    float canopyDistance = sdEllipse(
        local - vec2(halfLength * 0.30, 0.0),
        vec2(halfLength * 0.31, radius * 0.52)
    );
    float canopy = fillMask(canopyDistance, aa) * life;
    float canopyEdge = strokeMask(canopyDistance, cursorSize * 0.028, aa) * life;
    float scan = pow(
        0.5 + 0.5 * sin(local.x / max(cursorSize, 0.0001) * 15.0 - iTime * 9.0),
        12.0
    ) * capsuleFill;

    vec2 finPoint = rotate2d(
        local - vec2(-halfLength * 0.18, radius * 0.73),
        -0.32
    );
    float fin = fillMask(
        sdBox(finPoint, vec2(halfLength * 0.29, radius * 0.12)),
        aa
    ) * life;
    vec2 lowerFinPoint = rotate2d(
        local - vec2(-halfLength * 0.18, -radius * 0.73),
        0.32
    );
    fin = max(
        fin,
        fillMask(
            sdBox(lowerFinPoint, vec2(halfLength * 0.29, radius * 0.12)),
            aa
        ) * life
    );
    float capsuleBloom = exp(
        -max(capsuleDistance, 0.0) / max(cursorSize * 0.62, 0.0001)
    ) * life;

    color.rgb += GOLD * capsuleBloom * 0.085;
    color.rgb = mix(color.rgb, CITY_DARK, capsuleFill * 0.30);
    color.rgb = mix(color.rgb, GOLD_HOT, shell * 0.72);
    color.rgb = mix(color.rgb, AMBER, innerShell * 0.50);
    color.rgb = mix(color.rgb, HOLOGRAM_CYAN, canopy * 0.50);
    color.rgb = mix(color.rgb, GOLD_HOT, canopyEdge * 0.38);
    color.rgb += HOLOGRAM_CYAN * scan * life * 0.11;
    color.rgb = mix(color.rgb, CITY_ROSE, fin * 0.72);

    vec2 diamondPoint = rotate2d(relative, -atan(direction.y, direction.x));
    float diamondDistance = abs(diamondPoint.x) + abs(diamondPoint.y)
        - cursorSize * mix(0.88, 1.34, movementFactor);
    float navigationDiamond = strokeMask(
        diamondDistance,
        cursorSize * 0.043,
        aa
    ) * life;
    color.rgb += CITY_ROSE * navigationDiamond * 0.18;

    float cursorDistance = sdBox(point - head, current.zw * 0.5);
    color = mix(color, untouched, fillMask(cursorDistance, aa));
    color.a = untouched.a;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    vec2 world = (fragCoord - 0.5 * resolution) / resolution.y;
    float aspect = resolution.x / resolution.y;
    float aa = 1.25 / resolution.y;

    vec4 terminalColor = texture(iChannel0, uv);
    vec3 city = renderUndergroundCity(world, aspect, aa)
        * backgroundProtection(terminalColor);
    fragColor = vec4(
        clamp(terminalColor.rgb + city, 0.0, 1.0),
        terminalColor.a
    );
    applyElevatorCapsuleCursor(fragColor, fragCoord);
}
