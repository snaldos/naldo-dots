// BACKGROUND-ONLY WALLPAPER VARIANT: mobius-lanterns
// Procedural geometry is composited behind exact terminal foreground.
// Pair this stage with any independently selected cursor shader.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 1
#endif
#define CREATIVE_GPU_ECO 0
#define CREATIVE_GPU_BALANCED 1
#define CREATIVE_GPU_QUALITY 2
#define CREATIVE_GPU_ULTRA 3

// Mobius Lanterns — one-sided 3D ribbons and a matching ribbon cursor
//
// Projected Möbius-strip wire meshes drift as luminous mathematical lanterns.
// Cursor motion summons a smaller one-sided ribbon, delayed ribbon echoes, and
// a subtle energy filament. Mesh density, object quantity, dimensions, paths,
// rotation, colors, and cursor response are all configurable.

// =============================================================================
// BACKGROUND CONTROLS
// =============================================================================

#if GHOSTTY_GPU_PROFILE == CREATIVE_GPU_ECO
#define MOBIUS_U_SEGMENT_COUNT 28
#define MC_U_SEGMENT_COUNT 18
#define MC_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_BALANCED
#define MOBIUS_U_SEGMENT_COUNT 38
#define MC_U_SEGMENT_COUNT 24
#define MC_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_QUALITY
#define MOBIUS_U_SEGMENT_COUNT 50
#define MC_U_SEGMENT_COUNT 32
#define MC_SPARK_COUNT 4
#else
#define MOBIUS_U_SEGMENT_COUNT 64
#define MC_U_SEGMENT_COUNT 40
#define MC_SPARK_COUNT 7
#endif

#define MOBIUS_OBJECT_COUNT 2            // quantity: 1..3
#define MOBIUS_RAIL_COUNT 5              // longitudinal mesh rails: 2..8
#define MOBIUS_RIB_COUNT 12              // transverse mesh ribs: 0..20
#define MOBIUS_ENABLE_LANTERN_CORE 1
#define MOBIUS_ENABLE_NODES 1

const float MOBIUS_MASTER_BRIGHTNESS = 1.00;
const float MOBIUS_SIZE = 0.090;
const float MOBIUS_COMPANION_SCALE = 0.72;
const float MOBIUS_SIZE_VARIATION = 0.10;
const float MOBIUS_NARROW_REFERENCE_ASPECT = 1.20;
const float MOBIUS_NARROW_MIN_SCALE = 0.62;
const float MOBIUS_CAMERA_DISTANCE = 4.20;
const float MOBIUS_CULL_RADIUS = 2.65;
const float MOBIUS_CULL_FEATHER = 0.60;
const float MOBIUS_BREATHE_AMOUNT = 0.060;
const float MOBIUS_BREATHE_SPEED = 1.08;
const float MOBIUS_MAJOR_RADIUS = 1.00;
const float MOBIUS_HALF_WIDTH = 0.48;
const float MOBIUS_TWIST_COUNT = 1.0;
const vec3 MOBIUS_ROTATION_BASE = vec3(0.92, -0.52, 0.14);
const vec3 MOBIUS_ROTATION_SPEED = vec3(0.15, 0.23, 0.10);
const vec3 MOBIUS_ROTATION_PHASE_STEP = vec3(0.76, 1.12, 0.63);

const vec2 MOBIUS_PATH_AMPLITUDE = vec2(0.40, 0.34);
const vec2 MOBIUS_PATH_FREQUENCY = vec2(0.67, 1.08);
const vec2 MOBIUS_PATH_PHASE = vec2(1.12, 0.38);
const float MOBIUS_PATH_SPEED = 0.098;
const float MOBIUS_COMPANION_PATH_SPEED_STEP = 0.025;

const float MOBIUS_RAIL_CORE_WIDTH = 0.011;
const float MOBIUS_RAIL_GLOW_WIDTH = 0.048;
const float MOBIUS_RAIL_CORE_STRENGTH = 0.64;
const float MOBIUS_RAIL_GLOW_STRENGTH = 0.11;
const float MOBIUS_RAIL_FALLOFF = 0.86;
const float MOBIUS_RIB_CORE_WIDTH = 0.009;
const float MOBIUS_RIB_GLOW_WIDTH = 0.036;
const float MOBIUS_RIB_CORE_STRENGTH = 0.40;
const float MOBIUS_RIB_GLOW_STRENGTH = 0.065;
const float MOBIUS_NODE_RADIUS = 0.040;
const float MOBIUS_NODE_STRENGTH = 0.30;
const float MOBIUS_CORE_RADIUS = 0.76;
const float MOBIUS_CORE_STRENGTH = 0.11;
const float MOBIUS_CORE_DARKEN = 0.08;
const float MOBIUS_EXPOSURE = 1.16;
const float MOBIUS_ALPHA_MAX = 0.50;
const float MOBIUS_LIGHT_ALPHA_GAIN = 0.78;

