// Cosmic Diamond cursor — an expanding, rotating octahedral cube
// A diamond-like 3D wireframe replaces the cosmic cursor rings while retaining
// its movement-scaled glow, comet trail, sparks, and exact cursor preservation.

#define DIAMOND_GPU_ECO      0
#define DIAMOND_GPU_BALANCED 1
#define DIAMOND_GPU_QUALITY  2
#define DIAMOND_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE DIAMOND_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == DIAMOND_GPU_ECO
#define PERF_DIAMOND_SPARKS 0
#elif GHOSTTY_GPU_PROFILE == DIAMOND_GPU_BALANCED
#define PERF_DIAMOND_SPARKS 2
#elif GHOSTTY_GPU_PROFILE == DIAMOND_GPU_QUALITY
#define PERF_DIAMOND_SPARKS 4
#else
#define PERF_DIAMOND_SPARKS 7
#endif

const float PI = 3.14159265359;
const float EFFECT_DURATION = 0.32;
const vec3 DIAMOND_CYAN = vec3(0.180, 0.840, 1.000);
const vec3 DIAMOND_BLUE = vec3(0.180, 0.320, 1.000);
const vec3 DIAMOND_VIOLET = vec3(0.680, 0.280, 1.000);
const vec3 DIAMOND_ROSE = vec3(0.980, 0.220, 0.650);
const vec3 DIAMOND_WHITE = vec3(0.980, 0.960, 1.000);

float saturate(float value) { return clamp(value, 0.0, 1.0); }
float luminance(vec3 color) { return dot(color, vec3(0.2126, 0.7152, 0.0722)); }

