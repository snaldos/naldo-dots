// BACKGROUND-ONLY WALLPAPER VARIANT: torus-knot-covenant
// Procedural geometry is composited behind exact terminal foreground.
// Pair this stage with any independently selected cursor shader.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 1
#endif
#define CREATIVE_GPU_ECO 0
#define CREATIVE_GPU_BALANCED 1
#define CREATIVE_GPU_QUALITY 2
#define CREATIVE_GPU_ULTRA 3

// Torus Knot Covenant — parametric 3D knots and a matching knot cursor
//
// True projected (p,q) torus knots wander behind the terminal. Cursor movement
// summons a smaller rotating knot, expanding knot echoes, a comet trail, and an
// optional filament to the primary object. All quantities and geometry are
// compile-time controls in the sections below.

// =============================================================================
// BACKGROUND CONTROLS
// =============================================================================

#if GHOSTTY_GPU_PROFILE == CREATIVE_GPU_ECO
#define KNOT_SEGMENT_COUNT 32
#define KC_SEGMENT_COUNT 20
#define KC_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_BALANCED
#define KNOT_SEGMENT_COUNT 44
#define KC_SEGMENT_COUNT 26
#define KC_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_QUALITY
#define KNOT_SEGMENT_COUNT 60
#define KC_SEGMENT_COUNT 34
#define KC_SPARK_COUNT 4
#else
#define KNOT_SEGMENT_COUNT 76
#define KC_SEGMENT_COUNT 44
#define KC_SPARK_COUNT 7
#endif

#define KNOT_OBJECT_COUNT 2              // quantity: 1..4
#define KNOT_ENABLE_NODES 1
#define KNOT_NODE_STRIDE 6

const float KNOT_MASTER_BRIGHTNESS = 1.00;
const float KNOT_SIZE = 0.086;
const float KNOT_COMPANION_SCALE = 0.76;
const float KNOT_SIZE_VARIATION = 0.10;
const float KNOT_NARROW_REFERENCE_ASPECT = 1.20;
const float KNOT_NARROW_MIN_SCALE = 0.62;
const float KNOT_CAMERA_DISTANCE = 4.20;
const float KNOT_CULL_RADIUS = 2.65;
const float KNOT_CULL_FEATHER = 0.60;
const float KNOT_BREATHE_AMOUNT = 0.055;
const float KNOT_BREATHE_SPEED = 1.15;

const float KNOT_PRIMARY_P = 2.0;
const float KNOT_PRIMARY_Q = 3.0;
const float KNOT_COMPANION_P = 3.0;
const float KNOT_COMPANION_Q = 5.0;
const float KNOT_MAJOR_RADIUS = 1.00;
const float KNOT_TUBE_RADIUS = 0.43;
const vec3 KNOT_ROTATION_BASE = vec3(0.66, -0.48, 0.18);
const vec3 KNOT_ROTATION_SPEED = vec3(0.14, 0.20, 0.11);
const vec3 KNOT_ROTATION_PHASE_STEP = vec3(0.83, 1.19, 0.67);

const vec2 KNOT_PATH_AMPLITUDE = vec2(0.40, 0.34);
const vec2 KNOT_PATH_FREQUENCY = vec2(0.71, 1.03);
const vec2 KNOT_PATH_PHASE = vec2(0.34, 1.18);
const float KNOT_PATH_SPEED = 0.105;
const float KNOT_COMPANION_PATH_SPEED_STEP = 0.022;

const float KNOT_CORE_WIDTH = 0.012;
const float KNOT_GLOW_WIDTH = 0.048;
const float KNOT_CORE_STRENGTH = 0.74;
const float KNOT_GLOW_STRENGTH = 0.13;
const float KNOT_DEPTH_COLOR_STRENGTH = 0.70;
const float KNOT_NODE_RADIUS = 0.046;
const float KNOT_NODE_STRENGTH = 0.34;
const float KNOT_AURA_RADIUS = 1.16;
const float KNOT_AURA_STRENGTH = 0.055;
const float KNOT_EXPOSURE = 1.18;
const float KNOT_ALPHA_MAX = 0.50;
const float KNOT_LIGHT_ALPHA_GAIN = 0.80;

const vec3 KNOT_VOID = vec3(0.010, 0.010, 0.045);
const vec3 KNOT_BLUE = vec3(0.100, 0.330, 1.000);
const vec3 KNOT_CYAN = vec3(0.110, 0.880, 1.000);
const vec3 KNOT_VIOLET = vec3(0.650, 0.250, 1.000);
const vec3 KNOT_ROSE = vec3(0.980, 0.200, 0.650);
const vec3 KNOT_GOLD = vec3(1.000, 0.720, 0.280);
const vec3 KNOT_WHITE = vec3(0.980, 0.970, 1.000);
const float KNOT_TAU = 6.28318530718;

