// Tesseract Cube — coordinated combined 3D background and cursor for Ghostty
//
// Floating nested hypercubes share color and motion with a movement-scaled 3D
// cube cursor. While moving, a faint configurable resonance filament connects
// the cursor to the primary tesseract. Background and cursor controls remain
// independent and are grouped in labelled sections below.

// Tesseract Drift — configurable floating nested hypercubes for Ghostty
// Two projected cubes, eight dimensional connectors, depth-colored edges, and
// optional vertex lights create a transparent 3D/4D wireframe familiar.

// =============================================================================
// GPU PROFILE AND FEATURE QUANTITIES
// =============================================================================

#define TESSERACT_GPU_ECO      0
#define TESSERACT_GPU_BALANCED 1
#define TESSERACT_GPU_QUALITY  2
#define TESSERACT_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE TESSERACT_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == TESSERACT_GPU_ECO
#define TESSERACT_PROFILE_EDGE_GAIN 0.72
#define TESSERACT_PROFILE_NODE_GAIN 0.00
#elif GHOSTTY_GPU_PROFILE == TESSERACT_GPU_BALANCED
#define TESSERACT_PROFILE_EDGE_GAIN 0.84
#define TESSERACT_PROFILE_NODE_GAIN 0.55
#elif GHOSTTY_GPU_PROFILE == TESSERACT_GPU_QUALITY
#define TESSERACT_PROFILE_EDGE_GAIN 0.96
#define TESSERACT_PROFILE_NODE_GAIN 0.82
#else
#define TESSERACT_PROFILE_EDGE_GAIN 1.06
#define TESSERACT_PROFILE_NODE_GAIN 1.00
#endif

#define TESSERACT_OBJECT_COUNT 2          // quantity: 1..4 recommended
#define TESSERACT_ENABLE_NODES 1
#define TESSERACT_ENABLE_HALO 1
#define TESSERACT_ENABLE_WAKE 1

// =============================================================================
// MASTER, SIZE, AND 4D SHAPE
// =============================================================================

const float TESSERACT_MASTER_BRIGHTNESS = 1.00;
const float TESSERACT_EXPOSURE = 1.18;
const float TESSERACT_ALPHA_MAX = 0.38;
const float TESSERACT_SIZE = 0.112;       // screen-height fraction
const float TESSERACT_COMPANION_SCALE = 0.72;
const float TESSERACT_SIZE_VARIATION = 0.12;
const float TESSERACT_OUTER_EXTENT = 1.00;
const float TESSERACT_INNER_SCALE = 0.46;
const float TESSERACT_INNER_SCALE_PULSE = 0.10;
const float TESSERACT_INNER_SCALE_SPEED = 0.37;
const float TESSERACT_INNER_TWIST = 0.46;
const float TESSERACT_INNER_TWIST_SPEED = 0.23;
const float TESSERACT_BREATHE_AMOUNT = 0.050;
const float TESSERACT_BREATHE_SPEED = 0.24;
const float TESSERACT_CAMERA_DISTANCE = 4.50;
const float TESSERACT_CULL_RADIUS = 3.60;
const float TESSERACT_NARROW_REFERENCE_ASPECT = 0.95;
const float TESSERACT_NARROW_MIN_SCALE = 0.58;

// =============================================================================
// FULL-SCREEN FLOATING PATH
// =============================================================================

const vec2 TESSERACT_PATH_CENTER = vec2(0.50, 0.50);
const vec2 TESSERACT_PATH_AMPLITUDE = vec2(0.420, 0.390);
const float TESSERACT_SCREEN_MARGIN = 0.055;
const float TESSERACT_PATH_X_SPEED = 0.060;
const float TESSERACT_PATH_Y_SPEED = 0.077;
const float TESSERACT_PATH_X_SECONDARY_SPEED = 0.151;
const float TESSERACT_PATH_Y_SECONDARY_SPEED = 0.129;
const float TESSERACT_PATH_PRIMARY_WEIGHT = 0.78;
const float TESSERACT_PATH_SECONDARY_WEIGHT = 0.22;
const float TESSERACT_OBJECT_PHASE_STEP = 2.41;
const float TESSERACT_OBJECT_SPEED_STEP = 0.065;
const float TESSERACT_COMPANION_PATH_SCALE = 0.92;

