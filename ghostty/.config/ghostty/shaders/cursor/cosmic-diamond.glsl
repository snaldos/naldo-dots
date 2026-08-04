// Cosmic Diamond cursor — configurable rotating octahedral cursor for Ghostty
// Movement controls growth; delayed diamond echoes replace circular ripples.

// =============================================================================
// GPU PROFILE AND QUANTITY SWITCHES
// =============================================================================

#define DIAMOND_GPU_ECO      0
#define DIAMOND_GPU_BALANCED 1
#define DIAMOND_GPU_QUALITY  2
#define DIAMOND_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE DIAMOND_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == DIAMOND_GPU_ECO
#define DIAMOND_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == DIAMOND_GPU_BALANCED
#define DIAMOND_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == DIAMOND_GPU_QUALITY
#define DIAMOND_SPARK_COUNT 4
#else
#define DIAMOND_SPARK_COUNT 7
#endif

#define DIAMOND_ECHO_COUNT 2       // quantity: 0..4 recommended
#define DIAMOND_ENABLE_TRAIL 1
#define DIAMOND_ENABLE_SPARKS 1
#define DIAMOND_ENABLE_CORE_GLOW 1

// =============================================================================
// MASTER TIMING AND MOVEMENT RESPONSE
// =============================================================================

const float DIAMOND_EFFECT_DURATION = 0.32;
const float DIAMOND_FADE_POWER = 1.75;
const float DIAMOND_MIN_MOVEMENT_CELLS = 0.025;
const float DIAMOND_GROWTH_START_CELLS = 0.08;
const float DIAMOND_GROWTH_FULL_CELLS = 8.00;
const float DIAMOND_MOVEMENT_RESPONSE_POWER = 1.00;
const float DIAMOND_CONTENT_PROTECTION = 0.18;
const float DIAMOND_CULL_RADIUS_MIN = 3.40;
const float DIAMOND_CULL_RADIUS_MAX = 6.40;
const float DIAMOND_MASTER_BRIGHTNESS = 1.00;

// =============================================================================
// DIAMOND SIZE, PROPORTIONS, PERSPECTIVE, AND ROTATION
// =============================================================================

const float DIAMOND_SIZE_MIN = 1.00;
const float DIAMOND_SIZE_MAX = 2.10;
const float DIAMOND_SIZE_PULSE = 0.12;
const vec3 DIAMOND_AXIS_SCALE = vec3(1.00, 1.00, 1.00);
const float DIAMOND_CAMERA_DISTANCE = 3.80;
const float DIAMOND_ROTATION_X_BASE = 0.42;
const float DIAMOND_ROTATION_Y_BASE = -0.58;
const float DIAMOND_ROTATION_Z_BASE = 0.00;
const float DIAMOND_ROTATION_X_SPEED = 0.72;
const float DIAMOND_ROTATION_Y_SPEED = 0.93;
const float DIAMOND_ROTATION_Z_SPEED = 0.20;
const float DIAMOND_MOVEMENT_DIRECTION_TILT = 0.22;

// =============================================================================
// WIREFRAME AND DEPTH LIGHTING
// =============================================================================

const float DIAMOND_EDGE_CORE_WIDTH = 0.042;
const float DIAMOND_EDGE_GLOW_WIDTH = 0.170;
const float DIAMOND_EDGE_CORE_STRENGTH = 0.50;
const float DIAMOND_EDGE_GLOW_STRENGTH = 0.075;
const float DIAMOND_NEAR_DEPTH_CENTER = 4.70;
const float DIAMOND_NEAR_DEPTH_RANGE = 1.80;
const float DIAMOND_NEAR_WHITE_MIX = 0.36;

// =============================================================================
// EXPANDING DIAMOND ECHOES
// =============================================================================

const float DIAMOND_ECHO_START_SCALE = 1.04;
const float DIAMOND_ECHO_END_SCALE = 2.25;
const float DIAMOND_ECHO_DELAY = 0.14;
const float DIAMOND_ECHO_WIDTH = 0.050;
const float DIAMOND_ECHO_STRENGTH = 0.17;
const float DIAMOND_ECHO_STRENGTH_FALLOFF = 0.70;
const float DIAMOND_ECHO_FADE_POWER = 1.00;

// =============================================================================
// TRAIL, CORE GLOW, AND SPARKS
// =============================================================================

