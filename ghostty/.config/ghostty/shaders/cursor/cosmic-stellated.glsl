// Cosmic Stellated cursor — configurable crystal-pet geometry for Ghostty
// A 14-vertex stellated cube grows with movement, rotates in true 3D, and emits
// delayed shape echoes plus a cosmic trail.

// =============================================================================
// GPU PROFILE AND QUANTITY SWITCHES
// =============================================================================

#define STELLATED_GPU_ECO      0
#define STELLATED_GPU_BALANCED 1
#define STELLATED_GPU_QUALITY  2
#define STELLATED_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE STELLATED_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == STELLATED_GPU_ECO
#define STELLATED_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == STELLATED_GPU_BALANCED
#define STELLATED_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == STELLATED_GPU_QUALITY
#define STELLATED_SPARK_COUNT 4
#else
#define STELLATED_SPARK_COUNT 7
#endif

#define STELLATED_ECHO_COUNT 2       // quantity: 0..3 recommended
#define STELLATED_ENABLE_TRAIL 1
#define STELLATED_ENABLE_SPARKS 1
#define STELLATED_ENABLE_CORE_GLOW 1

// =============================================================================
// MASTER TIMING AND MOVEMENT RESPONSE
// =============================================================================

const float STELLATED_EFFECT_DURATION = 0.36;
const float STELLATED_FADE_POWER = 1.70;
const float STELLATED_MIN_MOVEMENT_CELLS = 0.025;
const float STELLATED_GROWTH_START_CELLS = 0.08;
const float STELLATED_GROWTH_FULL_CELLS = 8.00;
const float STELLATED_MOVEMENT_RESPONSE_POWER = 1.00;
const float STELLATED_CONTENT_PROTECTION = 0.18;
const float STELLATED_CULL_RADIUS_MIN = 4.20;
const float STELLATED_CULL_RADIUS_MAX = 7.80;
const float STELLATED_MASTER_BRIGHTNESS = 1.00;

// =============================================================================
// GEOMETRY, SIZE, PERSPECTIVE, AND ROTATION
// =============================================================================

const float STELLATED_BASE_HALF_EXTENT = 0.46;
const float STELLATED_TIP_LENGTH = 3.00;
const float STELLATED_SIZE_MIN = 0.86;
const float STELLATED_SIZE_MAX = 1.72;
const float STELLATED_SIZE_PULSE = 0.14;
const float STELLATED_CAMERA_DISTANCE = 4.20;
const float STELLATED_ROTATION_X_BASE = 0.00;
const float STELLATED_ROTATION_Y_BASE = 0.00;
const float STELLATED_ROTATION_Z_BASE = 0.00;
const float STELLATED_ROTATION_X_SPEED = 0.92;
const float STELLATED_ROTATION_Y_SPEED = -1.08;
const float STELLATED_ROTATION_Z_SPEED = 0.44;
const float STELLATED_AGE_ROTATION_X = 0.70;
const float STELLATED_AGE_ROTATION_Y = 0.90;
const float STELLATED_MOVEMENT_DIRECTION_TILT = 0.18;

// =============================================================================
// WIREFRAME AND DEPTH LIGHTING
// =============================================================================

const float STELLATED_EDGE_CORE_WIDTH = 0.038;
const float STELLATED_EDGE_GLOW_WIDTH = 0.140;
const float STELLATED_EDGE_CORE_STRENGTH = 0.34;
const float STELLATED_EDGE_GLOW_STRENGTH = 0.040;
const float STELLATED_NEAR_DEPTH_CENTER = 5.20;
const float STELLATED_NEAR_DEPTH_RANGE = 2.20;
const float STELLATED_NEAR_WHITE_MIX = 0.40;

// =============================================================================
// EXPANDING STELLATED ECHOES
// =============================================================================

const float STELLATED_ECHO_START_SCALE = 1.03;
const float STELLATED_ECHO_END_SCALE = 2.05;
const float STELLATED_ECHO_DELAY = 0.15;
const float STELLATED_ECHO_WIDTH = 0.046;
const float STELLATED_ECHO_STRENGTH = 0.085;
const float STELLATED_ECHO_STRENGTH_FALLOFF = 0.66;
const float STELLATED_ECHO_FADE_POWER = 1.00;

// =============================================================================
// TRAIL, CORE GLOW, AND SPARKS
// =============================================================================

const float STELLATED_TRAIL_WIDTH_MIN = 0.12;
const float STELLATED_TRAIL_WIDTH_MAX = 0.25;
const float STELLATED_TRAIL_GLOW_MULTIPLIER = 4.20;
const float STELLATED_TRAIL_GLOW_STRENGTH = 0.055;
const float STELLATED_TRAIL_CORE_STRENGTH = 0.24;
const float STELLATED_TRAIL_TAIL_FADE = 0.20;
const float STELLATED_TRAIL_GOLD_START = 0.78;
const float STELLATED_TRAIL_GOLD_MIX = 0.52;
const float STELLATED_CORE_GLOW_RADIUS = 0.72;
const float STELLATED_CORE_GLOW_STRENGTH = 0.070;
const float STELLATED_SPARK_RADIUS = 0.070;
const float STELLATED_SPARK_SPREAD = 1.80;
const float STELLATED_SPARK_STRENGTH = 0.22;

