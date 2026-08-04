// BACKGROUND-ONLY WALLPAPER VARIANT: lorenz-constellation
// Procedural geometry is composited behind exact terminal foreground.
// Pair this stage with any independently selected cursor shader.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 1
#endif
#define CREATIVE_GPU_ECO 0
#define CREATIVE_GPU_BALANCED 1
#define CREATIVE_GPU_QUALITY 2
#define CREATIVE_GPU_ULTRA 3

// Lorenz Constellation — numerically integrated strange attractors and cursor
//
// Roaming 3D Lorenz trajectories are integrated directly in the fragment shader
// with midpoint steps. Nearby strands expose sensitive dependence on initial
// conditions. Cursor motion summons a miniature chaotic butterfly, expanding
// attractor echoes, a comet trail, and an optional connection to the main system.

// =============================================================================
// BACKGROUND CONTROLS
// =============================================================================

#if GHOSTTY_GPU_PROFILE == CREATIVE_GPU_ECO
#define LORENZ_SEGMENT_COUNT 34
#define LC_SEGMENT_COUNT 20
#define LC_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_BALANCED
#define LORENZ_SEGMENT_COUNT 46
#define LC_SEGMENT_COUNT 26
#define LC_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_QUALITY
#define LORENZ_SEGMENT_COUNT 60
#define LC_SEGMENT_COUNT 34
#define LC_SPARK_COUNT 4
#else
#define LORENZ_SEGMENT_COUNT 76
#define LC_SEGMENT_COUNT 42
#define LC_SPARK_COUNT 7
#endif

#define LORENZ_OBJECT_COUNT 1            // quantity: 1..2
#define LORENZ_STRAND_COUNT 2            // nearby chaotic trajectories: 1..3
#define LORENZ_STEPS_PER_SEGMENT 4       // integration density: 1..6
#define LORENZ_ENABLE_EQUILIBRIA 1
#define LORENZ_ENABLE_CORE 1

const float LORENZ_SIGMA = 10.0;
const float LORENZ_RHO = 28.0;
const float LORENZ_BETA = 2.66666666667;
const float LORENZ_TIME_STEP = 0.012;
const float LORENZ_INITIAL_SEPARATION = 0.030;
const vec3 LORENZ_INITIAL_STATE = vec3(-8.0, 8.0, 27.0);
const vec3 LORENZ_DISPLAY_SCALE = vec3(0.050, 0.040, 0.050);
const float LORENZ_DISPLAY_Z_CENTER = 25.0;

const float LORENZ_MASTER_BRIGHTNESS = 1.00;
const float LORENZ_SIZE = 0.140;
const float LORENZ_COMPANION_SCALE = 0.72;
const float LORENZ_SIZE_VARIATION = 0.08;
const float LORENZ_NARROW_REFERENCE_ASPECT = 1.20;
const float LORENZ_NARROW_MIN_SCALE = 0.62;
const float LORENZ_CAMERA_DISTANCE = 4.30;
const float LORENZ_CULL_RADIUS = 2.30;
const float LORENZ_CULL_FEATHER = 0.50;
const float LORENZ_BREATHE_AMOUNT = 0.050;
const float LORENZ_BREATHE_SPEED = 1.06;
const vec3 LORENZ_ROTATION_BASE = vec3(0.36, -0.48, 0.06);
const vec3 LORENZ_ROTATION_SPEED = vec3(0.10, 0.15, 0.08);
const vec3 LORENZ_ROTATION_PHASE_STEP = vec3(0.74, 1.08, 0.62);

const vec2 LORENZ_PATH_AMPLITUDE = vec2(0.39, 0.33);
const vec2 LORENZ_PATH_FREQUENCY = vec2(0.71, 1.05);
const vec2 LORENZ_PATH_PHASE = vec2(2.04, 0.22);
const float LORENZ_PATH_SPEED = 0.094;
const float LORENZ_COMPANION_PATH_SPEED_STEP = 0.021;

const float LORENZ_CORE_WIDTH = 0.009;
const float LORENZ_GLOW_WIDTH = 0.038;
const float LORENZ_CORE_STRENGTH = 0.68;
const float LORENZ_GLOW_STRENGTH = 0.11;
const float LORENZ_STRAND_FALLOFF = 0.78;
const float LORENZ_DEPTH_COLOR_STRENGTH = 0.62;
const float LORENZ_EQUILIBRIUM_RADIUS = 0.036;
const float LORENZ_EQUILIBRIUM_STRENGTH = 0.34;
const float LORENZ_CENTER_CORE_RADIUS = 0.62;
const float LORENZ_CENTER_CORE_STRENGTH = 0.055;
const float LORENZ_EXPOSURE = 1.20;
const float LORENZ_ALPHA_MAX = 0.50;
const float LORENZ_LIGHT_ALPHA_GAIN = 0.80;

