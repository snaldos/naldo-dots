// WALLPAPER VARIANT: crystal-resonance
// Procedural geometry is the rear layer; terminal text is composited
// above it, and the matching movement-reactive cursor is topmost.

// Crystal Resonance — coordinated stellated crystal background and cursor
//
// The roaming faceted crystal shares blue-violet light with a movement-scaled
// 14-vertex cursor crystal, stretched tips, delayed stellated echoes, and an
// optional resonance filament. Object, echo, spark, size, and speed controls
// are independently exposed below.

// Crystal Pet — configurable roaming blue/violet stellated crystals for Ghostty
//
// Background-only shader based on a 14-vertex, 24-face polyhedron. The control
// panel below intentionally keeps appearance, quantity, size, path, rotation,
// lighting, and compositing independent. Start with one parameter at a time.

// =============================================================================
// GPU PROFILE AND FEATURE SWITCHES
// =============================================================================

#define PET_GPU_ECO      0
#define PET_GPU_BALANCED 1
#define PET_GPU_QUALITY  2
#define PET_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE PET_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == PET_GPU_ECO
#define PET_PROFILE_EDGE_GAIN 0.70
#define PET_PROFILE_SPECULAR_GAIN 0.68
#elif GHOSTTY_GPU_PROFILE == PET_GPU_BALANCED
#define PET_PROFILE_EDGE_GAIN 0.82
#define PET_PROFILE_SPECULAR_GAIN 0.78
#elif GHOSTTY_GPU_PROFILE == PET_GPU_QUALITY
#define PET_PROFILE_EDGE_GAIN 0.94
#define PET_PROFILE_SPECULAR_GAIN 0.90
#else
#define PET_PROFILE_EDGE_GAIN 1.04
#define PET_PROFILE_SPECULAR_GAIN 1.00
#endif

#define PET_OBJECT_COUNT 1       // quantity: 1..4 recommended
#define PET_ENABLE_HALO 1        // 0 removes the soft aura
#define PET_ENABLE_GLINT 1       // 0 removes the travelling tip flare

// =============================================================================
// MASTER, SIZE, AND GEOMETRY
// =============================================================================

const float PET_MASTER_BRIGHTNESS = 1.00;
const float PET_EXPOSURE = 1.12;
const float PET_ALPHA_MAX = 0.46;
const float PET_SIZE = 0.125;                  // fraction of screen height
const float PET_COMPANION_SCALE = 0.80;        // each additional pet / previous
const float PET_COMPANION_SIZE_VARIATION = 0.10;
const float PET_BASE_HALF_EXTENT = 0.46;
const float PET_TIP_LENGTH = 3.00;              // steeple length / cube half-size
const float PET_CAMERA_DISTANCE = 4.25;
const float PET_CAMERA_MIN_DEPTH = 0.35;
const float PET_CULL_RADIUS = 4.20;             // multiples of final pet size
const float PET_NARROW_REFERENCE_ASPECT = 0.95;
const float PET_NARROW_MIN_SCALE = 0.58;
const float PET_BREATHE_AMOUNT = 0.045;
const float PET_BREATHE_SPEED = 0.31;
const float PET_BREATHE_PHASE_STEP = 1.70;

// =============================================================================
// FULL-SCREEN MOVEMENT
// =============================================================================

const vec2 PET_PATH_CENTER = vec2(0.50, 0.50);
const vec2 PET_PATH_AMPLITUDE = vec2(0.445, 0.425);
const float PET_SCREEN_MARGIN = 0.045;
const float PET_PATH_X_PRIMARY_WEIGHT = 0.82;
const float PET_PATH_X_SECONDARY_WEIGHT = 0.18;
const float PET_PATH_Y_PRIMARY_WEIGHT = 0.80;
const float PET_PATH_Y_SECONDARY_WEIGHT = 0.20;
const float PET_PATH_X_PRIMARY_SPEED = 0.071;
const float PET_PATH_X_SECONDARY_SPEED = 0.173;
const float PET_PATH_Y_PRIMARY_SPEED = 0.083;
const float PET_PATH_Y_SECONDARY_SPEED = 0.137;
const float PET_PATH_X_PRIMARY_PHASE = 0.35;
const float PET_PATH_X_SECONDARY_PHASE = 2.10;
const float PET_PATH_Y_PRIMARY_PHASE = 2.30;
const float PET_PATH_Y_SECONDARY_PHASE = 5.10;
const float PET_OBJECT_PATH_PHASE_STEP = 2.37;
const float PET_OBJECT_PATH_SPEED_STEP = 0.055;
const float PET_COMPANION_PATH_SCALE = 0.92;

// =============================================================================
// 3D ROTATION
// =============================================================================

const float PET_ROTATION_X_SPEED = 0.115;
const float PET_ROTATION_Y_SPEED = -0.092;
const float PET_ROTATION_Z_SPEED = 0.052;
const float PET_ROTATION_X_WOBBLE = 0.48;
const float PET_ROTATION_Y_WOBBLE = 0.42;
const float PET_ROTATION_Z_WOBBLE = 0.18;
const float PET_ROTATION_X_WOBBLE_SPEED = 0.031;
const float PET_ROTATION_Y_WOBBLE_SPEED = 0.043;
const float PET_ROTATION_Z_WOBBLE_SPEED = 0.057;
const float PET_OBJECT_ROTATION_PHASE_STEP = 1.43;
const float PET_OBJECT_ROTATION_SPEED_STEP = 0.08;

