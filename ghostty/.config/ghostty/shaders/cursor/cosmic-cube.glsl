// Cosmic Cube cursor — configurable true-3D wireframe cube for Ghostty
// The control panel separates timing, movement response, size, rotation, echoes,
// trail, sparks, line rendering, colors, and terminal protection.

// =============================================================================
// GPU PROFILE AND QUANTITY SWITCHES
// =============================================================================

#define CUBE_GPU_ECO      0
#define CUBE_GPU_BALANCED 1
#define CUBE_GPU_QUALITY  2
#define CUBE_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE CUBE_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == CUBE_GPU_ECO
#define CUBE_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == CUBE_GPU_BALANCED
#define CUBE_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == CUBE_GPU_QUALITY
#define CUBE_SPARK_COUNT 4
#else
#define CUBE_SPARK_COUNT 7
#endif

#define CUBE_ECHO_COUNT 2          // quantity: 0..4 recommended
#define CUBE_ENABLE_TRAIL 1
#define CUBE_ENABLE_SPARKS 1
#define CUBE_ENABLE_HALO 1

// =============================================================================
// MASTER TIMING AND MOVEMENT RESPONSE
// =============================================================================

const float CUBE_EFFECT_DURATION = 0.30;          // seconds after movement
const float CUBE_FADE_POWER = 1.80;
const float CUBE_MIN_MOVEMENT_CELLS = 0.025;      // ignore smaller changes
const float CUBE_GROWTH_START_CELLS = 0.08;
const float CUBE_GROWTH_FULL_CELLS = 8.00;
const float CUBE_MOVEMENT_RESPONSE_POWER = 1.00;
const float CUBE_CONTENT_PROTECTION = 0.18;
const float CUBE_CULL_RADIUS_MIN = 3.20;           // cursor-cell multiples
const float CUBE_CULL_RADIUS_MAX = 6.00;
const float CUBE_MASTER_BRIGHTNESS = 1.00;

// =============================================================================
// CUBE SIZE, PERSPECTIVE, AND ROTATION
// =============================================================================

const float CUBE_SIZE_MIN = 0.78;                 // cursor-cell multiples
const float CUBE_SIZE_MAX = 1.72;
const float CUBE_SIZE_PULSE = 0.10;
const float CUBE_CAMERA_DISTANCE = 4.00;
const float CUBE_ROTATION_X_BASE = 0.58;
const float CUBE_ROTATION_Y_BASE = -0.68;
const float CUBE_ROTATION_Z_BASE = 0.00;
const float CUBE_ROTATION_X_SPEED = 0.24;
const float CUBE_ROTATION_Y_SPEED = 0.31;
const float CUBE_ROTATION_Z_SPEED = 0.00;
const float CUBE_MOVEMENT_DIRECTION_TILT = 0.12;

// =============================================================================
// WIREFRAME AND DEPTH LIGHTING
// =============================================================================

const float CUBE_EDGE_CORE_WIDTH = 0.040;
const float CUBE_EDGE_GLOW_WIDTH = 0.150;
const float CUBE_EDGE_CORE_STRENGTH = 0.48;
const float CUBE_EDGE_GLOW_STRENGTH = 0.075;
const float CUBE_NEAR_DEPTH_CENTER = 4.90;
const float CUBE_NEAR_DEPTH_RANGE = 1.80;
const float CUBE_NEAR_WHITE_MIX = 0.34;

// =============================================================================
// EXPANDING CUBE ECHOES
// =============================================================================

const float CUBE_ECHO_START_SCALE = 1.02;
const float CUBE_ECHO_END_SCALE = 2.15;
const float CUBE_ECHO_DELAY = 0.13;               // normalized lifetime / echo
const float CUBE_ECHO_WIDTH = 0.050;
const float CUBE_ECHO_STRENGTH = 0.16;
const float CUBE_ECHO_STRENGTH_FALLOFF = 0.72;
const float CUBE_ECHO_FADE_POWER = 1.00;

// =============================================================================
// COMET TRAIL
// =============================================================================

const float CUBE_TRAIL_WIDTH_MIN = 0.12;
const float CUBE_TRAIL_WIDTH_MAX = 0.25;
const float CUBE_TRAIL_GLOW_MULTIPLIER = 3.80;
const float CUBE_TRAIL_GLOW_STRENGTH = 0.055;
const float CUBE_TRAIL_CORE_STRENGTH = 0.24;
const float CUBE_TRAIL_TAIL_FADE = 0.22;
const float CUBE_TRAIL_GOLD_START = 0.72;