// =============================================================================
float saturate(float value) { return clamp(value, 0.0, 1.0); }
float luminance(vec3 color) { return dot(color, vec3(0.2126, 0.7152, 0.0722)); }
float hash12(vec2 value) {
    vec3 p = fract(vec3(value.xyx) * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}
float gaussianPoint(vec2 point, float radius) {
    float safeRadius = max(radius, 0.00001);
    return exp(-dot(point, point) / (2.0 * safeRadius * safeRadius));
}
float segmentParameter(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    return clamp(dot(point - startPoint, segment) / max(dot(segment, segment), 0.000001), 0.0, 1.0);
}
float segmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    return length(point - mix(startPoint, endPoint, segmentParameter(point, startPoint, endPoint)));
}
vec3 rotateX(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(point.x, c * point.y - s * point.z, s * point.y + c * point.z);
}
vec3 rotateY(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(c * point.x + s * point.z, point.y, -s * point.x + c * point.z);
}
vec3 rotateZ(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(c * point.x - s * point.y, s * point.x + c * point.y, point.z);
}
vec3 rotateXYZ(vec3 point, vec3 angle) {
    return rotateZ(rotateY(rotateX(point, angle.x), angle.y), angle.z);
}
vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return mat2(c, -s, s, c) * point;
}
const float CREATIVE_BACKGROUND_TOLERANCE_LOW = 0.030;
const float CREATIVE_BACKGROUND_TOLERANCE_HIGH = 0.245;
const float CREATIVE_TRANSPARENT_CELL_GAIN = 0.48;

float backgroundCellMask(vec4 terminalColor) {
    float difference = length(terminalColor.rgb - iBackgroundColor);
    float colorMatch = 1.0 - smoothstep(
        CREATIVE_BACKGROUND_TOLERANCE_LOW,
        CREATIVE_BACKGROUND_TOLERANCE_HIGH,
        difference
    );
    float darkFallback = 1.0 - smoothstep(0.12, 0.58, luminance(terminalColor.rgb));
    float transparentCell = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(
        colorMatch,
        darkFallback * transparentCell * CREATIVE_TRANSPARENT_CELL_GAIN
    ));
}
vec2 cursorCenterPixels(vec4 cursorRectangle) {
    return vec2(cursorRectangle.x + cursorRectangle.z * 0.5, cursorRectangle.y - cursorRectangle.w * 0.5);
}
float insideCursor(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(cursorRectangle.x, cursorRectangle.y - cursorRectangle.w);
    vec2 maximumPoint = vec2(cursorRectangle.x + cursorRectangle.z, cursorRectangle.y);
    return step(minimumPoint.x, point.x) * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x) * step(point.y, maximumPoint.y);
}
vec2 scenePoint(vec2 pixelPoint) {
    return (pixelPoint - 0.5 * iResolution.xy) / max(iResolution.y, 1.0);
}
vec2 lissajousUv(
    float timeValue,
    float identity,
    vec2 amplitude,
    vec2 frequency,
    float speed,
    vec2 phase
) {
    float timePhase = timeValue * speed;
    return vec2(0.5) + amplitude * vec2(
        sin(timePhase * frequency.x + phase.x + identity * 2.17),
        sin(timePhase * frequency.y + phase.y + identity * 2.93)
    );
}
vec2 projectPoint(
    vec3 point,
    vec2 center,
    float scaleValue,
    float cameraDistance,
    out float depth
) {
    depth = max(cameraDistance - point.z, 0.12);
    return center + point.xy * scaleValue * cameraDistance / depth;
}

vec3 knotPoint(float parameter, float p, float q) {
    float radial = KNOT_MAJOR_RADIUS + KNOT_TUBE_RADIUS * cos(q * parameter);
    return vec3(
        radial * cos(p * parameter),
        radial * sin(p * parameter),
        KNOT_TUBE_RADIUS * sin(q * parameter)
    );
}

vec2 knotUv(float timeValue, float identity) {
    return lissajousUv(
        timeValue,
        identity,
        KNOT_PATH_AMPLITUDE,
        KNOT_PATH_FREQUENCY,
        KNOT_PATH_SPEED + identity * KNOT_COMPANION_PATH_SPEED_STEP,
        KNOT_PATH_PHASE
    );
}

