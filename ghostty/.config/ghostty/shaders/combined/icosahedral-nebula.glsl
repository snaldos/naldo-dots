#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 1
#endif
#define CREATIVE_GPU_ECO 0
#define CREATIVE_GPU_BALANCED 1
#define CREATIVE_GPU_QUALITY 2
#define CREATIVE_GPU_ULTRA 3

// Icosahedral Nebula — cosmic clouds caged in true projected icosahedra
//
// Roaming 20-faced stellar cages contain animated nebula cores and vertex stars.
// Cursor movement summons a matching icosahedron with a miniature nova, expanding
// polyhedral echoes, and an optional resonance beam. Quantities, geometry, cloud
// structure, path, lighting, and response are exposed below.

// =============================================================================
// BACKGROUND CONTROLS
// =============================================================================

#if GHOSTTY_GPU_PROFILE == CREATIVE_GPU_ECO
#define ICO_VERTEX_GAIN 0.12
#define IC_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_BALANCED
#define ICO_VERTEX_GAIN 0.24
#define IC_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_QUALITY
#define ICO_VERTEX_GAIN 0.36
#define IC_SPARK_COUNT 4
#else
#define ICO_VERTEX_GAIN 0.48
#define IC_SPARK_COUNT 7
#endif

#define ICO_OBJECT_COUNT 2               // quantity: 1..4
#define ICO_ENABLE_NEBULA 1
#define ICO_ENABLE_VERTEX_STARS 1
#define ICO_ENABLE_ORBITAL_WISP 1

const float ICO_MASTER_BRIGHTNESS = 1.00;
const float ICO_SIZE = 0.100;
const float ICO_COMPANION_SCALE = 0.70;
const float ICO_SIZE_VARIATION = 0.10;
const float ICO_NARROW_REFERENCE_ASPECT = 1.20;
const float ICO_NARROW_MIN_SCALE = 0.62;
const float ICO_CAMERA_DISTANCE = 4.20;
const float ICO_CULL_RADIUS = 1.72;
const float ICO_BREATHE_AMOUNT = 0.060;
const float ICO_BREATHE_SPEED = 1.14;
const vec3 ICO_ROTATION_BASE = vec3(0.58, -0.70, 0.12);
const vec3 ICO_ROTATION_SPEED = vec3(0.16, 0.23, 0.12);
const vec3 ICO_ROTATION_PHASE_STEP = vec3(0.82, 1.17, 0.66);

const vec2 ICO_PATH_AMPLITUDE = vec2(0.40, 0.34);
const vec2 ICO_PATH_FREQUENCY = vec2(0.69, 1.07);
const vec2 ICO_PATH_PHASE = vec2(1.72, 0.66);
const float ICO_PATH_SPEED = 0.102;
const float ICO_COMPANION_PATH_SPEED_STEP = 0.024;

const float ICO_EDGE_CORE_WIDTH = 0.009;
const float ICO_EDGE_GLOW_WIDTH = 0.038;
const float ICO_EDGE_CORE_STRENGTH = 0.62;
const float ICO_EDGE_GLOW_STRENGTH = 0.105;
const float ICO_DEPTH_COLOR_STRENGTH = 0.78;
const float ICO_VERTEX_RADIUS = 0.025;
const float ICO_VERTEX_STRENGTH = 0.46;
const float ICO_NEBULA_RADIUS = 0.88;
const float ICO_NEBULA_DARKEN = 0.20;
const float ICO_NEBULA_STRENGTH = 0.24;
const float ICO_NEBULA_SWIRL_COUNT = 4.0;
const float ICO_NEBULA_RADIAL_FREQUENCY = 11.0;
const float ICO_NEBULA_SPIN_SPEED = 0.38;
const float ICO_NEBULA_CONTRAST = 0.62;
const float ICO_WISP_RADIUS = 0.68;
const float ICO_WISP_COMPRESSION = 0.32;
const float ICO_WISP_WIDTH = 0.090;
const float ICO_WISP_STRENGTH = 0.13;
const float ICO_WISP_ROTATION_SPEED = 0.22;
const float ICO_EXPOSURE = 1.18;
const float ICO_ALPHA_MAX = 0.54;
const float ICO_LIGHT_ALPHA_GAIN = 0.82;