const vec3 LORENZ_VOID = vec3(0.008, 0.006, 0.038);
const vec3 LORENZ_BLUE = vec3(0.080, 0.290, 1.000);
const vec3 LORENZ_CYAN = vec3(0.080, 0.900, 1.000);
const vec3 LORENZ_VIOLET = vec3(0.650, 0.220, 1.000);
const vec3 LORENZ_ROSE = vec3(0.990, 0.180, 0.590);
const vec3 LORENZ_GOLD = vec3(1.000, 0.710, 0.250);
const vec3 LORENZ_WHITE = vec3(0.990, 0.970, 1.000);

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

vec3 lorenzDerivative(vec3 state) {
    return vec3(
        LORENZ_SIGMA * (state.y - state.x),
        state.x * (LORENZ_RHO - state.z) - state.y,
        state.x * state.y - LORENZ_BETA * state.z
    );
}

vec3 lorenzStep(vec3 state, float stepSize) {
    vec3 midpoint = state + 0.5 * stepSize * lorenzDerivative(state);
    return state + stepSize * lorenzDerivative(midpoint);
}

vec3 lorenzDisplay(vec3 state) {
    return vec3(
        state.x * LORENZ_DISPLAY_SCALE.x,
        (state.z - LORENZ_DISPLAY_Z_CENTER) * LORENZ_DISPLAY_SCALE.y,
        state.y * LORENZ_DISPLAY_SCALE.z
    );
}

vec2 lorenzUv(float timeValue, float identity) {
    return lissajousUv(
        timeValue,
        identity,
        LORENZ_PATH_AMPLITUDE,
        LORENZ_PATH_FREQUENCY,
        LORENZ_PATH_SPEED + identity * LORENZ_COMPANION_PATH_SPEED_STEP,
        LORENZ_PATH_PHASE
    );
}

