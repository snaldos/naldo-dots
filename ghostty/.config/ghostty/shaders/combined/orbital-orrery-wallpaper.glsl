// WALLPAPER VARIANT: orbital-orrery
// Procedural geometry is the rear layer; terminal text is composited
// above it, and the matching movement-reactive cursor is topmost.

// Orbital Orrery — coordinated floating planets and miniature cursor system
//
// Wandering ringed planets share their palette with a movement-scaled cursor
// planet, projected rings, orbiting moons, expanding orbital pulses, and an
// optional resonance filament to the primary world. Every quantity and motion
// scale is independently tunable below.

// Orbital Orbs — configurable floating 3D planets, rings, and moons for Ghostty
// Hollow latitude-longitude surfaces preserve spherical form while projected
// orbital planes keep rings and moons in coherent front/back layers.

// =============================================================================
// GPU PROFILE AND FEATURE QUANTITIES
// =============================================================================

#define ORB_GPU_ECO      0
#define ORB_GPU_BALANCED 1
#define ORB_GPU_QUALITY  2
#define ORB_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE ORB_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == ORB_GPU_ECO
#define ORB_PROFILE_SPECULAR_GAIN 0.62
#define ORB_PROFILE_RING_GAIN 0.72
#elif GHOSTTY_GPU_PROFILE == ORB_GPU_BALANCED
#define ORB_PROFILE_SPECULAR_GAIN 0.76
#define ORB_PROFILE_RING_GAIN 0.84
#elif GHOSTTY_GPU_PROFILE == ORB_GPU_QUALITY
#define ORB_PROFILE_SPECULAR_GAIN 0.90
#define ORB_PROFILE_RING_GAIN 0.96
#else
#define ORB_PROFILE_SPECULAR_GAIN 1.00
#define ORB_PROFILE_RING_GAIN 1.06
#endif

#define ORB_OBJECT_COUNT 2              // quantity: 1..4 recommended
#define ORB_RING_COUNT 3                // quantity per orb: 0..5
#define ORB_MOON_COUNT 2                // quantity per orb: 0..4
#define ORB_ENABLE_ATMOSPHERE 1
#define ORB_ENABLE_WAKE 1

// =============================================================================
// MASTER, SIZE, AND SPHERE SHAPE
// =============================================================================

const float ORB_MASTER_BRIGHTNESS = 1.00;
const float ORB_EXPOSURE = 1.10;
const float ORB_ALPHA_MAX = 0.43;
const float ORB_SIZE = 0.098;            // screen-height fraction
const float ORB_COMPANION_SCALE = 0.76;
const float ORB_SIZE_VARIATION = 0.12;
const float ORB_BREATHE_AMOUNT = 0.035;
const float ORB_BREATHE_SPEED = 0.22;
const float ORB_CULL_RADIUS = 3.20;
const float ORB_NARROW_REFERENCE_ASPECT = 0.95;
const float ORB_NARROW_MIN_SCALE = 0.60;

// =============================================================================
// FULL-SCREEN MOVEMENT
// =============================================================================

const vec2 ORB_PATH_CENTER = vec2(0.50, 0.50);
const vec2 ORB_PATH_AMPLITUDE = vec2(0.425, 0.395);
const float ORB_SCREEN_MARGIN = 0.055;
const float ORB_PATH_PRIMARY_WEIGHT = 0.80;
const float ORB_PATH_SECONDARY_WEIGHT = 0.20;
const float ORB_PATH_X_SPEED = 0.054;
const float ORB_PATH_Y_SPEED = 0.069;
const float ORB_PATH_X_SECONDARY_SPEED = 0.143;
const float ORB_PATH_Y_SECONDARY_SPEED = 0.127;
const float ORB_OBJECT_PATH_PHASE_STEP = 2.57;
const float ORB_OBJECT_PATH_SPEED_STEP = 0.061;
const float ORB_COMPANION_PATH_SCALE = 0.93;

// =============================================================================
// HOLLOW LATITUDE-LONGITUDE SPHERE AND SPIN
// =============================================================================

const float ORB_SPIN_SPEED = 0.22;
const float ORB_SPIN_SPEED_STEP = 0.07;
const float ORB_AXIAL_TILT = 0.34;
const float ORB_LATITUDE_COUNT = 7.0;
const float ORB_LONGITUDE_COUNT = 12.0;
const float ORB_GRID_CORE_WIDTH = 0.030;
const float ORB_GRID_GLOW_WIDTH = 0.105;
const float ORB_GRID_CORE_STRENGTH = 0.54;
const float ORB_GRID_GLOW_STRENGTH = 0.095;
const float ORB_GRID_BACK_STRENGTH = 0.24;
const float ORB_GRID_POLE_FADE_START = 0.055;
const float ORB_GRID_POLE_FADE_END = 0.20;
const float ORB_SILHOUETTE_CORE_WIDTH = 0.018;
const float ORB_SILHOUETTE_GLOW_WIDTH = 0.075;
const float ORB_SILHOUETTE_CORE_STRENGTH = 0.62;
const float ORB_SILHOUETTE_GLOW_STRENGTH = 0.12;
const float ORB_RING_BACK_VISIBILITY = 0.30;
const float ORB_MOON_BACK_VISIBILITY = 0.24;
const vec3 ORB_LIGHT_DIRECTION = vec3(-0.62, 0.72, 1.25);
const float ORB_GRID_AMBIENT_LIGHT = 0.44;
const float ORB_GRID_DIFFUSE_LIGHT = 0.56;

// =============================================================================
// ATMOSPHERE
// =============================================================================

const float ORB_ATMOSPHERE_RADIUS = 1.22;
const float ORB_ATMOSPHERE_RIM_WIDTH = 0.15;
const float ORB_ATMOSPHERE_STRENGTH = 0.10;
const float ORB_ATMOSPHERE_HALO_RADIUS = 1.55;
const float ORB_ATMOSPHERE_HALO_STRENGTH = 0.026;

// =============================================================================
// PROJECTED 3D RINGS
// =============================================================================