// =============================================================================
// 3D ROTATION
// =============================================================================

const vec3 TESSERACT_ROTATION_BASE = vec3(0.35, -0.52, 0.12);
const vec3 TESSERACT_ROTATION_SPEED = vec3(0.17, -0.21, 0.095);
const vec3 TESSERACT_ROTATION_WOBBLE = vec3(0.24, 0.20, 0.12);
const vec3 TESSERACT_ROTATION_WOBBLE_SPEED = vec3(0.041, 0.053, 0.067);
const float TESSERACT_OBJECT_ROTATION_PHASE_STEP = 1.37;
const float TESSERACT_OBJECT_ROTATION_SPEED_STEP = 0.08;

// =============================================================================
// EDGES, NODES, CORE, HALO, AND MOTION WAKE
// =============================================================================

const float TESSERACT_EDGE_CORE_WIDTH = 0.010;
const float TESSERACT_EDGE_GLOW_WIDTH = 0.045;
const float TESSERACT_EDGE_CORE_STRENGTH = 0.58;
const float TESSERACT_EDGE_GLOW_STRENGTH = 0.11;
const float TESSERACT_CONNECTOR_STRENGTH = 0.76;
const float TESSERACT_NEAR_DEPTH_CENTER = 5.50;
const float TESSERACT_NEAR_DEPTH_RANGE = 2.40;
const float TESSERACT_NEAR_WHITE_MIX = 0.35;
const float TESSERACT_NODE_RADIUS = 0.025;
const float TESSERACT_NODE_STRENGTH = 0.28;
const float TESSERACT_CORE_RADIUS = 0.34;
const float TESSERACT_CORE_DARKEN = 0.10;
const float TESSERACT_HALO_RADIUS = 1.65;
const float TESSERACT_HALO_STRENGTH = 0.025;
const float TESSERACT_WAKE_SECONDS = 1.10;
const float TESSERACT_WAKE_WIDTH = 0.075;
const float TESSERACT_WAKE_STRENGTH = 0.032;

// =============================================================================
// TERMINAL COMPOSITING AND COLORS
// =============================================================================

const float TESSERACT_BACKGROUND_TOLERANCE_LOW = 0.030;
const float TESSERACT_BACKGROUND_TOLERANCE_HIGH = 0.245;
const float TESSERACT_TEXT_PROTECTION = 0.48;
const float TESSERACT_LIGHT_ALPHA_GAIN = 0.78;
const vec3 TESSERACT_VOID    = vec3(0.008, 0.012, 0.055);
const vec3 TESSERACT_BLUE    = vec3(0.080, 0.300, 0.980);
const vec3 TESSERACT_CYAN    = vec3(0.160, 0.850, 1.000);
const vec3 TESSERACT_VIOLET  = vec3(0.590, 0.240, 1.000);
const vec3 TESSERACT_MAGENTA = vec3(0.920, 0.200, 0.760);
const vec3 TESSERACT_WHITE   = vec3(0.900, 0.930, 1.000);

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
    float difference = length(terminalColor.rgb - iBackgroundColor);
    float colorMatch = 1.0 - smoothstep(
        TESSERACT_BACKGROUND_TOLERANCE_LOW,
        TESSERACT_BACKGROUND_TOLERANCE_HIGH,
        difference
    );
    float darkFallback = 1.0 - smoothstep(0.12, 0.58, luminance(terminalColor.rgb));
    float transparent = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(colorMatch, darkFallback * transparent * TESSERACT_TEXT_PROTECTION));
}

