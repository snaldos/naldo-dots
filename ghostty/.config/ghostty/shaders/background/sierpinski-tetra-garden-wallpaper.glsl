// BACKGROUND-ONLY WALLPAPER VARIANT: sierpinski-tetra-garden
// Procedural geometry is composited behind exact terminal foreground.
// Pair this stage with any independently selected cursor shader.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 1
#endif
#define CREATIVE_GPU_ECO 0
#define CREATIVE_GPU_BALANCED 1
#define CREATIVE_GPU_QUALITY 2
#define CREATIVE_GPU_ULTRA 3

// Sierpinski Tetra Garden — recursive 3D tetrahedra and a fractal-burst cursor
//
// True projected tetrahedral children form roaming Sierpinski structures. The
// matching cursor begins as one rotating tetrahedron, then sheds four smaller
// tetrahedra along its vertices while delayed wireframe echoes expand outward.
// Recursion, child quantity, object size, paths, colors, and response are tunable.

// =============================================================================
// BACKGROUND CONTROLS
// =============================================================================

#if GHOSTTY_GPU_PROFILE == CREATIVE_GPU_ECO
#define FT_NODE_GAIN 0.00
#define FC_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_BALANCED
#define FT_NODE_GAIN 0.20
#define FC_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == CREATIVE_GPU_QUALITY
#define FT_NODE_GAIN 0.32
#define FC_SPARK_COUNT 4
#else
#define FT_NODE_GAIN 0.42
#define FC_SPARK_COUNT 7
#endif

#define FT_OBJECT_COUNT 2                // quantity: 1..4
#define FT_RECURSION_DEPTH 2             // 1, 2, or 3
#define FT_CHILD_COUNT 16                // use 4, 16, or 64 with depth 1, 2, or 3
#define FT_ENABLE_VERTEX_LIGHTS 1
#define FT_ENABLE_CORE 1

const float FT_MASTER_BRIGHTNESS = 1.00;
const float FT_SIZE = 0.112;
const float FT_COMPANION_SCALE = 0.70;
const float FT_SIZE_VARIATION = 0.10;
const float FT_NARROW_REFERENCE_ASPECT = 1.20;
const float FT_NARROW_MIN_SCALE = 0.62;
const float FT_CAMERA_DISTANCE = 4.30;
const float FT_CULL_RADIUS = 2.30;
const float FT_CULL_FEATHER = 0.50;
const float FT_BREATHE_AMOUNT = 0.055;
const float FT_BREATHE_SPEED = 1.18;
const vec3 FT_ROTATION_BASE = vec3(0.54, -0.62, 0.10);
const vec3 FT_ROTATION_SPEED = vec3(0.15, 0.21, 0.12);
const vec3 FT_ROTATION_PHASE_STEP = vec3(0.86, 1.10, 0.64);

const vec2 FT_PATH_AMPLITUDE = vec2(0.40, 0.34);
const vec2 FT_PATH_FREQUENCY = vec2(0.73, 1.09);
const vec2 FT_PATH_PHASE = vec2(0.82, 1.46);
const float FT_PATH_SPEED = 0.100;
const float FT_COMPANION_PATH_SPEED_STEP = 0.023;

const float FT_EDGE_CORE_WIDTH = 0.0072;
const float FT_EDGE_GLOW_WIDTH = 0.030;
const float FT_EDGE_CORE_STRENGTH = 0.58;
const float FT_EDGE_GLOW_STRENGTH = 0.095;
const float FT_DEPTH_COLOR_STRENGTH = 0.76;
const float FT_VERTEX_RADIUS = 0.017;
const float FT_VERTEX_STRENGTH = 0.34;
const float FT_CORE_RADIUS = 0.72;
const float FT_CORE_STRENGTH = 0.060;
const float FT_CORE_DARKEN = 0.06;
const float FT_EXPOSURE = 1.24;
const float FT_ALPHA_MAX = 0.50;
const float FT_LIGHT_ALPHA_GAIN = 0.82;

const vec3 FT_VOID = vec3(0.010, 0.008, 0.042);
const vec3 FT_BLUE = vec3(0.090, 0.300, 1.000);
const vec3 FT_CYAN = vec3(0.100, 0.880, 1.000);
const vec3 FT_VIOLET = vec3(0.650, 0.240, 1.000);
const vec3 FT_ROSE = vec3(0.980, 0.190, 0.610);
const vec3 FT_GOLD = vec3(1.000, 0.720, 0.260);
const vec3 FT_WHITE = vec3(0.980, 0.970, 1.000);

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

vec3 tetraVertex(int index) {
    const float normalizer = 0.57735026919;
    if (index == 0) return vec3( 1.0,  1.0,  1.0) * normalizer;
    if (index == 1) return vec3(-1.0, -1.0,  1.0) * normalizer;
    if (index == 2) return vec3(-1.0,  1.0, -1.0) * normalizer;
    return vec3(1.0, -1.0, -1.0) * normalizer;
}

vec3 fractalChildCenter(int childIndex) {
    vec3 center = vec3(0.0);
    float offsetScale = 0.5;
    int code = childIndex;
    for (int depthIndex = 0; depthIndex < FT_RECURSION_DEPTH; depthIndex++) {
        int cornerIndex = code % 4;
        center += tetraVertex(cornerIndex) * offsetScale;
        code /= 4;
        offsetScale *= 0.5;
    }
    return center;
}

