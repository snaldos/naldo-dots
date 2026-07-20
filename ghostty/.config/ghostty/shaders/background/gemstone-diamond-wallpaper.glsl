// BACKGROUND-ONLY WALLPAPER VARIANT: gemstone-diamond
// Procedural geometry is composited behind exact terminal foreground.
// Pair this stage with any independently selected cursor shader.

// Gemstone Diamond — coordinated faceted background and cursor for Ghostty
//
// Floating solid gemstones share their palette with a movement-scaled faceted
// diamond cursor, delayed diamond echoes, and an optional resonance filament.
// Background and cursor quantities, dimensions, speeds, and lighting are all
// independently configurable below.

// Gemstone Drift — configurable floating faceted octahedra for Ghostty
// Solid depth-selected faces, transformed normals, luminous edges, tip glints,
// and independent full-screen paths create a small fleet of 3D gemstones.

// =============================================================================
// GPU PROFILE AND FEATURE QUANTITIES
// =============================================================================

#define GEM_GPU_ECO      0
#define GEM_GPU_BALANCED 1
#define GEM_GPU_QUALITY  2
#define GEM_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE GEM_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == GEM_GPU_ECO
#define GEM_PROFILE_EDGE_GAIN 0.70
#define GEM_PROFILE_SPECULAR_GAIN 0.64
#elif GHOSTTY_GPU_PROFILE == GEM_GPU_BALANCED
#define GEM_PROFILE_EDGE_GAIN 0.82
#define GEM_PROFILE_SPECULAR_GAIN 0.78
#elif GHOSTTY_GPU_PROFILE == GEM_GPU_QUALITY
#define GEM_PROFILE_EDGE_GAIN 0.95
#define GEM_PROFILE_SPECULAR_GAIN 0.90
#else
#define GEM_PROFILE_EDGE_GAIN 1.06
#define GEM_PROFILE_SPECULAR_GAIN 1.00
#endif

#define GEM_OBJECT_COUNT 3              // quantity: 1..6 recommended
#define GEM_ENABLE_HALO 1
#define GEM_ENABLE_GLINT 1
#define GEM_ENABLE_WAKE 1

// =============================================================================
// MASTER, SIZE, AND GEOMETRY
// =============================================================================

const float GEM_MASTER_BRIGHTNESS = 1.00;
const float GEM_EXPOSURE = 1.12;
const float GEM_ALPHA_MAX = 0.42;
const float GEM_SIZE = 0.086;            // screen-height fraction
const float GEM_COMPANION_SCALE = 0.86;
const float GEM_SIZE_VARIATION = 0.16;
const vec3 GEM_AXIS_SCALE = vec3(1.00, 1.28, 0.92);
const float GEM_CAMERA_DISTANCE = 4.10;
const float GEM_CAMERA_MIN_DEPTH = 0.40;
const float GEM_CULL_RADIUS = 2.65;
const float GEM_NARROW_REFERENCE_ASPECT = 0.95;
const float GEM_NARROW_MIN_SCALE = 0.60;
const float GEM_BREATHE_AMOUNT = 0.050;
const float GEM_BREATHE_SPEED = 0.29;

// =============================================================================
// FULL-SCREEN MOVEMENT
// =============================================================================

const vec2 GEM_PATH_CENTER = vec2(0.50, 0.50);
const vec2 GEM_PATH_AMPLITUDE = vec2(0.430, 0.405);
const float GEM_SCREEN_MARGIN = 0.050;
const float GEM_PATH_PRIMARY_WEIGHT = 0.76;
const float GEM_PATH_SECONDARY_WEIGHT = 0.24;
const float GEM_PATH_X_SPEED = 0.068;
const float GEM_PATH_Y_SPEED = 0.081;
const float GEM_PATH_X_SECONDARY_SPEED = 0.157;
const float GEM_PATH_Y_SECONDARY_SPEED = 0.139;
const float GEM_OBJECT_PATH_PHASE_STEP = 2.13;
const float GEM_OBJECT_PATH_SPEED_STEP = 0.072;
const float GEM_COMPANION_PATH_SCALE = 0.94;