vec2 tesseractUv(float timeValue, float identity) {
    float speedScale = 1.0 + identity * TESSERACT_OBJECT_SPEED_STEP;
    float phase = identity * TESSERACT_OBJECT_PHASE_STEP;
    float x = TESSERACT_PATH_PRIMARY_WEIGHT
            * sin(timeValue * TESSERACT_PATH_X_SPEED * speedScale + 0.30 + phase)
        + TESSERACT_PATH_SECONDARY_WEIGHT
            * sin(timeValue * TESSERACT_PATH_X_SECONDARY_SPEED / speedScale + 2.20 - phase);
    float y = TESSERACT_PATH_PRIMARY_WEIGHT
            * sin(timeValue * TESSERACT_PATH_Y_SPEED * speedScale + 2.00 - phase * 0.61)
        + TESSERACT_PATH_SECONDARY_WEIGHT
            * sin(timeValue * TESSERACT_PATH_Y_SECONDARY_SPEED / speedScale + 4.70 + phase);
    float pathScale = identity < 0.5
        ? 1.0
        : pow(TESSERACT_COMPANION_PATH_SCALE, identity);
    return clamp(
        TESSERACT_PATH_CENTER + TESSERACT_PATH_AMPLITUDE * pathScale * vec2(x, y),
        vec2(TESSERACT_SCREEN_MARGIN),
        vec2(1.0 - TESSERACT_SCREEN_MARGIN)
    );
}

struct TesseractSample {
    vec3 radiance;
    float opacity;
    float core;
};