vec2 fractalUv(float timeValue, float identity) {
    return lissajousUv(
        timeValue,
        identity,
        FT_PATH_AMPLITUDE,
        FT_PATH_FREQUENCY,
        FT_PATH_SPEED + identity * FT_COMPANION_PATH_SPEED_STEP,
        FT_PATH_PHASE
    );
}

void renderFractalBackground(out vec4 fragColor, vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    // Wallpaper mode renders a complete procedural layer. Terminal
    // foreground coverage is applied only after the scene is complete.
    float backgroundMask = 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / FT_NARROW_REFERENCE_ASPECT,
        FT_NARROW_MIN_SCALE,
        1.0
    );
    vec3 composite = vec3(0.0);
    float sceneAlpha = 0.0;
    const int edgeA[6] = int[6](0, 0, 0, 1, 1, 2);
    const int edgeB[6] = int[6](1, 2, 3, 2, 3, 3);

    for (int objectIndex = 0; objectIndex < FT_OBJECT_COUNT; objectIndex++) {
        float identity = float(objectIndex);
        vec2 centerUv = fractalUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = objectIndex == 0 ? 1.0 : mix(
            1.0 - FT_SIZE_VARIATION,
            1.0 + FT_SIZE_VARIATION,
            hash12(vec2(identity, 21.4))
        );
        float sizeValue = FT_SIZE * narrowScale
            * pow(FT_COMPANION_SCALE, identity) * randomScale
            * (1.0 + FT_BREATHE_AMOUNT * sin(
                iTime * FT_BREATHE_SPEED + identity * 1.71
            ));
        float objectCullDistance = length(point - center) / max(sizeValue, 0.0001);
        if (objectCullDistance >= FT_CULL_RADIUS) continue;
        float objectCullFeather = 1.0 - smoothstep(
            FT_CULL_RADIUS - FT_CULL_FEATHER,
            FT_CULL_RADIUS,
            objectCullDistance
        );

        vec3 angle = FT_ROTATION_BASE
            + iTime * FT_ROTATION_SPEED
            + identity * FT_ROTATION_PHASE_STEP;
        vec3 radiance = vec3(0.0);
        float opacity = 0.0;
        float childScale = pow(0.5, float(FT_RECURSION_DEPTH));

        for (int childIndex = 0; childIndex < FT_CHILD_COUNT; childIndex++) {
            vec3 childCenter = fractalChildCenter(childIndex);
            vec2 projected[4];
            float depth[4];
            for (int vertexIndex = 0; vertexIndex < 4; vertexIndex++) {
                vec3 vertex = rotateXYZ(
                    childCenter + tetraVertex(vertexIndex) * childScale,
                    angle
                );
                projected[vertexIndex] = projectPoint(
                    vertex,
                    center,
                    sizeValue,
                    FT_CAMERA_DISTANCE,
                    depth[vertexIndex]
                );
            }
            float childPhase = float(childIndex) / max(float(FT_CHILD_COUNT - 1), 1.0);
            for (int edgeIndex = 0; edgeIndex < 6; edgeIndex++) {
                int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
                float edgeDistance = segmentDistance(point, projected[first], projected[second]);
                float core = exp(-edgeDistance / max(sizeValue * FT_EDGE_CORE_WIDTH, 0.00010));
                float glow = exp(-edgeDistance / max(sizeValue * FT_EDGE_GLOW_WIDTH, 0.00026));
                float nearFactor = saturate((FT_CAMERA_DISTANCE + 0.8 - 0.5 * (
                    depth[first] + depth[second]
                )) / 1.7);
                vec3 indexColor = mix(FT_VIOLET, FT_CYAN, fract(childPhase * 2.3));
                vec3 depthColor = mix(FT_BLUE, FT_ROSE, nearFactor);
                vec3 color = mix(indexColor, depthColor, FT_DEPTH_COLOR_STRENGTH);
                color = mix(color, FT_WHITE, nearFactor * 0.30);
                radiance += color * (
                    core * FT_EDGE_CORE_STRENGTH
                    + glow * FT_EDGE_GLOW_STRENGTH
                );
                opacity = max(opacity, max(core, glow * 0.32));
            }
#if FT_ENABLE_VERTEX_LIGHTS
            for (int vertexIndex = 0; vertexIndex < 4; vertexIndex++) {
                float node = gaussianPoint(point - projected[vertexIndex], sizeValue * FT_VERTEX_RADIUS);
                radiance += mix(FT_GOLD, FT_CYAN, float(vertexIndex) / 3.0)
                    * node * FT_VERTEX_STRENGTH * FT_NODE_GAIN;
                opacity = max(opacity, node * 0.42 * FT_NODE_GAIN);
            }
#endif
        }

#if FT_ENABLE_CORE
        float coreGlow = gaussianPoint(point - center, sizeValue * FT_CORE_RADIUS);
        composite = mix(
            composite,
            FT_VOID,
            coreGlow * FT_CORE_DARKEN * objectCullFeather * backgroundMask
        );
        radiance += mix(FT_VIOLET, FT_BLUE, 0.52) * coreGlow * FT_CORE_STRENGTH;
        opacity = max(opacity, coreGlow * 0.20);
#endif
        radiance *= objectCullFeather;
        opacity *= objectCullFeather;
        vec3 light = vec3(1.0) - exp(
            -max(radiance, vec3(0.0)) * FT_EXPOSURE * FT_MASTER_BRIGHTNESS
        );
        composite += light * backgroundMask;
        sceneAlpha = max(
            sceneAlpha,
            backgroundMask * FT_ALPHA_MAX
                * saturate(opacity + luminance(light) * FT_LIGHT_ALPHA_GAIN)
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
    renderFractalBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);
}