void renderLorenzBackground(out vec4 fragColor, vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    // Wallpaper mode renders a complete procedural layer. Terminal
    // foreground coverage is applied only after the scene is complete.
    float backgroundMask = 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / LORENZ_NARROW_REFERENCE_ASPECT,
        LORENZ_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = vec3(0.0);
    float sceneAlpha = 0.0;

    for (int objectIndex = 0; objectIndex < LORENZ_OBJECT_COUNT; objectIndex++) {
        float identity = float(objectIndex);
        vec2 centerUv = lorenzUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = objectIndex == 0 ? 1.0 : mix(
            1.0 - LORENZ_SIZE_VARIATION,
            1.0 + LORENZ_SIZE_VARIATION,
            hash12(vec2(identity, 25.2))
        );
        float sizeValue = LORENZ_SIZE * narrowScale
            * pow(LORENZ_COMPANION_SCALE, identity) * randomScale
            * (1.0 + LORENZ_BREATHE_AMOUNT * sin(
                iTime * LORENZ_BREATHE_SPEED + identity * 1.73
            ));
        float objectCullDistance = length(point - center) / max(sizeValue, 0.0001);
        if (objectCullDistance >= LORENZ_CULL_RADIUS) continue;
        float objectCullFeather = 1.0 - smoothstep(
            LORENZ_CULL_RADIUS - LORENZ_CULL_FEATHER,
            LORENZ_CULL_RADIUS,
            objectCullDistance
        );

        vec3 angle = LORENZ_ROTATION_BASE
            + iTime * LORENZ_ROTATION_SPEED
            + identity * LORENZ_ROTATION_PHASE_STEP;
        vec3 radiance = vec3(0.0);
        float opacity = 0.0;
        float objectSign = (objectIndex % 2) == 0 ? 1.0 : -1.0;

        for (int strandIndex = 0; strandIndex < LORENZ_STRAND_COUNT; strandIndex++) {
            float strandPhase = float(strandIndex) / max(float(LORENZ_STRAND_COUNT - 1), 1.0);
            float separation = (float(strandIndex) - 0.5 * float(LORENZ_STRAND_COUNT - 1))
                * LORENZ_INITIAL_SEPARATION;
            vec3 state = LORENZ_INITIAL_STATE * objectSign
                + vec3(separation, -separation * 0.7, 0.0);
            state.z = LORENZ_INITIAL_STATE.z;
            float strandStrength = pow(LORENZ_STRAND_FALLOFF, float(strandIndex));
            for (int segmentIndex = 0; segmentIndex < LORENZ_SEGMENT_COUNT; segmentIndex++) {
                vec3 previousState = state;
                for (int stepIndex = 0; stepIndex < LORENZ_STEPS_PER_SEGMENT; stepIndex++) {
                    state = lorenzStep(state, LORENZ_TIME_STEP);
                }
                vec3 vertex0 = rotateXYZ(lorenzDisplay(previousState), angle);
                vec3 vertex1 = rotateXYZ(lorenzDisplay(state), angle);
                float depth0, depth1;
                vec2 projected0 = projectPoint(vertex0, center, sizeValue, LORENZ_CAMERA_DISTANCE, depth0);
                vec2 projected1 = projectPoint(vertex1, center, sizeValue, LORENZ_CAMERA_DISTANCE, depth1);
                float curveDistance = segmentDistance(point, projected0, projected1);
                float core = exp(-curveDistance / max(sizeValue * LORENZ_CORE_WIDTH, 0.00010));
                float glow = exp(-curveDistance / max(sizeValue * LORENZ_GLOW_WIDTH, 0.00028));
                float lobe = smoothstep(-14.0, 14.0, 0.5 * (previousState.x + state.x));
                float nearFactor = saturate((LORENZ_CAMERA_DISTANCE + 0.8 - 0.5 * (
                    depth0 + depth1
                )) / 1.7);
                vec3 lobeColor = mix(LORENZ_VIOLET, LORENZ_CYAN, lobe);
                vec3 depthColor = mix(LORENZ_BLUE, LORENZ_ROSE, nearFactor);
                vec3 color = mix(lobeColor, depthColor, LORENZ_DEPTH_COLOR_STRENGTH);
                color = mix(color, LORENZ_WHITE, nearFactor * 0.26);
                radiance += color * strandStrength * (
                    core * LORENZ_CORE_STRENGTH
                    + glow * LORENZ_GLOW_STRENGTH
                );
                opacity = max(opacity, strandStrength * max(core, glow * 0.34));
            }
        }

#if LORENZ_ENABLE_EQUILIBRIA
        float equilibriumCoordinate = sqrt(LORENZ_BETA * (LORENZ_RHO - 1.0));
        for (int equilibriumIndex = 0; equilibriumIndex < 2; equilibriumIndex++) {
            float signValue = equilibriumIndex == 0 ? -1.0 : 1.0;
            vec3 equilibriumState = vec3(
                signValue * equilibriumCoordinate,
                signValue * equilibriumCoordinate,
                LORENZ_RHO - 1.0
            );
            vec3 vertex = rotateXYZ(lorenzDisplay(equilibriumState), angle);
            float depth;
            vec2 projected = projectPoint(
                vertex,
                center,
                sizeValue,
                LORENZ_CAMERA_DISTANCE,
                depth
            );
            float equilibrium = gaussianPoint(
                point - projected,
                sizeValue * LORENZ_EQUILIBRIUM_RADIUS
            );
            radiance += mix(LORENZ_ROSE, LORENZ_CYAN, float(equilibriumIndex))
                * equilibrium * LORENZ_EQUILIBRIUM_STRENGTH;
            opacity = max(opacity, equilibrium * 0.50);
        }
#endif
#if LORENZ_ENABLE_CORE
        float coreGlow = gaussianPoint(
            point - center,
            sizeValue * LORENZ_CENTER_CORE_RADIUS
        );
        radiance += mix(LORENZ_VIOLET, LORENZ_BLUE, 0.48)
            * coreGlow * LORENZ_CENTER_CORE_STRENGTH;
        opacity = max(opacity, coreGlow * 0.18);
#endif
        radiance *= objectCullFeather;
        opacity *= objectCullFeather;
        vec3 light = vec3(1.0) - exp(
            -max(radiance, vec3(0.0)) * LORENZ_EXPOSURE * LORENZ_MASTER_BRIGHTNESS
        );
        composite += light * backgroundMask;
        sceneAlpha = max(
            sceneAlpha,
            backgroundMask * LORENZ_ALPHA_MAX
                * saturate(opacity + luminance(light) * LORENZ_LIGHT_ALPHA_GAIN)
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
    renderLorenzBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);
}