TesseractSample renderTesseract(
    vec2 point,
    vec2 center,
    float size,
    float identity
) {
    vec2 projected[16];
    float depth[16];
    float phase = identity * TESSERACT_OBJECT_ROTATION_PHASE_STEP;
    float speedScale = 1.0 + identity * TESSERACT_OBJECT_ROTATION_SPEED_STEP;
    vec3 angle = TESSERACT_ROTATION_BASE
        + iTime * TESSERACT_ROTATION_SPEED * speedScale
        + TESSERACT_ROTATION_WOBBLE * sin(
            iTime * TESSERACT_ROTATION_WOBBLE_SPEED + vec3(phase, phase + 1.7, phase + 3.2)
        );
    float innerScale = TESSERACT_INNER_SCALE * (
        1.0 + TESSERACT_INNER_SCALE_PULSE
            * sin(iTime * TESSERACT_INNER_SCALE_SPEED + phase)
    );
    float innerTwist = TESSERACT_INNER_TWIST
        * sin(iTime * TESSERACT_INNER_TWIST_SPEED + phase);

    for (int vertexIndex = 0; vertexIndex < 16; vertexIndex++) {
        int cornerIndex = vertexIndex & 7;
        vec3 vertex = vec3(
            (cornerIndex & 1) != 0 ? 1.0 : -1.0,
            (cornerIndex & 2) != 0 ? 1.0 : -1.0,
            (cornerIndex & 4) != 0 ? 1.0 : -1.0
        ) * TESSERACT_OUTER_EXTENT;
        if (vertexIndex >= 8) {
            vertex *= innerScale;
            vertex = rotateZ(rotateY(vertex, -innerTwist * 0.73), innerTwist);
        }
        vertex = rotateZ(rotateX(rotateY(vertex, angle.y), angle.x), angle.z);
        depth[vertexIndex] = TESSERACT_CAMERA_DISTANCE - vertex.z;
        projected[vertexIndex] = center
            + vertex.xy * size * TESSERACT_CAMERA_DISTANCE / depth[vertexIndex];
    }

    const int edgeA[32] = int[32](
        0,1,3,2, 4,5,7,6, 0,1,2,3,
        8,9,11,10, 12,13,15,14, 8,9,10,11,
        0,1,2,3,4,5,6,7
    );
    const int edgeB[32] = int[32](
        1,3,2,0, 5,7,6,4, 4,5,6,7,
        9,11,10,8, 13,15,14,12, 12,13,14,15,
        8,9,10,11,12,13,14,15
    );

    vec3 radiance = vec3(0.0);
    float opacity = 0.0;
    for (int edgeIndex = 0; edgeIndex < 32; edgeIndex++) {
        int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
        float edgeDepth = 0.5 * (depth[first] + depth[second]);
        float nearFactor = saturate(
            (TESSERACT_NEAR_DEPTH_CENTER - edgeDepth) / TESSERACT_NEAR_DEPTH_RANGE
        );
        float distanceValue = segmentDistance(point, projected[first], projected[second]);
        float core = exp(-distanceValue / max(size * TESSERACT_EDGE_CORE_WIDTH, 0.00012));
        float glow = exp(-distanceValue / max(size * TESSERACT_EDGE_GLOW_WIDTH, 0.00030));
        float connector = edgeIndex >= 24 ? TESSERACT_CONNECTOR_STRENGTH : 1.0;
        vec3 farColor = mix(TESSERACT_VIOLET, TESSERACT_MAGENTA, fract(identity * 0.37));
        vec3 edgeColor = mix(farColor, TESSERACT_CYAN, nearFactor);
        edgeColor = mix(edgeColor, TESSERACT_WHITE, nearFactor * TESSERACT_NEAR_WHITE_MIX);
        radiance += edgeColor * connector * TESSERACT_PROFILE_EDGE_GAIN * (
            core * TESSERACT_EDGE_CORE_STRENGTH
            + glow * TESSERACT_EDGE_GLOW_STRENGTH
        );
        opacity = max(opacity, core * 0.48 + glow * 0.12);
    }

#if TESSERACT_ENABLE_NODES
    for (int nodeIndex = 0; nodeIndex < 16; nodeIndex++) {
        float nearFactor = saturate(
            (TESSERACT_NEAR_DEPTH_CENTER - depth[nodeIndex]) / TESSERACT_NEAR_DEPTH_RANGE
        );
        float node = gaussianPoint(
            point - projected[nodeIndex],
            max(size * TESSERACT_NODE_RADIUS, 0.0012)
        );
        radiance += mix(TESSERACT_VIOLET, TESSERACT_CYAN, nearFactor)
            * node * TESSERACT_NODE_STRENGTH * TESSERACT_PROFILE_NODE_GAIN;
        opacity = max(opacity, node * 0.22 * TESSERACT_PROFILE_NODE_GAIN);
    }
#endif

    float coreDistance = max(abs(point.x - center.x), abs(point.y - center.y));
    float centralCore = 1.0 - smoothstep(
        size * TESSERACT_CORE_RADIUS * 0.45,
        size * TESSERACT_CORE_RADIUS,
        coreDistance
    );
#if TESSERACT_ENABLE_HALO
    float halo = gaussianPoint(point - center, size * TESSERACT_HALO_RADIUS);
    radiance += mix(TESSERACT_BLUE, TESSERACT_VIOLET, 0.52)
        * halo * TESSERACT_HALO_STRENGTH;
    opacity = max(opacity, halo * 0.025);
#endif
    return TesseractSample(radiance, saturate(opacity), centralCore);
}