// =============================================================================
// 3D ROTATION
// =============================================================================

const vec3 GEM_ROTATION_BASE = vec3(0.24, -0.38, 0.08);
const vec3 GEM_ROTATION_SPEED = vec3(0.24, -0.31, 0.13);
const vec3 GEM_ROTATION_WOBBLE = vec3(0.18, 0.22, 0.10);
const vec3 GEM_ROTATION_WOBBLE_SPEED = vec3(0.047, 0.059, 0.071);
const float GEM_OBJECT_ROTATION_PHASE_STEP = 1.51;
const float GEM_OBJECT_ROTATION_SPEED_STEP = 0.11;

// =============================================================================
// FACE LIGHTING AND EDGES
// =============================================================================

const vec3 GEM_LIGHT_DIRECTION = vec3(-0.62, 0.76, 1.20);
const float GEM_AMBIENT_LIGHT = 0.13;
const float GEM_DIFFUSE_LIGHT = 0.87;
const float GEM_FRESNEL_POWER = 1.75;
const float GEM_FRESNEL_MIX = 0.30;
const float GEM_SPECULAR_POWER = 34.0;
const float GEM_SPECULAR_STRENGTH = 0.82;
const float GEM_FACE_DARK_MULTIPLIER = 0.38;
const float GEM_FACE_LIGHT_MULTIPLIER = 1.10;
const float GEM_EDGE_INNER_WIDTH = 0.012;
const float GEM_EDGE_OUTER_WIDTH = 0.095;
const float GEM_EDGE_STRENGTH = 0.72;

// =============================================================================
// HALO, GLINT, AND WAKE
// =============================================================================

const float GEM_HALO_RADIUS = 1.75;
const float GEM_HALO_STRENGTH = 0.028;
const float GEM_GLINT_RATE = 0.23;
const float GEM_GLINT_RADIUS = 0.090;
const float GEM_GLINT_STRENGTH = 0.38;
const float GEM_GLINT_FLARE_LENGTH = 5.20;
const float GEM_GLINT_FLARE_WIDTH = 0.18;
const float GEM_WAKE_SECONDS = 0.90;
const float GEM_WAKE_WIDTH = 0.080;
const float GEM_WAKE_STRENGTH = 0.024;

// =============================================================================
// COMPOSITING AND PALETTE
// =============================================================================

const float GEM_BODY_BLEND = 0.54;
const float GEM_BODY_OPACITY_BASE = 0.30;
const float GEM_BODY_OPACITY_FRESNEL = 0.18;
const float GEM_LIGHT_ALPHA_GAIN = 0.50;
const float GEM_BACKGROUND_TOLERANCE_LOW = 0.030;
const float GEM_BACKGROUND_TOLERANCE_HIGH = 0.245;
const float GEM_TEXT_PROTECTION = 0.48;
const vec3 GEM_VOID    = vec3(0.010, 0.018, 0.070);
const vec3 GEM_BLUE    = vec3(0.070, 0.300, 0.960);
const vec3 GEM_CYAN    = vec3(0.130, 0.880, 1.000);
const vec3 GEM_TEAL    = vec3(0.120, 0.820, 0.680);
const vec3 GEM_VIOLET  = vec3(0.620, 0.240, 1.000);
const vec3 GEM_ROSE    = vec3(0.980, 0.210, 0.650);
const vec3 GEM_GOLD    = vec3(1.000, 0.700, 0.270);
const vec3 GEM_WHITE   = vec3(0.940, 0.950, 1.000);

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

float cross2d(vec2 first, vec2 second) {
    return first.x * second.y - first.y * second.x;
}

vec3 barycentricCoordinates(vec2 point, vec2 first, vec2 second, vec2 third) {
    float denominator = cross2d(second - first, third - first);
    float safeDenominator = abs(denominator) < 0.000001
        ? (denominator < 0.0 ? -0.000001 : 0.000001)
        : denominator;
    float firstWeight = cross2d(second - point, third - point) / safeDenominator;
    float secondWeight = cross2d(third - point, first - point) / safeDenominator;
    return vec3(firstWeight, secondWeight, 1.0 - firstWeight - secondWeight);
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
        GEM_BACKGROUND_TOLERANCE_LOW,
        GEM_BACKGROUND_TOLERANCE_HIGH,
        difference
    );
    float darkFallback = 1.0 - smoothstep(0.12, 0.58, luminance(terminalColor.rgb));
    float transparent = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(colorMatch, darkFallback * transparent * GEM_TEXT_PROTECTION));
}

