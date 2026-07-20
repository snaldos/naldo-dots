// Cosmic Stellated cursor — expanding 14-vertex crystal from crystal-pet.glsl
// The shape rotates in true 3D, grows with movement, emits a larger wireframe
// echo, and keeps the cosmic cursor's restrained comet trail.

#define STELLATED_GPU_ECO      0
#define STELLATED_GPU_BALANCED 1
#define STELLATED_GPU_QUALITY  2
#define STELLATED_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE STELLATED_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == STELLATED_GPU_ECO
#define PERF_STELLATED_SPARKS 0
#elif GHOSTTY_GPU_PROFILE == STELLATED_GPU_BALANCED
#define PERF_STELLATED_SPARKS 2
#elif GHOSTTY_GPU_PROFILE == STELLATED_GPU_QUALITY
#define PERF_STELLATED_SPARKS 4
#else
#define PERF_STELLATED_SPARKS 7
#endif

const float PI = 3.14159265359;
const float EFFECT_DURATION = 0.36;
const vec3 STAR_CYAN = vec3(0.180, 0.820, 1.000);
const vec3 STAR_BLUE = vec3(0.140, 0.300, 1.000);
const vec3 STAR_VIOLET = vec3(0.650, 0.260, 1.000);
const vec3 STAR_DEEP = vec3(0.130, 0.070, 0.420);
const vec3 STAR_WHITE = vec3(0.980, 0.950, 1.000);
const vec3 STAR_GOLD = vec3(1.000, 0.760, 0.340);

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
    float cullRadius = cursorPixels * mix(4.2, 7.8, movementFactor);
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
    float life = pow(1.0 - age, 1.70);
    float contentMask = mix(0.18, 1.0, backgroundCellMask(original));

    float trailDistance = segmentDistance(point, tail, head);
    float along = segmentParameter(point, tail, head);
    float trailWidth = cursorSize * mix(0.12, 0.25, movementFactor);
    float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
        * smoothstep(0.0, 0.20, along) * life;
    float trailGlow = exp(-trailDistance / max(trailWidth * 4.2, 0.0004))
        * smoothstep(0.0, 0.17, along) * life;
    vec3 trailColor = mix(STAR_VIOLET, STAR_CYAN, smoothstep(0.05, 0.72, along));
    trailColor = mix(trailColor, STAR_GOLD, smoothstep(0.78, 1.0, along) * 0.52);
    fragColor.rgb += trailColor * trailGlow * 0.055 * contentMask;
    fragColor.rgb += trailColor * trailCore * 0.24 * contentMask;

    vec3 localVertex[14];
    vec2 projected[14];
    float depth[14];
    float side = 0.46;
    localVertex[0] = vec3(-side,  side, -side);
    localVertex[1] = vec3( side,  side, -side);
    localVertex[2] = vec3( side, -side, -side);
    localVertex[3] = vec3(-side, -side, -side);
    localVertex[4] = vec3(-side,  side,  side);
    localVertex[5] = vec3( side,  side,  side);
    localVertex[6] = vec3( side, -side,  side);
    localVertex[7] = vec3(-side, -side,  side);
    localVertex[8]  = vec3(0.0,  side * 3.0, 0.0);
    localVertex[9]  = vec3(0.0, -side * 3.0, 0.0);
    localVertex[10] = vec3( side * 3.0, 0.0, 0.0);
    localVertex[11] = vec3(-side * 3.0, 0.0, 0.0);
    localVertex[12] = vec3(0.0, 0.0, -side * 3.0);
    localVertex[13] = vec3(0.0, 0.0,  side * 3.0);

    float shapeScale = cursorSize * mix(0.86, 1.72, movementFactor)
        * (1.0 + 0.14 * sin(age * PI));
    float angleX = iTime * 0.92 + age * 0.7;
    float angleY = iTime * -1.08 + age * 0.9;
    float angleZ = iTime * 0.44 + atan(direction.y, direction.x) * 0.18;
    float cameraDistance = 4.2;
    for (int vertexIndex = 0; vertexIndex < 14; vertexIndex++) {
        vec3 vertex = localVertex[vertexIndex];
        vertex = rotateY(vertex, angleY);
        vertex = rotateX(vertex, angleX);
        vertex = rotateZ(vertex, angleZ);
        depth[vertexIndex] = cameraDistance - vertex.z;
        projected[vertexIndex] = head
            + vertex.xy * shapeScale * cameraDistance / depth[vertexIndex];
    }

    const int edgeA[36] = int[36](
        0,1,2,3, 4,5,6,7, 0,1,2,3,
        0,1,4,5, 3,2,7,6, 1,2,5,6,
        0,3,4,7, 0,1,2,3, 4,5,6,7
    );
    const int edgeB[36] = int[36](
        1,2,3,0, 5,6,7,4, 4,5,6,7,
        8,8,8,8, 9,9,9,9, 10,10,10,10,
        11,11,11,11, 12,12,12,12, 13,13,13,13
    );

    vec3 shapeLight = vec3(0.0);
    for (int edgeIndex = 0; edgeIndex < 36; edgeIndex++) {
        int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
        float nearFactor = saturate((5.2 - 0.5 * (depth[first] + depth[second])) / 2.2);
        float distanceValue = segmentDistance(point, projected[first], projected[second]);
        float core = exp(-distanceValue / max(cursorSize * 0.038, 0.00010));
        float glow = exp(-distanceValue / max(cursorSize * 0.14, 0.00024));
        vec3 edgeColor = mix(STAR_DEEP, STAR_CYAN, nearFactor);
        edgeColor = mix(edgeColor, STAR_WHITE, nearFactor * 0.40);
        shapeLight += edgeColor * (core * 0.34 + glow * 0.040);

        float echoScale = mix(1.03, 2.05, easedAge);
        vec2 echoFirst = head + (projected[first] - head) * echoScale;
        vec2 echoSecond = head + (projected[second] - head) * echoScale;
        float echoDistance = segmentDistance(point, echoFirst, echoSecond);
        float echo = exp(-echoDistance / max(cursorSize * 0.046, 0.00011))
            * (1.0 - easedAge);
        shapeLight += mix(STAR_BLUE, STAR_VIOLET, nearFactor) * echo * 0.085;
    }

    float centerGlow = gaussianPoint(point - head, shapeScale * 0.72);
    shapeLight += mix(STAR_BLUE, STAR_VIOLET, 0.50) * centerGlow * 0.070;
    fragColor.rgb += shapeLight * life * contentMask;

#if PERF_STELLATED_SPARKS > 0
    vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
    for (int sparkIndex = 0; sparkIndex < PERF_STELLATED_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
        float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
        vec2 sparkCenter = mix(tail, head, positionRandom)
            + normal * (sideRandom - 0.5) * cursorSize * 1.8;
        float spark = gaussianPoint(point - sparkCenter, cursorSize * 0.070) * life;
        fragColor.rgb += mix(STAR_CYAN, STAR_GOLD, sideRandom)
            * spark * 0.22 * contentMask;
    }
#endif

    float cursorCoverage = insideCursorRectangle(fragCoord, iCurrentCursor);
    fragColor = mix(fragColor, original, cursorCoverage);
    fragColor.a = original.a;
}
