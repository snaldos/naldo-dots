// Crystal Familiar — large wandering 3D crystal pets for Ghostty
//
// Background-only shader. One dominant stellated crystal wanders around the
// terminal like the geodesic black hole, with a few large companions at higher
// GPU profiles. There is deliberately no small-shard storm, particle field, or
// full-screen magical texture: the wallpaper remains quiet and readable.
//
// The supplied 14-vertex / 24-face crystal idea is rendered as actual projected
// geometry. Vertices rotate in 3D, each triangular face is tested with
// barycentric coordinates, interpolated depth selects the nearest surface, and
// transformed normals drive diffuse, Fresnel, and specular light.
//
// The main familiar gently notices recent cursor movement: it leans a little
// toward the cursor and brightens one tip before returning to its own path.
// Pair this background with any cursor shader through ghostty-shaders.sh.

// =============================================================================
// GPU PROFILE
// =============================================================================

#define CRYSTAL_PET_ECO      0
#define CRYSTAL_PET_BALANCED 1
#define CRYSTAL_PET_QUALITY  2
#define CRYSTAL_PET_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE CRYSTAL_PET_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == CRYSTAL_PET_ECO
#define PERF_PET_COUNT 1
#elif GHOSTTY_GPU_PROFILE == CRYSTAL_PET_BALANCED
#define PERF_PET_COUNT 2
#else
#define PERF_PET_COUNT 3
#endif

// =============================================================================
// PALETTE AND MASTER CONTROLS
// =============================================================================

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float PET_EXPOSURE = 1.12;
const float PET_ALPHA_MAX = 0.42;

const vec3 CRYSTAL_CYAN    = vec3(0.140, 0.820, 1.000);
const vec3 CRYSTAL_BLUE    = vec3(0.180, 0.330, 1.000);
const vec3 CRYSTAL_VIOLET  = vec3(0.650, 0.300, 1.000);
const vec3 CRYSTAL_ROSE    = vec3(1.000, 0.210, 0.600);
const vec3 CRYSTAL_GREEN   = vec3(0.280, 1.000, 0.720);
const vec3 CRYSTAL_GOLD    = vec3(1.000, 0.760, 0.390);
const vec3 CRYSTAL_IVORY   = vec3(0.975, 0.950, 1.000);
const vec3 CRYSTAL_DEEP    = vec3(0.035, 0.055, 0.180);

// =============================================================================
// HELPERS
// =============================================================================