vec3 gemPalette(float selector) {
    selector = fract(selector);
    if (selector < 0.20) return mix(GEM_BLUE, GEM_CYAN, selector / 0.20);
    if (selector < 0.40) return mix(GEM_CYAN, GEM_TEAL, (selector - 0.20) / 0.20);
    if (selector < 0.65) return mix(GEM_TEAL, GEM_VIOLET, (selector - 0.40) / 0.25);
    if (selector < 0.85) return mix(GEM_VIOLET, GEM_ROSE, (selector - 0.65) / 0.20);
    return mix(GEM_ROSE, GEM_GOLD, (selector - 0.85) / 0.15);
}

vec2 gemUv(float timeValue, float identity) {
    float speedScale = 1.0 + identity * GEM_OBJECT_PATH_SPEED_STEP;
    float phase = identity * GEM_OBJECT_PATH_PHASE_STEP;
    float x = GEM_PATH_PRIMARY_WEIGHT
            * sin(timeValue * GEM_PATH_X_SPEED * speedScale + 0.52 + phase)
        + GEM_PATH_SECONDARY_WEIGHT
            * sin(timeValue * GEM_PATH_X_SECONDARY_SPEED / speedScale + 2.75 - phase);
    float y = GEM_PATH_PRIMARY_WEIGHT
            * sin(timeValue * GEM_PATH_Y_SPEED * speedScale + 2.10 - phase * 0.58)
        + GEM_PATH_SECONDARY_WEIGHT
            * sin(timeValue * GEM_PATH_Y_SECONDARY_SPEED / speedScale + 5.20 + phase);
    float pathScale = identity < 0.5 ? 1.0 : pow(GEM_COMPANION_PATH_SCALE, identity);
    return clamp(
        GEM_PATH_CENTER + GEM_PATH_AMPLITUDE * pathScale * vec2(x, y),
        vec2(GEM_SCREEN_MARGIN),
        vec2(1.0 - GEM_SCREEN_MARGIN)
    );
}

struct GemSample {
    vec3 bodyColor;
    vec3 radiance;
    float coverage;
    float opacity;
};