const float ORB_RING_RADIUS_START = 1.35;
const float ORB_RING_RADIUS_SPACING = 0.25;
const float ORB_RING_COMPRESSION = 0.34;          // 1 face-on, 0 edge-on
const float ORB_RING_ROLL = -0.38;
const float ORB_RING_ROLL_SPEED = 0.035;
const float ORB_RING_WIDTH = 0.028;
const float ORB_RING_GLOW_WIDTH = 0.085;
const float ORB_RING_CORE_STRENGTH = 0.34;
const float ORB_RING_GLOW_STRENGTH = 0.075;
const float ORB_RING_STRENGTH_FALLOFF = 0.78;
const float ORB_RING_DASH_COUNT = 11.0;
const float ORB_RING_DASH_SPEED = 0.55;
const float ORB_RING_DASH_STRENGTH = 0.25;
const float ORB_RING_FRONT_SIGN = 1.0;

// =============================================================================
// ORBITING MOONS
// =============================================================================

const float ORB_MOON_ORBIT_RADIUS = 1.72;
const float ORB_MOON_ORBIT_SPACING = 0.34;
const float ORB_MOON_ORBIT_SPEED = 0.31;
const float ORB_MOON_ORBIT_SPEED_STEP = 0.13;
const float ORB_MOON_RADIUS = 0.115;
const float ORB_MOON_RADIUS_FALLOFF = 0.82;
const float ORB_MOON_GLOW_RADIUS = 2.60;
const float ORB_MOON_GLOW_STRENGTH = 0.10;
const float ORB_MOON_BODY_STRENGTH = 0.72;

// =============================================================================
// MOTION WAKE AND COMPOSITING
// =============================================================================

const float ORB_WAKE_SECONDS = 1.15;
const float ORB_WAKE_WIDTH = 0.090;
const float ORB_WAKE_STRENGTH = 0.020;
const float ORB_LIGHT_ALPHA_GAIN = 0.55;
const float ORB_BACKGROUND_TOLERANCE_LOW = 0.030;
const float ORB_BACKGROUND_TOLERANCE_HIGH = 0.245;
const float ORB_TEXT_PROTECTION = 0.48;

// =============================================================================
// PALETTE
// =============================================================================

const vec3 ORB_VOID       = vec3(0.008, 0.016, 0.060);
const vec3 ORB_DEEP_BLUE  = vec3(0.035, 0.100, 0.330);
const vec3 ORB_BLUE       = vec3(0.080, 0.320, 0.950);
const vec3 ORB_CYAN       = vec3(0.140, 0.830, 1.000);
const vec3 ORB_TEAL       = vec3(0.100, 0.720, 0.650);
const vec3 ORB_VIOLET     = vec3(0.570, 0.220, 0.980);
const vec3 ORB_ROSE       = vec3(0.940, 0.220, 0.620);
const vec3 ORB_PINK       = vec3(0.980, 0.240, 0.690);
const vec3 ORB_WHITE      = vec3(0.950, 0.970, 1.000);

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

float saturate(float value) { return clamp(value, 0.0, 1.0); }
float luminance(vec3 color) { return dot(color, vec3(0.2126, 0.7152, 0.0722)); }

float hash12(vec2 point) {
    vec3 p3 = fract(vec3(point.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec2(c * point.x - s * point.y, s * point.x + c * point.y);
}

vec3 rotateX(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(point.x, point.y * c - point.z * s, point.y * s + point.z * c);
}

vec3 rotateY(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(point.x * c + point.z * s, point.y, -point.x * s + point.z * c);
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
        ORB_BACKGROUND_TOLERANCE_LOW,
        ORB_BACKGROUND_TOLERANCE_HIGH,
        difference
    );
    float darkFallback = 1.0 - smoothstep(0.12, 0.58, luminance(terminalColor.rgb));
    float transparent = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(colorMatch, darkFallback * transparent * ORB_TEXT_PROTECTION));
}

vec3 orbPalette(float selector) {
    selector = fract(selector);
    if (selector < 0.22) return mix(ORB_DEEP_BLUE, ORB_BLUE, selector / 0.22);
    if (selector < 0.44) return mix(ORB_BLUE, ORB_CYAN, (selector - 0.22) / 0.22);
    if (selector < 0.66) return mix(ORB_CYAN, ORB_TEAL, (selector - 0.44) / 0.22);
    if (selector < 0.84) return mix(ORB_TEAL, ORB_VIOLET, (selector - 0.66) / 0.18);
    return mix(ORB_VIOLET, ORB_ROSE, (selector - 0.84) / 0.16);
}

vec2 orbUv(float timeValue, float identity) {
    float speedScale = 1.0 + identity * ORB_OBJECT_PATH_SPEED_STEP;
    float phase = identity * ORB_OBJECT_PATH_PHASE_STEP;
    float x = ORB_PATH_PRIMARY_WEIGHT
            * sin(timeValue * ORB_PATH_X_SPEED * speedScale + 0.75 + phase)
        + ORB_PATH_SECONDARY_WEIGHT
            * sin(timeValue * ORB_PATH_X_SECONDARY_SPEED / speedScale + 2.80 - phase);
    float y = ORB_PATH_PRIMARY_WEIGHT
            * sin(timeValue * ORB_PATH_Y_SPEED * speedScale + 2.45 - phase * 0.57)
        + ORB_PATH_SECONDARY_WEIGHT
            * sin(timeValue * ORB_PATH_Y_SECONDARY_SPEED / speedScale + 5.30 + phase);
    float pathScale = identity < 0.5 ? 1.0 : pow(ORB_COMPANION_PATH_SCALE, identity);
    return clamp(
        ORB_PATH_CENTER + ORB_PATH_AMPLITUDE * pathScale * vec2(x, y),
        vec2(ORB_SCREEN_MARGIN),
        vec2(1.0 - ORB_SCREEN_MARGIN)
    );
}

struct OrbSample {
    vec3 radiance;
    float opacity;
};

float periodicGridDistance(float phase) {
    return abs(fract(phase + 0.5) - 0.5);
}

