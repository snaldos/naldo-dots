// WALLPAPER VARIANT: gemstone-diamond
// Procedural geometry is the rear layer; terminal text is composited
// above it, and the matching movement-reactive cursor is topmost.

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
// MATCHED FACETED DIAMOND CURSOR — QUANTITY, SIZE, SPEED, AND RESPONSE
// =============================================================================

#if GHOSTTY_GPU_PROFILE == GEM_GPU_ECO
#define GD_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == GEM_GPU_BALANCED
#define GD_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == GEM_GPU_QUALITY
#define GD_SPARK_COUNT 4
#else
#define GD_SPARK_COUNT 7
#endif

#define GD_ECHO_COUNT 2                  // quantity: 0..4
#define GD_ENABLE_TRAIL 1
#define GD_ENABLE_SPARKS 1
#define GD_ENABLE_RESONANCE_LINK 1    // 0 removes every cursor-object connection
#define GD_LINK_ALL_OBJECTS 1         // 1: every object; 0: primary object only
#define GD_ENABLE_FACET_FILL 1

const float GD_EFFECT_DURATION = 0.34;
const float GD_FADE_POWER = 1.75;
const float GD_MIN_MOVEMENT_CELLS = 0.025;
const float GD_GROWTH_START_CELLS = 0.08;
const float GD_GROWTH_FULL_CELLS = 8.00;
const float GD_MOVEMENT_RESPONSE_POWER = 1.00;
const float GD_CONTENT_PROTECTION = 0.18;
const float GD_CULL_RADIUS_MIN = 3.50;
const float GD_CULL_RADIUS_MAX = 6.80;
const float GD_MASTER_BRIGHTNESS = 1.00;

const float GD_SIZE_MIN = 1.00;
const float GD_SIZE_MAX = 2.18;
const float GD_SIZE_PULSE = 0.12;
const vec3 GD_AXIS_SCALE = vec3(1.00, 1.18, 0.92);
const float GD_CAMERA_DISTANCE = 3.90;
const vec3 GD_ROTATION_BASE = vec3(0.42, -0.58, 0.00);
const vec3 GD_ROTATION_SPEED = vec3(0.72, 0.93, 0.20);
const float GD_DIRECTION_TILT = 0.22;

const float GD_FACE_OPACITY = 0.22;
const float GD_FACE_AMBIENT = 0.24;
const float GD_FACE_DIFFUSE = 0.76;
const vec3 GD_LIGHT_DIRECTION = vec3(-0.62, 0.76, 1.20);
const float GD_EDGE_CORE_WIDTH = 0.042;
const float GD_EDGE_GLOW_WIDTH = 0.170;
const float GD_EDGE_CORE_STRENGTH = 0.52;
const float GD_EDGE_GLOW_STRENGTH = 0.080;
const float GD_NEAR_DEPTH_CENTER = 4.80;
const float GD_NEAR_DEPTH_RANGE = 1.90;
const float GD_NEAR_WHITE_MIX = 0.38;

const float GD_ECHO_START_SCALE = 1.04;
const float GD_ECHO_END_SCALE = 2.28;
const float GD_ECHO_DELAY = 0.14;
const float GD_ECHO_WIDTH = 0.050;
const float GD_ECHO_STRENGTH = 0.18;
const float GD_ECHO_FALLOFF = 0.70;
const float GD_ECHO_FADE_POWER = 1.00;

const float GD_TRAIL_WIDTH_MIN = 0.11;
const float GD_TRAIL_WIDTH_MAX = 0.24;
const float GD_TRAIL_GLOW_MULTIPLIER = 4.00;
const float GD_TRAIL_GLOW_STRENGTH = 0.055;
const float GD_TRAIL_CORE_STRENGTH = 0.24;
const float GD_TRAIL_TAIL_FADE = 0.20;
const float GD_SPARK_RADIUS = 0.075;
const float GD_SPARK_SPREAD = 1.60;
const float GD_SPARK_STRENGTH = 0.25;

