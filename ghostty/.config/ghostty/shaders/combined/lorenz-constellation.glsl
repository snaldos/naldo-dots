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
// MATCHED CURSOR CONTROLS
// =============================================================================

#define LC_ECHO_COUNT 2                  // quantity: 0..3
#define LC_ENABLE_TRAIL 1
#define LC_ENABLE_SPARKS 1
#define LC_ENABLE_RESONANCE_LINK 1    // 0 removes every cursor-object connection
#define LC_LINK_ALL_OBJECTS 1         // 1: every object; 0: primary object only
#define LC_ENABLE_CHAOS_CORE 1

const float LC_EFFECT_DURATION = 0.42;
const float LC_FADE_POWER = 1.62;
const float LC_MIN_MOVEMENT_CELLS = 0.025;
const float LC_GROWTH_START_CELLS = 0.08;
const float LC_GROWTH_FULL_CELLS = 8.00;
const float LC_SIZE_MIN = 1.12;
const float LC_SIZE_MAX = 2.72;
const float LC_SIZE_PULSE = 0.11;
const float LC_CAMERA_DISTANCE = 4.00;
const float LC_TIME_STEP_MULTIPLIER = 1.80;
const vec3 LC_INITIAL_STATE = vec3(1.0, 1.0, 20.0);
const float LC_CULL_RADIUS_MIN = 4.4;
const float LC_CULL_RADIUS_MAX = 8.4;
const float LC_CONTENT_PROTECTION = 0.18;
const float LC_MASTER_BRIGHTNESS = 1.00;
const float LC_ALPHA_MAX = 0.58;
const float LC_ALPHA_GAIN = 1.35;
const vec3 LC_ROTATION_BASE = vec3(0.05, -0.10, 0.00);
const vec3 LC_ROTATION_SPEED = vec3(0.010, -0.015, 0.020);
const float LC_DIRECTION_TILT = 0.16;
const float LC_CORE_WIDTH = 0.038;
const float LC_GLOW_WIDTH = 0.145;
const float LC_CORE_STRENGTH = 0.46;
const float LC_GLOW_STRENGTH = 0.070;
const float LC_CHAOS_CORE_RADIUS = 0.68;
const float LC_CHAOS_CORE_STRENGTH = 0.080;
const float LC_ECHO_START_SCALE = 1.03;
const float LC_ECHO_END_SCALE = 2.18;
const float LC_ECHO_DELAY = 0.15;
const float LC_ECHO_WIDTH = 0.046;
const float LC_ECHO_STRENGTH = 0.105;
const float LC_ECHO_FALLOFF = 0.66;
const float LC_TRAIL_WIDTH_MIN = 0.11;
const float LC_TRAIL_WIDTH_MAX = 0.24;
const float LC_TRAIL_GLOW_MULTIPLIER = 4.0;
const float LC_TRAIL_CORE_STRENGTH = 0.22;
const float LC_TRAIL_GLOW_STRENGTH = 0.052;
const float LC_SPARK_RADIUS = 0.070;
const float LC_SPARK_SPREAD = 1.85;
const float LC_SPARK_STRENGTH = 0.24;
const float LC_LINK_WIDTH = 0.060;
const float LC_LINK_GLOW_WIDTH = 0.25;
const float LC_LINK_CORE_STRENGTH = 0.045;
const float LC_LINK_GLOW_STRENGTH = 0.011;
const float LC_LINK_DASH_COUNT = 23.0;
const float LC_LINK_DASH_SPEED = 1.78;
const float LC_LINK_SECONDARY_FALLOFF = 0.72;
const float LC_LINK_COLOR_PHASE_STEP = 0.23;
// Movement factor 0..1 also drives link thickness, glow, energy, and dash density.
// MIN values apply to tiny cursor moves; MAX values apply at GROWTH_FULL_CELLS.
const float LC_LINK_MOVEMENT_POWER = 1.15;
const float LC_LINK_WIDTH_MIN_SCALE = 0.28;
const float LC_LINK_WIDTH_MAX_SCALE = 1.35;
const float LC_LINK_GLOW_WIDTH_MIN_SCALE = 0.22;
const float LC_LINK_GLOW_WIDTH_MAX_SCALE = 1.45;
const float LC_LINK_INTENSITY_MIN_SCALE = 0.10;
const float LC_LINK_INTENSITY_MAX_SCALE = 1.25;
const float LC_LINK_OPACITY_MIN_SCALE = 0.08;
const float LC_LINK_OPACITY_MAX_SCALE = 1.30;
const float LC_LINK_DASH_DENSITY_MIN_SCALE = 0.42;
const float LC_LINK_DASH_DENSITY_MAX_SCALE = 1.30;
const float LC_LINK_DASH_SPEED_MIN_SCALE = 0.40;
const float LC_LINK_DASH_SPEED_MAX_SCALE = 1.25;
const float LC_LINK_CULL_MIN_SCALE = 0.55;
const float LC_LINK_CULL_MAX_SCALE = 1.70;
const float LC_LINK_CULL_MIN_PIXELS = 4.0;


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
    float backgroundMask = backgroundCellMask(terminalColor);
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / LORENZ_NARROW_REFERENCE_ASPECT,
        LORENZ_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = terminalColor.rgb;
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
        max(terminalColor.a, sceneAlpha)
    );
}

void applyLorenzCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = cursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = cursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / LC_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * LC_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = smoothstep(
        cursorPixels * LC_GROWTH_START_CELLS,
        cursorPixels * LC_GROWTH_FULL_CELLS,
        movedPixels
    );
    float linkMovementFactor = pow(movementFactor, LC_LINK_MOVEMENT_POWER);
    float linkWidthScale = mix(
        LC_LINK_WIDTH_MIN_SCALE,
        LC_LINK_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkGlowWidthScale = mix(
        LC_LINK_GLOW_WIDTH_MIN_SCALE,
        LC_LINK_GLOW_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkIntensityScale = mix(
        LC_LINK_INTENSITY_MIN_SCALE,
        LC_LINK_INTENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkOpacityScale = mix(
        LC_LINK_OPACITY_MIN_SCALE,
        LC_LINK_OPACITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashDensityScale = mix(
        LC_LINK_DASH_DENSITY_MIN_SCALE,
        LC_LINK_DASH_DENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashSpeedScale = mix(
        LC_LINK_DASH_SPEED_MIN_SCALE,
        LC_LINK_DASH_SPEED_MAX_SCALE,
        linkMovementFactor
    );
    float linkCullScale = mix(
        LC_LINK_CULL_MIN_SCALE,
        LC_LINK_CULL_MAX_SCALE,
        linkMovementFactor
    );
    float cullRadius = cursorPixels * mix(
        LC_CULL_RADIUS_MIN,
        LC_CULL_RADIUS_MAX,
        movementFactor
    );
    bool nearCursor = all(greaterThanEqual(
        fragCoord,
        min(headPixels, tailPixels) - vec2(cullRadius)
    )) && all(lessThanEqual(
        fragCoord,
        max(headPixels, tailPixels) + vec2(cullRadius)
    ));
    float linkCull = max(
        cursorPixels * linkCullScale,
        LC_LINK_CULL_MIN_PIXELS
    );
    bool nearAnyLink = false;
#if LC_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < LORENZ_OBJECT_COUNT; linkIndex++) {
        if (LC_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = lorenzUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        nearAnyLink = nearAnyLink || linkPixelDistance <= linkCull;
    }
#endif
    if (!nearCursor && !nearAnyLink) return;

    vec2 point = scenePoint(fragCoord);
    vec2 head = scenePoint(headPixels);
    vec2 tail = scenePoint(tailPixels);
    vec2 movement = head - tail;
    vec2 direction = movement / max(length(movement), 0.000001);
    vec2 normal2d = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float life = pow(1.0 - age, LC_FADE_POWER);
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float contentMask = mix(LC_CONTENT_PROTECTION, 1.0, backgroundCellMask(terminalColor));
    vec3 effectLight = vec3(0.0);
    float effectOpacity = 0.0;

#if LC_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < LORENZ_OBJECT_COUNT; linkIndex++) {
        if (LC_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = lorenzUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        if (linkPixelDistance > linkCull) continue;

        vec2 linkObject = scenePoint(linkObjectPixels);
        float linkDistance = segmentDistance(point, head, linkObject);
        float linkAlong = segmentParameter(point, head, linkObject);
        float linkStrength = pow(LC_LINK_SECONDARY_FALLOFF, linkIdentity);
        float linkColorMix = saturate(
            linkAlong * 0.78 + linkIdentity * LC_LINK_COLOR_PHASE_STEP
        );
        float dash = 0.64 + 0.36 * sin(
            linkAlong * LC_LINK_DASH_COUNT * linkDashDensityScale
            - iTime * LC_LINK_DASH_SPEED * linkDashSpeedScale
            + linkIdentity * 2.17
        );
        float linkCore = exp(
            -linkDistance / max(cursorSize * LC_LINK_WIDTH * linkWidthScale, 0.0002)
        );
        float linkGlow = exp(
            -linkDistance / max(cursorSize * LC_LINK_GLOW_WIDTH * linkGlowWidthScale, 0.0005)
        );
        vec3 linkColor = mix(LORENZ_ROSE, LORENZ_CYAN, linkColorMix);
        effectLight += linkColor * dash * linkStrength * linkIntensityScale * (
            linkCore * LC_LINK_CORE_STRENGTH
            + linkGlow * LC_LINK_GLOW_STRENGTH
        );
        effectOpacity = max(
            effectOpacity,
            linkStrength * linkOpacityScale
                * (linkCore * 0.16 + linkGlow * 0.04)
        );
    }
#endif

    if (nearCursor) {
#if LC_ENABLE_TRAIL
        float trailDistance = segmentDistance(point, tail, head);
        float along = segmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            LC_TRAIL_WIDTH_MIN,
            LC_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, 0.20, along);
        float trailGlow = exp(-trailDistance / max(
            trailWidth * LC_TRAIL_GLOW_MULTIPLIER,
            0.0004
        )) * smoothstep(0.0, 0.16, along);
        vec3 trailColor = mix(LORENZ_VIOLET, LORENZ_CYAN, along);
        effectLight += trailColor * (
            trailCore * LC_TRAIL_CORE_STRENGTH
            + trailGlow * LC_TRAIL_GLOW_STRENGTH
        );
        effectOpacity = max(effectOpacity, trailCore * 0.28 + trailGlow * 0.07);
#endif

        float shapeScale = cursorSize * mix(LC_SIZE_MIN, LC_SIZE_MAX, movementFactor)
            * (1.0 + LC_SIZE_PULSE * sin(age * 3.14159265359));
        vec3 angle = LC_ROTATION_BASE + iTime * LC_ROTATION_SPEED;
        angle.z += atan(direction.y, direction.x) * LC_DIRECTION_TILT;
        vec3 state = LC_INITIAL_STATE
            + vec3(movementFactor * 0.08, -movementFactor * 0.04, 0.0);
        for (int segmentIndex = 0; segmentIndex < LC_SEGMENT_COUNT; segmentIndex++) {
            vec3 previousState = state;
            for (int stepIndex = 0; stepIndex < LORENZ_STEPS_PER_SEGMENT; stepIndex++) {
                state = lorenzStep(
                    state,
                    LORENZ_TIME_STEP * LC_TIME_STEP_MULTIPLIER
                );
            }
            vec3 vertex0 = rotateXYZ(lorenzDisplay(previousState), angle);
            vec3 vertex1 = rotateXYZ(lorenzDisplay(state), angle);
            float depth0, depth1;
            vec2 projected0 = projectPoint(vertex0, head, shapeScale, LC_CAMERA_DISTANCE, depth0);
            vec2 projected1 = projectPoint(vertex1, head, shapeScale, LC_CAMERA_DISTANCE, depth1);
            float curveDistance = segmentDistance(point, projected0, projected1);
            float core = exp(-curveDistance / max(cursorSize * LC_CORE_WIDTH, 0.0001));
            float glow = exp(-curveDistance / max(cursorSize * LC_GLOW_WIDTH, 0.00024));
            float lobe = smoothstep(-14.0, 14.0, 0.5 * (previousState.x + state.x));
            float nearFactor = saturate((LC_CAMERA_DISTANCE + 0.8 - 0.5 * (
                depth0 + depth1
            )) / 1.8);
            vec3 color = mix(LORENZ_VIOLET, LORENZ_CYAN, lobe);
            color = mix(color, LORENZ_WHITE, nearFactor * 0.30);
            effectLight += color * (
                core * LC_CORE_STRENGTH + glow * LC_GLOW_STRENGTH
            );
            effectOpacity = max(effectOpacity, core * 0.62 + glow * 0.12);
            for (int echoIndex = 0; echoIndex < LC_ECHO_COUNT; echoIndex++) {
                float delay = float(echoIndex) * LC_ECHO_DELAY;
                float progress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
                float echoActive = step(delay, easedAge);
                float scaleValue = mix(LC_ECHO_START_SCALE, LC_ECHO_END_SCALE, progress);
                vec2 echo0 = head + (projected0 - head) * scaleValue;
                vec2 echo1 = head + (projected1 - head) * scaleValue;
                float echoDistance = segmentDistance(point, echo0, echo1);
                float echo = exp(-echoDistance / max(cursorSize * LC_ECHO_WIDTH, 0.00011))
                    * (1.0 - progress) * echoActive;
                effectLight += mix(LORENZ_BLUE, LORENZ_ROSE, lobe) * echo
                    * LC_ECHO_STRENGTH * pow(LC_ECHO_FALLOFF, float(echoIndex));
                effectOpacity = max(effectOpacity, echo * 0.16);
            }
        }

#if LC_ENABLE_CHAOS_CORE
        float chaosCore = gaussianPoint(point - head, shapeScale * LC_CHAOS_CORE_RADIUS);
        effectLight += mix(LORENZ_VIOLET, LORENZ_CYAN, 0.48)
            * chaosCore * LC_CHAOS_CORE_STRENGTH;
        effectOpacity = max(effectOpacity, chaosCore * 0.18);
#endif
#if LC_ENABLE_SPARKS && LC_SPARK_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int sparkIndex = 0; sparkIndex < LC_SPARK_COUNT; sparkIndex++) {
            float index = float(sparkIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 sparkCenter = mix(tail, head, positionRandom)
                + normal2d * (sideRandom - 0.5) * cursorSize * LC_SPARK_SPREAD;
            float spark = gaussianPoint(point - sparkCenter, cursorSize * LC_SPARK_RADIUS);
            effectLight += mix(LORENZ_CYAN, LORENZ_GOLD, sideRandom)
                * spark * LC_SPARK_STRENGTH;
            effectOpacity = max(effectOpacity, spark * 0.18);
        }
#endif
    }

    effectLight *= life * contentMask * LC_MASTER_BRIGHTNESS;
    scene.rgb += effectLight;
    scene.a = max(
        scene.a,
        life * contentMask * LC_ALPHA_MAX
            * saturate(effectOpacity + luminance(effectLight) * LC_ALPHA_GAIN)
    );
    float cursorCoverage = insideCursor(fragCoord, iCurrentCursor);
    scene = mix(scene, terminalColor, cursorCoverage);
    scene.rgb = clamp(scene.rgb, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    renderLorenzBackground(fragColor, fragCoord);
    applyLorenzCursor(fragColor, fragCoord);
}