void sphericalGridMask(
    vec3 surfaceNormal,
    float latitudeCount,
    float longitudeCount,
    float coreWidth,
    float glowWidth,
    float pixelRadius,
    float poleFadeStart,
    float poleFadeEnd,
    out float core,
    out float glow
) {
    float latitude = asin(clamp(surfaceNormal.y, -1.0, 1.0));
    float longitude = atan(surfaceNormal.z, surfaceNormal.x);
    float latitudePhase = (latitude / PI + 0.5) * latitudeCount;
    float longitudePhase = (longitude / TAU + 0.5) * longitudeCount;
    float latitudeDistance = periodicGridDistance(latitudePhase);
    float longitudeDistance = periodicGridDistance(longitudePhase);
    float latitudeAa = 0.72 * latitudeCount
        / max(PI * pixelRadius, 1.0);
    float longitudeAa = 0.72 * longitudeCount
        / max(TAU * pixelRadius, 1.0);
    float latitudeCore = 1.0 - smoothstep(
        coreWidth,
        coreWidth + latitudeAa,
        latitudeDistance
    );
    float latitudeGlow = 1.0 - smoothstep(
        glowWidth,
        glowWidth + latitudeAa,
        latitudeDistance
    );
    float poleFade = smoothstep(
        poleFadeStart,
        poleFadeEnd,
        length(surfaceNormal.xz)
    );
    float longitudeCore = poleFade * (1.0 - smoothstep(
        coreWidth,
        coreWidth + longitudeAa,
        longitudeDistance
    ));
    float longitudeGlow = poleFade * (1.0 - smoothstep(
        glowWidth,
        glowWidth + longitudeAa,
        longitudeDistance
    ));
    core = max(latitudeCore, longitudeCore);
    glow = max(latitudeGlow, longitudeGlow);
}

OrbSample renderOrb(vec2 point, vec2 center, float radius, float identity) {
    vec2 local = (point - center) / max(radius, 0.0001);
    float radial = length(local);
    float sphereAa = max(fwidth(radial), 0.002);
    float sphereCoverage = 1.0 - smoothstep(
        1.0 - sphereAa,
        1.0 + sphereAa,
        radial
    );
    vec3 radiance = vec3(0.0);
    float opacity = 0.0;

    if (radial < 1.0 + sphereAa * 2.0) {
        float z = sqrt(max(1.0 - dot(local, local), 0.0));
        vec3 frontNormal = normalize(vec3(local, z));
        vec3 backNormal = normalize(vec3(local, -z));
        float spin = iTime * (ORB_SPIN_SPEED + identity * ORB_SPIN_SPEED_STEP);
        vec3 frontGridNormal = rotateY(rotateX(frontNormal, ORB_AXIAL_TILT), spin);
        vec3 backGridNormal = rotateY(rotateX(backNormal, ORB_AXIAL_TILT), spin);
        float frontCore, frontGlow, backCore, backGlow;
        float pixelRadius = max(radius * iResolution.y, 1.0);
        sphericalGridMask(
            frontGridNormal,
            ORB_LATITUDE_COUNT,
            ORB_LONGITUDE_COUNT,
            ORB_GRID_CORE_WIDTH,
            ORB_GRID_GLOW_WIDTH,
            pixelRadius,
            ORB_GRID_POLE_FADE_START,
            ORB_GRID_POLE_FADE_END,
            frontCore,
            frontGlow
        );
        sphericalGridMask(
            backGridNormal,
            ORB_LATITUDE_COUNT,
            ORB_LONGITUDE_COUNT,
            ORB_GRID_CORE_WIDTH,
            ORB_GRID_GLOW_WIDTH,
            pixelRadius,
            ORB_GRID_POLE_FADE_START,
            ORB_GRID_POLE_FADE_END,
            backCore,
            backGlow
        );
        vec3 lightDirection = normalize(ORB_LIGHT_DIRECTION);
        float diffuse = ORB_GRID_AMBIENT_LIGHT + ORB_GRID_DIFFUSE_LIGHT
            * max(dot(frontNormal, lightDirection), 0.0);
        vec3 frontColor = mix(
            orbPalette(identity * 0.29 + frontGridNormal.y * 0.12),
            ORB_CYAN,
            0.48 + 0.24 * frontGridNormal.y
        ) * diffuse;
        vec3 backColor = mix(ORB_VIOLET, ORB_BLUE, 0.52);
        radiance += frontColor * ORB_PROFILE_SPECULAR_GAIN * (
            frontCore * ORB_GRID_CORE_STRENGTH
            + frontGlow * ORB_GRID_GLOW_STRENGTH
        );
        radiance += backColor * ORB_GRID_BACK_STRENGTH * (
            backCore * ORB_GRID_CORE_STRENGTH
            + backGlow * ORB_GRID_GLOW_STRENGTH
        );
        float silhouetteDistance = abs(radial - 1.0);
        float silhouetteCore = exp(
            -silhouetteDistance / max(ORB_SILHOUETTE_CORE_WIDTH, 0.001)
        );
        float silhouetteGlow = exp(
            -silhouetteDistance / max(ORB_SILHOUETTE_GLOW_WIDTH, 0.002)
        );
        vec3 silhouetteColor = mix(
            ORB_CYAN,
            ORB_VIOLET,
            0.5 + 0.5 * sin(identity * 1.7 + iTime * 0.08)
        );
        radiance += silhouetteColor * (
            silhouetteCore * ORB_SILHOUETTE_CORE_STRENGTH
            + silhouetteGlow * ORB_SILHOUETTE_GLOW_STRENGTH
        );
        opacity = max(opacity, max(
            frontCore,
            max(backCore * ORB_GRID_BACK_STRENGTH, silhouetteCore)
        ));
        opacity = max(opacity, max(frontGlow, silhouetteGlow) * 0.20);
    }

#if ORB_ENABLE_ATMOSPHERE
    float atmosphereBand = exp(
        -abs(radial - 1.0) / max(ORB_ATMOSPHERE_RIM_WIDTH, 0.001)
    ) * (1.0 - smoothstep(
        ORB_ATMOSPHERE_RADIUS,
        ORB_ATMOSPHERE_RADIUS + 0.08,
        radial
    ));
    float atmosphereHalo = exp(-abs(radial - 1.10) / 0.24)
        * smoothstep(0.76, 0.98, radial)
        * (1.0 - smoothstep(ORB_ATMOSPHERE_HALO_RADIUS, 1.72, radial));
    vec3 atmosphereColor = mix(ORB_CYAN, ORB_VIOLET, fract(identity * 0.37));
    radiance += atmosphereColor * (
        atmosphereBand * ORB_ATMOSPHERE_STRENGTH
        + atmosphereHalo * ORB_ATMOSPHERE_HALO_STRENGTH
    );
    opacity = max(opacity, atmosphereBand * 0.10 + atmosphereHalo * 0.018);
#endif

    float ringRoll = ORB_RING_ROLL + iTime * ORB_RING_ROLL_SPEED + identity * 0.48;
    vec2 ringLocal = rotate2d((point - center) / max(radius, 0.0001), -ringRoll);
    vec2 ellipsePoint = vec2(ringLocal.x, ringLocal.y / max(ORB_RING_COMPRESSION, 0.04));
    float ellipseRadius = length(ellipsePoint);
    float ellipseAngle = atan(ellipsePoint.y, ellipsePoint.x);
    float frontHalf = step(0.0, ringLocal.y * ORB_RING_FRONT_SIGN);

    for (int ringIndex = 0; ringIndex < ORB_RING_COUNT; ringIndex++) {
        float index = float(ringIndex);
        float targetRadius = ORB_RING_RADIUS_START + index * ORB_RING_RADIUS_SPACING;
        float ringDistance = abs(ellipseRadius - targetRadius);
        float core = exp(-ringDistance / max(ORB_RING_WIDTH, 0.001));
        float glow = exp(-ringDistance / max(ORB_RING_GLOW_WIDTH, 0.002));
        float dash = mix(
            1.0,
            0.5 + 0.5 * sin(
                ellipseAngle * ORB_RING_DASH_COUNT
                - iTime * ORB_RING_DASH_SPEED * (1.0 + index * 0.17)
                + identity
            ),
            ORB_RING_DASH_STRENGTH
        );
        float insideSphereVisibility = mix(
            ORB_RING_BACK_VISIBILITY,
            1.0,
            frontHalf
        );
        float occlusion = mix(1.0, insideSphereVisibility, sphereCoverage);
        float ringStrength = pow(ORB_RING_STRENGTH_FALLOFF, index);
        vec3 ringColor = mix(
            mix(ORB_PINK, ORB_ROSE, fract(identity * 0.31)),
            ORB_CYAN,
            index / max(float(ORB_RING_COUNT - 1), 1.0)
        );
        radiance += ringColor * occlusion * dash * ringStrength * ORB_PROFILE_RING_GAIN
            * (core * ORB_RING_CORE_STRENGTH + glow * ORB_RING_GLOW_STRENGTH);
        opacity = max(opacity, occlusion * core * ringStrength * 0.18);
    }

    for (int moonIndex = 0; moonIndex < ORB_MOON_COUNT; moonIndex++) {
        float index = float(moonIndex);
        float orbitRadius = ORB_MOON_ORBIT_RADIUS + index * ORB_MOON_ORBIT_SPACING;
        float orbitAngle = iTime * (
            ORB_MOON_ORBIT_SPEED + index * ORB_MOON_ORBIT_SPEED_STEP
        ) + identity * 1.9 + index * TAU / max(float(ORB_MOON_COUNT), 1.0);
        float orbitDepth = sin(orbitAngle);
        vec2 orbitPlane = vec2(
            cos(orbitAngle) * orbitRadius,
            orbitDepth * orbitRadius * ORB_RING_COMPRESSION
        );
        vec2 moonCenter = center + rotate2d(orbitPlane, ringRoll) * radius;
        float moonRadius = radius * ORB_MOON_RADIUS * pow(ORB_MOON_RADIUS_FALLOFF, index);
        vec2 moonDelta = point - moonCenter;
        float moonDistance = length(moonDelta);
        float moonCoverage = 1.0 - smoothstep(
            moonRadius * 0.88,
            moonRadius * 1.08,
            moonDistance
        );
        float behind = 1.0 - step(0.0, orbitDepth);
        float moonOcclusion = 1.0 - behind * sphereCoverage
            * (1.0 - ORB_MOON_BACK_VISIBILITY);
        vec3 moonColor = mix(ORB_WHITE, orbPalette(identity * 0.29 + index * 0.23), 0.52);
        float moonShade = 0.35 + 0.65 * saturate(
            dot(
                normalize(vec3(moonDelta / max(moonRadius, 0.0001), 0.65)),
                normalize(ORB_LIGHT_DIRECTION)
            )
        );
        float moonGlow = gaussianPoint(moonDelta, moonRadius * ORB_MOON_GLOW_RADIUS);
        radiance += moonColor * moonOcclusion * (
            moonCoverage * moonShade * ORB_MOON_BODY_STRENGTH
            + moonGlow * ORB_MOON_GLOW_STRENGTH
        );
        opacity = max(opacity, moonOcclusion * (moonCoverage * 0.42 + moonGlow * 0.035));
    }

    // Only the spherical surface grid, silhouette, rings, and moons contribute;
    // no disk-shaped body color is composited, so the interior stays empty.
    return OrbSample(radiance, saturate(opacity));
}