const float GD_LINK_WIDTH = 0.060;
const float GD_LINK_GLOW_WIDTH = 0.24;
const float GD_LINK_CORE_STRENGTH = 0.050;
const float GD_LINK_GLOW_STRENGTH = 0.012;
const float GD_LINK_DASH_COUNT = 16.0;
const float GD_LINK_DASH_SPEED = 1.65;
const float GD_LINK_SECONDARY_FALLOFF = 0.72;
const float GD_LINK_COLOR_PHASE_STEP = 0.23;
const float GD_LINK_ENDPOINT_GLOW = 0.090;

const vec3 GD_DEEP = vec3(0.060, 0.030, 0.220);
const vec3 GD_BLUE = vec3(0.150, 0.340, 1.000);
const vec3 GD_CYAN = vec3(0.150, 0.880, 1.000);
const vec3 GD_VIOLET = vec3(0.680, 0.260, 1.000);
const vec3 GD_ROSE = vec3(0.980, 0.220, 0.650);
const vec3 GD_WHITE = vec3(0.980, 0.960, 1.000);
const float GD_PI = 3.14159265359;

vec2 gdCursorCenterPixels(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}

vec2 gdScenePoint(vec2 pixelPoint) {
    return (pixelPoint - 0.5 * iResolution.xy) / max(iResolution.y, 1.0);
}

float gdInsideCursor(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(cursorRectangle.x, cursorRectangle.y - cursorRectangle.w);
    vec2 maximumPoint = vec2(cursorRectangle.x + cursorRectangle.z, cursorRectangle.y);
    return step(minimumPoint.x, point.x) * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x) * step(point.y, maximumPoint.y);
}

void applyGemstoneDiamondCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = gdCursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = gdCursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / GD_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * GD_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = pow(
        smoothstep(
            cursorPixels * GD_GROWTH_START_CELLS,
            cursorPixels * GD_GROWTH_FULL_CELLS,
            movedPixels
        ),
        GD_MOVEMENT_RESPONSE_POWER
    );
    float cullRadius = cursorPixels * mix(
        GD_CULL_RADIUS_MIN,
        GD_CULL_RADIUS_MAX,
        movementFactor
    );
    bool nearCursor = all(greaterThanEqual(
        fragCoord,
        min(headPixels, tailPixels) - vec2(cullRadius)
    )) && all(lessThanEqual(
        fragCoord,
        max(headPixels, tailPixels) + vec2(cullRadius)
    ));
    float linkCull = max(cursorPixels * 1.5, 8.0);
    bool nearAnyLink = false;
#if GD_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < GEM_OBJECT_COUNT; linkIndex++) {
        if (GD_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = gemUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        nearAnyLink = nearAnyLink || linkPixelDistance <= linkCull;
    }
#endif
    if (!nearCursor && !nearAnyLink) return;

    vec2 point = gdScenePoint(fragCoord);
    vec2 head = gdScenePoint(headPixels);
    vec2 tail = gdScenePoint(tailPixels);
    vec2 movement = head - tail;
    vec2 direction = movement / max(length(movement), 0.000001);
    vec2 normal2d = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - age, GD_FADE_POWER);
    float contentMask = mix(GD_CONTENT_PROTECTION, 1.0, backgroundCellMask(terminalColor));

#if GD_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < GEM_OBJECT_COUNT; linkIndex++) {
        if (GD_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = gemUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        if (linkPixelDistance > linkCull) continue;

        vec2 linkObject = gdScenePoint(linkObjectPixels);
        float linkDistance = segmentDistance(point, head, linkObject);
        float linkAlong = segmentParameter(point, head, linkObject);
        float linkStrength = pow(GD_LINK_SECONDARY_FALLOFF, linkIdentity);
        float linkColorMix = saturate(
            linkAlong * 0.78 + linkIdentity * GD_LINK_COLOR_PHASE_STEP
        );
        float dash = 0.62 + 0.38 * sin(
            linkAlong * GD_LINK_DASH_COUNT
            - iTime * GD_LINK_DASH_SPEED
            + linkIdentity * 2.17
        );
        float linkCore = exp(
            -linkDistance / max(cursorSize * GD_LINK_WIDTH, 0.0002)
        );
        float linkGlow = exp(
            -linkDistance / max(cursorSize * GD_LINK_GLOW_WIDTH, 0.0005)
        );
        vec3 linkColor = mix(GD_ROSE, GD_CYAN, linkColorMix);
        scene.rgb += linkColor * dash * linkStrength * life * contentMask * (
            linkCore * GD_LINK_CORE_STRENGTH
            + linkGlow * GD_LINK_GLOW_STRENGTH
        );
        float endpoint = gaussianPoint(
            point - linkObject,
            cursorSize * 0.72
        );
        vec3 endpointColor = mix(
            GD_ROSE,
            GD_CYAN,
            saturate(0.78 + linkIdentity * GD_LINK_COLOR_PHASE_STEP)
        );
        scene.rgb += endpointColor * endpoint * linkStrength * life
            * GD_LINK_ENDPOINT_GLOW * contentMask;
    }