const vec3 ICO_VOID = vec3(0.006, 0.005, 0.034);
const vec3 ICO_BLUE = vec3(0.080, 0.290, 1.000);
const vec3 ICO_CYAN = vec3(0.090, 0.880, 1.000);
const vec3 ICO_VIOLET = vec3(0.650, 0.220, 1.000);
const vec3 ICO_ROSE = vec3(0.980, 0.180, 0.600);
const vec3 ICO_GOLD = vec3(1.000, 0.700, 0.240);
const vec3 ICO_WHITE = vec3(0.990, 0.970, 1.000);
const float ICO_TAU = 6.28318530718;

// =============================================================================
// MATCHED CURSOR CONTROLS
// =============================================================================

#define IC_ECHO_COUNT 2                  // quantity: 0..4
#define IC_ENABLE_TRAIL 1
#define IC_ENABLE_SPARKS 1
#define IC_ENABLE_RESONANCE_LINK 1
#define IC_ENABLE_CURSOR_NOVA 1

const float IC_EFFECT_DURATION = 0.40;
const float IC_FADE_POWER = 1.66;
const float IC_MIN_MOVEMENT_CELLS = 0.025;
const float IC_GROWTH_START_CELLS = 0.08;
const float IC_GROWTH_FULL_CELLS = 8.00;
const float IC_SIZE_MIN = 0.92;
const float IC_SIZE_MAX = 1.94;
const float IC_SIZE_PULSE = 0.12;
const float IC_CAMERA_DISTANCE = 4.00;
const float IC_CULL_RADIUS_MIN = 4.4;
const float IC_CULL_RADIUS_MAX = 8.4;
const float IC_CONTENT_PROTECTION = 0.18;
const float IC_MASTER_BRIGHTNESS = 1.00;
const float IC_ALPHA_MAX = 0.60;
const float IC_ALPHA_GAIN = 1.38;
const vec3 IC_ROTATION_SPEED = vec3(0.90, -1.08, 0.44);
const float IC_DIRECTION_TILT = 0.20;
const float IC_EDGE_CORE_WIDTH = 0.038;
const float IC_EDGE_GLOW_WIDTH = 0.145;
const float IC_EDGE_CORE_STRENGTH = 0.44;
const float IC_EDGE_GLOW_STRENGTH = 0.068;
const float IC_VERTEX_RADIUS = 0.085;
const float IC_VERTEX_STRENGTH = 0.22;
const float IC_NOVA_RADIUS = 0.70;
const float IC_NOVA_STRENGTH = 0.17;
const float IC_NOVA_RAY_COUNT = 8.0;
const float IC_NOVA_RAY_STRENGTH = 0.060;
const float IC_ECHO_START_SCALE = 1.03;
const float IC_ECHO_END_SCALE = 2.22;
const float IC_ECHO_DELAY = 0.14;
const float IC_ECHO_WIDTH = 0.046;
const float IC_ECHO_STRENGTH = 0.105;
const float IC_ECHO_FALLOFF = 0.67;
const float IC_TRAIL_WIDTH_MIN = 0.11;
const float IC_TRAIL_WIDTH_MAX = 0.24;
const float IC_TRAIL_GLOW_MULTIPLIER = 4.0;
const float IC_TRAIL_CORE_STRENGTH = 0.22;
const float IC_TRAIL_GLOW_STRENGTH = 0.052;
const float IC_SPARK_RADIUS = 0.070;
const float IC_SPARK_SPREAD = 1.85;
const float IC_SPARK_STRENGTH = 0.24;
const float IC_LINK_WIDTH = 0.060;
const float IC_LINK_GLOW_WIDTH = 0.25;
const float IC_LINK_CORE_STRENGTH = 0.045;
const float IC_LINK_GLOW_STRENGTH = 0.011;
const float IC_LINK_DASH_COUNT = 21.0;
const float IC_LINK_DASH_SPEED = 1.72;


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