// =============================================================================
// FACE LIGHTING, EDGES, HALO, AND GLINT
// =============================================================================

const vec3 PET_LIGHT_DIRECTION = vec3(-0.58, 0.72, 1.30);
const float PET_AMBIENT_LIGHT = 0.16;
const float PET_DIFFUSE_LIGHT = 0.84;
const float PET_FRESNEL_POWER = 1.60;
const float PET_FRESNEL_COLOR_MIX = 0.24;
const float PET_SPECULAR_POWER = 30.0;
const float PET_FACE_LIGHT_MIX = 0.62;
const float PET_FACE_DARK_MULTIPLIER = 0.46;
const float PET_FACE_LIGHT_MULTIPLIER = 1.10;
const float PET_EDGE_INNER_WIDTH = 0.012;
const float PET_EDGE_OUTER_WIDTH = 0.088;
const float PET_EDGE_STRENGTH = 1.00;
const float PET_SPECULAR_STRENGTH = 1.00;
const float PET_HALO_RADIUS = 2.55;             // multiples of pet size
const float PET_HALO_STRENGTH = 0.030;
const float PET_GLINT_RATE = 0.18;
const float PET_GLINT_RADIUS = 0.080;           // multiples of pet size
const float PET_GLINT_STRENGTH = 0.34;
const float PET_GLINT_FLARE_LENGTH = 5.50;
const float PET_GLINT_FLARE_WIDTH = 0.18;
const float PET_GLINT_FLARE_STRENGTH = 0.25;

// =============================================================================
// TERMINAL COMPOSITING
// =============================================================================

const float PET_BODY_COLOR_MIX = 0.86;
const float PET_BODY_BLEND = 0.60;
const float PET_BODY_OPACITY_BASE = 0.28;
const float PET_BODY_OPACITY_FRESNEL = 0.18;
const float PET_BODY_OPACITY_EDGE = 0.20;
const float PET_HALO_OPACITY = 0.025;
const float PET_GLINT_OPACITY = 0.12;
const float PET_LIGHT_ALPHA_GAIN = 0.55;
const float PET_BACKGROUND_COLOR_TOLERANCE_LOW = 0.030;
const float PET_BACKGROUND_COLOR_TOLERANCE_HIGH = 0.245;
const float PET_TEXT_PROTECTION = 0.48;

// =============================================================================
// BLUE–VIOLET PALETTE
// =============================================================================

const vec3 PET_INK_BLUE      = vec3(0.008, 0.018, 0.075);
const vec3 PET_DEEP_INDIGO   = vec3(0.025, 0.055, 0.190);
const vec3 PET_ELECTRIC_BLUE = vec3(0.080, 0.280, 0.920);
const vec3 PET_DEEP_VIOLET   = vec3(0.250, 0.070, 0.590);
const vec3 PET_BRIGHT_VIOLET = vec3(0.620, 0.280, 1.000);
const vec3 PET_ICE_BLUE      = vec3(0.580, 0.780, 1.000);
const vec3 PET_PALE_VIOLET   = vec3(0.860, 0.760, 1.000);

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

float gaussianPoint(vec2 delta, float radius) {
    return exp(-dot(delta, delta) / max(radius * radius, 0.000001));
}

float backgroundCellMask(vec4 terminalColor) {
    float colorDifference = length(terminalColor.rgb - iBackgroundColor);
    float colorMatch = 1.0 - smoothstep(
        PET_BACKGROUND_COLOR_TOLERANCE_LOW,
        PET_BACKGROUND_COLOR_TOLERANCE_HIGH,
        colorDifference
    );
    float darkFallback = 1.0 - smoothstep(0.12, 0.58, luminance(terminalColor.rgb));
    float transparent = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(colorMatch, darkFallback * transparent * PET_TEXT_PROTECTION));
}

vec3 blueVioletPalette(float selector) {
    selector = fract(selector);
    if (selector < 0.22) return mix(PET_INK_BLUE, PET_DEEP_INDIGO, selector / 0.22);
    if (selector < 0.48) return mix(PET_DEEP_INDIGO, PET_ELECTRIC_BLUE, (selector - 0.22) / 0.26);
    if (selector < 0.72) return mix(PET_ELECTRIC_BLUE, PET_DEEP_VIOLET, (selector - 0.48) / 0.24);
    return mix(PET_DEEP_VIOLET, PET_BRIGHT_VIOLET, (selector - 0.72) / 0.28);
}