void renderKnotBackground(out vec4 fragColor, vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    // Wallpaper mode renders a complete procedural layer. Terminal
    // foreground coverage is applied only after the scene is complete.
    float backgroundMask = 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / KNOT_NARROW_REFERENCE_ASPECT,
        KNOT_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = vec3(0.0);
    float sceneAlpha = 0.0;

    for (int objectIndex = 0; objectIndex < KNOT_OBJECT_COUNT; objectIndex++) {
        float identity = float(objectIndex);
        vec2 centerUv = knotUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = objectIndex == 0 ? 1.0 : mix(
            1.0 - KNOT_SIZE_VARIATION,
            1.0 + KNOT_SIZE_VARIATION,
            hash12(vec2(identity, 7.31))
        );
        float sizeValue = KNOT_SIZE * narrowScale
            * pow(KNOT_COMPANION_SCALE, identity) * randomScale
            * (1.0 + KNOT_BREATHE_AMOUNT * sin(
                iTime * KNOT_BREATHE_SPEED + identity * 1.83
            ));
        float objectCullDistance = length(point - center) / max(sizeValue, 0.0001);
        if (objectCullDistance >= KNOT_CULL_RADIUS) continue;
        float objectCullFeather = 1.0 - smoothstep(
            KNOT_CULL_RADIUS - KNOT_CULL_FEATHER,
            KNOT_CULL_RADIUS,
            objectCullDistance
        );

        float p = objectIndex == 0 ? KNOT_PRIMARY_P : KNOT_COMPANION_P;
        float q = objectIndex == 0 ? KNOT_PRIMARY_Q : KNOT_COMPANION_Q;
        vec3 angle = KNOT_ROTATION_BASE
            + iTime * KNOT_ROTATION_SPEED
            + identity * KNOT_ROTATION_PHASE_STEP;
        vec3 radiance = vec3(0.0);
        float opacity = 0.0;

        for (int segmentIndex = 0; segmentIndex < KNOT_SEGMENT_COUNT; segmentIndex++) {
            float segmentPhase0 = float(segmentIndex) / float(KNOT_SEGMENT_COUNT);
            float segmentPhase1 = float(segmentIndex + 1) / float(KNOT_SEGMENT_COUNT);
            vec3 vertex0 = rotateXYZ(knotPoint(segmentPhase0 * KNOT_TAU, p, q), angle);
            vec3 vertex1 = rotateXYZ(knotPoint(segmentPhase1 * KNOT_TAU, p, q), angle);
            float depth0, depth1;
            vec2 projected0 = projectPoint(vertex0, center, sizeValue, KNOT_CAMERA_DISTANCE, depth0);
            vec2 projected1 = projectPoint(vertex1, center, sizeValue, KNOT_CAMERA_DISTANCE, depth1);
            float distanceToCurve = segmentDistance(point, projected0, projected1);
            float core = exp(-distanceToCurve / max(sizeValue * KNOT_CORE_WIDTH, 0.00012));
            float glow = exp(-distanceToCurve / max(sizeValue * KNOT_GLOW_WIDTH, 0.00035));
            float nearFactor = saturate((KNOT_CAMERA_DISTANCE + 0.8 - 0.5 * (depth0 + depth1)) / 1.7);
            vec3 phaseColor = mix(KNOT_VIOLET, KNOT_CYAN, 0.5 + 0.5 * sin(
                segmentPhase0 * KNOT_TAU + identity * 1.9
            ));
            vec3 depthColor = mix(KNOT_BLUE, KNOT_ROSE, nearFactor);
            vec3 color = mix(phaseColor, depthColor, KNOT_DEPTH_COLOR_STRENGTH);
            color = mix(color, KNOT_WHITE, nearFactor * 0.28);
            radiance += color * (
                core * KNOT_CORE_STRENGTH + glow * KNOT_GLOW_STRENGTH
            );
            opacity = max(opacity, max(core, glow * 0.36));
#if KNOT_ENABLE_NODES
            if ((segmentIndex % KNOT_NODE_STRIDE) == 0) {
                float node = gaussianPoint(point - projected0, sizeValue * KNOT_NODE_RADIUS);
                radiance += mix(KNOT_GOLD, KNOT_CYAN, nearFactor)
                    * node * KNOT_NODE_STRENGTH;
                opacity = max(opacity, node * 0.64);
            }
#endif
        }

        float aura = gaussianPoint(point - center, sizeValue * KNOT_AURA_RADIUS);
        radiance += mix(KNOT_VIOLET, KNOT_BLUE, 0.45)
            * aura * KNOT_AURA_STRENGTH;
        radiance *= objectCullFeather;
        opacity *= objectCullFeather;
        vec3 light = vec3(1.0) - exp(
            -max(radiance, vec3(0.0)) * KNOT_EXPOSURE * KNOT_MASTER_BRIGHTNESS
        );
        composite += light * backgroundMask;
        sceneAlpha = max(
            sceneAlpha,
            backgroundMask * KNOT_ALPHA_MAX
                * saturate(opacity + luminance(light) * KNOT_LIGHT_ALPHA_GAIN)
        );
    }
    fragColor = vec4(
        clamp(composite, 0.0, 1.0),
        sceneAlpha
    );
}

// =============================================================================
// WALLPAPER COMPOSITION — TERMINAL FOREGROUND OVER PROCEDURAL GEOMETRY
// =============================================================================

vec4 compositeGeometryBehindTerminal(
    vec4 wallpaperColor,
    vec4 terminalColor
) {
    // Terminal alpha is the layer boundary. Opaque glyph and cursor pixels stay
    // exact; transparent cells reveal the procedural layer. Preserve Ghostty's
    // original terminal alpha so the desktop compositor remains authoritative.
    float terminalCoverage = saturate(terminalColor.a);
    return vec4(
        mix(wallpaperColor.rgb, terminalColor.rgb, terminalCoverage),
        terminalColor.a
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 terminalUv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, terminalUv);

    vec4 wallpaperColor;
    renderKnotBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);
}
