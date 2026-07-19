// Arcane Sigil cursor — counter-rotating geometry, runes, nodes, and spell trail
// Cursor-only Ghostty shader. Movement draws the sigil; stillness stays clean.

#define SIGIL_GPU_ECO      0
#define SIGIL_GPU_BALANCED 1
#define SIGIL_GPU_QUALITY  2
#define SIGIL_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE SIGIL_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == SIGIL_GPU_ECO
#define PERF_SIGIL_NODES  3
#define PERF_RUNE_TICKS   4
#define PERF_SPELL_SPARKS 1
#elif GHOSTTY_GPU_PROFILE == SIGIL_GPU_BALANCED
#define PERF_SIGIL_NODES  5
#define PERF_RUNE_TICKS   6
#define PERF_SPELL_SPARKS 3
#elif GHOSTTY_GPU_PROFILE == SIGIL_GPU_QUALITY
#define PERF_SIGIL_NODES  6
#define PERF_RUNE_TICKS   8
#define PERF_SPELL_SPARKS 5
#else
#define PERF_SIGIL_NODES  8
#define PERF_RUNE_TICKS   12
#define PERF_SPELL_SPARKS 8
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float EFFECT_DURATION = 0.40;
const vec3 ARCANE_CYAN = vec3(0.140, 0.850, 1.000);
const vec3 ARCANE_BLUE = vec3(0.200, 0.340, 1.000);
const vec3 ARCANE_VIOLET = vec3(0.680, 0.270, 1.000);
const vec3 ARCANE_GOLD = vec3(1.000, 0.720, 0.280);
const vec3 ARCANE_ROSE = vec3(1.000, 0.190, 0.550);
const vec3 ARCANE_WHITE = vec3(0.980, 0.960, 1.000);

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

float lineMask(
    vec2 point,
    vec2 startPoint,
    vec2 endPoint,
    float width
) {
    float distanceValue = segmentDistance(point, startPoint, endPoint);
    float aa = max(fwidth(distanceValue), 0.00015);
    return 1.0 - smoothstep(width, width + aa, distanceValue);
}

float ringMask(float distanceValue, float radius, float width) {
    float aa = max(fwidth(distanceValue), 0.00015);
    return 1.0 - smoothstep(
        max(width - aa, 0.0),
        width + aa,
        abs(distanceValue - radius)
    );
}

float gaussianPoint(vec2 delta, float radius) {
    return exp(
        -dot(delta, delta) / max(radius * radius, 0.000001)
    );
}