vec3 icosaVertex(int index) {
    const float phi = 1.61803398875;
    const float normalizer = 0.52573111212;
    if (index == 0)  return vec3(0.0,  1.0,  phi) * normalizer;
    if (index == 1)  return vec3(0.0, -1.0,  phi) * normalizer;
    if (index == 2)  return vec3(0.0,  1.0, -phi) * normalizer;
    if (index == 3)  return vec3(0.0, -1.0, -phi) * normalizer;
    if (index == 4)  return vec3( 1.0,  phi, 0.0) * normalizer;
    if (index == 5)  return vec3(-1.0,  phi, 0.0) * normalizer;
    if (index == 6)  return vec3( 1.0, -phi, 0.0) * normalizer;
    if (index == 7)  return vec3(-1.0, -phi, 0.0) * normalizer;
    if (index == 8)  return vec3( phi, 0.0,  1.0) * normalizer;
    if (index == 9)  return vec3(-phi, 0.0,  1.0) * normalizer;
    if (index == 10) return vec3( phi, 0.0, -1.0) * normalizer;
    return vec3(-phi, 0.0, -1.0) * normalizer;
}

bool isIcosaEdge(int first, int second) {
    float vertexDistance = length(icosaVertex(first) - icosaVertex(second));
    return vertexDistance < 1.10;
}

vec2 icosaUv(float timeValue, float identity) {
    return lissajousUv(
        timeValue,
        identity,
        ICO_PATH_AMPLITUDE,
        ICO_PATH_FREQUENCY,
        ICO_PATH_SPEED + identity * ICO_COMPANION_PATH_SPEED_STEP,
        ICO_PATH_PHASE
    );
}