void renderOrbitalBackground(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    // Wallpaper mode renders a complete procedural layer. Terminal
    // foreground coverage is applied only after the scene is complete.
    float backgroundMask = 1.0;
    float aspect = resolution.x / resolution.y;
    vec2 point = (fragCoord - 0.5 * resolution) / resolution.y;
    float narrowScale = clamp(aspect / ORB_NARROW_REFERENCE_ASPECT, ORB_NARROW_MIN_SCALE, 1.0);

    vec3 composite = vec3(0.0);
    float sceneAlpha = 0.0;

    for (int objectIndex = 0; objectIndex < ORB_OBJECT_COUNT; objectIndex++) {
        float identity = float(objectIndex);
        vec2 centerUv = orbUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = objectIndex == 0
            ? 1.0
            : mix(1.0 - ORB_SIZE_VARIATION, 1.0 + ORB_SIZE_VARIATION, hash12(vec2(identity, 9.21)));
        float radius = ORB_SIZE * narrowScale
            * pow(ORB_COMPANION_SCALE, identity) * randomScale
            * (1.0 + ORB_BREATHE_AMOUNT * sin(iTime * ORB_BREATHE_SPEED + identity * 1.6));

#if ORB_ENABLE_WAKE
        vec2 previousUv = orbUv(iTime - ORB_WAKE_SECONDS, identity);
        vec2 previousCenter = (previousUv - 0.5) * vec2(aspect, 1.0);
        float wakeDistance = segmentDistance(point, previousCenter, center);
        float wakeAlong = segmentParameter(point, previousCenter, center);
        float wake = exp(-wakeDistance / max(radius * ORB_WAKE_WIDTH, 0.0005))
            * smoothstep(0.0, 0.84, wakeAlong);
        composite += orbPalette(identity * 0.29) * wake * ORB_WAKE_STRENGTH * backgroundMask;
        sceneAlpha = max(sceneAlpha, wake * ORB_ALPHA_MAX * 0.05 * backgroundMask);
#endif

        if (
            abs(point.x - center.x) < radius * ORB_CULL_RADIUS
            && abs(point.y - center.y) < radius * ORB_CULL_RADIUS
        ) {
            OrbSample sampleValue = renderOrb(point, center, radius, identity);
            vec3 light = vec3(1.0) - exp(
                -max(sampleValue.radiance, vec3(0.0))
                    * ORB_EXPOSURE * ORB_MASTER_BRIGHTNESS
            );
            composite += light * backgroundMask;
            sceneAlpha = max(
                sceneAlpha,
                backgroundMask * ORB_ALPHA_MAX * saturate(
                    sampleValue.opacity + luminance(light) * ORB_LIGHT_ALPHA_GAIN
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
// MATCHED ORRERY CURSOR — PLANET, RINGS, MOONS, QUANTITIES, AND RESPONSE
// =============================================================================

#if GHOSTTY_GPU_PROFILE == ORB_GPU_ECO
#define OC_STAR_COUNT 0
#elif GHOSTTY_GPU_PROFILE == ORB_GPU_BALANCED
#define OC_STAR_COUNT 2
#elif GHOSTTY_GPU_PROFILE == ORB_GPU_QUALITY
#define OC_STAR_COUNT 4
#else
#define OC_STAR_COUNT 7
#endif

#define OC_RING_COUNT 2                  // quantity around cursor: 0..4
#define OC_MOON_COUNT 2                  // quantity around cursor: 0..4
#define OC_PULSE_COUNT 2                 // expanding orbital echoes: 0..4
#define OC_ENABLE_TRAIL 1
#define OC_ENABLE_STARS 1
#define OC_ENABLE_RESONANCE_LINK 1    // 0 removes every cursor-object connection
#define OC_LINK_ALL_OBJECTS 1         // 1: every object; 0: primary object only

const float OC_EFFECT_DURATION = 0.38;
const float OC_FADE_POWER = 1.65;
const float OC_MIN_MOVEMENT_CELLS = 0.025;
const float OC_GROWTH_START_CELLS = 0.08;
const float OC_GROWTH_FULL_CELLS = 8.00;
const float OC_MOVEMENT_RESPONSE_POWER = 1.00;
const float OC_CONTENT_PROTECTION = 0.18;
const float OC_CULL_RADIUS_MIN = 4.00;
const float OC_CULL_RADIUS_MAX = 8.20;
const float OC_MASTER_BRIGHTNESS = 1.00;

const float OC_PLANET_RADIUS_MIN = 0.72;
const float OC_PLANET_RADIUS_MAX = 1.62;
const float OC_SIZE_PULSE = 0.10;
const vec3 OC_LIGHT_DIRECTION = vec3(-0.62, 0.72, 1.25);
const float OC_AXIAL_TILT = 0.34;
const float OC_SURFACE_SPIN_SPEED = 1.25;
const float OC_LATITUDE_COUNT = 6.0;
const float OC_LONGITUDE_COUNT = 10.0;
const float OC_GRID_CORE_WIDTH = 0.032;
const float OC_GRID_GLOW_WIDTH = 0.110;
const float OC_GRID_CORE_STRENGTH = 0.54;
const float OC_GRID_GLOW_STRENGTH = 0.10;
const float OC_GRID_BACK_STRENGTH = 0.24;
const float OC_GRID_POLE_FADE_START = 0.055;
const float OC_GRID_POLE_FADE_END = 0.20;
const float OC_SILHOUETTE_CORE_WIDTH = 0.020;
const float OC_SILHOUETTE_GLOW_WIDTH = 0.082;
const float OC_SILHOUETTE_CORE_STRENGTH = 0.64;
const float OC_SILHOUETTE_GLOW_STRENGTH = 0.13;
const float OC_RING_BACK_VISIBILITY = 0.30;
const float OC_MOON_BACK_VISIBILITY = 0.24;
const float OC_GRID_AMBIENT_LIGHT = 0.46;
const float OC_GRID_DIFFUSE_LIGHT = 0.54;

const float OC_RING_RADIUS_START = 1.34;
const float OC_RING_RADIUS_SPACING = 0.28;
const float OC_RING_COMPRESSION = 0.34;
const float OC_RING_ROLL = -0.38;
const float OC_RING_ROLL_SPEED = 0.72;
const float OC_RING_WIDTH = 0.028;
const float OC_RING_GLOW_WIDTH = 0.090;
const float OC_RING_CORE_STRENGTH = 0.40;
const float OC_RING_GLOW_STRENGTH = 0.085;
const float OC_RING_STRENGTH_FALLOFF = 0.76;
const float OC_RING_DASH_COUNT = 9.0;
const float OC_RING_DASH_SPEED = 1.70;
const float OC_RING_DASH_STRENGTH = 0.28;

const float OC_MOON_ORBIT_RADIUS = 1.78;
const float OC_MOON_ORBIT_SPACING = 0.34;
const float OC_MOON_ORBIT_SPEED = 2.10;
const float OC_MOON_ORBIT_SPEED_STEP = 0.55;
const float OC_MOON_RADIUS = 0.13;
const float OC_MOON_RADIUS_FALLOFF = 0.82;
const float OC_MOON_BODY_STRENGTH = 0.72;
const float OC_MOON_GLOW_RADIUS = 2.70;
const float OC_MOON_GLOW_STRENGTH = 0.12;

const float OC_PULSE_START_SCALE = 1.04;
const float OC_PULSE_END_SCALE = 2.55;
const float OC_PULSE_DELAY = 0.14;
const float OC_PULSE_WIDTH = 0.030;
const float OC_PULSE_GLOW_WIDTH = 0.095;
const float OC_PULSE_STRENGTH = 0.18;
const float OC_PULSE_FALLOFF = 0.68;

const float OC_TRAIL_WIDTH_MIN = 0.12;
const float OC_TRAIL_WIDTH_MAX = 0.26;
const float OC_TRAIL_GLOW_MULTIPLIER = 4.20;
const float OC_TRAIL_GLOW_STRENGTH = 0.052;
const float OC_TRAIL_CORE_STRENGTH = 0.22;
const float OC_TRAIL_TAIL_FADE = 0.20;
const float OC_STAR_RADIUS = 0.070;
const float OC_STAR_SPREAD = 1.80;
const float OC_STAR_STRENGTH = 0.24;

const float OC_LINK_WIDTH = 0.060;
const float OC_LINK_GLOW_WIDTH = 0.25;
const float OC_LINK_CORE_STRENGTH = 0.045;
const float OC_LINK_GLOW_STRENGTH = 0.011;
const float OC_LINK_DASH_COUNT = 20.0;
const float OC_LINK_DASH_SPEED = 1.55;
const float OC_LINK_SECONDARY_FALLOFF = 0.72;
const float OC_LINK_COLOR_PHASE_STEP = 0.23;
// Movement factor 0..1 also drives link thickness, glow, energy, and dash density.
// MIN values apply to tiny cursor moves; MAX values apply at GROWTH_FULL_CELLS.
const float OC_LINK_MOVEMENT_POWER = 1.15;
const float OC_LINK_WIDTH_MIN_SCALE = 0.28;
const float OC_LINK_WIDTH_MAX_SCALE = 1.35;
const float OC_LINK_GLOW_WIDTH_MIN_SCALE = 0.22;
const float OC_LINK_GLOW_WIDTH_MAX_SCALE = 1.45;
const float OC_LINK_INTENSITY_MIN_SCALE = 0.10;
const float OC_LINK_INTENSITY_MAX_SCALE = 1.25;
const float OC_LINK_DASH_DENSITY_MIN_SCALE = 0.42;
const float OC_LINK_DASH_DENSITY_MAX_SCALE = 1.30;
const float OC_LINK_DASH_SPEED_MIN_SCALE = 0.40;
const float OC_LINK_DASH_SPEED_MAX_SCALE = 1.25;
const float OC_LINK_CULL_MIN_SCALE = 0.55;
const float OC_LINK_CULL_MAX_SCALE = 1.70;
const float OC_LINK_CULL_MIN_PIXELS = 4.0;
const float OC_LINK_ENDPOINT_GLOW = 0.085;

const vec3 OC_VOID = vec3(0.010, 0.018, 0.070);
const vec3 OC_BLUE = vec3(0.090, 0.340, 0.960);
const vec3 OC_CYAN = vec3(0.140, 0.860, 1.000);
const vec3 OC_TEAL = vec3(0.100, 0.740, 0.650);
const vec3 OC_VIOLET = vec3(0.600, 0.240, 1.000);
const vec3 OC_ROSE = vec3(0.950, 0.220, 0.620);
const vec3 OC_PINK = vec3(0.980, 0.240, 0.690);
const vec3 OC_WHITE = vec3(0.970, 0.980, 1.000);
const float OC_PI = 3.14159265359;
const float OC_TAU = 6.28318530718;

vec2 ocCursorCenterPixels(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}

vec2 ocScenePoint(vec2 pixelPoint) {
    return (pixelPoint - 0.5 * iResolution.xy) / max(iResolution.y, 1.0);
}

float ocInsideCursor(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(cursorRectangle.x, cursorRectangle.y - cursorRectangle.w);
    vec2 maximumPoint = vec2(cursorRectangle.x + cursorRectangle.z, cursorRectangle.y);
    return step(minimumPoint.x, point.x) * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x) * step(point.y, maximumPoint.y);
}

void applyOrbitalOrreryCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = ocCursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = ocCursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / OC_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * OC_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = pow(
        smoothstep(
            cursorPixels * OC_GROWTH_START_CELLS,
            cursorPixels * OC_GROWTH_FULL_CELLS,
            movedPixels
        ),
        OC_MOVEMENT_RESPONSE_POWER
    );
    float linkMovementFactor = pow(movementFactor, OC_LINK_MOVEMENT_POWER);
    float linkWidthScale = mix(
        OC_LINK_WIDTH_MIN_SCALE,
        OC_LINK_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkGlowWidthScale = mix(
        OC_LINK_GLOW_WIDTH_MIN_SCALE,
        OC_LINK_GLOW_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkIntensityScale = mix(
        OC_LINK_INTENSITY_MIN_SCALE,
        OC_LINK_INTENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashDensityScale = mix(
        OC_LINK_DASH_DENSITY_MIN_SCALE,
        OC_LINK_DASH_DENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashSpeedScale = mix(
        OC_LINK_DASH_SPEED_MIN_SCALE,
        OC_LINK_DASH_SPEED_MAX_SCALE,
        linkMovementFactor
    );
    float linkCullScale = mix(
        OC_LINK_CULL_MIN_SCALE,
        OC_LINK_CULL_MAX_SCALE,
        linkMovementFactor
    );
    float cullRadius = cursorPixels * mix(
        OC_CULL_RADIUS_MIN,
        OC_CULL_RADIUS_MAX,
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
        OC_LINK_CULL_MIN_PIXELS
    );
    bool nearAnyLink = false;
#if OC_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < ORB_OBJECT_COUNT; linkIndex++) {
        if (OC_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = orbUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        nearAnyLink = nearAnyLink || linkPixelDistance <= linkCull;
    }
#endif
    if (!nearCursor && !nearAnyLink) return;

    vec2 point = ocScenePoint(fragCoord);
    vec2 head = ocScenePoint(headPixels);
    vec2 tail = ocScenePoint(tailPixels);
    vec2 movement = head - tail;
    vec2 direction = movement / max(length(movement), 0.000001);
    vec2 normal2d = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - age, OC_FADE_POWER);
    float contentMask = mix(OC_CONTENT_PROTECTION, 1.0, backgroundCellMask(terminalColor));

#if OC_ENABLE_RESONANCE_LINK
    for (int linkIndex = 0; linkIndex < ORB_OBJECT_COUNT; linkIndex++) {
        if (OC_LINK_ALL_OBJECTS == 0 && linkIndex > 0) continue;
        float linkIdentity = float(linkIndex);
        vec2 linkObjectPixels = orbUv(iTime, linkIdentity) * resolution;
        float linkPixelDistance = segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels
        );
        if (linkPixelDistance > linkCull) continue;

        vec2 linkObject = ocScenePoint(linkObjectPixels);
        float linkDistance = segmentDistance(point, head, linkObject);
        float linkAlong = segmentParameter(point, head, linkObject);
        float linkStrength = pow(OC_LINK_SECONDARY_FALLOFF, linkIdentity);
        float linkColorMix = saturate(
            linkAlong * 0.78 + linkIdentity * OC_LINK_COLOR_PHASE_STEP
        );
        float dash = 0.64 + 0.36 * sin(
            linkAlong * OC_LINK_DASH_COUNT * linkDashDensityScale
            - iTime * OC_LINK_DASH_SPEED * linkDashSpeedScale
            + linkIdentity * 2.17
        );
        float linkCore = exp(
            -linkDistance / max(cursorSize * OC_LINK_WIDTH * linkWidthScale, 0.0002)
        );
        float linkGlow = exp(
            -linkDistance / max(cursorSize * OC_LINK_GLOW_WIDTH * linkGlowWidthScale, 0.0005)
        );
        vec3 linkColor = mix(OC_PINK, OC_CYAN, linkColorMix);
        scene.rgb += linkColor * dash * linkStrength * linkIntensityScale
            * life * contentMask * (
            linkCore * OC_LINK_CORE_STRENGTH
            + linkGlow * OC_LINK_GLOW_STRENGTH
        );
        float endpoint = gaussianPoint(
            point - linkObject,
            cursorSize * 0.74
        );
        vec3 endpointColor = mix(
            OC_PINK,
            OC_CYAN,
            saturate(0.78 + linkIdentity * OC_LINK_COLOR_PHASE_STEP)
        );
        scene.rgb += endpointColor * endpoint * linkStrength * life
            * linkIntensityScale * OC_LINK_ENDPOINT_GLOW * contentMask;
    }
#endif

    if (nearCursor) {
#if OC_ENABLE_TRAIL
        float trailDistance = segmentDistance(point, tail, head);
        float along = segmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            OC_TRAIL_WIDTH_MIN,
            OC_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, OC_TRAIL_TAIL_FADE, along) * life;
        float trailGlow = exp(
            -trailDistance / max(trailWidth * OC_TRAIL_GLOW_MULTIPLIER, 0.0004)
        ) * smoothstep(0.0, OC_TRAIL_TAIL_FADE * 0.84, along) * life;
        vec3 trailColor = mix(OC_VIOLET, OC_CYAN, along);
        trailColor = mix(trailColor, OC_PINK, smoothstep(0.76, 1.0, along) * 0.48);
        scene.rgb += trailColor * trailGlow * OC_TRAIL_GLOW_STRENGTH * contentMask;
        scene.rgb += trailColor * trailCore * OC_TRAIL_CORE_STRENGTH * contentMask;
#endif

        float planetRadius = cursorSize * mix(
            OC_PLANET_RADIUS_MIN,
            OC_PLANET_RADIUS_MAX,
            movementFactor
        ) * (1.0 + OC_SIZE_PULSE * sin(age * OC_PI));
        vec2 local = (point - head) / max(planetRadius, 0.0001);
        float radial = length(local);
        float sphereAa = max(fwidth(radial), 0.003);
        float sphereCoverage = 1.0 - smoothstep(1.0 - sphereAa, 1.0 + sphereAa, radial);
        vec3 cursorLight = vec3(0.0);

        if (radial < 1.0 + sphereAa * 2.0) {
            float z = sqrt(max(1.0 - dot(local, local), 0.0));
            vec3 frontNormal = normalize(vec3(local, z));
            vec3 backNormal = normalize(vec3(local, -z));
            float spin = iTime * OC_SURFACE_SPIN_SPEED;
            vec3 frontGridNormal = rotateY(rotateX(frontNormal, OC_AXIAL_TILT), spin);
            vec3 backGridNormal = rotateY(rotateX(backNormal, OC_AXIAL_TILT), spin);
            float frontCore, frontGlow, backCore, backGlow;
            float pixelRadius = max(planetRadius * resolution.y, 1.0);
            sphericalGridMask(
                frontGridNormal,
                OC_LATITUDE_COUNT,
                OC_LONGITUDE_COUNT,
                OC_GRID_CORE_WIDTH,
                OC_GRID_GLOW_WIDTH,
                pixelRadius,
                OC_GRID_POLE_FADE_START,
                OC_GRID_POLE_FADE_END,
                frontCore,
                frontGlow
            );
            sphericalGridMask(
                backGridNormal,
                OC_LATITUDE_COUNT,
                OC_LONGITUDE_COUNT,
                OC_GRID_CORE_WIDTH,
                OC_GRID_GLOW_WIDTH,
                pixelRadius,
                OC_GRID_POLE_FADE_START,
                OC_GRID_POLE_FADE_END,
                backCore,
                backGlow
            );
            vec3 lightDirection = normalize(OC_LIGHT_DIRECTION);
            float diffuse = OC_GRID_AMBIENT_LIGHT + OC_GRID_DIFFUSE_LIGHT
                * max(dot(frontNormal, lightDirection), 0.0);
            vec3 frontColor = mix(
                OC_BLUE,
                OC_CYAN,
                0.58 + 0.22 * frontGridNormal.y
            ) * diffuse;
            vec3 backColor = mix(OC_VIOLET, OC_BLUE, 0.48);
            cursorLight += frontColor * (
                frontCore * OC_GRID_CORE_STRENGTH
                + frontGlow * OC_GRID_GLOW_STRENGTH
            );
            cursorLight += backColor * OC_GRID_BACK_STRENGTH * (
                backCore * OC_GRID_CORE_STRENGTH
                + backGlow * OC_GRID_GLOW_STRENGTH
            );
            float silhouetteDistance = abs(radial - 1.0);
            float silhouetteCore = exp(
                -silhouetteDistance / max(OC_SILHOUETTE_CORE_WIDTH, 0.001)
            );
            float silhouetteGlow = exp(
                -silhouetteDistance / max(OC_SILHOUETTE_GLOW_WIDTH, 0.002)
            );
            cursorLight += mix(OC_CYAN, OC_VIOLET, 0.42) * (
                silhouetteCore * OC_SILHOUETTE_CORE_STRENGTH
                + silhouetteGlow * OC_SILHOUETTE_GLOW_STRENGTH
            );
        }

        float ringRoll = OC_RING_ROLL + iTime * OC_RING_ROLL_SPEED;
        vec2 ringLocal = rotate2d((point - head) / max(planetRadius, 0.0001), -ringRoll);
        vec2 ellipsePoint = vec2(ringLocal.x, ringLocal.y / max(OC_RING_COMPRESSION, 0.04));
        float ellipseRadius = length(ellipsePoint);
        float ellipseAngle = atan(ellipsePoint.y, ellipsePoint.x);
        float frontHalf = step(0.0, ringLocal.y);
        for (int ringIndex = 0; ringIndex < OC_RING_COUNT; ringIndex++) {
            float index = float(ringIndex);
            float targetRadius = OC_RING_RADIUS_START + index * OC_RING_RADIUS_SPACING;
            float ringDistance = abs(ellipseRadius - targetRadius);
            float core = exp(-ringDistance / max(OC_RING_WIDTH, 0.001));
            float glow = exp(-ringDistance / max(OC_RING_GLOW_WIDTH, 0.002));
            float dash = mix(
                1.0,
                0.5 + 0.5 * sin(
                    ellipseAngle * OC_RING_DASH_COUNT
                    - iTime * OC_RING_DASH_SPEED * (1.0 + index * 0.17)
                ),
                OC_RING_DASH_STRENGTH
            );
            float insideVisibility = mix(
                OC_RING_BACK_VISIBILITY,
                1.0,
                frontHalf
            );
            float occlusion = mix(1.0, insideVisibility, sphereCoverage);
            float ringStrength = pow(OC_RING_STRENGTH_FALLOFF, index);
            vec3 ringColor = mix(OC_PINK, OC_CYAN, index / max(float(OC_RING_COUNT - 1), 1.0));
            cursorLight += ringColor * occlusion * dash * ringStrength * (
                core * OC_RING_CORE_STRENGTH + glow * OC_RING_GLOW_STRENGTH
            );
        }

        for (int moonIndex = 0; moonIndex < OC_MOON_COUNT; moonIndex++) {
            float index = float(moonIndex);
            float orbitRadius = OC_MOON_ORBIT_RADIUS + index * OC_MOON_ORBIT_SPACING;
            float orbitAngle = iTime * (
                OC_MOON_ORBIT_SPEED + index * OC_MOON_ORBIT_SPEED_STEP
            ) + index * OC_TAU / max(float(OC_MOON_COUNT), 1.0);
            float orbitDepth = sin(orbitAngle);
            vec2 orbitPlane = vec2(
                cos(orbitAngle) * orbitRadius,
                orbitDepth * orbitRadius * OC_RING_COMPRESSION
            );
            vec2 moonCenter = head + rotate2d(orbitPlane, ringRoll) * planetRadius;
            float moonRadius = planetRadius * OC_MOON_RADIUS * pow(OC_MOON_RADIUS_FALLOFF, index);
            vec2 moonDelta = point - moonCenter;
            float moonCoverage = 1.0 - smoothstep(
                moonRadius * 0.86,
                moonRadius * 1.10,
                length(moonDelta)
            );
            float behind = 1.0 - step(0.0, orbitDepth);
            float moonOcclusion = 1.0 - behind * sphereCoverage
                * (1.0 - OC_MOON_BACK_VISIBILITY);
            float moonGlow = gaussianPoint(moonDelta, moonRadius * OC_MOON_GLOW_RADIUS);
            vec3 moonColor = mix(OC_WHITE, OC_CYAN, index * 0.28);
            cursorLight += moonColor * moonOcclusion * (
                moonCoverage * OC_MOON_BODY_STRENGTH
                + moonGlow * OC_MOON_GLOW_STRENGTH
            );
        }

        for (int pulseIndex = 0; pulseIndex < OC_PULSE_COUNT; pulseIndex++) {
            float index = float(pulseIndex);
            float delay = index * OC_PULSE_DELAY;
            float progress = saturate((easedAge - delay) / max(1.0 - delay, 0.001));
            float pulseActive = step(delay, easedAge);
            float pulseScale = mix(OC_PULSE_START_SCALE, OC_PULSE_END_SCALE, progress);
            float pulseDistance = abs(ellipseRadius - pulseScale);
            float core = exp(-pulseDistance / max(OC_PULSE_WIDTH, 0.001));
            float glow = exp(-pulseDistance / max(OC_PULSE_GLOW_WIDTH, 0.002));
            cursorLight += mix(OC_CYAN, OC_VIOLET, index * 0.35)
                * (core + glow * 0.32) * (1.0 - progress) * pulseActive
                * OC_PULSE_STRENGTH * pow(OC_PULSE_FALLOFF, index);
        }

        scene.rgb += cursorLight * life * contentMask * OC_MASTER_BRIGHTNESS;

#if OC_ENABLE_STARS && OC_STAR_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int starIndex = 0; starIndex < OC_STAR_COUNT; starIndex++) {
            float index = float(starIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 starCenter = mix(tail, head, positionRandom)
                + normal2d * (sideRandom - 0.5) * cursorSize * OC_STAR_SPREAD;
            float star = gaussianPoint(point - starCenter, cursorSize * OC_STAR_RADIUS) * life;
            scene.rgb += mix(OC_CYAN, OC_PINK, sideRandom)
                * star * OC_STAR_STRENGTH * contentMask;
        }
#endif
    }

    float cursorCoverage = ocInsideCursor(fragCoord, iCurrentCursor);
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
    renderOrbitalBackground(wallpaperColor, fragCoord);
    fragColor = compositeGeometryBehindTerminal(wallpaperColor, terminalColor);

    // The matching movement effect is applied after the terminal foreground,
    // while the real Ghostty cursor rectangle remains exact inside its bounds.
    applyOrbitalOrreryCursor(fragColor, fragCoord);
    fragColor.a = terminalColor.a;
}