GemSample renderGem(vec2 point, vec2 center, float size, float identity) {
    vec3 localVertex[6];
    localVertex[0] = vec3( 1.0, 0.0, 0.0) * GEM_AXIS_SCALE;
    localVertex[1] = vec3(-1.0, 0.0, 0.0) * GEM_AXIS_SCALE;
    localVertex[2] = vec3(0.0,  1.0, 0.0) * GEM_AXIS_SCALE;
    localVertex[3] = vec3(0.0, -1.0, 0.0) * GEM_AXIS_SCALE;
    localVertex[4] = vec3(0.0, 0.0,  1.0) * GEM_AXIS_SCALE;
    localVertex[5] = vec3(0.0, 0.0, -1.0) * GEM_AXIS_SCALE;

    vec3 transformed[6];
    vec2 projected[6];
    float depth[6];
    float phase = identity * GEM_OBJECT_ROTATION_PHASE_STEP;
    float speedScale = 1.0 + identity * GEM_OBJECT_ROTATION_SPEED_STEP;
    vec3 angle = GEM_ROTATION_BASE
        + iTime * GEM_ROTATION_SPEED * speedScale
        + GEM_ROTATION_WOBBLE * sin(
            iTime * GEM_ROTATION_WOBBLE_SPEED + vec3(phase, phase + 1.4, phase + 2.8)
        );

    for (int vertexIndex = 0; vertexIndex < 6; vertexIndex++) {
        vec3 vertex = rotateZ(
            rotateX(rotateY(localVertex[vertexIndex], angle.y), angle.x),
            angle.z
        );
        transformed[vertexIndex] = vertex;
        depth[vertexIndex] = GEM_CAMERA_DISTANCE - vertex.z;
        projected[vertexIndex] = center
            + vertex.xy * size * GEM_CAMERA_DISTANCE
                / max(depth[vertexIndex], GEM_CAMERA_MIN_DEPTH);
    }

    const int faceA[8] = int[8](0,2,1,3, 2,1,3,0);
    const int faceB[8] = int[8](2,1,3,0, 0,2,1,3);
    const int faceC[8] = int[8](4,4,4,4, 5,5,5,5);
    float nearestDepth = 1000.0;
    vec3 selectedColor = vec3(0.0);
    float selectedCoverage = 0.0;
    float selectedEdge = 0.0;
    float selectedFresnel = 0.0;
    float selectedSpecular = 0.0;
    vec3 lightDirection = normalize(GEM_LIGHT_DIRECTION);
    vec3 viewDirection = vec3(0.0, 0.0, 1.0);

    for (int faceIndex = 0; faceIndex < 8; faceIndex++) {
        int first = faceA[faceIndex], second = faceB[faceIndex], third = faceC[faceIndex];
        vec3 barycentric = barycentricCoordinates(
            point, projected[first], projected[second], projected[third]
        );
        float minimumWeight = min(barycentric.x, min(barycentric.y, barycentric.z));
        float aa = clamp(fwidth(minimumWeight), 0.0014, 0.040);
        float coverage = smoothstep(-aa, aa, minimumWeight);
        float faceDepth = dot(barycentric, vec3(depth[first], depth[second], depth[third]));
        if (minimumWeight > -aa * 1.6 && faceDepth < nearestDepth) {
            nearestDepth = faceDepth;
            vec3 normal = normalize(cross(
                transformed[second] - transformed[first],
                transformed[third] - transformed[first]
            ));
            if (normal.z < 0.0) normal = -normal;
            float diffuse = GEM_AMBIENT_LIGHT
                + GEM_DIFFUSE_LIGHT * max(dot(normal, lightDirection), 0.0);
            float fresnel = pow(1.0 - abs(dot(normal, viewDirection)), GEM_FRESNEL_POWER);
            float specular = pow(
                max(dot(reflect(-lightDirection, normal), viewDirection), 0.0),
                GEM_SPECULAR_POWER
            );
            float edge = (1.0 - smoothstep(
                GEM_EDGE_INNER_WIDTH,
                GEM_EDGE_OUTER_WIDTH + aa,
                minimumWeight
            )) * coverage;
            vec3 baseColor = gemPalette(identity * 0.271 + float(faceIndex) * 0.109);
            vec3 alternate = gemPalette(identity * 0.271 + 0.38 + normal.x * 0.08);
            selectedColor = mix(baseColor, alternate, diffuse * 0.52 + fresnel * GEM_FRESNEL_MIX);
            selectedColor *= mix(GEM_FACE_DARK_MULTIPLIER, GEM_FACE_LIGHT_MULTIPLIER, diffuse);
            selectedCoverage = coverage;
            selectedEdge = edge;
            selectedFresnel = fresnel;
            selectedSpecular = specular;
        }
    }

    vec3 radiance = mix(GEM_CYAN, GEM_WHITE, selectedFresnel)
        * selectedEdge * GEM_EDGE_STRENGTH * GEM_PROFILE_EDGE_GAIN;
    radiance += GEM_WHITE * selectedSpecular * selectedCoverage
        * GEM_SPECULAR_STRENGTH * GEM_PROFILE_SPECULAR_GAIN;

    float halo = 0.0;
#if GEM_ENABLE_HALO
    halo = gaussianPoint(point - center, size * GEM_HALO_RADIUS);
    radiance += gemPalette(identity * 0.271) * halo * GEM_HALO_STRENGTH;
#endif

    float glint = 0.0;
#if GEM_ENABLE_GLINT
    int glintVertex = int(mod(floor(iTime * GEM_GLINT_RATE + identity * 1.7), 6.0));
    vec2 glintDelta = point - projected[glintVertex];
    float glintRadius = max(size * GEM_GLINT_RADIUS, 0.0012);
    glint = gaussianPoint(glintDelta, glintRadius);
    float flareX = exp(-abs(glintDelta.y) / max(glintRadius * GEM_GLINT_FLARE_WIDTH, 0.0003))
        * exp(-abs(glintDelta.x) / max(glintRadius * GEM_GLINT_FLARE_LENGTH, 0.001));
    float flareY = exp(-abs(glintDelta.x) / max(glintRadius * GEM_GLINT_FLARE_WIDTH, 0.0003))
        * exp(-abs(glintDelta.y) / max(glintRadius * GEM_GLINT_FLARE_LENGTH, 0.001));
    radiance += GEM_WHITE * (glint + 0.24 * (flareX + flareY)) * GEM_GLINT_STRENGTH;
#endif

    float opacity = selectedCoverage * (
        GEM_BODY_OPACITY_BASE + selectedFresnel * GEM_BODY_OPACITY_FRESNEL
    );
    opacity = max(opacity, selectedEdge * 0.25 + halo * 0.025 + glint * 0.12);
    return GemSample(selectedColor, radiance, selectedCoverage, saturate(opacity));
}