vec2 petUv(float timeValue, float identity) {
    float speedScale = 1.0 + identity * PET_OBJECT_PATH_SPEED_STEP;
    float phase = identity * PET_OBJECT_PATH_PHASE_STEP;
    float x = PET_PATH_X_PRIMARY_WEIGHT
            * sin(timeValue * PET_PATH_X_PRIMARY_SPEED * speedScale + PET_PATH_X_PRIMARY_PHASE + phase)
        + PET_PATH_X_SECONDARY_WEIGHT
            * sin(timeValue * PET_PATH_X_SECONDARY_SPEED / speedScale + PET_PATH_X_SECONDARY_PHASE - phase * 0.73);
    float y = PET_PATH_Y_PRIMARY_WEIGHT
            * sin(timeValue * PET_PATH_Y_PRIMARY_SPEED * speedScale + PET_PATH_Y_PRIMARY_PHASE - phase * 0.61)
        + PET_PATH_Y_SECONDARY_WEIGHT
            * sin(timeValue * PET_PATH_Y_SECONDARY_SPEED / speedScale + PET_PATH_Y_SECONDARY_PHASE + phase);
    float pathScale = identity < 0.5 ? 1.0 : pow(PET_COMPANION_PATH_SCALE, identity);
    return clamp(
        PET_PATH_CENTER + PET_PATH_AMPLITUDE * pathScale * vec2(x, y),
        vec2(PET_SCREEN_MARGIN),
        vec2(1.0 - PET_SCREEN_MARGIN)
    );
}

struct CrystalSample {
    vec3 bodyColor;
    vec3 light;
    float coverage;
    float opacity;
};