const vec3 MOBIUS_VOID = vec3(0.012, 0.010, 0.045);
const vec3 MOBIUS_BLUE = vec3(0.090, 0.320, 1.000);
const vec3 MOBIUS_CYAN = vec3(0.100, 0.900, 1.000);
const vec3 MOBIUS_VIOLET = vec3(0.650, 0.240, 1.000);
const vec3 MOBIUS_ROSE = vec3(0.980, 0.200, 0.620);
const vec3 MOBIUS_GOLD = vec3(1.000, 0.690, 0.230);
const vec3 MOBIUS_WHITE = vec3(0.980, 0.970, 1.000);
const float MOBIUS_TAU = 6.28318530718;

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

vec3 mobiusPoint(float parameter, float transverse) {
    float twist = 0.5 * MOBIUS_TWIST_COUNT * parameter;
    float radial = MOBIUS_MAJOR_RADIUS + transverse * cos(twist);
    return vec3(
        radial * cos(parameter),
        radial * sin(parameter),
        transverse * sin(twist)
    );
}

vec2 mobiusUv(float timeValue, float identity) {
    return lissajousUv(
        timeValue,
        identity,
        MOBIUS_PATH_AMPLITUDE,
        MOBIUS_PATH_FREQUENCY,
        MOBIUS_PATH_SPEED + identity * MOBIUS_COMPANION_PATH_SPEED_STEP,
        MOBIUS_PATH_PHASE
    );
}