#endif

    if (nearCursor) {
#if GD_ENABLE_TRAIL
        float trailDistance = segmentDistance(point, tail, head);
        float along = segmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            GD_TRAIL_WIDTH_MIN,
            GD_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, GD_TRAIL_TAIL_FADE, along) * life;
        float trailGlow = exp(
            -trailDistance / max(trailWidth * GD_TRAIL_GLOW_MULTIPLIER, 0.0004)
        ) * smoothstep(0.0, GD_TRAIL_TAIL_FADE * 0.84, along) * life;
        vec3 trailColor = mix(GD_VIOLET, GD_CYAN, along);
        trailColor = mix(trailColor, GD_ROSE, smoothstep(0.78, 1.0, along) * 0.42);
        scene.rgb += trailColor * trailGlow * GD_TRAIL_GLOW_STRENGTH * contentMask;
        scene.rgb += trailColor * trailCore * GD_TRAIL_CORE_STRENGTH * contentMask;
#endif

        vec3 localVertex[6];
        localVertex[0] = vec3( 1.0, 0.0, 0.0) * GD_AXIS_SCALE;
        localVertex[1] = vec3(-1.0, 0.0, 0.0) * GD_AXIS_SCALE;
        localVertex[2] = vec3(0.0,  1.0, 0.0) * GD_AXIS_SCALE;
        localVertex[3] = vec3(0.0, -1.0, 0.0) * GD_AXIS_SCALE;
        localVertex[4] = vec3(0.0, 0.0,  1.0) * GD_AXIS_SCALE;
        localVertex[5] = vec3(0.0, 0.0, -1.0) * GD_AXIS_SCALE;
        vec3 transformed[6];
        vec2 projected[6];
        float depth[6];
        float diamondSize = cursorSize * mix(GD_SIZE_MIN, GD_SIZE_MAX, movementFactor)
            * (1.0 + GD_SIZE_PULSE * sin(age * GD_PI));
        vec3 angle = GD_ROTATION_BASE + iTime * GD_ROTATION_SPEED;
        angle.z += atan(direction.y, direction.x) * GD_DIRECTION_TILT;
        for (int vertexIndex = 0; vertexIndex < 6; vertexIndex++) {
            vec3 vertex = rotateZ(
                rotateY(rotateX(localVertex[vertexIndex], angle.x), angle.y),
                angle.z
            );
            transformed[vertexIndex] = vertex;
            depth[vertexIndex] = GD_CAMERA_DISTANCE - vertex.z;
            projected[vertexIndex] = head
                + vertex.xy * diamondSize * GD_CAMERA_DISTANCE / depth[vertexIndex];
        }

        const int faceA[8] = int[8](0,2,1,3, 2,1,3,0);
        const int faceB[8] = int[8](2,1,3,0, 0,2,1,3);
        const int faceC[8] = int[8](4,4,4,4, 5,5,5,5);
