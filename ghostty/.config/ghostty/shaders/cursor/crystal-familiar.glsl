// Crystal Familiar cursor — faceted comet, orbiting companions, fracture wake
// Cursor-only Ghostty shader. Movement activates the familiar; stillness is clean.

#define FAMILIAR_GPU_ECO      0
#define FAMILIAR_GPU_BALANCED 1
#define FAMILIAR_GPU_QUALITY  2
#define FAMILIAR_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE FAMILIAR_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == FAMILIAR_GPU_ECO
#define PERF_ORBITING_SHARDS 2
#define PERF_TRAIL_CHIPS     2
#elif GHOSTTY_GPU_PROFILE == FAMILIAR_GPU_BALANCED
#define PERF_ORBITING_SHARDS 3
#define PERF_TRAIL_CHIPS     4
#elif GHOSTTY_GPU_PROFILE == FAMILIAR_GPU_QUALITY
#define PERF_ORBITING_SHARDS 4
#define PERF_TRAIL_CHIPS     7
#else
#define PERF_ORBITING_SHARDS 5
#define PERF_TRAIL_CHIPS     10
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float EFFECT_DURATION = 0.42;
const vec3 DEEP_GLASS = vec3(0.025, 0.045, 0.150);
const vec3 CYAN = vec3(0.100, 0.850, 1.000);
const vec3 BLUE = vec3(0.160, 0.300, 1.000);
const vec3 VIOLET = vec3(0.670, 0.260, 1.000);
const vec3 ROSE = vec3(1.000, 0.180, 0.590);
const vec3 IVORY = vec3(0.980, 0.950, 1.000);