void renderMobiusBackground(out vec4 fragColor, vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    // Wallpaper mode renders a complete procedural layer. Terminal
    // foreground coverage is applied only after the scene is complete.
    float backgroundMask = 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / MOBIUS_NARROW_REFERENCE_ASPECT,
        MOBIUS_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = vec3(0.0);
    float sceneAlpha = 0.0;

    for (int objectIndex = 0; objectIndex < MOBIUS_OBJECT_COUNT; objectIndex++) {
        float identity = float(objectIndex);
        vec2 centerUv = mobiusUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = objectIndex == 0 ? 1.0 : mix(
            1.0 - MOBIUS_SIZE_VARIATION,
            1.0 + MOBIUS_SIZE_VARIATION,
            hash12(vec2(identity, 12.7))
        );
        float sizeValue = MOBIUS_SIZE * narrowScale
            * pow(MOBIUS_COMPANION_SCALE, identity) * randomScale
            * (1.0 + MOBIUS_BREATHE_AMOUNT * sin(
                iTime * MOBIUS_BREATHE_SPEED + identity * 1.77
            ));
        float objectCullDistance = length(point - center) / max(sizeValue, 0.0001);
        if (objectCullDistance >= MOBIUS_CULL_RADIUS) continue;
        float objectCullFeather = 1.0 - smoothstep(
            MOBIUS_CULL_RADIUS - MOBIUS_CULL_FEATHER,
            MOBIUS_CULL_RADIUS,
            objectCullDistance
        );

        vec3 angle = MOBIUS_ROTATION_BASE
            + iTime * MOBIUS_ROTATION_SPEED
            + identity * MOBIUS_ROTATION_PHASE_STEP;
        vec3 radiance = vec3(0.0);
        float opacity = 0.0;

        for (int railIndex = 0; railIndex < MOBIUS_RAIL_COUNT; railIndex++) {
            float railPhase = float(railIndex) / max(float(MOBIUS_RAIL_COUNT - 1), 1.0);
            float transverse = mix(-MOBIUS_HALF_WIDTH, MOBIUS_HALF_WIDTH, railPhase);
            float railStrength = pow(MOBIUS_RAIL_FALLOFF, abs(
                float(railIndex) - 0.5 * float(MOBIUS_RAIL_COUNT - 1)
            ));
            for (int segmentIndex = 0; segmentIndex < MOBIUS_U_SEGMENT_COUNT; segmentIndex++) {
                float phase0 = float(segmentIndex) / float(MOBIUS_U_SEGMENT_COUNT);
                float phase1 = float(segmentIndex + 1) / float(MOBIUS_U_SEGMENT_COUNT);
                vec3 vertex0 = rotateXYZ(mobiusPoint(phase0 * MOBIUS_TAU, transverse), angle);
                vec3 vertex1 = rotateXYZ(mobiusPoint(phase1 * MOBIUS_TAU, transverse), angle);
                float depth0, depth1;
                vec2 projected0 = projectPoint(vertex0, center, sizeValue, MOBIUS_CAMERA_DISTANCE, depth0);
                vec2 projected1 = projectPoint(vertex1, center, sizeValue, MOBIUS_CAMERA_DISTANCE, depth1);
                float meshDistance = segmentDistance(point, projected0, projected1);
                float core = exp(-meshDistance / max(sizeValue * MOBIUS_RAIL_CORE_WIDTH, 0.00011));
                float glow = exp(-meshDistance / max(sizeValue * MOBIUS_RAIL_GLOW_WIDTH, 0.00032));
                float nearFactor = saturate((MOBIUS_CAMERA_DISTANCE + 0.8 - 0.5 * (depth0 + depth1)) / 1.7);
                vec3 sideColor = mix(MOBIUS_ROSE, MOBIUS_CYAN, railPhase);
                vec3 color = mix(sideColor, MOBIUS_VIOLET, 0.34 + 0.30 * nearFactor);
                color = mix(color, MOBIUS_WHITE, nearFactor * 0.30);
                radiance += color * railStrength * (
                    core * MOBIUS_RAIL_CORE_STRENGTH
                    + glow * MOBIUS_RAIL_GLOW_STRENGTH
                );
                opacity = max(opacity, railStrength * max(core, glow * 0.34));
            }
        }

        for (int ribIndex = 0; ribIndex < MOBIUS_RIB_COUNT; ribIndex++) {
            float phase = float(ribIndex) / float(MOBIUS_RIB_COUNT);
            float parameter = phase * MOBIUS_TAU;
            vec3 vertex0 = rotateXYZ(mobiusPoint(parameter, -MOBIUS_HALF_WIDTH), angle);
            vec3 vertex1 = rotateXYZ(mobiusPoint(parameter,  MOBIUS_HALF_WIDTH), angle);
            float depth0, depth1;
            vec2 projected0 = projectPoint(vertex0, center, sizeValue, MOBIUS_CAMERA_DISTANCE, depth0);
            vec2 projected1 = projectPoint(vertex1, center, sizeValue, MOBIUS_CAMERA_DISTANCE, depth1);
            float meshDistance = segmentDistance(point, projected0, projected1);
            float core = exp(-meshDistance / max(sizeValue * MOBIUS_RIB_CORE_WIDTH, 0.00010));
            float glow = exp(-meshDistance / max(sizeValue * MOBIUS_RIB_GLOW_WIDTH, 0.00028));
            float nearFactor = saturate((MOBIUS_CAMERA_DISTANCE + 0.8 - 0.5 * (depth0 + depth1)) / 1.7);
            vec3 color = mix(MOBIUS_GOLD, MOBIUS_CYAN, nearFactor);
            radiance += color * (
                core * MOBIUS_RIB_CORE_STRENGTH
                + glow * MOBIUS_RIB_GLOW_STRENGTH
            );
            opacity = max(opacity, max(core, glow * 0.28));
#if MOBIUS_ENABLE_NODES
            float node = gaussianPoint(point - mix(projected0, projected1, 0.5), sizeValue * MOBIUS_NODE_RADIUS);
            radiance += mix(MOBIUS_GOLD, MOBIUS_WHITE, nearFactor)
                * node * MOBIUS_NODE_STRENGTH;
            opacity = max(opacity, node * 0.58);
#endif
        }

#if MOBIUS_ENABLE_LANTERN_CORE
        float coreGlow = gaussianPoint(point - center, sizeValue * MOBIUS_CORE_RADIUS);
        composite = mix(
            composite,
            MOBIUS_VOID,
            coreGlow * MOBIUS_CORE_DARKEN * objectCullFeather * backgroundMask
        );
        radiance += mix(MOBIUS_GOLD, MOBIUS_VIOLET, 0.62)
            * coreGlow * MOBIUS_CORE_STRENGTH;
        opacity = max(opacity, coreGlow * 0.24);
#endif
        radiance *= objectCullFeather;
        opacity *= objectCullFeather;
        vec3 light = vec3(1.0) - exp(
            -max(radiance, vec3(0.0)) * MOBIUS_EXPOSURE * MOBIUS_MASTER_BRIGHTNESS
        );
        composite += light * backgroundMask;
        sceneAlpha = max(
            sceneAlpha,
            backgroundMask * MOBIUS_ALPHA_MAX
                * saturate(opacity + luminance(light) * MOBIUS_LIGHT_ALPHA_GAIN)
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
    renderMobiusBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);
}
