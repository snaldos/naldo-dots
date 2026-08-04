// BUILD: standalone mobius-lanterns cursor
// Derived from combined/mobius-lanterns.glsl; mainImage never renders its background.
// Cursor movement effects vanish while stationary and preserve terminal alpha.

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
// MATCHED CURSOR CONTROLS
// =============================================================================

#define MC_RAIL_COUNT 3                  // cursor ribbon rails: 2..6
#define MC_RIB_COUNT 8                   // cursor transverse ribs: 0..14
#define MC_ECHO_COUNT 2                  // quantity: 0..3
#define MC_ENABLE_TRAIL 1
#define MC_ENABLE_SPARKS 1
#define MC_ENABLE_RESONANCE_LINK 0    // standalone cursor: no links to invisible objects
#define MC_LINK_ALL_OBJECTS 1         // 1: every object; 0: primary object only

const float MC_EFFECT_DURATION = 0.40;
const float MC_FADE_POWER = 1.68;
const float MC_MIN_MOVEMENT_CELLS = 0.025;
const float MC_GROWTH_START_CELLS = 0.08;
const float MC_GROWTH_FULL_CELLS = 8.00;
const float MC_SIZE_MIN = 0.76;
const float MC_SIZE_MAX = 1.72;
const float MC_SIZE_PULSE = 0.11;
const float MC_CAMERA_DISTANCE = 4.00;
const float MC_CULL_RADIUS_MIN = 4.2;
const float MC_CULL_RADIUS_MAX = 7.8;
const float MC_CONTENT_PROTECTION = 0.18;
const float MC_MASTER_BRIGHTNESS = 1.00;
const float MC_ALPHA_MAX = 0.58;
const float MC_ALPHA_GAIN = 1.35;
const vec3 MC_ROTATION_SPEED = vec3(0.84, -1.02, 0.40);
const float MC_DIRECTION_TILT = 0.20;
const float MC_CORE_WIDTH = 0.038;
const float MC_GLOW_WIDTH = 0.145;
const float MC_CORE_STRENGTH = 0.42;
const float MC_GLOW_STRENGTH = 0.067;
const float MC_RIB_STRENGTH = 0.72;
const float MC_ECHO_START_SCALE = 1.03;
const float MC_ECHO_END_SCALE = 2.16;
const float MC_ECHO_DELAY = 0.15;
const float MC_ECHO_WIDTH = 0.046;
const float MC_ECHO_STRENGTH = 0.10;
const float MC_ECHO_FALLOFF = 0.66;
const float MC_TRAIL_WIDTH_MIN = 0.11;
const float MC_TRAIL_WIDTH_MAX = 0.24;
const float MC_TRAIL_GLOW_MULTIPLIER = 4.0;
const float MC_TRAIL_CORE_STRENGTH = 0.22;
const float MC_TRAIL_GLOW_STRENGTH = 0.052;
const float MC_SPARK_RADIUS = 0.070;
const float MC_SPARK_SPREAD = 1.75;
const float MC_SPARK_STRENGTH = 0.23;
const float MC_LINK_WIDTH = 0.060;
const float MC_LINK_GLOW_WIDTH = 0.25;
const float MC_LINK_CORE_STRENGTH = 0.045;
const float MC_LINK_GLOW_STRENGTH = 0.011;
const float MC_LINK_DASH_COUNT = 18.0;
const float MC_LINK_DASH_SPEED = 1.62;
const float MC_LINK_SECONDARY_FALLOFF = 0.72;
const float MC_LINK_COLOR_PHASE_STEP = 0.23;
// Movement factor 0..1 also drives link thickness, glow, energy, and dash density.
// MIN values apply to tiny cursor moves; MAX values apply at GROWTH_FULL_CELLS.
const float MC_LINK_MOVEMENT_POWER = 1.15;
const float MC_LINK_WIDTH_MIN_SCALE = 0.28;
const float MC_LINK_WIDTH_MAX_SCALE = 1.35;
const float MC_LINK_GLOW_WIDTH_MIN_SCALE = 0.22;
const float MC_LINK_GLOW_WIDTH_MAX_SCALE = 1.45;
const float MC_LINK_INTENSITY_MIN_SCALE = 0.10;
const float MC_LINK_INTENSITY_MAX_SCALE = 1.25;
const float MC_LINK_OPACITY_MIN_SCALE = 0.08;
const float MC_LINK_OPACITY_MAX_SCALE = 1.30;
const float MC_LINK_DASH_DENSITY_MIN_SCALE = 0.42;
const float MC_LINK_DASH_DENSITY_MAX_SCALE = 1.30;
const float MC_LINK_DASH_SPEED_MIN_SCALE = 0.40;
const float MC_LINK_DASH_SPEED_MAX_SCALE = 1.25;
const float MC_LINK_CULL_MIN_SCALE = 0.55;
const float MC_LINK_CULL_MAX_SCALE = 1.70;
const float MC_LINK_CULL_MIN_PIXELS = 4.0;


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
    float backgroundMask = backgroundCellMask(terminalColor);
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / MOBIUS_NARROW_REFERENCE_ASPECT,
        MOBIUS_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = terminalColor.rgb;
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
        max(terminalColor.a, sceneAlpha)
    );
}

void applyMobiusCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = cursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = cursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / MC_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * MC_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = smoothstep(
        cursorPixels * MC_GROWTH_START_CELLS,
        cursorPixels * MC_GROWTH_FULL_CELLS,
        movedPixels
    );
    float linkMovementFactor = pow(movementFactor, MC_LINK_MOVEMENT_POWER);
    float linkWidthScale = mix(
        MC_LINK_WIDTH_MIN_SCALE,
        MC_LINK_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkGlowWidthScale = mix(
        MC_LINK_GLOW_WIDTH_MIN_SCALE,
        MC_LINK_GLOW_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkIntensityScale = mix(
        MC_LINK_INTENSITY_MIN_SCALE,
        MC_LINK_INTENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkOpacityScale = mix(
        MC_LINK_OPACITY_MIN_SCALE,
        MC_LINK_OPACITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashDensityScale = mix(
        MC_LINK_DASH_DENSITY_MIN_SCALE,
        MC_LINK_DASH_DENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashSpeedScale = mix(
        MC_LINK_DASH_SPEED_MIN_SCALE,
        MC_LINK_DASH_SPEED_MAX_SCALE,
        linkMovementFactor
    );
    float linkCullScale = mix(
        MC_LINK_CULL_MIN_SCALE,
        MC_LINK_CULL_MAX_SCALE,
        linkMovementFactor
    );
    float cullRadius = cursorPixels * mix(
        MC_CULL_RADIUS_MIN,
        MC_CULL_RADIUS_MAX,
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
        MC_LINK_CULL_MIN_PIXELS
    );
    bool nearAnyLink = false;
#if MC_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < MOBIUS_OBJECT_COUNT; linkIndex++) {
        if (MC_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = mobiusUv(iTime, linkIdentity) * resolution;
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
    float life = pow(1.0 - age, MC_FADE_POWER);
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float contentMask = mix(MC_CONTENT_PROTECTION, 1.0, backgroundCellMask(terminalColor));
    vec3 effectLight = vec3(0.0);
    float effectOpacity = 0.0;

#if MC_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < MOBIUS_OBJECT_COUNT; linkIndex++) {
        if (MC_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = mobiusUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        if (linkPixelDistance > linkCull) continue;

        vec2 linkObject = scenePoint(linkObjectPixels);
        float linkDistance = segmentDistance(point, head, linkObject);
        float linkAlong = segmentParameter(point, head, linkObject);
        float linkStrength = pow(MC_LINK_SECONDARY_FALLOFF, linkIdentity);
        float linkColorMix = saturate(
            linkAlong * 0.78 + linkIdentity * MC_LINK_COLOR_PHASE_STEP
        );
        float dash = 0.64 + 0.36 * sin(
            linkAlong * MC_LINK_DASH_COUNT * linkDashDensityScale
            - iTime * MC_LINK_DASH_SPEED * linkDashSpeedScale
            + linkIdentity * 2.17
        );
        float linkCore = exp(
            -linkDistance / max(cursorSize * MC_LINK_WIDTH * linkWidthScale, 0.0002)
        );
        float linkGlow = exp(
            -linkDistance / max(cursorSize * MC_LINK_GLOW_WIDTH * linkGlowWidthScale, 0.0005)
        );
        vec3 linkColor = mix(MOBIUS_GOLD, MOBIUS_CYAN, linkColorMix);
        effectLight += linkColor * dash * linkStrength * linkIntensityScale * (
            linkCore * MC_LINK_CORE_STRENGTH
            + linkGlow * MC_LINK_GLOW_STRENGTH
        );
        effectOpacity = max(
            effectOpacity,
            linkStrength * linkOpacityScale
                * (linkCore * 0.16 + linkGlow * 0.04)
        );
    }
#endif

    if (nearCursor) {
#if MC_ENABLE_TRAIL
        float trailDistance = segmentDistance(point, tail, head);
        float along = segmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            MC_TRAIL_WIDTH_MIN,
            MC_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, 0.20, along);
        float trailGlow = exp(-trailDistance / max(
            trailWidth * MC_TRAIL_GLOW_MULTIPLIER,
            0.0004
        )) * smoothstep(0.0, 0.16, along);
        vec3 trailColor = mix(MOBIUS_VIOLET, MOBIUS_CYAN, along);
        effectLight += trailColor * (
            trailCore * MC_TRAIL_CORE_STRENGTH
            + trailGlow * MC_TRAIL_GLOW_STRENGTH
        );
        effectOpacity = max(effectOpacity, trailCore * 0.28 + trailGlow * 0.07);
#endif

        float ribbonScale = cursorSize * mix(MC_SIZE_MIN, MC_SIZE_MAX, movementFactor)
            * (1.0 + MC_SIZE_PULSE * sin(age * 3.14159265359));
        vec3 angle = iTime * MC_ROTATION_SPEED;
        angle.z += atan(direction.y, direction.x) * MC_DIRECTION_TILT;
        for (int railIndex = 0; railIndex < MC_RAIL_COUNT; railIndex++) {
            float railPhase = float(railIndex) / max(float(MC_RAIL_COUNT - 1), 1.0);
            float transverse = mix(-MOBIUS_HALF_WIDTH, MOBIUS_HALF_WIDTH, railPhase);
            for (int segmentIndex = 0; segmentIndex < MC_U_SEGMENT_COUNT; segmentIndex++) {
                float phase0 = float(segmentIndex) / float(MC_U_SEGMENT_COUNT);
                float phase1 = float(segmentIndex + 1) / float(MC_U_SEGMENT_COUNT);
                vec3 vertex0 = rotateXYZ(mobiusPoint(phase0 * MOBIUS_TAU, transverse), angle);
                vec3 vertex1 = rotateXYZ(mobiusPoint(phase1 * MOBIUS_TAU, transverse), angle);
                float depth0, depth1;
                vec2 projected0 = projectPoint(vertex0, head, ribbonScale, MC_CAMERA_DISTANCE, depth0);
                vec2 projected1 = projectPoint(vertex1, head, ribbonScale, MC_CAMERA_DISTANCE, depth1);
                float meshDistance = segmentDistance(point, projected0, projected1);
                float core = exp(-meshDistance / max(cursorSize * MC_CORE_WIDTH, 0.0001));
                float glow = exp(-meshDistance / max(cursorSize * MC_GLOW_WIDTH, 0.00024));
                float nearFactor = saturate((MC_CAMERA_DISTANCE + 0.8 - 0.5 * (depth0 + depth1)) / 1.8);
                vec3 color = mix(MOBIUS_ROSE, MOBIUS_CYAN, railPhase);
                color = mix(color, MOBIUS_WHITE, nearFactor * 0.30);
                effectLight += color * (
                    core * MC_CORE_STRENGTH + glow * MC_GLOW_STRENGTH
                );
                effectOpacity = max(effectOpacity, core * 0.60 + glow * 0.12);
                for (int echoIndex = 0; echoIndex < MC_ECHO_COUNT; echoIndex++) {
                    float delay = float(echoIndex) * MC_ECHO_DELAY;
                    float progress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
                    float echoActive = step(delay, easedAge);
                    float scaleValue = mix(MC_ECHO_START_SCALE, MC_ECHO_END_SCALE, progress);
                    vec2 echo0 = head + (projected0 - head) * scaleValue;
                    vec2 echo1 = head + (projected1 - head) * scaleValue;
                    float echoDistance = segmentDistance(point, echo0, echo1);
                    float echo = exp(-echoDistance / max(cursorSize * MC_ECHO_WIDTH, 0.00011))
                        * (1.0 - progress) * echoActive;
                    effectLight += mix(MOBIUS_BLUE, MOBIUS_VIOLET, railPhase)
                        * echo * MC_ECHO_STRENGTH * pow(MC_ECHO_FALLOFF, float(echoIndex));
                    effectOpacity = max(effectOpacity, echo * 0.15);
                }
            }
        }

        for (int ribIndex = 0; ribIndex < MC_RIB_COUNT; ribIndex++) {
            float parameter = float(ribIndex) / float(MC_RIB_COUNT) * MOBIUS_TAU;
            vec3 vertex0 = rotateXYZ(mobiusPoint(parameter, -MOBIUS_HALF_WIDTH), angle);
            vec3 vertex1 = rotateXYZ(mobiusPoint(parameter,  MOBIUS_HALF_WIDTH), angle);
            float depth0, depth1;
            vec2 projected0 = projectPoint(vertex0, head, ribbonScale, MC_CAMERA_DISTANCE, depth0);
            vec2 projected1 = projectPoint(vertex1, head, ribbonScale, MC_CAMERA_DISTANCE, depth1);
            float meshDistance = segmentDistance(point, projected0, projected1);
            float core = exp(-meshDistance / max(cursorSize * MC_CORE_WIDTH, 0.0001));
            float glow = exp(-meshDistance / max(cursorSize * MC_GLOW_WIDTH, 0.00024));
            effectLight += mix(MOBIUS_GOLD, MOBIUS_CYAN, float(ribIndex) / max(float(MC_RIB_COUNT - 1), 1.0))
                * MC_RIB_STRENGTH * (
                    core * MC_CORE_STRENGTH + glow * MC_GLOW_STRENGTH
                );
            effectOpacity = max(effectOpacity, core * 0.48 + glow * 0.10);
        }

#if MC_ENABLE_SPARKS && MC_SPARK_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int sparkIndex = 0; sparkIndex < MC_SPARK_COUNT; sparkIndex++) {
            float index = float(sparkIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 sparkCenter = mix(tail, head, positionRandom)
                + normal2d * (sideRandom - 0.5) * cursorSize * MC_SPARK_SPREAD;
            float spark = gaussianPoint(point - sparkCenter, cursorSize * MC_SPARK_RADIUS);
            effectLight += mix(MOBIUS_CYAN, MOBIUS_GOLD, sideRandom)
                * spark * MC_SPARK_STRENGTH;
            effectOpacity = max(effectOpacity, spark * 0.18);
        }
#endif
    }

    effectLight *= life * contentMask * MC_MASTER_BRIGHTNESS;
    scene.rgb += effectLight;
    scene.a = max(
        scene.a,
        life * contentMask * MC_ALPHA_MAX
            * saturate(effectOpacity + luminance(effectLight) * MC_ALPHA_GAIN)
    );
    float cursorCoverage = insideCursor(fragCoord, iCurrentCursor);
    scene = mix(scene, terminalColor, cursorCoverage);
    scene.rgb = clamp(scene.rgb, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 terminalUv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, terminalUv);
    fragColor = terminalColor;
    applyMobiusCursor(fragColor, fragCoord);
    // The desktop compositor remains authoritative outside the terminal layer.
    fragColor.a = terminalColor.a;
}
