// Newton Prism cursor — white motion enters glass and leaves as a spectrum
// Cursor-only Ghostty shader. The real cursor and terminal alpha are preserved.

#define PRISM_GPU_ECO      0
#define PRISM_GPU_BALANCED 1
#define PRISM_GPU_QUALITY  2
#define PRISM_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE PRISM_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == PRISM_GPU_ECO
#define PERF_SPECTRAL_RAYS 5
#define PERF_PRISM_SPARKS   2
#elif GHOSTTY_GPU_PROFILE == PRISM_GPU_BALANCED
#define PERF_SPECTRAL_RAYS 7
#define PERF_PRISM_SPARKS   4
#elif GHOSTTY_GPU_PROFILE == PRISM_GPU_QUALITY
#define PERF_SPECTRAL_RAYS 7
#define PERF_PRISM_SPARKS   7
#else
#define PERF_SPECTRAL_RAYS 7
#define PERF_PRISM_SPARKS   10
#endif

const float PI = 3.14159265359;
const float EFFECT_DURATION = 0.38;
const vec3 GLASS_DEEP = vec3(0.030, 0.055, 0.150);
const vec3 GLASS_CYAN = vec3(0.180, 0.850, 1.000);
const vec3 WHITE_LIGHT = vec3(1.000, 0.980, 0.900);

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

float cross2d(vec2 first, vec2 second) {
    return first.x * second.y - first.y * second.x;
}