float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float hash12(vec2 point) {
    vec3 p3 = fract(vec3(point.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * point;
}

vec3 rotateX(vec3 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec3(
        point.x,
        point.y * c - point.z * s,
        point.y * s + point.z * c
    );
}

vec3 rotateY(vec3 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec3(
        point.x * c + point.z * s,
        point.y,
        -point.x * s + point.z * c
    );
}

vec3 rotateZ(vec3 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec3(
        point.x * c - point.y * s,
        point.x * s + point.y * c,
        point.z
    );
}

float cross2d(vec2 first, vec2 second) {
    return first.x * second.y - first.y * second.x;
}

vec3 barycentricCoordinates(
    vec2 point,
    vec2 first,
    vec2 second,
    vec2 third
) {
    float denominator = cross2d(second - first, third - first);
    float safeDenominator = abs(denominator) < 0.000001
        ? (denominator < 0.0 ? -0.000001 : 0.000001)
        : denominator;
    float firstWeight = cross2d(second - point, third - point)
        / safeDenominator;
    float secondWeight = cross2d(third - point, first - point)
        / safeDenominator;
    return vec3(
        firstWeight,
        secondWeight,
        1.0 - firstWeight - secondWeight
    );
}

float gaussianPoint(vec2 delta, float radius) {
    return exp(
        -dot(delta, delta) / max(radius * radius, 0.000001)
    );
}

vec3 crystalPalette(float selector) {
    selector = fract(selector);
    if (selector < 0.20) {
        return mix(CRYSTAL_CYAN, CRYSTAL_BLUE, selector / 0.20);
    }
    if (selector < 0.43) {
        return mix(
            CRYSTAL_BLUE,
            CRYSTAL_VIOLET,
            (selector - 0.20) / 0.23
        );
    }
    if (selector < 0.68) {
        return mix(
            CRYSTAL_VIOLET,
            CRYSTAL_ROSE,
            (selector - 0.43) / 0.25
        );
    }
    if (selector < 0.84) {
        return mix(
            CRYSTAL_ROSE,
            CRYSTAL_GOLD,
            (selector - 0.68) / 0.16
        );
    }
    return mix(
        CRYSTAL_GREEN,
        CRYSTAL_CYAN,
        (selector - 0.84) / 0.16
    );
}

float backgroundCellMask(vec4 terminalColor) {
    float colorDifference = length(terminalColor.rgb - iBackgroundColor);
    float colorMatch = 1.0 - smoothstep(0.030, 0.245, colorDifference);
    float darkFallback = 1.0 - smoothstep(
        0.12,
        0.58,
        luminance(terminalColor.rgb)
    );
    float transparent = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(colorMatch, darkFallback * transparent * 0.48));
}

vec2 cursorCenterPixels(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}

struct PetSample {
    vec3 radiance;
    float opacity;
};

// =============================================================================
// ORGANIC WANDERING AND CURSOR ATTENTION
// =============================================================================

vec2 mainPetUv(float timeValue) {
    float x = 0.72 * sin(timeValue * 0.071 + 0.40)
        + 0.28 * sin(timeValue * 0.173 + 2.10);
    float y = 0.68 * sin(timeValue * 0.083 + 2.30)
        + 0.32 * sin(timeValue * 0.137 + 5.10);
    return vec2(0.50 + 0.34 * x, 0.50 + 0.30 * y);
}

float petAttention() {
    float cursorAge = max(iTime - iTimeCursorChange, 0.0);
    return float(iCursorVisible != 0) * exp(-cursorAge / 2.4);
}

void crystalPetState(
    int petIndex,
    float aspect,
    out vec2 center,
    out float size,
    out float identity,
    out float attention
) {
    vec2 mainUv = mainPetUv(iTime);
    attention = petIndex == 0 ? petAttention() : 0.0;

    if (petIndex == 0 && attention > 0.001) {
        vec2 cursorUv = cursorCenterPixels(iCurrentCursor)
            / max(iResolution.xy, vec2(1.0));
        cursorUv = clamp(cursorUv, vec2(0.08), vec2(0.92));
        mainUv = mix(mainUv, cursorUv, attention * 0.11);
    }

    vec2 uv = mainUv;
    if (petIndex == 1) {
        float orbit = iTime * 0.092 + 1.7;
        uv = mainUv + vec2(
            0.205 * cos(orbit),
            0.155 * sin(orbit * 0.83)
        );
    } else if (petIndex == 2) {
        vec2 opposite = vec2(1.0 - mainUv.x, 1.0 - mainUv.y);
        uv = mix(
            opposite,
            vec2(
                0.50 + 0.28 * sin(iTime * 0.047 + 4.2),
                0.50 + 0.24 * sin(iTime * 0.061 + 0.8)
            ),
            0.46
        );
    }
    uv = clamp(uv, vec2(0.075), vec2(0.925));
    center = (uv - 0.5) * vec2(aspect, 1.0);

    if (petIndex == 0) {
        size = 0.170 * (1.0 + 0.045 * sin(iTime * 0.33));
        identity = 0.574;
    } else if (petIndex == 1) {
        size = 0.092 * (1.0 + 0.055 * sin(iTime * 0.27 + 2.1));
        identity = 0.137;
    } else {
        size = 0.104 * (1.0 + 0.050 * sin(iTime * 0.24 + 4.3));
        identity = 0.823;
    }

    // Preserve the pet scale on wide wallpaper terminals while avoiding a
    // near-full-width object in narrow splits.
    size *= clamp(aspect / 0.95, 0.58, 1.0);
}

// =============================================================================
// PROJECTED 14-VERTEX / 24-FACE STELLATED CRYSTAL
// =============================================================================

PetSample renderCrystalPet(
    vec2 point,
    vec2 center,
    float size,
    float identity,
    float attention,
    float petIndex
) {
    vec3 localVertex[14];
    vec3 transformedVertex[14];
    vec2 projectedVertex[14];
    float vertexDepth[14];

    float halfX = mix(0.34, 0.47, hash12(vec2(identity, 11.3)));
    float halfY = mix(0.44, 0.62, hash12(vec2(identity, 29.7)));
    float halfZ = mix(0.31, 0.45, hash12(vec2(identity, 47.1)));
    localVertex[0] = vec3(-halfX,  halfY, -halfZ);
    localVertex[1] = vec3( halfX,  halfY, -halfZ);
    localVertex[2] = vec3( halfX, -halfY, -halfZ);
    localVertex[3] = vec3(-halfX, -halfY, -halfZ);
    localVertex[4] = vec3(-halfX,  halfY,  halfZ);
    localVertex[5] = vec3( halfX,  halfY,  halfZ);
    localVertex[6] = vec3( halfX, -halfY,  halfZ);
    localVertex[7] = vec3(-halfX, -halfY,  halfZ);

    float steeple = mix(2.55, 3.10, hash12(vec2(identity, 73.1)));
    localVertex[8]  = vec3(0.0,  halfY * steeple, 0.0);
    localVertex[9]  = vec3(0.0, -halfY * mix(2.30, 2.85, identity), 0.0);
    localVertex[10] = vec3( halfX * mix(2.00, 2.55, identity), 0.0, 0.0);
    localVertex[11] = vec3(-halfX * mix(1.90, 2.45, identity), 0.0, 0.0);
    localVertex[12] = vec3(0.0, 0.0, -halfZ * mix(2.00, 2.55, identity));
    localVertex[13] = vec3(0.0, 0.0,  halfZ * mix(2.10, 2.70, identity));

    float curiosityTilt = attention * 0.22;
    float angleX = iTime * mix(0.075, 0.135, identity)
        + identity * 13.7 + petIndex * 1.3;
    float angleY = iTime * mix(-0.115, 0.105, hash12(vec2(identity, 17.3)))
        + identity * 31.1 + curiosityTilt;
    float angleZ = iTime * mix(0.028, 0.070, hash12(vec2(identity, 53.7)))
        + identity * TAU - curiosityTilt * 0.6;
    float cameraDistance = 4.35;

    for (int vertexIndex = 0; vertexIndex < 14; vertexIndex++) {
        vec3 transformed = localVertex[vertexIndex];
        transformed = rotateY(transformed, angleY);
        transformed = rotateX(transformed, angleX);
        transformed = rotateZ(transformed, angleZ);
        transformedVertex[vertexIndex] = transformed;
        float depth = cameraDistance - transformed.z;
        vertexDepth[vertexIndex] = depth;
        float perspective = cameraDistance / max(depth, 0.35);
        projectedVertex[vertexIndex] = center
            + transformed.xy * size * perspective;
    }

    const int faceA[24] = int[24](
        0, 1, 5, 4,
        2, 6, 7, 3,
        1, 2, 6, 5,
        3, 7, 4, 0,
        1, 2, 3, 0,
        4, 5, 6, 7
    );
    const int faceB[24] = int[24](
        8, 8, 8, 8,
        9, 9, 9, 9,
        10, 10, 10, 10,
        11, 11, 11, 11,
        12, 12, 12, 12,
        13, 13, 13, 13
    );
    const int faceC[24] = int[24](
        1, 5, 4, 0,
        3, 2, 6, 7,
        2, 6, 5, 1,
        0, 3, 7, 4,
        0, 1, 2, 3,
        5, 6, 7, 4
    );

    float nearestDepth = 1000.0;
    vec3 selectedColor = vec3(0.0);
    float selectedCoverage = 0.0;
    float selectedEdge = 0.0;
    float selectedSpecular = 0.0;
    float selectedFresnel = 0.0;
    vec3 lightDirection = normalize(vec3(-0.58, 0.74, 1.30));
    vec3 viewDirection = vec3(0.0, 0.0, 1.0);

    if (length(point - center) < size * 3.55) {
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
            float minimumWeight = min(
                barycentric.x,
                min(barycentric.y, barycentric.z)
            );
            float aa = clamp(fwidth(minimumWeight), 0.0014, 0.035);
            float coverage = smoothstep(-aa, aa, minimumWeight);
            float depth = dot(
                barycentric,
                vec3(
                    vertexDepth[firstIndex],
                    vertexDepth[secondIndex],
                    vertexDepth[thirdIndex]
                )
            );

            if (minimumWeight > -aa * 1.7 && depth < nearestDepth) {
                nearestDepth = depth;
                vec3 firstPoint = transformedVertex[firstIndex];
                vec3 secondPoint = transformedVertex[secondIndex];
                vec3 thirdPoint = transformedVertex[thirdIndex];
                vec3 normal = normalize(cross(
                    secondPoint - firstPoint,
                    thirdPoint - firstPoint
                ));
                if (normal.z < 0.0) {
                    normal = -normal;
                }

                float diffuse = 0.22
                    + 0.78 * max(dot(normal, lightDirection), 0.0);
                float fresnel = pow(
                    1.0 - abs(dot(normal, viewDirection)),
                    1.60
                );
                vec3 reflected = reflect(-lightDirection, normal);
                float specular = pow(
                    max(dot(reflected, viewDirection), 0.0),
                    mix(20.0, 40.0, identity)
                );
                float edge = (
                    1.0 - smoothstep(0.012, 0.090 + aa, minimumWeight)
                ) * coverage;

                vec3 surfacePoint = firstPoint * barycentric.x
                    + secondPoint * barycentric.y
                    + thirdPoint * barycentric.z;
                float internalBand = 0.5 + 0.5 * sin(
                    surfacePoint.x * 7.0
                        + surfacePoint.y * 5.0
                        + surfacePoint.z * 6.0
                        + identity * 31.0
                );
                float faceIdentity = fract(
                    identity
                        + float(faceIndex) * 0.087
                        + normal.x * 0.07
                        - normal.y * 0.05
                );
                vec3 faceTint = crystalPalette(faceIdentity);
                vec3 refractedTint = crystalPalette(faceIdentity + 0.20);
                selectedColor = mix(
                    faceTint,
                    refractedTint,
                    fresnel * 0.45 + internalBand * 0.15
                ) * mix(0.50, 1.16, diffuse);
                selectedCoverage = coverage;
                selectedEdge = edge;
                selectedSpecular = specular;
                selectedFresnel = fresnel;
            }
        }
    }

    vec3 radiance = selectedColor
        * selectedCoverage
        * mix(0.22, 0.38, identity);
    radiance += mix(selectedColor, CRYSTAL_IVORY, 0.74)
        * selectedEdge
        * mix(0.56, 0.90, identity);
    radiance += CRYSTAL_IVORY
        * selectedSpecular
        * selectedCoverage
        * (0.84 + attention * 0.35);
    radiance += crystalPalette(identity + 0.17)
        * selectedFresnel
        * selectedCoverage
        * 0.090;

    vec2 delta = point - center;
    float halo = gaussianPoint(delta, size * mix(2.25, 2.85, identity));
    radiance += crystalPalette(identity) * halo * 0.026;

    int glintTipIndex = 8 + int(floor(identity * 5.999));
    vec2 glintDelta = point - projectedVertex[glintTipIndex];
    float glintRadius = max(size * 0.095, 0.0015);
    float glintCore = gaussianPoint(glintDelta, glintRadius);
    float horizontalFlare = exp(
        -abs(glintDelta.y) / max(glintRadius * 0.20, 0.0004)
    ) * exp(
        -abs(glintDelta.x) / max(glintRadius * 6.5, 0.002)
    );
    float verticalFlare = exp(
        -abs(glintDelta.x) / max(glintRadius * 0.20, 0.0004)
    ) * exp(
        -abs(glintDelta.y) / max(glintRadius * 6.5, 0.002)
    );
    float blink = pow(
        max(0.0, sin(iTime * mix(0.64, 1.05, identity) + identity * 71.0)),
        8.0
    );
    float glint = (
        glintCore + 0.28 * (horizontalFlare + verticalFlare)
    ) * (0.38 + blink * 0.62 + attention * 0.50);
    radiance += CRYSTAL_IVORY * glint * 0.52;

    float opacity = selectedCoverage
        * (0.20 + selectedFresnel * 0.18 + selectedEdge * 0.20);
    opacity = max(opacity, halo * 0.028 + glint * 0.15);
    return PetSample(radiance, saturate(opacity));
}