void renderTesseractBackground(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    float backgroundMask = backgroundCellMask(terminalColor);
    float aspect = resolution.x / resolution.y;
    vec2 point = (fragCoord - 0.5 * resolution) / resolution.y;
    float narrowScale = clamp(
        aspect / TESSERACT_NARROW_REFERENCE_ASPECT,
        TESSERACT_NARROW_MIN_SCALE,
        1.0
    );

    vec3 composite = terminalColor.rgb;
    float sceneAlpha = 0.0;

    for (int objectIndex = 0; objectIndex < TESSERACT_OBJECT_COUNT; objectIndex++) {
        float identity = float(objectIndex);
        vec2 centerUv = tesseractUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = objectIndex == 0
            ? 1.0
            : mix(
                1.0 - TESSERACT_SIZE_VARIATION,
                1.0 + TESSERACT_SIZE_VARIATION,
                hash12(vec2(identity, 8.17))
            );
        float size = TESSERACT_SIZE * narrowScale
            * pow(TESSERACT_COMPANION_SCALE, identity)
            * randomScale
            * (1.0 + TESSERACT_BREATHE_AMOUNT
                * sin(iTime * TESSERACT_BREATHE_SPEED + identity * 1.8));

#if TESSERACT_ENABLE_WAKE
        vec2 previousUv = tesseractUv(iTime - TESSERACT_WAKE_SECONDS, identity);
        vec2 previousCenter = (previousUv - 0.5) * vec2(aspect, 1.0);
        float wakeDistance = segmentDistance(point, previousCenter, center);
        float wakeAlong = segmentParameter(point, previousCenter, center);
        float wake = exp(-wakeDistance / max(size * TESSERACT_WAKE_WIDTH, 0.0005))
            * smoothstep(0.0, 0.85, wakeAlong);
        vec3 wakeColor = mix(TESSERACT_VIOLET, TESSERACT_CYAN, wakeAlong);
        composite += wakeColor * wake * TESSERACT_WAKE_STRENGTH * backgroundMask;
        sceneAlpha = max(sceneAlpha, wake * TESSERACT_ALPHA_MAX * 0.08 * backgroundMask);
#endif

        if (
            abs(point.x - center.x) < size * TESSERACT_CULL_RADIUS
            && abs(point.y - center.y) < size * TESSERACT_CULL_RADIUS
        ) {
            TesseractSample sampleValue = renderTesseract(point, center, size, identity);
            vec3 light = vec3(1.0) - exp(
                -max(sampleValue.radiance, vec3(0.0))
                    * TESSERACT_EXPOSURE * TESSERACT_MASTER_BRIGHTNESS
            );
            composite = mix(
                composite,
                TESSERACT_VOID,
                sampleValue.core * TESSERACT_CORE_DARKEN * backgroundMask
            );
            composite += light * backgroundMask;
            sceneAlpha = max(
                sceneAlpha,
                backgroundMask * TESSERACT_ALPHA_MAX
                    * saturate(sampleValue.opacity + luminance(light) * TESSERACT_LIGHT_ALPHA_GAIN)
            );
        }
    }

    fragColor = vec4(clamp(composite, 0.0, 1.0), max(terminalColor.a, sceneAlpha));
}

// =============================================================================
// MATCHED CUBE CURSOR — QUANTITY, SIZE, SPEED, AND RESPONSE
// =============================================================================

#if GHOSTTY_GPU_PROFILE == TESSERACT_GPU_ECO
#define TC_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == TESSERACT_GPU_BALANCED
#define TC_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == TESSERACT_GPU_QUALITY
#define TC_SPARK_COUNT 4
#else
#define TC_SPARK_COUNT 7
#endif

#define TC_ECHO_COUNT 2                  // quantity: 0..4
#define TC_ENABLE_TRAIL 1
#define TC_ENABLE_SPARKS 1
#define TC_ENABLE_RESONANCE_LINK 1

const float TC_EFFECT_DURATION = 0.32;
const float TC_FADE_POWER = 1.80;
const float TC_MIN_MOVEMENT_CELLS = 0.025;
const float TC_GROWTH_START_CELLS = 0.08;
const float TC_GROWTH_FULL_CELLS = 8.00;
const float TC_MOVEMENT_RESPONSE_POWER = 1.00;
const float TC_CONTENT_PROTECTION = 0.18;
const float TC_CULL_RADIUS_MIN = 3.20;
const float TC_CULL_RADIUS_MAX = 6.40;
const float TC_MASTER_BRIGHTNESS = 1.00;