vec3 barycentricCoordinates(
    vec2 point,
    vec2 first,
    vec2 second,
    vec2 third
) {
    float denominator = cross2d(second - first, third - first);
    float safeDenominator = abs(denominator) < 0.000001
        ? (denominator < 0.0 ? -0.000001 : 0.000001)
        : denominator;
    float firstWeight = cross2d(second - point, third - point)
        / safeDenominator;
    float secondWeight = cross2d(third - point, first - point)
        / safeDenominator;
    return vec3(
        firstWeight,
        secondWeight,
        1.0 - firstWeight - secondWeight
    );
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

float strokeLine(
    vec2 point,
    vec2 startPoint,
    vec2 endPoint,
    float width
) {
    float distanceValue = segmentDistance(point, startPoint, endPoint);
    float aa = max(fwidth(distanceValue), 0.00015);
    return 1.0 - smoothstep(width, width + aa, distanceValue);
}

float gaussianPoint(vec2 delta, float radius) {
    return exp(
        -dot(delta, delta) / max(radius * radius, 0.000001)
    );
}

vec3 spectrum(float value) {
    value = saturate(value);
    if (value < 1.0 / 6.0) {
        return mix(
            vec3(1.00, 0.08, 0.12),
            vec3(1.00, 0.42, 0.04),
            value * 6.0
        );
    }
    if (value < 2.0 / 6.0) {
        return mix(
            vec3(1.00, 0.42, 0.04),
            vec3(1.00, 0.92, 0.08),
            value * 6.0 - 1.0
        );
    }
    if (value < 3.0 / 6.0) {
        return mix(
            vec3(1.00, 0.92, 0.08),
            vec3(0.16, 1.00, 0.42),
            value * 6.0 - 2.0
        );
    }
    if (value < 4.0 / 6.0) {
        return mix(
            vec3(0.16, 1.00, 0.42),
            vec3(0.04, 0.82, 1.00),
            value * 6.0 - 3.0
        );
    }
    if (value < 5.0 / 6.0) {
        return mix(
            vec3(0.04, 0.82, 1.00),
            vec3(0.24, 0.22, 1.00),
            value * 6.0 - 4.0
        );
    }
    return mix(
        vec3(0.24, 0.22, 1.00),
        vec3(0.78, 0.16, 1.00),
        value * 6.0 - 5.0
    );
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
    float cullRadius = cursorPixels * mix(5.0, 9.5, movementFactor);
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
    float contentMask = mix(
        0.16,
        1.0,
        backgroundCellMask(original)
    );

    // Offset the prism ahead of the real cursor so the cursor block does not
    // hide its center.
    vec2 prismCenter = head + direction * cursorSize * 0.62;
    float prismLength = cursorSize * mix(0.95, 1.45, movementFactor);
    float prismWidth = cursorSize * mix(0.78, 1.08, movementFactor);
    vec2 localDelta = point - prismCenter;
    vec2 local = vec2(
        dot(localDelta, direction),
        dot(localDelta, normal)
    );
    vec2 firstVertex = vec2(prismLength * 0.82, 0.0);
    vec2 secondVertex = vec2(-prismLength * 0.58, prismWidth * 0.72);
    vec2 thirdVertex = vec2(-prismLength * 0.58, -prismWidth * 0.72);
    vec3 barycentric = barycentricCoordinates(
        local,
        firstVertex,
        secondVertex,
        thirdVertex
    );
    float minimumWeight = min(
        barycentric.x,
        min(barycentric.y, barycentric.z)
    );
    float aa = clamp(fwidth(minimumWeight), 0.0015, 0.080);
    float body = smoothstep(-aa, aa, minimumWeight) * life;
    float edgeDistance = min(
        segmentDistance(local, firstVertex, secondVertex),
        min(
            segmentDistance(local, secondVertex, thirdVertex),
            segmentDistance(local, thirdVertex, firstVertex)
        )
    );
    float edge = 1.0 - smoothstep(
        cursorSize * 0.055,
        cursorSize * 0.115,
        edgeDistance
    );
    edge *= life;

    vec3 glassColor = mix(
        vec3(0.22, 0.55, 1.00),
        vec3(0.84, 0.24, 1.00),
        barycentric.y
    );
    glassColor = mix(glassColor, vec3(0.20, 1.00, 0.78), barycentric.z * 0.35);
    fragColor.rgb = mix(
        fragColor.rgb,
        mix(GLASS_DEEP, glassColor, 0.62),
        body * 0.48 * contentMask
    );
    fragColor.rgb += mix(glassColor, WHITE_LIGHT, 0.76)
        * edge * 0.60 * contentMask;

    // Incoming white ray: cursor motion itself becomes Newton's incident beam.
    float incidentDistance = segmentDistance(point, tail, prismCenter);
    float incidentCore = exp(
        -incidentDistance / max(cursorSize * 0.050, 0.00015)
    );
    float incidentGlow = exp(
        -incidentDistance / max(cursorSize * 0.24, 0.0003)
    );
    float incidentAlong = segmentParameter(point, tail, prismCenter);
    float incidentFade = smoothstep(0.0, 0.16, incidentAlong) * life;
    fragColor.rgb += WHITE_LIGHT
        * incidentCore * incidentFade * 0.52 * contentMask;
    fragColor.rgb += vec3(0.55, 0.72, 1.00)
        * incidentGlow * incidentFade * 0.075 * contentMask;

    // A seven-color fan leaves the forward point of the glass prism.
    vec2 exitPoint = prismCenter + direction * prismLength * 0.72;
    for (int rayIndex = 0; rayIndex < PERF_SPECTRAL_RAYS; rayIndex++) {
        float rayFraction = PERF_SPECTRAL_RAYS > 1
            ? float(rayIndex) / float(PERF_SPECTRAL_RAYS - 1)
            : 0.5;
        float fanAngle = mix(-0.34, 0.34, rayFraction)
            * mix(0.72, 1.0, movementFactor);
        vec2 rayDirection = rotate2d(direction, fanAngle);
        float rayLength = cursorSize * mix(4.0, 7.2, movementFactor);
        vec2 rayEnd = exitPoint + rayDirection * rayLength;
        float rayDistance = segmentDistance(point, exitPoint, rayEnd);
        float rayAlong = segmentParameter(point, exitPoint, rayEnd);
        float core = exp(
            -rayDistance / max(cursorSize * 0.038, 0.00012)
        );
        float glow = exp(
            -rayDistance / max(cursorSize * 0.16, 0.0003)
        );
        float rayFade = (1.0 - smoothstep(0.58, 1.0, rayAlong)) * life;
        vec3 rayColor = spectrum(rayFraction);
        fragColor.rgb += rayColor
            * (core * 0.38 + glow * 0.065)
            * rayFade
            * contentMask;
    }

    float prismHalo = gaussianPoint(
        point - prismCenter,
        cursorSize * mix(1.8, 2.6, movementFactor)
    ) * life;
    fragColor.rgb += mix(GLASS_CYAN, vec3(0.78, 0.22, 1.0), 0.48)
        * prismHalo * 0.085 * contentMask;

#if PERF_PRISM_SPARKS > 0
    vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
    for (int sparkIndex = 0; sparkIndex < PERF_PRISM_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        float positionRandom = hash12(
            eventSeed + vec2(index * 11.7, index * 31.9)
        );
        float sideRandom = hash12(
            eventSeed + vec2(index * 43.1, index * 7.3)
        );
        vec2 sparkCenter = mix(exitPoint, head, positionRandom)
            + normal * (sideRandom - 0.5) * cursorSize * 2.2;
        float spark = gaussianPoint(
            point - sparkCenter,
            cursorSize * mix(0.055, 0.12, sideRandom)
        ) * life;
        fragColor.rgb += spectrum(positionRandom)
            * spark * 0.32 * contentMask;
    }
#endif

    float cursorCoverage = insideCursorRectangle(fragCoord, iCurrentCursor);
    fragColor = mix(fragColor, original, cursorCoverage);
    fragColor.a = original.a;
}