// =============================================================================
// MAIN
// =============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    float backgroundMask = backgroundCellMask(terminalColor);
    float aspect = resolution.x / resolution.y;
    vec2 point = (fragCoord - 0.5 * resolution) / resolution.y;

    vec3 petRadiance = vec3(0.0);
    float petOpacity = 0.0;

    for (int petIndex = 0; petIndex < PERF_PET_COUNT; petIndex++) {
        vec2 center;
        float size;
        float identity;
        float attention;
        crystalPetState(
            petIndex,
            aspect,
            center,
            size,
            identity,
            attention
        );
        float workRadius = size * 4.4;
        if (
            abs(point.x - center.x) < workRadius
            && abs(point.y - center.y) < workRadius
        ) {
            PetSample pet = renderCrystalPet(
                point,
                center,
                size,
                identity,
                attention,
                float(petIndex)
            );
            petRadiance += pet.radiance;
            petOpacity = max(petOpacity, pet.opacity);
        }
    }

    petRadiance = vec3(1.0)
        - exp(-max(petRadiance, vec3(0.0)) * PET_EXPOSURE);
    vec3 composite = terminalColor.rgb
        + petRadiance * backgroundMask;
    float sceneAlpha = backgroundMask
        * PET_ALPHA_MAX
        * saturate(petOpacity + luminance(petRadiance) * 0.55);

    fragColor = vec4(
        clamp(composite, 0.0, 1.0),
        max(terminalColor.a, sceneAlpha)
    );
}