const float DIAMOND_TRAIL_WIDTH_MIN = 0.11;
const float DIAMOND_TRAIL_WIDTH_MAX = 0.23;
const float DIAMOND_TRAIL_GLOW_MULTIPLIER = 4.00;
const float DIAMOND_TRAIL_GLOW_STRENGTH = 0.055;
const float DIAMOND_TRAIL_CORE_STRENGTH = 0.24;
const float DIAMOND_TRAIL_TAIL_FADE = 0.20;
const float DIAMOND_TRAIL_ROSE_START = 0.78;
const float DIAMOND_TRAIL_ROSE_MIX = 0.38;
const float DIAMOND_CORE_GLOW_RADIUS = 0.65;
const float DIAMOND_CORE_GLOW_STRENGTH = 0.060;
const float DIAMOND_SPARK_RADIUS = 0.075;
const float DIAMOND_SPARK_SPREAD = 1.60;
const float DIAMOND_SPARK_STRENGTH = 0.25;

// =============================================================================
// COLORS
// =============================================================================

const vec3 DIAMOND_CYAN   = vec3(0.180, 0.840, 1.000);
const vec3 DIAMOND_BLUE   = vec3(0.180, 0.320, 1.000);
const vec3 DIAMOND_VIOLET = vec3(0.680, 0.280, 1.000);
const vec3 DIAMOND_ROSE   = vec3(0.980, 0.220, 0.650);
const vec3 DIAMOND_WHITE  = vec3(0.980, 0.960, 1.000);

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
    float age = saturate((iTime - iTimeCursorChange) / DIAMOND_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * DIAMOND_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = pow(
        smoothstep(
            cursorPixels * DIAMOND_GROWTH_START_CELLS,
            cursorPixels * DIAMOND_GROWTH_FULL_CELLS,
            movedPixels
        ),
        DIAMOND_MOVEMENT_RESPONSE_POWER
    );
    float cullRadius = cursorPixels * mix(
        DIAMOND_CULL_RADIUS_MIN,
        DIAMOND_CULL_RADIUS_MAX,
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
    float life = pow(1.0 - age, DIAMOND_FADE_POWER);
    float contentMask = mix(DIAMOND_CONTENT_PROTECTION, 1.0, backgroundCellMask(original));

#if DIAMOND_ENABLE_TRAIL
    float trailDistance = segmentDistance(point, tail, head);
    float along = segmentParameter(point, tail, head);
    float trailWidth = cursorSize * mix(
        DIAMOND_TRAIL_WIDTH_MIN,
        DIAMOND_TRAIL_WIDTH_MAX,
        movementFactor
    );
    float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
        * smoothstep(0.0, DIAMOND_TRAIL_TAIL_FADE, along) * life;
    float trailGlow = exp(
        -trailDistance / max(trailWidth * DIAMOND_TRAIL_GLOW_MULTIPLIER, 0.0004)
    ) * smoothstep(0.0, DIAMOND_TRAIL_TAIL_FADE * 0.85, along) * life;
    vec3 trailColor = mix(DIAMOND_VIOLET, DIAMOND_CYAN, along);
    trailColor = mix(
        trailColor,
        DIAMOND_ROSE,
        smoothstep(DIAMOND_TRAIL_ROSE_START, 1.0, along) * DIAMOND_TRAIL_ROSE_MIX
    );
    fragColor.rgb += trailColor * trailGlow * DIAMOND_TRAIL_GLOW_STRENGTH * contentMask;
    fragColor.rgb += trailColor * trailCore * DIAMOND_TRAIL_CORE_STRENGTH * contentMask;
#endif

    vec3 localVertex[6];
    localVertex[0] = vec3( 1.0, 0.0, 0.0) * DIAMOND_AXIS_SCALE;
    localVertex[1] = vec3(-1.0, 0.0, 0.0) * DIAMOND_AXIS_SCALE;
    localVertex[2] = vec3(0.0,  1.0, 0.0) * DIAMOND_AXIS_SCALE;
    localVertex[3] = vec3(0.0, -1.0, 0.0) * DIAMOND_AXIS_SCALE;
    localVertex[4] = vec3(0.0, 0.0,  1.0) * DIAMOND_AXIS_SCALE;
    localVertex[5] = vec3(0.0, 0.0, -1.0) * DIAMOND_AXIS_SCALE;
    vec2 projected[6];
    float depth[6];
    float diamondSize = cursorSize * mix(DIAMOND_SIZE_MIN, DIAMOND_SIZE_MAX, movementFactor)
        * (1.0 + DIAMOND_SIZE_PULSE * sin(age * PI));
    float angleX = DIAMOND_ROTATION_X_BASE + iTime * DIAMOND_ROTATION_X_SPEED;
    float angleY = DIAMOND_ROTATION_Y_BASE + iTime * DIAMOND_ROTATION_Y_SPEED;
    float angleZ = DIAMOND_ROTATION_Z_BASE + iTime * DIAMOND_ROTATION_Z_SPEED
        + atan(direction.y, direction.x) * DIAMOND_MOVEMENT_DIRECTION_TILT;

    for (int vertexIndex = 0; vertexIndex < 6; vertexIndex++) {
        vec3 vertex = rotateZ(rotateY(rotateX(localVertex[vertexIndex], angleX), angleY), angleZ);
        depth[vertexIndex] = DIAMOND_CAMERA_DISTANCE - vertex.z;
        projected[vertexIndex] = head
            + vertex.xy * diamondSize * DIAMOND_CAMERA_DISTANCE / depth[vertexIndex];
    }

    const int edgeA[12] = int[12](0,0,0,0, 1,1,1,1, 2,2,3,3);
    const int edgeB[12] = int[12](2,3,4,5, 2,3,4,5, 4,5,4,5);
    vec3 diamondLight = vec3(0.0);

    for (int edgeIndex = 0; edgeIndex < 12; edgeIndex++) {
        int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
        float nearFactor = saturate(
            (DIAMOND_NEAR_DEPTH_CENTER - 0.5 * (depth[first] + depth[second]))
                / DIAMOND_NEAR_DEPTH_RANGE
        );
        float distanceValue = segmentDistance(point, projected[first], projected[second]);
        float core = exp(-distanceValue / max(cursorSize * DIAMOND_EDGE_CORE_WIDTH, 0.00010));
        float glow = exp(-distanceValue / max(cursorSize * DIAMOND_EDGE_GLOW_WIDTH, 0.00025));
        vec3 edgeColor = mix(DIAMOND_VIOLET, DIAMOND_CYAN, nearFactor);
        edgeColor = mix(edgeColor, DIAMOND_WHITE, nearFactor * DIAMOND_NEAR_WHITE_MIX);
        diamondLight += edgeColor * (
            core * DIAMOND_EDGE_CORE_STRENGTH
            + glow * DIAMOND_EDGE_GLOW_STRENGTH
        );

        for (int echoIndex = 0; echoIndex < DIAMOND_ECHO_COUNT; echoIndex++) {
            float delay = float(echoIndex) * DIAMOND_ECHO_DELAY;
            float echoProgress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
            float echoActive = step(delay, easedAge);
            float echoScale = mix(
                DIAMOND_ECHO_START_SCALE,
                DIAMOND_ECHO_END_SCALE,
                echoProgress
            );
            vec2 echoFirst = head + (projected[first] - head) * echoScale;
            vec2 echoSecond = head + (projected[second] - head) * echoScale;
            float echoDistance = segmentDistance(point, echoFirst, echoSecond);
            float echo = exp(
                -echoDistance / max(cursorSize * DIAMOND_ECHO_WIDTH, 0.00012)
            ) * pow(1.0 - echoProgress, DIAMOND_ECHO_FADE_POWER) * echoActive;
            float echoGain = DIAMOND_ECHO_STRENGTH
                * pow(DIAMOND_ECHO_STRENGTH_FALLOFF, float(echoIndex));
            diamondLight += mix(DIAMOND_BLUE, DIAMOND_VIOLET, nearFactor)
                * echo * echoGain;
        }
    }

#if DIAMOND_ENABLE_CORE_GLOW
    float centerGlow = gaussianPoint(point - head, diamondSize * DIAMOND_CORE_GLOW_RADIUS);
    diamondLight += mix(DIAMOND_BLUE, DIAMOND_VIOLET, 0.48)
        * centerGlow * DIAMOND_CORE_GLOW_STRENGTH;
#endif
    fragColor.rgb += diamondLight * life * contentMask * DIAMOND_MASTER_BRIGHTNESS;

#if DIAMOND_ENABLE_SPARKS && DIAMOND_SPARK_COUNT > 0
    vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
    for (int sparkIndex = 0; sparkIndex < DIAMOND_SPARK_COUNT; sparkIndex++) {
        float index = float(sparkIndex);
        float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
        float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
        vec2 sparkCenter = mix(tail, head, positionRandom)
            + normal * (sideRandom - 0.5) * cursorSize * DIAMOND_SPARK_SPREAD;
        float spark = gaussianPoint(point - sparkCenter, cursorSize * DIAMOND_SPARK_RADIUS) * life;
        fragColor.rgb += mix(DIAMOND_CYAN, DIAMOND_ROSE, sideRandom)
            * spark * DIAMOND_SPARK_STRENGTH * contentMask;
    }
#endif

    float cursorCoverage = insideCursorRectangle(fragCoord, iCurrentCursor);
    fragColor = mix(fragColor, original, cursorCoverage);
    fragColor.a = original.a;
}