void renderGemstoneBackground(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    // Wallpaper mode renders a complete procedural layer. Terminal
    // foreground coverage is applied only after the scene is complete.
    float backgroundMask = 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 point = (fragCoord - 0.5 * resolution) / resolution.y;
    float narrowScale = clamp(aspect / GEM_NARROW_REFERENCE_ASPECT, GEM_NARROW_MIN_SCALE, 1.0);

    vec3 composite = vec3(0.0);
    float sceneAlpha = 0.0;

    for (int objectIndex = 0; objectIndex < GEM_OBJECT_COUNT; objectIndex++) {
        float identity = float(objectIndex);
        vec2 centerUv = gemUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = objectIndex == 0
            ? 1.0
            : mix(1.0 - GEM_SIZE_VARIATION, 1.0 + GEM_SIZE_VARIATION, hash12(vec2(identity, 6.37)));
        float size = GEM_SIZE * narrowScale
            * pow(GEM_COMPANION_SCALE, identity) * randomScale
            * (1.0 + GEM_BREATHE_AMOUNT * sin(iTime * GEM_BREATHE_SPEED + identity * 1.9));

#if GEM_ENABLE_WAKE
        vec2 previousUv = gemUv(iTime - GEM_WAKE_SECONDS, identity);
        vec2 previousCenter = (previousUv - 0.5) * vec2(aspect, 1.0);
        float wakeDistance = segmentDistance(point, previousCenter, center);
        float wakeAlong = segmentParameter(point, previousCenter, center);
        float wake = exp(-wakeDistance / max(size * GEM_WAKE_WIDTH, 0.0005))
            * smoothstep(0.0, 0.82, wakeAlong);
        composite += gemPalette(identity * 0.271) * wake * GEM_WAKE_STRENGTH * backgroundMask;
        sceneAlpha = max(sceneAlpha, wake * GEM_ALPHA_MAX * 0.06 * backgroundMask);
#endif

        if (
            abs(point.x - center.x) < size * GEM_CULL_RADIUS
            && abs(point.y - center.y) < size * GEM_CULL_RADIUS
        ) {
            GemSample sampleValue = renderGem(point, center, size, identity);
            vec3 light = vec3(1.0) - exp(
                -max(sampleValue.radiance, vec3(0.0))
                    * GEM_EXPOSURE * GEM_MASTER_BRIGHTNESS
            );
            vec3 bodyTarget = mix(GEM_VOID, sampleValue.bodyColor, 0.88);
            composite = mix(
                composite,
                bodyTarget,
                sampleValue.coverage * GEM_BODY_BLEND * backgroundMask
            );
            composite += light * backgroundMask;
            sceneAlpha = max(
                sceneAlpha,
                backgroundMask * GEM_ALPHA_MAX * saturate(
                    sampleValue.opacity + luminance(light) * GEM_LIGHT_ALPHA_GAIN
                )
            );
        }
    }

    fragColor = vec4(
        clamp(composite, 0.0, 1.0),
        sceneAlpha
    );
}

// =============================================================================

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
    renderGemstoneBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);
}