float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float hash12(vec2 point) {
    vec3 p3 = fract(vec3(point.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * point;
}

float segmentParameter(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    return clamp(
        dot(point - startPoint, segment)
            / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );
}

float segmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    return length(
        point - mix(
            startPoint,
            endPoint,
            segmentParameter(point, startPoint, endPoint)
        )
    );
}

float gaussianPoint(vec2 delta, float radius) {
    return exp(
        -dot(delta, delta) / max(radius * radius, 0.000001)
    );
}

float diamondMask(vec2 point, vec2 radii) {
    vec2 normalized = point / max(radii, vec2(0.0001));
    float distanceValue = abs(normalized.x) + abs(normalized.y) - 1.0;
    float aa = max(fwidth(distanceValue), 0.012);
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float diamondEdge(vec2 point, vec2 radii) {
    vec2 normalized = point / max(radii, vec2(0.0001));
    float distanceValue = abs(normalized.x) + abs(normalized.y) - 1.0;
    float aa = max(fwidth(distanceValue), 0.012);
    return (
        1.0 - smoothstep(0.025, 0.14 + aa, abs(distanceValue))
    ) * (1.0 - smoothstep(-aa, aa, distanceValue));
}

float ringMask(float distanceValue, float radius, float width) {
    float aa = max(fwidth(distanceValue), 0.00015);
    return 1.0 - smoothstep(
        max(width - aa, 0.0),
        width + aa,
        abs(distanceValue - radius)
    );
}

vec3 palette(float selector) {
    selector = fract(selector);
    if (selector < 0.33) {
        return mix(CYAN, BLUE, selector / 0.33);
    }
    if (selector < 0.66) {
        return mix(BLUE, VIOLET, (selector - 0.33) / 0.33);
    }
    return mix(VIOLET, ROSE, (selector - 0.66) / 0.34);
}

float backgroundCellMask(vec4 terminalColor) {
    float colorDifference = length(terminalColor.rgb - iBackgroundColor);
    float colorMatch = 1.0 - smoothstep(0.030, 0.245, colorDifference);
    float darkFallback = 1.0 - smoothstep(
        0.12,
        0.58,
        luminance(terminalColor.rgb)
    );
    float transparent = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(colorMatch, darkFallback * transparent * 0.48));
}

vec2 cursorCenterPixels(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}

vec2 scenePoint(vec2 pixelPoint) {
    return (pixelPoint - 0.5 * iResolution.xy)
        / max(iResolution.y, 1.0);
}

float insideCursorRectangle(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(
        cursorRectangle.x,
        cursorRectangle.y - cursorRectangle.w
    );
    vec2 maximumPoint = vec2(
        cursorRectangle.x + cursorRectangle.z,
        cursorRectangle.y
    );
    return step(minimumPoint.x, point.x)
        * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x)
        * step(point.y, maximumPoint.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 original = texture(iChannel0, uv);
    fragColor = original;

    if (iCursorVisible == 0) {
        return;
    }

    vec2 headPixels = cursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = cursorCenterPixels(iPreviousCursor);
    vec2 movementPixels = headPixels - tailPixels;
    float movedPixels = length(movementPixels);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float age = saturate((iTime - iTimeCursorChange) / EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * 0.025
        || age >= 1.0
    ) {
        return;
    }

    float movementFactor = smoothstep(
        cursorPixels * 0.08,
        cursorPixels * 8.0,
        movedPixels
    );
    float cullRadius = cursorPixels * mix(4.2, 7.0, movementFactor);
    if (
        any(lessThan(fragCoord, min(headPixels, tailPixels) - vec2(cullRadius)))
        || any(greaterThan(fragCoord, max(headPixels, tailPixels) + vec2(cullRadius)))
    ) {
        return;
    }

    vec2 point = scenePoint(fragCoord);
    vec2 head = scenePoint(headPixels);
    vec2 tail = scenePoint(tailPixels);
    vec2 movement = head - tail;
    float movementLength = length(movement);
    vec2 direction = movement / max(movementLength, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - easedAge, 1.48);
    float contentMask = mix(0.16, 1.0, backgroundCellMask(original));

    float along = segmentParameter(point, tail, head);
    vec2 pathCenter = mix(tail, head, along);
    float across = dot(point - pathCenter, normal);
    float braid = cursorSize
        * mix(0.18, 0.40, movementFactor)
        * (1.0 - along)
        * sin(along * TAU * 1.9 - easedAge * PI);
    float trailWidth = max(cursorSize * 0.075, 0.7 / resolution.y);
    float cyanTrail = exp(-abs(across - braid) / trailWidth)
        * smoothstep(0.0, 0.17, along) * life;
    float roseTrail = exp(-abs(across + braid) / trailWidth)
        * smoothstep(0.0, 0.17, along) * life;
    float coreTrail = exp(-abs(across) / max(trailWidth * 0.42, 0.00015))
        * smoothstep(0.45, 1.0, along) * life;
    fragColor.rgb += CYAN * cyanTrail * 0.29 * contentMask;
    fragColor.rgb += ROSE * roseTrail * 0.27 * contentMask;
    fragColor.rgb += IVORY * coreTrail * 0.30 * contentMask;

    vec2 familiarCenter = head + direction * cursorSize * 0.44;
    vec2 relative = point - familiarCenter;
    float spin = iTime * 2.3 + age * PI;
    vec2 spun = rotate2d(relative, -spin);
    float mainLength = cursorSize * mix(0.84, 1.26, movementFactor);
    float mainWidth = cursorSize * mix(0.44, 0.64, movementFactor);
    vec2 mainRadii = vec2(mainWidth, mainLength);
    float body = diamondMask(spun, mainRadii) * life;
    float edge = diamondEdge(spun, mainRadii) * life;
    vec2 normalized = spun / max(mainRadii, vec2(0.0001));
    float ridgeA = exp(-abs(normalized.x) / 0.055) * body;
    float ridgeB = exp(-abs(normalized.y) / 0.070) * body;
    vec3 bodyColor = mix(CYAN, VIOLET, smoothstep(-0.8, 0.8, normalized.x));
    bodyColor = mix(bodyColor, ROSE, smoothstep(0.25, 0.95, normalized.y) * 0.48);

    fragColor.rgb = mix(
        fragColor.rgb,
        mix(DEEP_GLASS, bodyColor, 0.62),
        body * 0.52 * contentMask
    );
    fragColor.rgb += mix(bodyColor, IVORY, 0.70)
        * edge * 0.60 * contentMask;
    fragColor.rgb += IVORY
        * (ridgeA + ridgeB) * 0.22 * life * contentMask;

    float orbitRadius = cursorSize * mix(1.15, 1.72, movementFactor);
    float orbitDistance = length(relative);
    float orbitRing = ringMask(
        orbitDistance,
        orbitRadius,
        max(cursorSize * 0.035, 0.55 / resolution.y)
    ) * life;
    fragColor.rgb += mix(CYAN, VIOLET, 0.50)
        * orbitRing * 0.15 * contentMask;

    for (int orbitIndex = 0; orbitIndex < PERF_ORBITING_SHARDS; orbitIndex++) {
        float index = float(orbitIndex);
        float fraction = index / max(float(PERF_ORBITING_SHARDS), 1.0);
        float phase = fraction * TAU
            + iTime * mix(1.8, 2.8, fract(index * 0.37 + 0.2));
        vec2 orbitPoint = familiarCenter + vec2(
            cos(phase) * orbitRadius,
            sin(phase) * orbitRadius * 0.58
        );
        vec2 miniLocal = rotate2d(
            point - orbitPoint,
            -phase - spin * 0.35
        );
        float miniSize = cursorSize * mix(0.14, 0.24, fract(index * 0.61 + 0.3));
        float mini = diamondMask(
            miniLocal,
            vec2(miniSize * 0.44, miniSize)
        ) * life;
        vec3 miniColor = palette(fraction + 0.12);
        fragColor.rgb += mix(miniColor, IVORY, 0.38)
            * mini * 0.40 * contentMask;
    }

#if PERF_TRAIL_CHIPS > 0
    vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
    for (int chipIndex = 0; chipIndex < PERF_TRAIL_CHIPS; chipIndex++) {
        float index = float(chipIndex);
        float positionRandom = hash12(
            eventSeed + vec2(index * 11.7, index * 31.9)
        );
        float sideRandom = hash12(
            eventSeed + vec2(index * 43.1, index * 7.3)
        );
        float sizeRandom = hash12(
            eventSeed + vec2(index * 19.7, index * 53.3)
        );
        float chipAlong = mix(0.08, 0.88, positionRandom);
        vec2 chipCenter = mix(tail, head, chipAlong)
            + normal * (sideRandom - 0.5) * cursorSize * 2.4;
        vec2 chipLocal = rotate2d(
            point - chipCenter,
            -sizeRandom * TAU - iTime * mix(-2.4, 2.4, sideRandom)
        );
        float chipSize = cursorSize * mix(0.10, 0.25, sizeRandom);
        float chip = diamondMask(
            chipLocal,
            vec2(chipSize * 0.34, chipSize)
        ) * life;
        fragColor.rgb += palette(sizeRandom + 0.18)
            * chip * 0.34 * contentMask;
    }
#endif

    float halo = gaussianPoint(
        relative,
        cursorSize * mix(1.8, 2.7, movementFactor)
    ) * life;
    fragColor.rgb += mix(CYAN, VIOLET, 0.55)
        * halo * 0.090 * contentMask;

    float cursorCoverage = insideCursorRectangle(fragCoord, iCurrentCursor);
    fragColor = mix(fragColor, original, cursorCoverage);
    fragColor.a = original.a;
}