float hash12(vec2 point) {
    vec3 p3 = fract(vec3(point.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 rotateX(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(point.x, point.y * c - point.z * s, point.y * s + point.z * c);
}

vec3 rotateY(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(point.x * c + point.z * s, point.y, -point.x * s + point.z * c);
}

vec3 rotateZ(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(point.x * c - point.y * s, point.x * s + point.y * c, point.z);
}

float segmentParameter(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    return clamp(dot(point - startPoint, segment) / max(dot(segment, segment), 0.000001), 0.0, 1.0);
}

float segmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    return length(point - mix(startPoint, endPoint, segmentParameter(point, startPoint, endPoint)));
}

float gaussianPoint(vec2 delta, float radius) {
    return exp(-dot(delta, delta) / max(radius * radius, 0.000001));
}

float backgroundCellMask(vec4 terminalColor) {
    float colorDifference = length(terminalColor.rgb - iBackgroundColor);
    float colorMatch = 1.0 - smoothstep(0.030, 0.245, colorDifference);
    float darkFallback = 1.0 - smoothstep(0.12, 0.58, luminance(terminalColor.rgb));
    float transparent = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(colorMatch, darkFallback * transparent * 0.48));
}

vec2 cursorCenterPixels(vec4 cursorRectangle) {
    return vec2(cursorRectangle.x + cursorRectangle.z * 0.5, cursorRectangle.y - cursorRectangle.w * 0.5);
}

vec2 scenePoint(vec2 pixelPoint) {
    return (pixelPoint - 0.5 * iResolution.xy) / max(iResolution.y, 1.0);
}

float insideCursorRectangle(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(cursorRectangle.x, cursorRectangle.y - cursorRectangle.w);
    vec2 maximumPoint = vec2(cursorRectangle.x + cursorRectangle.z, cursorRectangle.y);
    return step(minimumPoint.x, point.x) * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x) * step(point.y, maximumPoint.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 original = texture(iChannel0, uv);
    fragColor = original;
    if (iCursorVisible == 0) return;

    vec2 headPixels = cursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = cursorCenterPixels(iPreviousCursor);
    vec2 movementPixels = headPixels - tailPixels;
    float movedPixels = length(movementPixels);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float age = saturate((iTime - iTimeCursorChange) / EFFECT_DURATION);
    if (cursorPixels <= 0.0 || movedPixels <= cursorPixels * 0.025 || age >= 1.0) return;

    float movementFactor = smoothstep(cursorPixels * 0.08, cursorPixels * 8.0, movedPixels);
    float cullRadius = cursorPixels * mix(3.4, 6.4, movementFactor);
    if (any(lessThan(fragCoord, min(headPixels, tailPixels) - vec2(cullRadius)))
        || any(greaterThan(fragCoord, max(headPixels, tailPixels) + vec2(cullRadius)))) return;

    vec2 point = scenePoint(fragCoord);
    vec2 head = scenePoint(headPixels);
    vec2 tail = scenePoint(tailPixels);
    vec2 movement = head - tail;
    float movementLength = length(movement);
    vec2 direction = movement / max(movementLength, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - age, 1.75);
    float contentMask = mix(0.18, 1.0, backgroundCellMask(original));

    float trailDistance = segmentDistance(point, tail, head);
    float along = segmentParameter(point, tail, head);
    float trailWidth = cursorSize * mix(0.11, 0.23, movementFactor);
    float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
        * smoothstep(0.0, 0.20, along) * life;
    float trailGlow = exp(-trailDistance / max(trailWidth * 4.0, 0.0004))
        * smoothstep(0.0, 0.17, along) * life;
    vec3 trailColor = mix(DIAMOND_VIOLET, DIAMOND_CYAN, along);
    trailColor = mix(trailColor, DIAMOND_ROSE, smoothstep(0.78, 1.0, along) * 0.38);
    fragColor.rgb += trailColor * trailGlow * 0.055 * contentMask;
    fragColor.rgb += trailColor * trailCore * 0.24 * contentMask;

    vec3 localVertex[6];
    localVertex[0] = vec3( 1.0, 0.0, 0.0);
    localVertex[1] = vec3(-1.0, 0.0, 0.0);
    localVertex[2] = vec3(0.0,  1.0, 0.0);
    localVertex[3] = vec3(0.0, -1.0, 0.0);
    localVertex[4] = vec3(0.0, 0.0,  1.0);
    localVertex[5] = vec3(0.0, 0.0, -1.0);
    vec2 projected[6];
    float depth[6];
    float diamondSize = cursorSize * mix(1.00, 2.10, movementFactor)
        * (1.0 + 0.12 * sin(age * PI));
    float angleX = 0.42 + iTime * 0.72;
    float angleY = -0.58 + iTime * 0.93;
    float angleZ = atan(direction.y, direction.x) * 0.22 + iTime * 0.20;
    float cameraDistance = 3.8;

    for (int vertexIndex = 0; vertexIndex < 6; vertexIndex++) {
        vec3 vertex = localVertex[vertexIndex];
        vertex = rotateX(vertex, angleX);
        vertex = rotateY(vertex, angleY);
        vertex = rotateZ(vertex, angleZ);
        depth[vertexIndex] = cameraDistance - vertex.z;
        projected[vertexIndex] = head
            + vertex.xy * diamondSize * cameraDistance / depth[vertexIndex];
    }

    const int edgeA[12] = int[12](0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3);
    const int edgeB[12] = int[12](2, 3, 4, 5, 2, 3, 4, 5, 4, 5, 4, 5);
    vec3 diamondLight = vec3(0.0);

    for (int edgeIndex = 0; edgeIndex < 12; edgeIndex++) {
        int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
        float nearFactor = saturate((4.7 - 0.5 * (depth[first] + depth[second])) / 1.8);
        float distanceValue = segmentDistance(point, projected[first], projected[second]);
        float core = exp(-distanceValue / max(cursorSize * 0.042, 0.00010));
        float glow = exp(-distanceValue / max(cursorSize * 0.17, 0.00025));
        vec3 edgeColor = mix(DIAMOND_VIOLET, DIAMOND_CYAN, nearFactor);
        edgeColor = mix(edgeColor, DIAMOND_WHITE, nearFactor * 0.36);
        diamondLight += edgeColor * (core * 0.50 + glow * 0.075);

        float echoScale = mix(1.04, 2.25, easedAge);
        vec2 echoFirst = head + (projected[first] - head) * echoScale;
        vec2 echoSecond = head + (projected[second] - head) * echoScale;
        float echoDistance = segmentDistance(point, echoFirst, echoSecond);
        float echo = exp(-echoDistance / max(cursorSize * 0.050, 0.00012))
            * (1.0 - easedAge);
        diamondLight += mix(DIAMOND_BLUE, DIAMOND_VIOLET, nearFactor)
            * echo * 0.17;
    }

    float centerGlow = gaussianPoint(point - head, diamondSize * 0.65);
    diamondLight += mix(DIAMOND_BLUE, DIAMOND_VIOLET, 0.48) * centerGlow * 0.060;
    fragColor.rgb += diamondLight * life * contentMask;

#if PERF_DIAMOND_SPARKS > 0
    vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
    for (int sparkIndex = 0; sparkIndex < PERF_DIAMOND_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
        float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
        vec2 sparkCenter = mix(tail, head, positionRandom)
            + normal * (sideRandom - 0.5) * cursorSize * 1.6;
        float spark = gaussianPoint(point - sparkCenter, cursorSize * 0.075) * life;
        fragColor.rgb += mix(DIAMOND_CYAN, DIAMOND_ROSE, sideRandom)
            * spark * 0.25 * contentMask;
    }
#endif

    float cursorCoverage = insideCursorRectangle(fragCoord, iCurrentCursor);
    fragColor = mix(fragColor, original, cursorCoverage);
    fragColor.a = original.a;
}