float polygonOutline(
    vec2 point,
    float radius,
    int sideCount,
    float rotation,
    float width
) {
    float result = 0.0;
    for (int sideIndex = 0; sideIndex < 8; sideIndex++) {
        if (sideIndex >= sideCount) {
            break;
        }
        float firstAngle = rotation
            + TAU * float(sideIndex) / float(sideCount);
        float secondAngle = rotation
            + TAU * float((sideIndex + 1) % sideCount) / float(sideCount);
        vec2 first = vec2(cos(firstAngle), sin(firstAngle)) * radius;
        vec2 second = vec2(cos(secondAngle), sin(secondAngle)) * radius;
        result = max(result, lineMask(point, first, second, width));
    }
    return result;
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
    float cullRadius = cursorPixels * mix(4.0, 6.8, movementFactor);
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
    float life = pow(1.0 - easedAge, 1.55);
    float contentMask = mix(0.16, 1.0, backgroundCellMask(original));

    float along = segmentParameter(point, tail, head);
    vec2 pathCenter = mix(tail, head, along);
    float across = dot(point - pathCenter, normal);
    float wave = cursorSize
        * mix(0.16, 0.38, movementFactor)
        * sin(along * TAU * 1.6 - easedAge * PI);
    float trailWidth = max(cursorSize * 0.070, 0.7 / resolution.y);
    float goldTrail = exp(-abs(across - wave) / trailWidth)
        * smoothstep(0.0, 0.16, along) * life;
    float violetTrail = exp(-abs(across + wave) / trailWidth)
        * smoothstep(0.0, 0.16, along) * life;
    fragColor.rgb += ARCANE_GOLD * goldTrail * 0.25 * contentMask;
    fragColor.rgb += ARCANE_VIOLET * violetTrail * 0.25 * contentMask;

    vec2 sigilCenter = head + direction * cursorSize * 0.30;
    vec2 relative = point - sigilCenter;
    float radius = cursorSize * mix(1.00, 1.55, movementFactor);
    float spin = iTime * 1.9 + easedAge * PI;
    float counterSpin = -iTime * 1.35 + easedAge * 0.7;
    float lineWidth = max(cursorSize * 0.043, 0.65 / resolution.y);

    float outerRing = ringMask(length(relative), radius, lineWidth) * life;
    float innerRing = ringMask(
        length(relative),
        radius * 0.58,
        lineWidth * 0.82
    ) * life;
    float hexagon = polygonOutline(
        relative,
        radius * 0.82,
        6,
        spin,
        lineWidth
    ) * life;
    float triangleA = polygonOutline(
        relative,
        radius * 0.68,
        3,
        counterSpin,
        lineWidth
    ) * life;
    float triangleB = polygonOutline(
        relative,
        radius * 0.68,
        3,
        counterSpin + PI,
        lineWidth
    ) * life;

    fragColor.rgb += ARCANE_CYAN * outerRing * 0.25 * contentMask;
    fragColor.rgb += ARCANE_GOLD * innerRing * 0.24 * contentMask;
    fragColor.rgb += mix(ARCANE_BLUE, ARCANE_VIOLET, 0.52)
        * hexagon * 0.36 * contentMask;
    fragColor.rgb += ARCANE_ROSE
        * triangleA * 0.30 * contentMask;
    fragColor.rgb += ARCANE_GOLD
        * triangleB * 0.28 * contentMask;

    for (int nodeIndex = 0; nodeIndex < PERF_SIGIL_NODES; nodeIndex++) {
        float index = float(nodeIndex);
        float fraction = index / max(float(PERF_SIGIL_NODES), 1.0);
        float phase = fraction * TAU + spin;
        vec2 nodePosition = sigilCenter
            + vec2(cos(phase), sin(phase)) * radius * 0.82;
        float node = gaussianPoint(
            point - nodePosition,
            cursorSize * 0.13
        ) * life;
        vec3 nodeColor = mix(
            ARCANE_CYAN,
            ARCANE_GOLD,
            0.5 + 0.5 * sin(phase)
        );
        fragColor.rgb += nodeColor * node * 0.36 * contentMask;
    }

    for (int tickIndex = 0; tickIndex < PERF_RUNE_TICKS; tickIndex++) {
        float index = float(tickIndex);
        float fraction = index / max(float(PERF_RUNE_TICKS), 1.0);
        float phase = fraction * TAU + counterSpin * 0.46;
        vec2 radial = vec2(cos(phase), sin(phase));
        vec2 first = sigilCenter + radial * radius * 1.04;
        vec2 second = sigilCenter + radial * radius * mix(
            1.14,
            1.28,
            hash12(vec2(index, 37.1))
        );
        float tick = lineMask(point, first, second, lineWidth * 0.72) * life;
        fragColor.rgb += mix(ARCANE_VIOLET, ARCANE_GOLD, fraction)
            * tick * 0.24 * contentMask;
    }

    float core = gaussianPoint(relative, cursorSize * 0.46) * life;
    float halo = gaussianPoint(relative, radius * 1.65) * life;
    fragColor.rgb += ARCANE_WHITE * core * 0.25 * contentMask;
    fragColor.rgb += mix(ARCANE_BLUE, ARCANE_VIOLET, 0.50)
        * halo * 0.070 * contentMask;

#if PERF_SPELL_SPARKS > 0
    vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
    for (int sparkIndex = 0; sparkIndex < PERF_SPELL_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        float positionRandom = hash12(
            eventSeed + vec2(index * 11.7, index * 31.9)
        );
        float sideRandom = hash12(
            eventSeed + vec2(index * 43.1, index * 7.3)
        );
        vec2 sparkCenter = mix(tail, head, positionRandom)
            + normal * (sideRandom - 0.5) * cursorSize * 2.7;
        float spark = gaussianPoint(
            point - sparkCenter,
            cursorSize * mix(0.050, 0.11, sideRandom)
        ) * life;
        fragColor.rgb += mix(ARCANE_CYAN, ARCANE_GOLD, sideRandom)
            * spark * 0.32 * contentMask;
    }
#endif

    float rippleRadius = radius * mix(0.62, 2.15, easedAge);
    float ripple = ringMask(
        length(relative),
        rippleRadius,
        lineWidth * 0.78
    ) * life * (1.0 - easedAge);
    fragColor.rgb += mix(ARCANE_ROSE, ARCANE_CYAN, easedAge)
        * ripple * 0.18 * contentMask;

    float cursorCoverage = insideCursorRectangle(fragCoord, iCurrentCursor);
    fragColor = mix(fragColor, original, cursorCoverage);
    fragColor.a = original.a;
}