#if GD_ENABLE_FACET_FILL
        float nearestDepth = 1000.0;
        float selectedCoverage = 0.0;
        vec3 selectedColor = vec3(0.0);
        vec3 lightDirection = normalize(GD_LIGHT_DIRECTION);
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
                vec3 faceNormal = normalize(cross(
                    transformed[second] - transformed[first],
                    transformed[third] - transformed[first]
                ));
                if (faceNormal.z < 0.0) faceNormal = -faceNormal;
                float diffuse = GD_FACE_AMBIENT
                    + GD_FACE_DIFFUSE * max(dot(faceNormal, lightDirection), 0.0);
                selectedColor = mix(GD_DEEP, mix(GD_BLUE, GD_ROSE, float(faceIndex) / 7.0), diffuse);
                selectedCoverage = coverage;
            }
        }
        scene.rgb = mix(
            scene.rgb,
            selectedColor,
            selectedCoverage * GD_FACE_OPACITY * life * contentMask
        );
#endif

        const int edgeA[12] = int[12](0,0,0,0, 1,1,1,1, 2,2,3,3);
        const int edgeB[12] = int[12](2,3,4,5, 2,3,4,5, 4,5,4,5);
        vec3 diamondLight = vec3(0.0);
        for (int edgeIndex = 0; edgeIndex < 12; edgeIndex++) {
            int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
            float nearFactor = saturate(
                (GD_NEAR_DEPTH_CENTER - 0.5 * (depth[first] + depth[second]))
                    / GD_NEAR_DEPTH_RANGE
            );
            float edgeDistance = segmentDistance(point, projected[first], projected[second]);
            float core = exp(-edgeDistance / max(cursorSize * GD_EDGE_CORE_WIDTH, 0.0001));
            float glow = exp(-edgeDistance / max(cursorSize * GD_EDGE_GLOW_WIDTH, 0.00025));
            vec3 edgeColor = mix(GD_VIOLET, GD_CYAN, nearFactor);
            edgeColor = mix(edgeColor, GD_WHITE, nearFactor * GD_NEAR_WHITE_MIX);
            diamondLight += edgeColor * (
                core * GD_EDGE_CORE_STRENGTH + glow * GD_EDGE_GLOW_STRENGTH
            );
            for (int echoIndex = 0; echoIndex < GD_ECHO_COUNT; echoIndex++) {
                float delay = float(echoIndex) * GD_ECHO_DELAY;
                float progress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
                float echoActive = step(delay, easedAge);
                float scaleValue = mix(GD_ECHO_START_SCALE, GD_ECHO_END_SCALE, progress);
                vec2 echoFirst = head + (projected[first] - head) * scaleValue;
                vec2 echoSecond = head + (projected[second] - head) * scaleValue;
                float echoDistance = segmentDistance(point, echoFirst, echoSecond);
                float echo = exp(-echoDistance / max(cursorSize * GD_ECHO_WIDTH, 0.00012))
                    * pow(1.0 - progress, GD_ECHO_FADE_POWER) * echoActive;
                diamondLight += mix(GD_BLUE, GD_VIOLET, nearFactor) * echo
                    * GD_ECHO_STRENGTH * pow(GD_ECHO_FALLOFF, float(echoIndex));
            }
        }
        scene.rgb += diamondLight * life * contentMask * GD_MASTER_BRIGHTNESS;

#if GD_ENABLE_SPARKS && GD_SPARK_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int sparkIndex = 0; sparkIndex < GD_SPARK_COUNT; sparkIndex++) {
            float index = float(sparkIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 sparkCenter = mix(tail, head, positionRandom)
                + normal2d * (sideRandom - 0.5) * cursorSize * GD_SPARK_SPREAD;
            float spark = gaussianPoint(point - sparkCenter, cursorSize * GD_SPARK_RADIUS) * life;
            scene.rgb += mix(GD_CYAN, GD_ROSE, sideRandom)
                * spark * GD_SPARK_STRENGTH * contentMask;
        }
#endif
    }

    float cursorCoverage = gdInsideCursor(fragCoord, iCurrentCursor);
    scene = mix(scene, terminalColor, cursorCoverage);
    scene.rgb = clamp(scene.rgb, 0.0, 1.0);
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
    renderGemstoneBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);

    // The matching movement effect is applied after the terminal foreground,
    // while the real Ghostty cursor rectangle remains exact inside its bounds.
    applyGemstoneDiamondCursor(fragColor, fragCoord);
    fragColor.a = terminalColor.a;
}