CrystalSample renderCrystal(vec2 point, vec2 center, float size, float identity) {
    vec3 localVertex[14];
    vec3 transformedVertex[14];
    vec2 projectedVertex[14];
    float vertexDepth[14];

    float side = PET_BASE_HALF_EXTENT;
    localVertex[0] = vec3(-side,  side, -side);
    localVertex[1] = vec3( side,  side, -side);
    localVertex[2] = vec3( side, -side, -side);
    localVertex[3] = vec3(-side, -side, -side);
    localVertex[4] = vec3(-side,  side,  side);
    localVertex[5] = vec3( side,  side,  side);
    localVertex[6] = vec3( side, -side,  side);
    localVertex[7] = vec3(-side, -side,  side);
    localVertex[8]  = vec3(0.0,  side * PET_TIP_LENGTH, 0.0);
    localVertex[9]  = vec3(0.0, -side * PET_TIP_LENGTH, 0.0);
    localVertex[10] = vec3( side * PET_TIP_LENGTH, 0.0, 0.0);
    localVertex[11] = vec3(-side * PET_TIP_LENGTH, 0.0, 0.0);
    localVertex[12] = vec3(0.0, 0.0, -side * PET_TIP_LENGTH);
    localVertex[13] = vec3(0.0, 0.0,  side * PET_TIP_LENGTH);

    float phase = identity * PET_OBJECT_ROTATION_PHASE_STEP;
    float speedScale = 1.0 + identity * PET_OBJECT_ROTATION_SPEED_STEP;
    float angleX = iTime * PET_ROTATION_X_SPEED * speedScale
        + PET_ROTATION_X_WOBBLE * sin(iTime * PET_ROTATION_X_WOBBLE_SPEED + phase);
    float angleY = iTime * PET_ROTATION_Y_SPEED * speedScale
        + PET_ROTATION_Y_WOBBLE * sin(iTime * PET_ROTATION_Y_WOBBLE_SPEED + 1.7 + phase);
    float angleZ = iTime * PET_ROTATION_Z_SPEED / speedScale
        + PET_ROTATION_Z_WOBBLE * sin(iTime * PET_ROTATION_Z_WOBBLE_SPEED + 3.2 - phase);

    for (int vertexIndex = 0; vertexIndex < 14; vertexIndex++) {
        vec3 transformed = rotateZ(rotateX(rotateY(localVertex[vertexIndex], angleY), angleX), angleZ);
        transformedVertex[vertexIndex] = transformed;
        float depth = PET_CAMERA_DISTANCE - transformed.z;
        vertexDepth[vertexIndex] = depth;
        float perspective = PET_CAMERA_DISTANCE / max(depth, PET_CAMERA_MIN_DEPTH);
        projectedVertex[vertexIndex] = center + transformed.xy * size * perspective;
    }

    const int faceA[24] = int[24](
        0,1,5,4, 2,6,7,3, 1,2,6,5,
        3,7,4,0, 1,2,3,0, 4,5,6,7
    );
    const int faceB[24] = int[24](
        8,8,8,8, 9,9,9,9, 10,10,10,10,
        11,11,11,11, 12,12,12,12, 13,13,13,13
    );
    const int faceC[24] = int[24](
        1,5,4,0, 3,2,6,7, 2,6,5,1,
        0,3,7,4, 0,1,2,3, 5,6,7,4
    );

    float nearestDepth = 1000.0;
    vec3 selectedColor = vec3(0.0);
    float selectedCoverage = 0.0;
    float selectedEdge = 0.0;
    float selectedSpecular = 0.0;
    float selectedFresnel = 0.0;
    vec3 lightDirection = normalize(PET_LIGHT_DIRECTION);
    vec3 viewDirection = vec3(0.0, 0.0, 1.0);

    for (int faceIndex = 0; faceIndex < 24; faceIndex++) {
        int firstIndex = faceA[faceIndex];
        int secondIndex = faceB[faceIndex];
        int thirdIndex = faceC[faceIndex];
        vec3 barycentric = barycentricCoordinates(
            point,
            projectedVertex[firstIndex],
            projectedVertex[secondIndex],
            projectedVertex[thirdIndex]
        );
        float minimumWeight = min(barycentric.x, min(barycentric.y, barycentric.z));
        float aa = clamp(fwidth(minimumWeight), 0.0014, 0.035);
        float coverage = smoothstep(-aa, aa, minimumWeight);
        float depth = dot(
            barycentric,
            vec3(vertexDepth[firstIndex], vertexDepth[secondIndex], vertexDepth[thirdIndex])
        );

        if (minimumWeight > -aa * 1.7 && depth < nearestDepth) {
            nearestDepth = depth;
            vec3 firstPoint = transformedVertex[firstIndex];
            vec3 secondPoint = transformedVertex[secondIndex];
            vec3 thirdPoint = transformedVertex[thirdIndex];
            vec3 normal = normalize(cross(secondPoint - firstPoint, thirdPoint - firstPoint));
            if (normal.z < 0.0) normal = -normal;

            float diffuse = PET_AMBIENT_LIGHT
                + PET_DIFFUSE_LIGHT * max(dot(normal, lightDirection), 0.0);
            float fresnel = pow(1.0 - abs(dot(normal, viewDirection)), PET_FRESNEL_POWER);
            float specular = pow(
                max(dot(reflect(-lightDirection, normal), viewDirection), 0.0),
                PET_SPECULAR_POWER
            );
            float edge = (
                1.0 - smoothstep(PET_EDGE_INNER_WIDTH, PET_EDGE_OUTER_WIDTH + aa, minimumWeight)
            ) * coverage;
            float faceTone = fract(
                float(faceIndex) * 0.119 + identity * 0.173
                    + normal.x * 0.10 - normal.y * 0.07
            );
            vec3 darkTone = blueVioletPalette(faceTone * 0.72);
            vec3 lightTone = mix(PET_ELECTRIC_BLUE, PET_BRIGHT_VIOLET, 0.5 + 0.5 * normal.x);
            selectedColor = mix(
                darkTone,
                lightTone,
                diffuse * PET_FACE_LIGHT_MIX + fresnel * PET_FRESNEL_COLOR_MIX
            );
            selectedColor *= mix(PET_FACE_DARK_MULTIPLIER, PET_FACE_LIGHT_MULTIPLIER, diffuse);
            selectedCoverage = coverage;
            selectedEdge = edge;
            selectedSpecular = specular;
            selectedFresnel = fresnel;
        }
    }

    vec3 edgeLight = mix(PET_ICE_BLUE, PET_PALE_VIOLET, selectedFresnel)
        * selectedEdge * PET_EDGE_STRENGTH * PET_PROFILE_EDGE_GAIN;
    vec3 specularLight = PET_PALE_VIOLET * selectedSpecular * selectedCoverage
        * PET_SPECULAR_STRENGTH * PET_PROFILE_SPECULAR_GAIN;

    float halo = 0.0;
#if PET_ENABLE_HALO
    halo = gaussianPoint(point - center, size * PET_HALO_RADIUS);
#endif
    vec3 haloLight = mix(PET_ELECTRIC_BLUE, PET_BRIGHT_VIOLET, 0.55)
        * halo * PET_HALO_STRENGTH;

    float glint = 0.0;
    vec3 glintLight = vec3(0.0);
#if PET_ENABLE_GLINT
    int glintTip = 8 + int(mod(floor(iTime * PET_GLINT_RATE + identity * 2.0), 6.0));
    vec2 glintDelta = point - projectedVertex[glintTip];
    float glintRadius = max(size * PET_GLINT_RADIUS, 0.0014);
    glint = gaussianPoint(glintDelta, glintRadius);
    float flareX = exp(-abs(glintDelta.y) / max(glintRadius * PET_GLINT_FLARE_WIDTH, 0.0003))
        * exp(-abs(glintDelta.x) / max(glintRadius * PET_GLINT_FLARE_LENGTH, 0.001));
    float flareY = exp(-abs(glintDelta.x) / max(glintRadius * PET_GLINT_FLARE_WIDTH, 0.0003))
        * exp(-abs(glintDelta.y) / max(glintRadius * PET_GLINT_FLARE_LENGTH, 0.001));
    glintLight = PET_PALE_VIOLET
        * (glint + PET_GLINT_FLARE_STRENGTH * (flareX + flareY))
        * PET_GLINT_STRENGTH;
#endif

    float opacity = selectedCoverage * (
        PET_BODY_OPACITY_BASE
        + selectedFresnel * PET_BODY_OPACITY_FRESNEL
        + selectedEdge * PET_BODY_OPACITY_EDGE
    );
    opacity = max(opacity, halo * PET_HALO_OPACITY + glint * PET_GLINT_OPACITY);
    return CrystalSample(
        selectedColor,
        (edgeLight + specularLight + haloLight + glintLight) * PET_MASTER_BRIGHTNESS,
        selectedCoverage,
        saturate(opacity)
    );
}