void renderIcosaBackground(out vec4 fragColor, vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    float backgroundMask = backgroundCellMask(terminalColor);
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / ICO_NARROW_REFERENCE_ASPECT,
        ICO_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = terminalColor.rgb;
    float sceneAlpha = 0.0;

    for (int objectIndex = 0; objectIndex < ICO_OBJECT_COUNT; objectIndex++) {
        float identity = float(objectIndex);
        vec2 centerUv = icosaUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = objectIndex == 0 ? 1.0 : mix(
            1.0 - ICO_SIZE_VARIATION,
            1.0 + ICO_SIZE_VARIATION,
            hash12(vec2(identity, 17.6))
        );
        float sizeValue = ICO_SIZE * narrowScale
            * pow(ICO_COMPANION_SCALE, identity) * randomScale
            * (1.0 + ICO_BREATHE_AMOUNT * sin(
                iTime * ICO_BREATHE_SPEED + identity * 1.79
            ));
        if (
            abs(point.x - center.x) > sizeValue * ICO_CULL_RADIUS
            || abs(point.y - center.y) > sizeValue * ICO_CULL_RADIUS
        ) continue;

        vec3 angle = ICO_ROTATION_BASE
            + iTime * ICO_ROTATION_SPEED
            + identity * ICO_ROTATION_PHASE_STEP;
        vec2 projected[12];
        float depth[12];
        for (int vertexIndex = 0; vertexIndex < 12; vertexIndex++) {
            vec3 vertex = rotateXYZ(icosaVertex(vertexIndex), angle);
            projected[vertexIndex] = projectPoint(
                vertex,
                center,
                sizeValue,
                ICO_CAMERA_DISTANCE,
                depth[vertexIndex]
            );
        }

        vec3 radiance = vec3(0.0);
        float opacity = 0.0;
#if ICO_ENABLE_NEBULA
        vec2 nebulaPoint = rotate2d(
            (point - center) / max(sizeValue, 0.0001),
            -iTime * ICO_NEBULA_SPIN_SPEED - identity
        );
        float nebulaRadius = length(nebulaPoint);
        float nebulaAngle = atan(nebulaPoint.y, nebulaPoint.x);
        float envelope = exp(-pow(nebulaRadius / ICO_NEBULA_RADIUS, 2.4));
        float swirl = 0.5 + 0.5 * sin(
            nebulaAngle * ICO_NEBULA_SWIRL_COUNT
            + nebulaRadius * ICO_NEBULA_RADIAL_FREQUENCY
            - iTime * ICO_NEBULA_SPIN_SPEED * 4.0
            + identity * 1.7
        );
        float cloud = envelope * mix(1.0 - ICO_NEBULA_CONTRAST, 1.0, swirl);
        composite = mix(
            composite,
            ICO_VOID,
            envelope * ICO_NEBULA_DARKEN * backgroundMask
        );
        radiance += mix(ICO_VIOLET, ICO_CYAN, swirl)
            * cloud * ICO_NEBULA_STRENGTH;
        radiance += ICO_ROSE * envelope * (1.0 - swirl) * ICO_NEBULA_STRENGTH * 0.52;
        opacity = max(opacity, cloud * 0.44);
#endif
#if ICO_ENABLE_ORBITAL_WISP
        vec2 wispPoint = rotate2d(
            (point - center) / max(sizeValue, 0.0001),
            iTime * ICO_WISP_ROTATION_SPEED + identity * 0.7
        );
        float wispRadius = length(vec2(
            wispPoint.x,
            wispPoint.y / max(ICO_WISP_COMPRESSION, 0.04)
        ));
        float wisp = exp(-abs(wispRadius - ICO_WISP_RADIUS) / ICO_WISP_WIDTH);
        radiance += mix(ICO_GOLD, ICO_CYAN, 0.42) * wisp * ICO_WISP_STRENGTH;
        opacity = max(opacity, wisp * 0.30);
#endif

        for (int first = 0; first < 12; first++) {
            for (int second = first + 1; second < 12; second++) {
                if (!isIcosaEdge(first, second)) continue;
                float edgeDistance = segmentDistance(point, projected[first], projected[second]);
                float core = exp(-edgeDistance / max(sizeValue * ICO_EDGE_CORE_WIDTH, 0.00010));
                float glow = exp(-edgeDistance / max(sizeValue * ICO_EDGE_GLOW_WIDTH, 0.00028));
                float nearFactor = saturate((ICO_CAMERA_DISTANCE + 0.8 - 0.5 * (
                    depth[first] + depth[second]
                )) / 1.7);
                vec3 depthColor = mix(ICO_VIOLET, ICO_CYAN, nearFactor);
                vec3 phaseColor = mix(ICO_BLUE, ICO_ROSE, float(first + second) / 22.0);
                vec3 color = mix(phaseColor, depthColor, ICO_DEPTH_COLOR_STRENGTH);
                color = mix(color, ICO_WHITE, nearFactor * 0.30);
                radiance += color * (
                    core * ICO_EDGE_CORE_STRENGTH
                    + glow * ICO_EDGE_GLOW_STRENGTH
                );
                opacity = max(opacity, max(core, glow * 0.34));
            }
        }
#if ICO_ENABLE_VERTEX_STARS
        for (int vertexIndex = 0; vertexIndex < 12; vertexIndex++) {
            float star = gaussianPoint(point - projected[vertexIndex], sizeValue * ICO_VERTEX_RADIUS);
            float nearFactor = saturate((ICO_CAMERA_DISTANCE + 0.8 - depth[vertexIndex]) / 1.7);
            radiance += mix(ICO_GOLD, ICO_WHITE, nearFactor)
                * star * ICO_VERTEX_STRENGTH * ICO_VERTEX_GAIN;
            opacity = max(opacity, star * 0.48 * ICO_VERTEX_GAIN);
        }
#endif
        vec3 light = vec3(1.0) - exp(
            -max(radiance, vec3(0.0)) * ICO_EXPOSURE * ICO_MASTER_BRIGHTNESS
        );
        composite += light * backgroundMask;
        sceneAlpha = max(
            sceneAlpha,
            backgroundMask * ICO_ALPHA_MAX
                * saturate(opacity + luminance(light) * ICO_LIGHT_ALPHA_GAIN)
        );
    }
    fragColor = vec4(
        clamp(composite, 0.0, 1.0),
        max(terminalColor.a, sceneAlpha)
    );
}

void applyIcosaCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = cursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = cursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / IC_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * IC_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = smoothstep(
        cursorPixels * IC_GROWTH_START_CELLS,
        cursorPixels * IC_GROWTH_FULL_CELLS,
        movedPixels
    );
    float cullRadius = cursorPixels * mix(
        IC_CULL_RADIUS_MIN,
        IC_CULL_RADIUS_MAX,
        movementFactor
    );
    bool nearCursor = all(greaterThanEqual(
        fragCoord,
        min(headPixels, tailPixels) - vec2(cullRadius)
    )) && all(lessThanEqual(
        fragCoord,
        max(headPixels, tailPixels) + vec2(cullRadius)
    ));
    vec2 primaryPixels = icosaUv(iTime, 0.0) * resolution;
    float linkCull = max(cursorPixels * 1.5, 8.0);
    bool nearLink = all(greaterThanEqual(
        fragCoord,
        min(headPixels, primaryPixels) - vec2(linkCull)
    )) && all(lessThanEqual(
        fragCoord,
        max(headPixels, primaryPixels) + vec2(linkCull)
    ));
    if (!nearCursor && !nearLink) return;

    vec2 point = scenePoint(fragCoord);
    vec2 head = scenePoint(headPixels);
    vec2 tail = scenePoint(tailPixels);
    vec2 primary = scenePoint(primaryPixels);
    vec2 movement = head - tail;
    vec2 direction = movement / max(length(movement), 0.000001);
    vec2 normal2d = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float life = pow(1.0 - age, IC_FADE_POWER);
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float contentMask = mix(IC_CONTENT_PROTECTION, 1.0, backgroundCellMask(terminalColor));
    vec3 effectLight = vec3(0.0);
    float effectOpacity = 0.0;

#if IC_ENABLE_RESONANCE_LINK
    if (nearLink) {
        float linkDistance = segmentDistance(point, head, primary);
        float linkAlong = segmentParameter(point, head, primary);
        float dash = 0.64 + 0.36 * sin(
            linkAlong * IC_LINK_DASH_COUNT - iTime * IC_LINK_DASH_SPEED
        );
        float core = exp(-linkDistance / max(cursorSize * IC_LINK_WIDTH, 0.0002));
        float glow = exp(-linkDistance / max(cursorSize * IC_LINK_GLOW_WIDTH, 0.0005));
        effectLight += mix(ICO_ROSE, ICO_CYAN, linkAlong) * dash * (
            core * IC_LINK_CORE_STRENGTH + glow * IC_LINK_GLOW_STRENGTH
        );
        effectOpacity = max(effectOpacity, core * 0.16 + glow * 0.04);
    }
#endif

    if (nearCursor) {
#if IC_ENABLE_TRAIL
        float trailDistance = segmentDistance(point, tail, head);
        float along = segmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            IC_TRAIL_WIDTH_MIN,
            IC_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, 0.20, along);
        float trailGlow = exp(-trailDistance / max(
            trailWidth * IC_TRAIL_GLOW_MULTIPLIER,
            0.0004
        )) * smoothstep(0.0, 0.16, along);
        vec3 trailColor = mix(ICO_VIOLET, ICO_CYAN, along);
        effectLight += trailColor * (
            trailCore * IC_TRAIL_CORE_STRENGTH
            + trailGlow * IC_TRAIL_GLOW_STRENGTH
        );
        effectOpacity = max(effectOpacity, trailCore * 0.28 + trailGlow * 0.07);