// =============================================================================
// SQUARE HALO AND SPARKS
// =============================================================================

const float CUBE_HALO_RADIUS = 1.70;
const float CUBE_HALO_STRENGTH = 0.025;
const float CUBE_SPARK_RADIUS = 0.075;
const float CUBE_SPARK_SPREAD = 1.50;
const float CUBE_SPARK_STRENGTH = 0.24;
const float CUBE_SPARK_POSITION_SEED = 11.70;

// =============================================================================
// COLORS
// =============================================================================

const vec3 CUBE_CYAN   = vec3(0.300, 0.760, 1.000);
const vec3 CUBE_BLUE   = vec3(0.260, 0.390, 1.000);
const vec3 CUBE_VIOLET = vec3(0.650, 0.350, 0.980);
const vec3 CUBE_GOLD   = vec3(1.000, 0.790, 0.360);
const vec3 CUBE_WHITE  = vec3(0.970, 0.970, 1.000);

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
    return clamp(
        dot(point - startPoint, segment) / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );
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
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
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
    float age = saturate((iTime - iTimeCursorChange) / CUBE_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * CUBE_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = pow(
        smoothstep(
            cursorPixels * CUBE_GROWTH_START_CELLS,
            cursorPixels * CUBE_GROWTH_FULL_CELLS,
            movedPixels
        ),
        CUBE_MOVEMENT_RESPONSE_POWER
    );
    float cullRadius = cursorPixels * mix(
        CUBE_CULL_RADIUS_MIN,
        CUBE_CULL_RADIUS_MAX,
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
    float life = pow(1.0 - age, CUBE_FADE_POWER);
    float contentMask = mix(CUBE_CONTENT_PROTECTION, 1.0, backgroundCellMask(original));

#if CUBE_ENABLE_TRAIL
    float trailDistance = segmentDistance(point, tail, head);
    float along = segmentParameter(point, tail, head);
    float trailWidth = cursorSize * mix(
        CUBE_TRAIL_WIDTH_MIN,
        CUBE_TRAIL_WIDTH_MAX,
        movementFactor
    );
    float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
        * smoothstep(0.0, CUBE_TRAIL_TAIL_FADE, along) * life;
    float trailGlow = exp(-trailDistance / max(trailWidth * CUBE_TRAIL_GLOW_MULTIPLIER, 0.0004))
        * smoothstep(0.0, CUBE_TRAIL_TAIL_FADE * 0.82, along) * life;
    vec3 trailColor = mix(CUBE_VIOLET, CUBE_CYAN, smoothstep(0.05, 0.72, along));
    trailColor = mix(trailColor, CUBE_GOLD, smoothstep(CUBE_TRAIL_GOLD_START, 1.0, along));
    fragColor.rgb += trailColor * trailGlow * CUBE_TRAIL_GLOW_STRENGTH * contentMask;
    fragColor.rgb += trailColor * trailCore * CUBE_TRAIL_CORE_STRENGTH * contentMask;
#endif

    vec2 projected[8];
    float depth[8];
    float cubeHalf = cursorSize * mix(CUBE_SIZE_MIN, CUBE_SIZE_MAX, movementFactor)
        * (1.0 + CUBE_SIZE_PULSE * sin(age * PI));
    float angleX = CUBE_ROTATION_X_BASE + iTime * CUBE_ROTATION_X_SPEED;
    float angleY = CUBE_ROTATION_Y_BASE + iTime * CUBE_ROTATION_Y_SPEED;
    float angleZ = CUBE_ROTATION_Z_BASE + iTime * CUBE_ROTATION_Z_SPEED
        + atan(direction.y, direction.x) * CUBE_MOVEMENT_DIRECTION_TILT;

    for (int vertexIndex = 0; vertexIndex < 8; vertexIndex++) {
        vec3 vertex = vec3(
            (vertexIndex & 1) != 0 ? 1.0 : -1.0,
            (vertexIndex & 2) != 0 ? 1.0 : -1.0,
            (vertexIndex & 4) != 0 ? 1.0 : -1.0
        );
        vertex = rotateZ(rotateY(rotateX(vertex, angleX), angleY), angleZ);
        depth[vertexIndex] = CUBE_CAMERA_DISTANCE - vertex.z;
        projected[vertexIndex] = head
            + vertex.xy * cubeHalf * CUBE_CAMERA_DISTANCE / depth[vertexIndex];
    }

    const int edgeA[12] = int[12](0,1,3,2, 4,5,7,6, 0,1,2,3);
    const int edgeB[12] = int[12](1,3,2,0, 5,7,6,4, 4,5,6,7);
    vec3 cubeLight = vec3(0.0);

    for (int edgeIndex = 0; edgeIndex < 12; edgeIndex++) {
        int first = edgeA[edgeIndex];
        int second = edgeB[edgeIndex];
        float edgeDepth = 0.5 * (depth[first] + depth[second]);
        float nearFactor = saturate(
            (CUBE_NEAR_DEPTH_CENTER - edgeDepth) / CUBE_NEAR_DEPTH_RANGE
        );
        float distanceValue = segmentDistance(point, projected[first], projected[second]);
        float core = exp(-distanceValue / max(cursorSize * CUBE_EDGE_CORE_WIDTH, 0.00010));
        float glow = exp(-distanceValue / max(cursorSize * CUBE_EDGE_GLOW_WIDTH, 0.00025));
        vec3 edgeColor = mix(CUBE_VIOLET, CUBE_CYAN, nearFactor);
        edgeColor = mix(edgeColor, CUBE_WHITE, nearFactor * CUBE_NEAR_WHITE_MIX);
        cubeLight += edgeColor * (
            core * CUBE_EDGE_CORE_STRENGTH
            + glow * CUBE_EDGE_GLOW_STRENGTH
        );

        for (int echoIndex = 0; echoIndex < CUBE_ECHO_COUNT; echoIndex++) {
            float delay = float(echoIndex) * CUBE_ECHO_DELAY;
            float echoProgress = saturate(
                (easedAge - delay) / max(1.0 - delay, 0.001)
            );
            float echoActive = step(delay, easedAge);
            float echoScale = mix(
                CUBE_ECHO_START_SCALE,
                CUBE_ECHO_END_SCALE,
                echoProgress
            );
            vec2 echoFirst = head + (projected[first] - head) * echoScale;
            vec2 echoSecond = head + (projected[second] - head) * echoScale;
            float echoDistance = segmentDistance(point, echoFirst, echoSecond);
            float echo = exp(
                -echoDistance / max(cursorSize * CUBE_ECHO_WIDTH, 0.00012)
            ) * pow(1.0 - echoProgress, CUBE_ECHO_FADE_POWER) * echoActive;
            float echoGain = CUBE_ECHO_STRENGTH
                * pow(CUBE_ECHO_STRENGTH_FALLOFF, float(echoIndex));
            cubeLight += mix(CUBE_BLUE, CUBE_VIOLET, nearFactor) * echo * echoGain;
        }
    }

#if CUBE_ENABLE_HALO
    float squareHaloDistance = max(abs(point.x - head.x), abs(point.y - head.y));
    float squareHalo = exp(-squareHaloDistance / max(cubeHalf * CUBE_HALO_RADIUS, 0.0005));
    cubeLight += mix(CUBE_BLUE, CUBE_VIOLET, 0.45)
        * squareHalo * CUBE_HALO_STRENGTH;
#endif
    fragColor.rgb += cubeLight * life * contentMask * CUBE_MASTER_BRIGHTNESS;

#if CUBE_ENABLE_SPARKS && CUBE_SPARK_COUNT > 0
    vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
    for (int sparkIndex = 0; sparkIndex < CUBE_SPARK_COUNT; sparkIndex++) {
        float index = float(sparkIndex);
        float positionRandom = hash12(eventSeed + vec2(index * CUBE_SPARK_POSITION_SEED, index * 31.9));
        float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
        vec2 sparkCenter = mix(tail, head, positionRandom)
            + normal * (sideRandom - 0.5) * cursorSize * CUBE_SPARK_SPREAD;
        float spark = gaussianPoint(point - sparkCenter, cursorSize * CUBE_SPARK_RADIUS) * life;
        fragColor.rgb += mix(CUBE_CYAN, CUBE_GOLD, sideRandom)
            * spark * CUBE_SPARK_STRENGTH * contentMask;
    }
#endif

    float cursorCoverage = insideCursorRectangle(fragCoord, iCurrentCursor);
    fragColor = mix(fragColor, original, cursorCoverage);
    fragColor.a = original.a;
}
