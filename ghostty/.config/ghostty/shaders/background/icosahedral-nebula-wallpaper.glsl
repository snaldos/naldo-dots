// BACKGROUND-ONLY WALLPAPER VARIANT: icosahedral-nebula
// Procedural geometry is composited behind exact terminal foreground.
// Pair this stage with any independently selected cursor shader.

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
const float ICO_CULL_RADIUS = 2.35;
const float ICO_CULL_FEATHER = 0.55;
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
    // Wallpaper mode renders a complete procedural layer. Terminal
    // foreground coverage is applied only after the scene is complete.
    float backgroundMask = 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / ICO_NARROW_REFERENCE_ASPECT,
        ICO_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = vec3(0.0);
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
        float objectCullDistance = length(point - center) / max(sizeValue, 0.0001);
        if (objectCullDistance >= ICO_CULL_RADIUS) continue;
        float objectCullFeather = 1.0 - smoothstep(
            ICO_CULL_RADIUS - ICO_CULL_FEATHER,
            ICO_CULL_RADIUS,
            objectCullDistance
        );

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
            envelope * ICO_NEBULA_DARKEN * objectCullFeather * backgroundMask
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
        radiance *= objectCullFeather;
        opacity *= objectCullFeather;
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
    renderIcosaBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);
}