#endif

        float shapeScale = cursorSize * mix(IC_SIZE_MIN, IC_SIZE_MAX, movementFactor)
            * (1.0 + IC_SIZE_PULSE * sin(age * 3.14159265359));
        vec3 angle = iTime * IC_ROTATION_SPEED;
        angle.z += atan(direction.y, direction.x) * IC_DIRECTION_TILT;
        vec2 projected[12];
        float depth[12];
        for (int vertexIndex = 0; vertexIndex < 12; vertexIndex++) {
            vec3 vertex = rotateXYZ(icosaVertex(vertexIndex), angle);
            projected[vertexIndex] = projectPoint(
                vertex,
                head,
                shapeScale,
                IC_CAMERA_DISTANCE,
                depth[vertexIndex]
            );
        }
        for (int first = 0; first < 12; first++) {
            for (int second = first + 1; second < 12; second++) {
                if (!isIcosaEdge(first, second)) continue;
                float edgeDistance = segmentDistance(point, projected[first], projected[second]);
                float core = exp(-edgeDistance / max(cursorSize * IC_EDGE_CORE_WIDTH, 0.0001));
                float glow = exp(-edgeDistance / max(cursorSize * IC_EDGE_GLOW_WIDTH, 0.00024));
                float nearFactor = saturate((IC_CAMERA_DISTANCE + 0.8 - 0.5 * (
                    depth[first] + depth[second]
                )) / 1.8);
                vec3 color = mix(ICO_VIOLET, ICO_CYAN, nearFactor);
                color = mix(color, ICO_WHITE, nearFactor * 0.32);
                effectLight += color * (
                    core * IC_EDGE_CORE_STRENGTH + glow * IC_EDGE_GLOW_STRENGTH
                );
                effectOpacity = max(effectOpacity, core * 0.62 + glow * 0.12);
                for (int echoIndex = 0; echoIndex < IC_ECHO_COUNT; echoIndex++) {
                    float delay = float(echoIndex) * IC_ECHO_DELAY;
                    float progress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
                    float echoActive = step(delay, easedAge);
                    float scaleValue = mix(IC_ECHO_START_SCALE, IC_ECHO_END_SCALE, progress);
                    vec2 echo0 = head + (projected[first] - head) * scaleValue;
                    vec2 echo1 = head + (projected[second] - head) * scaleValue;
                    float echoDistance = segmentDistance(point, echo0, echo1);
                    float echo = exp(-echoDistance / max(cursorSize * IC_ECHO_WIDTH, 0.00011))
                        * (1.0 - progress) * echoActive;
                    effectLight += mix(ICO_BLUE, ICO_ROSE, nearFactor) * echo
                        * IC_ECHO_STRENGTH * pow(IC_ECHO_FALLOFF, float(echoIndex));
                    effectOpacity = max(effectOpacity, echo * 0.16);
                }
            }
        }
        for (int vertexIndex = 0; vertexIndex < 12; vertexIndex++) {
            float star = gaussianPoint(
                point - projected[vertexIndex],
                cursorSize * IC_VERTEX_RADIUS
            );
            effectLight += mix(ICO_GOLD, ICO_CYAN, float(vertexIndex) / 11.0)
                * star * IC_VERTEX_STRENGTH;
            effectOpacity = max(effectOpacity, star * 0.20);
        }

#if IC_ENABLE_CURSOR_NOVA
        vec2 novaPoint = (point - head) / max(shapeScale, 0.0001);
        float novaRadius = length(novaPoint);
        float novaAngle = atan(novaPoint.y, novaPoint.x);
        float nova = gaussianPoint(point - head, shapeScale * IC_NOVA_RADIUS);
        float rays = pow(abs(cos(novaAngle * 0.5 * IC_NOVA_RAY_COUNT)), 18.0)
            * exp(-novaRadius * 2.8);
        effectLight += mix(ICO_VIOLET, ICO_CYAN, 0.54)
            * nova * IC_NOVA_STRENGTH;
        effectLight += ICO_WHITE * rays * IC_NOVA_RAY_STRENGTH;
        effectOpacity = max(effectOpacity, nova * 0.24 + rays * 0.12);
#endif

#if IC_ENABLE_SPARKS && IC_SPARK_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int sparkIndex = 0; sparkIndex < IC_SPARK_COUNT; sparkIndex++) {
            float index = float(sparkIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 sparkCenter = mix(tail, head, positionRandom)
                + normal2d * (sideRandom - 0.5) * cursorSize * IC_SPARK_SPREAD;
            float spark = gaussianPoint(point - sparkCenter, cursorSize * IC_SPARK_RADIUS);
            effectLight += mix(ICO_CYAN, ICO_GOLD, sideRandom)
                * spark * IC_SPARK_STRENGTH;
            effectOpacity = max(effectOpacity, spark * 0.18);
        }
#endif
    }

    effectLight *= life * contentMask * IC_MASTER_BRIGHTNESS;
    scene.rgb += effectLight;
    scene.a = max(
        scene.a,
        life * contentMask * IC_ALPHA_MAX
            * saturate(effectOpacity + luminance(effectLight) * IC_ALPHA_GAIN)
    );
    float cursorCoverage = insideCursor(fragCoord, iCurrentCursor);
    scene = mix(scene, terminalColor, cursorCoverage);
    scene.rgb = clamp(scene.rgb, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    renderIcosaBackground(fragColor, fragCoord);
    applyIcosaCursor(fragColor, fragCoord);
}