// =============================================================================
// COLORS
// =============================================================================

const vec3 STELLATED_CYAN   = vec3(0.180, 0.820, 1.000);
const vec3 STELLATED_BLUE   = vec3(0.140, 0.300, 1.000);
const vec3 STELLATED_VIOLET = vec3(0.650, 0.260, 1.000);
const vec3 STELLATED_DEEP   = vec3(0.130, 0.070, 0.420);
const vec3 STELLATED_WHITE  = vec3(0.980, 0.950, 1.000);
const vec3 STELLATED_GOLD   = vec3(1.000, 0.760, 0.340);

const float PI = 3.14159265359;

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
    float age = saturate((iTime - iTimeCursorChange) / STELLATED_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * STELLATED_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = pow(
        smoothstep(
            cursorPixels * STELLATED_GROWTH_START_CELLS,
            cursorPixels * STELLATED_GROWTH_FULL_CELLS,
            movedPixels
        ),
        STELLATED_MOVEMENT_RESPONSE_POWER
    );
    float cullRadius = cursorPixels * mix(
        STELLATED_CULL_RADIUS_MIN,
        STELLATED_CULL_RADIUS_MAX,
        movementFactor
    );
    if (
        any(lessThan(fragCoord, min(headPixels, tailPixels) - vec2(cullRadius)))
        || any(greaterThan(fragCoord, max(headPixels, tailPixels) + vec2(cullRadius)))
    ) return;

    vec2 point = scenePoint(fragCoord);
    vec2 head = scenePoint(headPixels);
    vec2 tail = scenePoint(tailPixels);
    vec2 movement = head - tail;
    float movementLength = length(movement);
    vec2 direction = movement / max(movementLength, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - age, STELLATED_FADE_POWER);
    float contentMask = mix(STELLATED_CONTENT_PROTECTION, 1.0, backgroundCellMask(original));

#if STELLATED_ENABLE_TRAIL
    float trailDistance = segmentDistance(point, tail, head);
    float along = segmentParameter(point, tail, head);
    float trailWidth = cursorSize * mix(
        STELLATED_TRAIL_WIDTH_MIN,
        STELLATED_TRAIL_WIDTH_MAX,
        movementFactor
    );
    float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
        * smoothstep(0.0, STELLATED_TRAIL_TAIL_FADE, along) * life;
    float trailGlow = exp(
        -trailDistance / max(trailWidth * STELLATED_TRAIL_GLOW_MULTIPLIER, 0.0004)
    ) * smoothstep(0.0, STELLATED_TRAIL_TAIL_FADE * 0.85, along) * life;
    vec3 trailColor = mix(STELLATED_VIOLET, STELLATED_CYAN, smoothstep(0.05, 0.72, along));
    trailColor = mix(
        trailColor,
        STELLATED_GOLD,
        smoothstep(STELLATED_TRAIL_GOLD_START, 1.0, along) * STELLATED_TRAIL_GOLD_MIX
    );
    fragColor.rgb += trailColor * trailGlow * STELLATED_TRAIL_GLOW_STRENGTH * contentMask;
    fragColor.rgb += trailColor * trailCore * STELLATED_TRAIL_CORE_STRENGTH * contentMask;
#endif

    vec3 localVertex[14];
    vec2 projected[14];
    float depth[14];
    float side = STELLATED_BASE_HALF_EXTENT;
    localVertex[0] = vec3(-side,  side, -side);
    localVertex[1] = vec3( side,  side, -side);
    localVertex[2] = vec3( side, -side, -side);
    localVertex[3] = vec3(-side, -side, -side);
    localVertex[4] = vec3(-side,  side,  side);
    localVertex[5] = vec3( side,  side,  side);
    localVertex[6] = vec3( side, -side,  side);
    localVertex[7] = vec3(-side, -side,  side);
    localVertex[8]  = vec3(0.0,  side * STELLATED_TIP_LENGTH, 0.0);
    localVertex[9]  = vec3(0.0, -side * STELLATED_TIP_LENGTH, 0.0);
    localVertex[10] = vec3( side * STELLATED_TIP_LENGTH, 0.0, 0.0);
    localVertex[11] = vec3(-side * STELLATED_TIP_LENGTH, 0.0, 0.0);
    localVertex[12] = vec3(0.0, 0.0, -side * STELLATED_TIP_LENGTH);
    localVertex[13] = vec3(0.0, 0.0,  side * STELLATED_TIP_LENGTH);

    float shapeScale = cursorSize * mix(
        STELLATED_SIZE_MIN,
        STELLATED_SIZE_MAX,
        movementFactor
    ) * (1.0 + STELLATED_SIZE_PULSE * sin(age * PI));
    float angleX = STELLATED_ROTATION_X_BASE
        + iTime * STELLATED_ROTATION_X_SPEED + age * STELLATED_AGE_ROTATION_X;
    float angleY = STELLATED_ROTATION_Y_BASE
        + iTime * STELLATED_ROTATION_Y_SPEED + age * STELLATED_AGE_ROTATION_Y;
    float angleZ = STELLATED_ROTATION_Z_BASE
        + iTime * STELLATED_ROTATION_Z_SPEED
        + atan(direction.y, direction.x) * STELLATED_MOVEMENT_DIRECTION_TILT;

    for (int vertexIndex = 0; vertexIndex < 14; vertexIndex++) {
        vec3 vertex = rotateZ(rotateX(rotateY(localVertex[vertexIndex], angleY), angleX), angleZ);
        depth[vertexIndex] = STELLATED_CAMERA_DISTANCE - vertex.z;
        projected[vertexIndex] = head
            + vertex.xy * shapeScale * STELLATED_CAMERA_DISTANCE / depth[vertexIndex];
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
        float nearFactor = saturate(
            (STELLATED_NEAR_DEPTH_CENTER - 0.5 * (depth[first] + depth[second]))
                / STELLATED_NEAR_DEPTH_RANGE
        );
        float distanceValue = segmentDistance(point, projected[first], projected[second]);
        float core = exp(-distanceValue / max(cursorSize * STELLATED_EDGE_CORE_WIDTH, 0.00010));
        float glow = exp(-distanceValue / max(cursorSize * STELLATED_EDGE_GLOW_WIDTH, 0.00024));
        vec3 edgeColor = mix(STELLATED_DEEP, STELLATED_CYAN, nearFactor);
        edgeColor = mix(edgeColor, STELLATED_WHITE, nearFactor * STELLATED_NEAR_WHITE_MIX);
        shapeLight += edgeColor * (
            core * STELLATED_EDGE_CORE_STRENGTH
            + glow * STELLATED_EDGE_GLOW_STRENGTH
        );

        for (int echoIndex = 0; echoIndex < STELLATED_ECHO_COUNT; echoIndex++) {
            float delay = float(echoIndex) * STELLATED_ECHO_DELAY;
            float echoProgress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
            float echoActive = step(delay, easedAge);
            float echoScale = mix(
                STELLATED_ECHO_START_SCALE,
                STELLATED_ECHO_END_SCALE,
                echoProgress
            );
            vec2 echoFirst = head + (projected[first] - head) * echoScale;
            vec2 echoSecond = head + (projected[second] - head) * echoScale;
            float echoDistance = segmentDistance(point, echoFirst, echoSecond);
            float echo = exp(
                -echoDistance / max(cursorSize * STELLATED_ECHO_WIDTH, 0.00011)
            ) * pow(1.0 - echoProgress, STELLATED_ECHO_FADE_POWER) * echoActive;
            float echoGain = STELLATED_ECHO_STRENGTH
                * pow(STELLATED_ECHO_STRENGTH_FALLOFF, float(echoIndex));
            shapeLight += mix(STELLATED_BLUE, STELLATED_VIOLET, nearFactor)
                * echo * echoGain;
        }
    }

#if STELLATED_ENABLE_CORE_GLOW
    float centerGlow = gaussianPoint(point - head, shapeScale * STELLATED_CORE_GLOW_RADIUS);
    shapeLight += mix(STELLATED_BLUE, STELLATED_VIOLET, 0.50)
        * centerGlow * STELLATED_CORE_GLOW_STRENGTH;
#endif
    fragColor.rgb += shapeLight * life * contentMask * STELLATED_MASTER_BRIGHTNESS;

#if STELLATED_ENABLE_SPARKS && STELLATED_SPARK_COUNT > 0
    vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
    for (int sparkIndex = 0; sparkIndex < STELLATED_SPARK_COUNT; sparkIndex++) {
        float index = float(sparkIndex);
        float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
        float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
        vec2 sparkCenter = mix(tail, head, positionRandom)
            + normal * (sideRandom - 0.5) * cursorSize * STELLATED_SPARK_SPREAD;
        float spark = gaussianPoint(point - sparkCenter, cursorSize * STELLATED_SPARK_RADIUS) * life;
        fragColor.rgb += mix(STELLATED_CYAN, STELLATED_GOLD, sideRandom)
            * spark * STELLATED_SPARK_STRENGTH * contentMask;
    }
#endif

    float cursorCoverage = insideCursorRectangle(fragCoord, iCurrentCursor);
    fragColor = mix(fragColor, original, cursorCoverage);
    fragColor.a = original.a;
}