const float TC_SIZE_MIN = 0.78;
const float TC_SIZE_MAX = 1.82;
const float TC_SIZE_PULSE = 0.11;
const float TC_CAMERA_DISTANCE = 4.00;
const vec3 TC_ROTATION_BASE = vec3(0.58, -0.68, 0.00);
const vec3 TC_ROTATION_SPEED = vec3(0.24, 0.31, 0.00);
const float TC_DIRECTION_TILT = 0.12;

const float TC_EDGE_CORE_WIDTH = 0.040;
const float TC_EDGE_GLOW_WIDTH = 0.150;
const float TC_EDGE_CORE_STRENGTH = 0.50;
const float TC_EDGE_GLOW_STRENGTH = 0.080;
const float TC_NEAR_DEPTH_CENTER = 4.90;
const float TC_NEAR_DEPTH_RANGE = 1.80;
const float TC_NEAR_WHITE_MIX = 0.34;

const float TC_ECHO_START_SCALE = 1.02;
const float TC_ECHO_END_SCALE = 2.20;
const float TC_ECHO_DELAY = 0.13;
const float TC_ECHO_WIDTH = 0.050;
const float TC_ECHO_STRENGTH = 0.17;
const float TC_ECHO_FALLOFF = 0.72;
const float TC_ECHO_FADE_POWER = 1.00;

const float TC_TRAIL_WIDTH_MIN = 0.12;
const float TC_TRAIL_WIDTH_MAX = 0.25;
const float TC_TRAIL_GLOW_MULTIPLIER = 3.80;
const float TC_TRAIL_GLOW_STRENGTH = 0.055;
const float TC_TRAIL_CORE_STRENGTH = 0.24;
const float TC_TRAIL_TAIL_FADE = 0.22;
const float TC_SPARK_RADIUS = 0.075;
const float TC_SPARK_SPREAD = 1.50;
const float TC_SPARK_STRENGTH = 0.24;

const float TC_LINK_WIDTH = 0.060;
const float TC_LINK_GLOW_WIDTH = 0.24;
const float TC_LINK_CORE_STRENGTH = 0.050;
const float TC_LINK_GLOW_STRENGTH = 0.012;
const float TC_LINK_DASH_COUNT = 18.0;
const float TC_LINK_DASH_SPEED = 1.80;
const float TC_LINK_ENDPOINT_GLOW = 0.085;

const vec3 TC_BLUE = vec3(0.180, 0.390, 1.000);
const vec3 TC_CYAN = vec3(0.220, 0.840, 1.000);
const vec3 TC_VIOLET = vec3(0.650, 0.300, 1.000);
const vec3 TC_MAGENTA = vec3(0.940, 0.220, 0.760);
const vec3 TC_WHITE = vec3(0.970, 0.970, 1.000);
const float TC_PI = 3.14159265359;

vec2 tcCursorCenterPixels(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}

vec2 tcScenePoint(vec2 pixelPoint) {
    return (pixelPoint - 0.5 * iResolution.xy) / max(iResolution.y, 1.0);
}

float tcInsideCursor(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(cursorRectangle.x, cursorRectangle.y - cursorRectangle.w);
    vec2 maximumPoint = vec2(cursorRectangle.x + cursorRectangle.z, cursorRectangle.y);
    return step(minimumPoint.x, point.x) * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x) * step(point.y, maximumPoint.y);
}

void applyTesseractCubeCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = tcCursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = tcCursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / TC_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * TC_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = pow(
        smoothstep(
            cursorPixels * TC_GROWTH_START_CELLS,
            cursorPixels * TC_GROWTH_FULL_CELLS,
            movedPixels
        ),
        TC_MOVEMENT_RESPONSE_POWER
    );
    float cullRadius = cursorPixels * mix(
        TC_CULL_RADIUS_MIN,
        TC_CULL_RADIUS_MAX,
        movementFactor
    );
    bool nearCursor = all(greaterThanEqual(
        fragCoord,
        min(headPixels, tailPixels) - vec2(cullRadius)
    )) && all(lessThanEqual(
        fragCoord,
        max(headPixels, tailPixels) + vec2(cullRadius)
    ));

    vec2 mainObjectPixels = tesseractUv(iTime, 0.0) * resolution;
    float linkCull = max(cursorPixels * 1.5, 8.0);
    bool nearLink = all(greaterThanEqual(
        fragCoord,
        min(headPixels, mainObjectPixels) - vec2(linkCull)
    )) && all(lessThanEqual(
        fragCoord,
        max(headPixels, mainObjectPixels) + vec2(linkCull)
    ));
    if (!nearCursor && !nearLink) return;

    vec2 point = tcScenePoint(fragCoord);
    vec2 head = tcScenePoint(headPixels);
    vec2 tail = tcScenePoint(tailPixels);
    vec2 mainObject = tcScenePoint(mainObjectPixels);
    vec2 movement = head - tail;
    vec2 direction = movement / max(length(movement), 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - age, TC_FADE_POWER);
    float contentMask = mix(TC_CONTENT_PROTECTION, 1.0, backgroundCellMask(terminalColor));

#if TC_ENABLE_RESONANCE_LINK
    if (nearLink) {
        float linkDistance = segmentDistance(point, head, mainObject);
        float linkAlong = segmentParameter(point, head, mainObject);
        float dash = 0.64 + 0.36 * sin(
            linkAlong * TC_LINK_DASH_COUNT - iTime * TC_LINK_DASH_SPEED
        );
        float linkCore = exp(-linkDistance / max(cursorSize * TC_LINK_WIDTH, 0.0002));
        float linkGlow = exp(-linkDistance / max(cursorSize * TC_LINK_GLOW_WIDTH, 0.0005));
        vec3 linkColor = mix(TC_VIOLET, TC_CYAN, linkAlong);
        scene.rgb += linkColor * dash * life * contentMask * (
            linkCore * TC_LINK_CORE_STRENGTH
            + linkGlow * TC_LINK_GLOW_STRENGTH
        );
        float endpoint = gaussianPoint(point - mainObject, cursorSize * 0.70);
        scene.rgb += TC_CYAN * endpoint * life * TC_LINK_ENDPOINT_GLOW * contentMask;
    }
#endif

    if (nearCursor) {
#if TC_ENABLE_TRAIL
        float trailDistance = segmentDistance(point, tail, head);
        float along = segmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            TC_TRAIL_WIDTH_MIN,
            TC_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, TC_TRAIL_TAIL_FADE, along) * life;
        float trailGlow = exp(
            -trailDistance / max(trailWidth * TC_TRAIL_GLOW_MULTIPLIER, 0.0004)
        ) * smoothstep(0.0, TC_TRAIL_TAIL_FADE * 0.82, along) * life;
        vec3 trailColor = mix(TC_VIOLET, TC_CYAN, along);
        trailColor = mix(trailColor, TC_MAGENTA, smoothstep(0.76, 1.0, along) * 0.35);
        scene.rgb += trailColor * trailGlow * TC_TRAIL_GLOW_STRENGTH * contentMask;
        scene.rgb += trailColor * trailCore * TC_TRAIL_CORE_STRENGTH * contentMask;
