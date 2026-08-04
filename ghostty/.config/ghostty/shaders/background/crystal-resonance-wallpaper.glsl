// BACKGROUND-ONLY WALLPAPER VARIANT: crystal-resonance
// Procedural geometry is composited behind exact terminal foreground.
// Pair this stage with any independently selected cursor shader.

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
}