void renderCrystalBackground(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    // Wallpaper mode renders a complete procedural layer. Terminal
    // foreground coverage is applied only after the scene is complete.
    float backgroundMask = 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 point = (fragCoord - 0.5 * resolution) / resolution.y;
    float narrowScale = clamp(
        aspect / PET_NARROW_REFERENCE_ASPECT,
        PET_NARROW_MIN_SCALE,
        1.0
    );

    vec3 composite = vec3(0.0);
    float sceneAlpha = 0.0;

    for (int petIndex = 0; petIndex < PET_OBJECT_COUNT; petIndex++) {
        float identity = float(petIndex);
        vec2 centerUv = petUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = petIndex == 0
            ? 1.0
            : mix(
                1.0 - PET_COMPANION_SIZE_VARIATION,
                1.0 + PET_COMPANION_SIZE_VARIATION,
                hash12(vec2(identity, 7.31))
            );
        float breathing = 1.0 + PET_BREATHE_AMOUNT
            * sin(iTime * PET_BREATHE_SPEED + identity * PET_BREATHE_PHASE_STEP);
        float size = PET_SIZE * narrowScale
            * pow(PET_COMPANION_SCALE, identity)
            * randomScale * breathing;

        if (
            abs(point.x - center.x) < size * PET_CULL_RADIUS
            && abs(point.y - center.y) < size * PET_CULL_RADIUS
        ) {
            CrystalSample crystal = renderCrystal(point, center, size, identity);
            vec3 crystalLight = vec3(1.0)
                - exp(-max(crystal.light, vec3(0.0)) * PET_EXPOSURE);
            vec3 bodyTarget = mix(PET_INK_BLUE, crystal.bodyColor, PET_BODY_COLOR_MIX);
            composite = mix(
                composite,
                bodyTarget,
                crystal.coverage * backgroundMask * PET_BODY_BLEND
            );
            composite += crystalLight * backgroundMask;
            sceneAlpha = max(
                sceneAlpha,
                backgroundMask * PET_ALPHA_MAX * saturate(
                    crystal.opacity + luminance(crystalLight) * PET_LIGHT_ALPHA_GAIN
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
// MATCHED STELLATED CURSOR — QUANTITY, SIZE, SPEED, AND RESONANCE
// =============================================================================

#if GHOSTTY_GPU_PROFILE == PET_GPU_ECO
#define CR_SPARK_COUNT 0
#elif GHOSTTY_GPU_PROFILE == PET_GPU_BALANCED
#define CR_SPARK_COUNT 2
#elif GHOSTTY_GPU_PROFILE == PET_GPU_QUALITY
#define CR_SPARK_COUNT 4
#else
#define CR_SPARK_COUNT 7
#endif

#define CR_ECHO_COUNT 2                  // quantity: 0..3
#define CR_ENABLE_TRAIL 1
#define CR_ENABLE_SPARKS 1
#define CR_ENABLE_RESONANCE_LINK 1    // 0 removes every cursor-object connection
#define CR_LINK_ALL_OBJECTS 1         // 1: every object; 0: primary object only
#define CR_ENABLE_CORE_GLOW 1

const float CR_EFFECT_DURATION = 0.38;
const float CR_FADE_POWER = 1.68;
const float CR_MIN_MOVEMENT_CELLS = 0.025;
const float CR_GROWTH_START_CELLS = 0.08;
const float CR_GROWTH_FULL_CELLS = 8.00;
const float CR_MOVEMENT_RESPONSE_POWER = 1.00;
const float CR_CONTENT_PROTECTION = 0.18;
const float CR_CULL_RADIUS_MIN = 4.30;
const float CR_CULL_RADIUS_MAX = 8.00;
const float CR_MASTER_BRIGHTNESS = 1.00;

const float CR_BASE_HALF_EXTENT = 0.46;
const float CR_TIP_LENGTH_MIN = 2.65;
const float CR_TIP_LENGTH_MAX = 3.35;
const float CR_SIZE_MIN = 0.88;
const float CR_SIZE_MAX = 1.82;
const float CR_SIZE_PULSE = 0.14;
const float CR_CAMERA_DISTANCE = 4.20;
const vec3 CR_ROTATION_BASE = vec3(0.00);
const vec3 CR_ROTATION_SPEED = vec3(0.92, -1.08, 0.44);
const vec2 CR_AGE_ROTATION = vec2(0.70, 0.90);
const float CR_DIRECTION_TILT = 0.18;

const float CR_EDGE_CORE_WIDTH = 0.038;
const float CR_EDGE_GLOW_WIDTH = 0.140;
const float CR_EDGE_CORE_STRENGTH = 0.35;
const float CR_EDGE_GLOW_STRENGTH = 0.042;
const float CR_NEAR_DEPTH_CENTER = 5.20;
const float CR_NEAR_DEPTH_RANGE = 2.20;
const float CR_NEAR_WHITE_MIX = 0.40;

const float CR_ECHO_START_SCALE = 1.03;
const float CR_ECHO_END_SCALE = 2.08;
const float CR_ECHO_DELAY = 0.15;
const float CR_ECHO_WIDTH = 0.046;
const float CR_ECHO_STRENGTH = 0.088;
const float CR_ECHO_FALLOFF = 0.66;
const float CR_ECHO_FADE_POWER = 1.00;

const float CR_TRAIL_WIDTH_MIN = 0.12;
const float CR_TRAIL_WIDTH_MAX = 0.25;
const float CR_TRAIL_GLOW_MULTIPLIER = 4.20;
const float CR_TRAIL_GLOW_STRENGTH = 0.055;
const float CR_TRAIL_CORE_STRENGTH = 0.24;
const float CR_TRAIL_TAIL_FADE = 0.20;
const float CR_CORE_GLOW_RADIUS = 0.72;
const float CR_CORE_GLOW_STRENGTH = 0.072;
const float CR_SPARK_RADIUS = 0.070;
const float CR_SPARK_SPREAD = 1.80;
const float CR_SPARK_STRENGTH = 0.22;

const float CR_LINK_WIDTH = 0.060;
const float CR_LINK_GLOW_WIDTH = 0.25;
const float CR_LINK_CORE_STRENGTH = 0.050;
const float CR_LINK_GLOW_STRENGTH = 0.012;
const float CR_LINK_DASH_COUNT = 22.0;
const float CR_LINK_DASH_SPEED = 1.90;
const float CR_LINK_SECONDARY_FALLOFF = 0.72;
const float CR_LINK_COLOR_PHASE_STEP = 0.23;
// Movement factor 0..1 also drives link thickness, glow, energy, and dash density.
// MIN values apply to tiny cursor moves; MAX values apply at GROWTH_FULL_CELLS.
const float CR_LINK_MOVEMENT_POWER = 1.15;
const float CR_LINK_WIDTH_MIN_SCALE = 0.28;
const float CR_LINK_WIDTH_MAX_SCALE = 1.35;
const float CR_LINK_GLOW_WIDTH_MIN_SCALE = 0.22;
const float CR_LINK_GLOW_WIDTH_MAX_SCALE = 1.45;
const float CR_LINK_INTENSITY_MIN_SCALE = 0.10;
const float CR_LINK_INTENSITY_MAX_SCALE = 1.25;
const float CR_LINK_DASH_DENSITY_MIN_SCALE = 0.42;
const float CR_LINK_DASH_DENSITY_MAX_SCALE = 1.30;
const float CR_LINK_DASH_SPEED_MIN_SCALE = 0.40;
const float CR_LINK_DASH_SPEED_MAX_SCALE = 1.25;
const float CR_LINK_CULL_MIN_SCALE = 0.55;
const float CR_LINK_CULL_MAX_SCALE = 1.70;
const float CR_LINK_CULL_MIN_PIXELS = 4.0;
const float CR_LINK_ENDPOINT_GLOW = 0.095;

const vec3 CR_DEEP = vec3(0.055, 0.025, 0.200);
const vec3 CR_BLUE = vec3(0.120, 0.300, 1.000);
const vec3 CR_CYAN = vec3(0.160, 0.820, 1.000);
const vec3 CR_VIOLET = vec3(0.650, 0.260, 1.000);
const vec3 CR_ROSE = vec3(0.950, 0.220, 0.680);
const vec3 CR_GOLD = vec3(1.000, 0.750, 0.330);
const vec3 CR_WHITE = vec3(0.980, 0.950, 1.000);
const float CR_PI = 3.14159265359;

float crSegmentParameter(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    return clamp(
        dot(point - startPoint, segment) / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );
}

float crSegmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    return length(point - mix(
        startPoint,
        endPoint,
        crSegmentParameter(point, startPoint, endPoint)
    ));
}

vec2 crCursorCenterPixels(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}

vec2 crScenePoint(vec2 pixelPoint) {
    return (pixelPoint - 0.5 * iResolution.xy) / max(iResolution.y, 1.0);
}

float crInsideCursor(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(cursorRectangle.x, cursorRectangle.y - cursorRectangle.w);
    vec2 maximumPoint = vec2(cursorRectangle.x + cursorRectangle.z, cursorRectangle.y);
    return step(minimumPoint.x, point.x) * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x) * step(point.y, maximumPoint.y);
}

void applyCrystalResonanceCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = crCursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = crCursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / CR_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * CR_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = pow(
        smoothstep(
            cursorPixels * CR_GROWTH_START_CELLS,
            cursorPixels * CR_GROWTH_FULL_CELLS,
            movedPixels
        ),
        CR_MOVEMENT_RESPONSE_POWER
    );
    float linkMovementFactor = pow(movementFactor, CR_LINK_MOVEMENT_POWER);
    float linkWidthScale = mix(
        CR_LINK_WIDTH_MIN_SCALE,
        CR_LINK_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkGlowWidthScale = mix(
        CR_LINK_GLOW_WIDTH_MIN_SCALE,
        CR_LINK_GLOW_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkIntensityScale = mix(
        CR_LINK_INTENSITY_MIN_SCALE,
        CR_LINK_INTENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashDensityScale = mix(
        CR_LINK_DASH_DENSITY_MIN_SCALE,
        CR_LINK_DASH_DENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashSpeedScale = mix(
        CR_LINK_DASH_SPEED_MIN_SCALE,
        CR_LINK_DASH_SPEED_MAX_SCALE,
        linkMovementFactor
    );
    float linkCullScale = mix(
        CR_LINK_CULL_MIN_SCALE,
        CR_LINK_CULL_MAX_SCALE,
        linkMovementFactor
    );
    float cullRadius = cursorPixels * mix(
        CR_CULL_RADIUS_MIN,
        CR_CULL_RADIUS_MAX,
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
        CR_LINK_CULL_MIN_PIXELS
    );
    bool nearAnyLink = false;
#if CR_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < PET_OBJECT_COUNT; linkIndex++) {
        if (CR_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = petUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = crSegmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        nearAnyLink = nearAnyLink || linkPixelDistance <= linkCull;
    }
#endif
    if (!nearCursor && !nearAnyLink) return;

    vec2 point = crScenePoint(fragCoord);
    vec2 head = crScenePoint(headPixels);
    vec2 tail = crScenePoint(tailPixels);
    vec2 movement = head - tail;
    vec2 direction = movement / max(length(movement), 0.000001);
    vec2 normal2d = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - age, CR_FADE_POWER);
    float contentMask = mix(CR_CONTENT_PROTECTION, 1.0, backgroundCellMask(terminalColor));

#if CR_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < PET_OBJECT_COUNT; linkIndex++) {
        if (CR_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = petUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = crSegmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        if (linkPixelDistance > linkCull) continue;

        vec2 linkObject = crScenePoint(linkObjectPixels);
        float linkDistance = crSegmentDistance(point, head, linkObject);
        float linkAlong = crSegmentParameter(point, head, linkObject);
        float linkStrength = pow(CR_LINK_SECONDARY_FALLOFF, linkIdentity);
        float linkColorMix = saturate(
            linkAlong * 0.78 + linkIdentity * CR_LINK_COLOR_PHASE_STEP
        );
        float dash = 0.62 + 0.38 * sin(
            linkAlong * CR_LINK_DASH_COUNT * linkDashDensityScale
            - iTime * CR_LINK_DASH_SPEED * linkDashSpeedScale
            + linkIdentity * 2.17
        );
        float linkCore = exp(
            -linkDistance / max(cursorSize * CR_LINK_WIDTH * linkWidthScale, 0.0002)
        );
        float linkGlow = exp(
            -linkDistance / max(cursorSize * CR_LINK_GLOW_WIDTH * linkGlowWidthScale, 0.0005)
        );
        vec3 linkColor = mix(CR_ROSE, CR_CYAN, linkColorMix);
        scene.rgb += linkColor * dash * linkStrength * linkIntensityScale
            * life * contentMask * (
            linkCore * CR_LINK_CORE_STRENGTH
            + linkGlow * CR_LINK_GLOW_STRENGTH
        );
        float endpoint = gaussianPoint(
            point - linkObject,
            cursorSize * 0.76
        );
        vec3 endpointColor = mix(
            CR_ROSE,
            CR_WHITE,
            saturate(0.78 + linkIdentity * CR_LINK_COLOR_PHASE_STEP)
        );
        scene.rgb += endpointColor * endpoint * linkStrength * life
            * linkIntensityScale * CR_LINK_ENDPOINT_GLOW * contentMask;
    }
#endif

    if (nearCursor) {
#if CR_ENABLE_TRAIL
        float trailDistance = crSegmentDistance(point, tail, head);
        float along = crSegmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            CR_TRAIL_WIDTH_MIN,
            CR_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, CR_TRAIL_TAIL_FADE, along) * life;
        float trailGlow = exp(
            -trailDistance / max(trailWidth * CR_TRAIL_GLOW_MULTIPLIER, 0.0004)
        ) * smoothstep(0.0, CR_TRAIL_TAIL_FADE * 0.84, along) * life;
        vec3 trailColor = mix(CR_VIOLET, CR_CYAN, along);
        trailColor = mix(trailColor, CR_GOLD, smoothstep(0.78, 1.0, along) * 0.48);
        scene.rgb += trailColor * trailGlow * CR_TRAIL_GLOW_STRENGTH * contentMask;
        scene.rgb += trailColor * trailCore * CR_TRAIL_CORE_STRENGTH * contentMask;
#endif

        vec3 localVertex[14];
        vec2 projected[14];
        float depth[14];
        float side = CR_BASE_HALF_EXTENT;
        float tipLength = mix(CR_TIP_LENGTH_MIN, CR_TIP_LENGTH_MAX, movementFactor);
        localVertex[0] = vec3(-side,  side, -side);
        localVertex[1] = vec3( side,  side, -side);
        localVertex[2] = vec3( side, -side, -side);
        localVertex[3] = vec3(-side, -side, -side);
        localVertex[4] = vec3(-side,  side,  side);
        localVertex[5] = vec3( side,  side,  side);
        localVertex[6] = vec3( side, -side,  side);
        localVertex[7] = vec3(-side, -side,  side);
        localVertex[8]  = vec3(0.0,  side * tipLength, 0.0);
        localVertex[9]  = vec3(0.0, -side * tipLength, 0.0);
        localVertex[10] = vec3( side * tipLength, 0.0, 0.0);
        localVertex[11] = vec3(-side * tipLength, 0.0, 0.0);
        localVertex[12] = vec3(0.0, 0.0, -side * tipLength);
        localVertex[13] = vec3(0.0, 0.0,  side * tipLength);

        float shapeScale = cursorSize * mix(CR_SIZE_MIN, CR_SIZE_MAX, movementFactor)
            * (1.0 + CR_SIZE_PULSE * sin(age * CR_PI));
        vec3 angle = CR_ROTATION_BASE + iTime * CR_ROTATION_SPEED;
        angle.xy += age * CR_AGE_ROTATION;
        angle.z += atan(direction.y, direction.x) * CR_DIRECTION_TILT;
        for (int vertexIndex = 0; vertexIndex < 14; vertexIndex++) {
            vec3 vertex = rotateZ(
                rotateX(rotateY(localVertex[vertexIndex], angle.y), angle.x),
                angle.z
            );
            depth[vertexIndex] = CR_CAMERA_DISTANCE - vertex.z;
            projected[vertexIndex] = head
                + vertex.xy * shapeScale * CR_CAMERA_DISTANCE / depth[vertexIndex];
        }

        const int edgeA[36] = int[36](
            0,1,2,3, 4,5,6,7, 0,1,2,3,
            0,1,4,5, 3,2,7,6, 1,2,5,6,
            0,3,4,7, 0,1,2,3, 4,5,6,7
        );
        const int edgeB[36] = int[36](
            1,2,3,0, 5,6,7,4, 4,5,6,7,
            8,8,8,8, 9,9,9,9, 10,10,10,10,
            11,11,11,11, 12,12,12,12, 13,13,13,13
        );
        vec3 crystalLight = vec3(0.0);
        for (int edgeIndex = 0; edgeIndex < 36; edgeIndex++) {
            int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
            float nearFactor = saturate(
                (CR_NEAR_DEPTH_CENTER - 0.5 * (depth[first] + depth[second]))
                    / CR_NEAR_DEPTH_RANGE
            );
            float edgeDistance = crSegmentDistance(point, projected[first], projected[second]);
            float core = exp(-edgeDistance / max(cursorSize * CR_EDGE_CORE_WIDTH, 0.0001));
            float glow = exp(-edgeDistance / max(cursorSize * CR_EDGE_GLOW_WIDTH, 0.00024));
            vec3 edgeColor = mix(CR_DEEP, CR_CYAN, nearFactor);
            edgeColor = mix(edgeColor, CR_WHITE, nearFactor * CR_NEAR_WHITE_MIX);
            crystalLight += edgeColor * (
                core * CR_EDGE_CORE_STRENGTH + glow * CR_EDGE_GLOW_STRENGTH
            );
            for (int echoIndex = 0; echoIndex < CR_ECHO_COUNT; echoIndex++) {
                float delay = float(echoIndex) * CR_ECHO_DELAY;
                float progress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
                float echoActive = step(delay, easedAge);
                float scaleValue = mix(CR_ECHO_START_SCALE, CR_ECHO_END_SCALE, progress);
                vec2 echoFirst = head + (projected[first] - head) * scaleValue;
                vec2 echoSecond = head + (projected[second] - head) * scaleValue;
                float echoDistance = crSegmentDistance(point, echoFirst, echoSecond);
                float echo = exp(-echoDistance / max(cursorSize * CR_ECHO_WIDTH, 0.00011))
                    * pow(1.0 - progress, CR_ECHO_FADE_POWER) * echoActive;
                crystalLight += mix(CR_BLUE, CR_VIOLET, nearFactor) * echo
                    * CR_ECHO_STRENGTH * pow(CR_ECHO_FALLOFF, float(echoIndex));
            }
        }
#if CR_ENABLE_CORE_GLOW
        float centerGlow = gaussianPoint(point - head, shapeScale * CR_CORE_GLOW_RADIUS);
        crystalLight += mix(CR_BLUE, CR_VIOLET, 0.50)
            * centerGlow * CR_CORE_GLOW_STRENGTH;
#endif
        scene.rgb += crystalLight * life * contentMask * CR_MASTER_BRIGHTNESS;

#if CR_ENABLE_SPARKS && CR_SPARK_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int sparkIndex = 0; sparkIndex < CR_SPARK_COUNT; sparkIndex++) {
            float index = float(sparkIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 sparkCenter = mix(tail, head, positionRandom)
                + normal2d * (sideRandom - 0.5) * cursorSize * CR_SPARK_SPREAD;
            float spark = gaussianPoint(point - sparkCenter, cursorSize * CR_SPARK_RADIUS) * life;
            scene.rgb += mix(CR_CYAN, CR_GOLD, sideRandom)
                * spark * CR_SPARK_STRENGTH * contentMask;
        }
#endif
    }

    float cursorCoverage = crInsideCursor(fragCoord, iCurrentCursor);
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
    renderCrystalBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);

    // The matching movement effect is applied after the terminal foreground,
    // while the real Ghostty cursor rectangle remains exact inside its bounds.
    applyCrystalResonanceCursor(fragColor, fragCoord);
    fragColor.a = terminalColor.a;
}