#endif

        vec2 projected[8];
        float depth[8];
        float cubeHalf = cursorSize * mix(TC_SIZE_MIN, TC_SIZE_MAX, movementFactor)
            * (1.0 + TC_SIZE_PULSE * sin(age * TC_PI));
        vec3 angle = TC_ROTATION_BASE + iTime * TC_ROTATION_SPEED;
        angle.z += atan(direction.y, direction.x) * TC_DIRECTION_TILT;
        for (int vertexIndex = 0; vertexIndex < 8; vertexIndex++) {
            vec3 vertex = vec3(
                (vertexIndex & 1) != 0 ? 1.0 : -1.0,
                (vertexIndex & 2) != 0 ? 1.0 : -1.0,
                (vertexIndex & 4) != 0 ? 1.0 : -1.0
            );
            vertex = rotateZ(rotateY(rotateX(vertex, angle.x), angle.y), angle.z);
            depth[vertexIndex] = TC_CAMERA_DISTANCE - vertex.z;
            projected[vertexIndex] = head
                + vertex.xy * cubeHalf * TC_CAMERA_DISTANCE / depth[vertexIndex];
        }

        const int edgeA[12] = int[12](0,1,3,2, 4,5,7,6, 0,1,2,3);
        const int edgeB[12] = int[12](1,3,2,0, 5,7,6,4, 4,5,6,7);
        vec3 cubeLight = vec3(0.0);
        for (int edgeIndex = 0; edgeIndex < 12; edgeIndex++) {
            int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
            float nearFactor = saturate(
                (TC_NEAR_DEPTH_CENTER - 0.5 * (depth[first] + depth[second]))
                    / TC_NEAR_DEPTH_RANGE
            );
            float edgeDistance = segmentDistance(point, projected[first], projected[second]);
            float core = exp(-edgeDistance / max(cursorSize * TC_EDGE_CORE_WIDTH, 0.0001));
            float glow = exp(-edgeDistance / max(cursorSize * TC_EDGE_GLOW_WIDTH, 0.00025));
            vec3 edgeColor = mix(TC_VIOLET, TC_CYAN, nearFactor);
            edgeColor = mix(edgeColor, TC_WHITE, nearFactor * TC_NEAR_WHITE_MIX);
            cubeLight += edgeColor * (
                core * TC_EDGE_CORE_STRENGTH + glow * TC_EDGE_GLOW_STRENGTH
            );

            for (int echoIndex = 0; echoIndex < TC_ECHO_COUNT; echoIndex++) {
                float delay = float(echoIndex) * TC_ECHO_DELAY;
                float progress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
                float echoActive = step(delay, easedAge);
                float scaleValue = mix(TC_ECHO_START_SCALE, TC_ECHO_END_SCALE, progress);
                vec2 echoFirst = head + (projected[first] - head) * scaleValue;
                vec2 echoSecond = head + (projected[second] - head) * scaleValue;
                float echoDistance = segmentDistance(point, echoFirst, echoSecond);
                float echo = exp(-echoDistance / max(cursorSize * TC_ECHO_WIDTH, 0.00012))
                    * pow(1.0 - progress, TC_ECHO_FADE_POWER) * echoActive;
                cubeLight += mix(TC_BLUE, TC_VIOLET, nearFactor) * echo
                    * TC_ECHO_STRENGTH * pow(TC_ECHO_FALLOFF, float(echoIndex));
            }
        }
        scene.rgb += cubeLight * life * contentMask * TC_MASTER_BRIGHTNESS;

#if TC_ENABLE_SPARKS && TC_SPARK_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int sparkIndex = 0; sparkIndex < TC_SPARK_COUNT; sparkIndex++) {
            float index = float(sparkIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 sparkCenter = mix(tail, head, positionRandom)
                + normal * (sideRandom - 0.5) * cursorSize * TC_SPARK_SPREAD;
            float spark = gaussianPoint(point - sparkCenter, cursorSize * TC_SPARK_RADIUS) * life;
            scene.rgb += mix(TC_CYAN, TC_MAGENTA, sideRandom)
                * spark * TC_SPARK_STRENGTH * contentMask;
        }
#endif
    }

    float cursorCoverage = tcInsideCursor(fragCoord, iCurrentCursor);
    scene = mix(scene, terminalColor, cursorCoverage);
    scene.rgb = clamp(scene.rgb, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    renderTesseractBackground(fragColor, fragCoord);
    applyTesseractCubeCursor(fragColor, fragCoord);
}
