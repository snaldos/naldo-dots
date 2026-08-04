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
// MATCHED CURSOR CONTROLS
// =============================================================================

#define KC_ECHO_COUNT 2                  // quantity: 0..4
#define KC_ENABLE_TRAIL 1
#define KC_ENABLE_SPARKS 1
#define KC_ENABLE_RESONANCE_LINK 1    // 0 removes every cursor-object connection
#define KC_LINK_ALL_OBJECTS 1         // 1: every object; 0: primary object only

const float KC_EFFECT_DURATION = 0.38;
const float KC_FADE_POWER = 1.70;
const float KC_MIN_MOVEMENT_CELLS = 0.025;
const float KC_GROWTH_START_CELLS = 0.08;
const float KC_GROWTH_FULL_CELLS = 8.00;
const float KC_SIZE_MIN = 0.72;
const float KC_SIZE_MAX = 1.62;
const float KC_SIZE_PULSE = 0.10;
const float KC_CAMERA_DISTANCE = 4.00;
const float KC_CULL_RADIUS_MIN = 4.0;
const float KC_CULL_RADIUS_MAX = 7.5;
const float KC_CONTENT_PROTECTION = 0.18;
const float KC_MASTER_BRIGHTNESS = 1.00;
const float KC_ALPHA_MAX = 0.58;
const float KC_ALPHA_GAIN = 1.35;
const vec3 KC_ROTATION_SPEED = vec3(0.88, -1.04, 0.36);
const float KC_DIRECTION_TILT = 0.18;
const float KC_CORE_WIDTH = 0.038;
const float KC_GLOW_WIDTH = 0.145;
const float KC_CORE_STRENGTH = 0.46;
const float KC_GLOW_STRENGTH = 0.072;
const float KC_ECHO_START_SCALE = 1.03;
const float KC_ECHO_END_SCALE = 2.18;
const float KC_ECHO_DELAY = 0.14;
const float KC_ECHO_WIDTH = 0.046;
const float KC_ECHO_STRENGTH = 0.12;
const float KC_ECHO_FALLOFF = 0.68;
const float KC_TRAIL_WIDTH_MIN = 0.11;
const float KC_TRAIL_WIDTH_MAX = 0.24;
const float KC_TRAIL_GLOW_MULTIPLIER = 4.0;
const float KC_TRAIL_CORE_STRENGTH = 0.22;
const float KC_TRAIL_GLOW_STRENGTH = 0.052;
const float KC_SPARK_RADIUS = 0.070;
const float KC_SPARK_SPREAD = 1.70;
const float KC_SPARK_STRENGTH = 0.23;
const float KC_LINK_WIDTH = 0.060;
const float KC_LINK_GLOW_WIDTH = 0.25;
const float KC_LINK_CORE_STRENGTH = 0.045;
const float KC_LINK_GLOW_STRENGTH = 0.011;
const float KC_LINK_DASH_COUNT = 20.0;
const float KC_LINK_DASH_SPEED = 1.70;
const float KC_LINK_SECONDARY_FALLOFF = 0.72;
const float KC_LINK_COLOR_PHASE_STEP = 0.23;
// Movement factor 0..1 also drives link thickness, glow, energy, and dash density.
// MIN values apply to tiny cursor moves; MAX values apply at GROWTH_FULL_CELLS.
const float KC_LINK_MOVEMENT_POWER = 1.15;
const float KC_LINK_WIDTH_MIN_SCALE = 0.28;
const float KC_LINK_WIDTH_MAX_SCALE = 1.35;
const float KC_LINK_GLOW_WIDTH_MIN_SCALE = 0.22;
const float KC_LINK_GLOW_WIDTH_MAX_SCALE = 1.45;
const float KC_LINK_INTENSITY_MIN_SCALE = 0.10;
const float KC_LINK_INTENSITY_MAX_SCALE = 1.25;
const float KC_LINK_OPACITY_MIN_SCALE = 0.08;
const float KC_LINK_OPACITY_MAX_SCALE = 1.30;
const float KC_LINK_DASH_DENSITY_MIN_SCALE = 0.42;
const float KC_LINK_DASH_DENSITY_MAX_SCALE = 1.30;
const float KC_LINK_DASH_SPEED_MIN_SCALE = 0.40;
const float KC_LINK_DASH_SPEED_MAX_SCALE = 1.25;
const float KC_LINK_CULL_MIN_SCALE = 0.55;
const float KC_LINK_CULL_MAX_SCALE = 1.70;
const float KC_LINK_CULL_MIN_PIXELS = 4.0;


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
    float backgroundMask = backgroundCellMask(terminalColor);
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / KNOT_NARROW_REFERENCE_ASPECT,
        KNOT_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = terminalColor.rgb;
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
        max(terminalColor.a, sceneAlpha)
    );
}

void applyKnotCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = cursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = cursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / KC_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * KC_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = smoothstep(
        cursorPixels * KC_GROWTH_START_CELLS,
        cursorPixels * KC_GROWTH_FULL_CELLS,
        movedPixels
    );
    float linkMovementFactor = pow(movementFactor, KC_LINK_MOVEMENT_POWER);
    float linkWidthScale = mix(
        KC_LINK_WIDTH_MIN_SCALE,
        KC_LINK_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkGlowWidthScale = mix(
        KC_LINK_GLOW_WIDTH_MIN_SCALE,
        KC_LINK_GLOW_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkIntensityScale = mix(
        KC_LINK_INTENSITY_MIN_SCALE,
        KC_LINK_INTENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkOpacityScale = mix(
        KC_LINK_OPACITY_MIN_SCALE,
        KC_LINK_OPACITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashDensityScale = mix(
        KC_LINK_DASH_DENSITY_MIN_SCALE,
        KC_LINK_DASH_DENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashSpeedScale = mix(
        KC_LINK_DASH_SPEED_MIN_SCALE,
        KC_LINK_DASH_SPEED_MAX_SCALE,
        linkMovementFactor
    );
    float linkCullScale = mix(
        KC_LINK_CULL_MIN_SCALE,
        KC_LINK_CULL_MAX_SCALE,
        linkMovementFactor
    );
    float cullRadius = cursorPixels * mix(
        KC_CULL_RADIUS_MIN,
        KC_CULL_RADIUS_MAX,
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
        KC_LINK_CULL_MIN_PIXELS
    );
    bool nearAnyLink = false;
#if KC_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < KNOT_OBJECT_COUNT; linkIndex++) {
        if (KC_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = knotUv(iTime, linkIdentity) * resolution;
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
    float life = pow(1.0 - age, KC_FADE_POWER);
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float contentMask = mix(KC_CONTENT_PROTECTION, 1.0, backgroundCellMask(terminalColor));
    vec3 effectLight = vec3(0.0);
    float effectOpacity = 0.0;

#if KC_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < KNOT_OBJECT_COUNT; linkIndex++) {
        if (KC_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = knotUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        if (linkPixelDistance > linkCull) continue;

        vec2 linkObject = scenePoint(linkObjectPixels);
        float linkDistance = segmentDistance(point, head, linkObject);
        float linkAlong = segmentParameter(point, head, linkObject);
        float linkStrength = pow(KC_LINK_SECONDARY_FALLOFF, linkIdentity);
        float linkColorMix = saturate(
            linkAlong * 0.78 + linkIdentity * KC_LINK_COLOR_PHASE_STEP
        );
        float dash = 0.64 + 0.36 * sin(
            linkAlong * KC_LINK_DASH_COUNT * linkDashDensityScale
            - iTime * KC_LINK_DASH_SPEED * linkDashSpeedScale
            + linkIdentity * 2.17
        );
        float linkCore = exp(
            -linkDistance / max(cursorSize * KC_LINK_WIDTH * linkWidthScale, 0.0002)
        );
        float linkGlow = exp(
            -linkDistance / max(cursorSize * KC_LINK_GLOW_WIDTH * linkGlowWidthScale, 0.0005)
        );
        vec3 linkColor = mix(KNOT_ROSE, KNOT_CYAN, linkColorMix);
        effectLight += linkColor * dash * linkStrength * linkIntensityScale * (
            linkCore * KC_LINK_CORE_STRENGTH
            + linkGlow * KC_LINK_GLOW_STRENGTH
        );
        effectOpacity = max(
            effectOpacity,
            linkStrength * linkOpacityScale
                * (linkCore * 0.16 + linkGlow * 0.04)
        );
    }
#endif

    if (nearCursor) {
#if KC_ENABLE_TRAIL
        float trailDistance = segmentDistance(point, tail, head);
        float along = segmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            KC_TRAIL_WIDTH_MIN,
            KC_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, 0.20, along);
        float trailGlow = exp(-trailDistance / max(
            trailWidth * KC_TRAIL_GLOW_MULTIPLIER,
            0.0004
        )) * smoothstep(0.0, 0.16, along);
        vec3 trailColor = mix(KNOT_VIOLET, KNOT_CYAN, along);
        effectLight += trailColor * (
            trailCore * KC_TRAIL_CORE_STRENGTH
            + trailGlow * KC_TRAIL_GLOW_STRENGTH
        );
        effectOpacity = max(effectOpacity, trailCore * 0.28 + trailGlow * 0.07);
#endif

        float knotScale = cursorSize * mix(KC_SIZE_MIN, KC_SIZE_MAX, movementFactor)
            * (1.0 + KC_SIZE_PULSE * sin(age * 3.14159265359));
        vec3 angle = iTime * KC_ROTATION_SPEED;
        angle.z += atan(direction.y, direction.x) * KC_DIRECTION_TILT;
        for (int segmentIndex = 0; segmentIndex < KC_SEGMENT_COUNT; segmentIndex++) {
            float phase0 = float(segmentIndex) / float(KC_SEGMENT_COUNT);
            float phase1 = float(segmentIndex + 1) / float(KC_SEGMENT_COUNT);
            vec3 vertex0 = rotateXYZ(knotPoint(phase0 * KNOT_TAU, 2.0, 3.0), angle);
            vec3 vertex1 = rotateXYZ(knotPoint(phase1 * KNOT_TAU, 2.0, 3.0), angle);
            float depth0, depth1;
            vec2 projected0 = projectPoint(vertex0, head, knotScale, KC_CAMERA_DISTANCE, depth0);
            vec2 projected1 = projectPoint(vertex1, head, knotScale, KC_CAMERA_DISTANCE, depth1);
            float curveDistance = segmentDistance(point, projected0, projected1);
            float core = exp(-curveDistance / max(cursorSize * KC_CORE_WIDTH, 0.0001));
            float glow = exp(-curveDistance / max(cursorSize * KC_GLOW_WIDTH, 0.00025));
            float nearFactor = saturate((KC_CAMERA_DISTANCE + 0.8 - 0.5 * (depth0 + depth1)) / 1.8);
            vec3 color = mix(KNOT_VIOLET, KNOT_CYAN, nearFactor);
            color = mix(color, KNOT_WHITE, nearFactor * 0.30);
            effectLight += color * (
                core * KC_CORE_STRENGTH + glow * KC_GLOW_STRENGTH
            );
            effectOpacity = max(effectOpacity, core * 0.64 + glow * 0.12);

            for (int echoIndex = 0; echoIndex < KC_ECHO_COUNT; echoIndex++) {
                float delay = float(echoIndex) * KC_ECHO_DELAY;
                float progress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
                float echoActive = step(delay, easedAge);
                float scaleValue = mix(KC_ECHO_START_SCALE, KC_ECHO_END_SCALE, progress);
                vec2 echo0 = head + (projected0 - head) * scaleValue;
                vec2 echo1 = head + (projected1 - head) * scaleValue;
                float echoDistance = segmentDistance(point, echo0, echo1);
                float echo = exp(-echoDistance / max(cursorSize * KC_ECHO_WIDTH, 0.00011))
                    * (1.0 - progress) * echoActive;
                effectLight += mix(KNOT_BLUE, KNOT_ROSE, nearFactor) * echo
                    * KC_ECHO_STRENGTH * pow(KC_ECHO_FALLOFF, float(echoIndex));
                effectOpacity = max(effectOpacity, echo * 0.16);
            }
        }

#if KC_ENABLE_SPARKS && KC_SPARK_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int sparkIndex = 0; sparkIndex < KC_SPARK_COUNT; sparkIndex++) {
            float index = float(sparkIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 sparkCenter = mix(tail, head, positionRandom)
                + normal2d * (sideRandom - 0.5) * cursorSize * KC_SPARK_SPREAD;
            float spark = gaussianPoint(point - sparkCenter, cursorSize * KC_SPARK_RADIUS);
            effectLight += mix(KNOT_CYAN, KNOT_GOLD, sideRandom)
                * spark * KC_SPARK_STRENGTH;
            effectOpacity = max(effectOpacity, spark * 0.18);
        }
#endif
    }

    effectLight *= life * contentMask * KC_MASTER_BRIGHTNESS;
    scene.rgb += effectLight;
    scene.a = max(
        scene.a,
        life * contentMask * KC_ALPHA_MAX
            * saturate(effectOpacity + luminance(effectLight) * KC_ALPHA_GAIN)
    );
    float cursorCoverage = insideCursor(fragCoord, iCurrentCursor);
    scene = mix(scene, terminalColor, cursorCoverage);
    scene.rgb = clamp(scene.rgb, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    renderKnotBackground(fragColor, fragCoord);
    applyKnotCursor(fragColor, fragCoord);
}
