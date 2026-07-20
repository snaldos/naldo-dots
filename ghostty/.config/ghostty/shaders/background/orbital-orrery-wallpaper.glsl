// BACKGROUND-ONLY WALLPAPER VARIANT: orbital-orrery
// Procedural geometry is composited behind exact terminal foreground.
// Pair this stage with any independently selected cursor shader.

// Orbital Orrery — coordinated floating planets and miniature cursor system
//
// Wandering ringed planets share their palette with a movement-scaled cursor
// planet, projected rings, orbiting moons, expanding orbital pulses, and an
// optional resonance filament to the primary world. Every quantity and motion
// scale is independently tunable below.

// Orbital Orbs — configurable floating 3D planets, rings, and moons for Ghostty
// Analytic sphere normals provide real lighting while projected orbital planes
// split rings and moons into front/back layers around each wandering orb.

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
// PLANET SURFACE AND SPIN
// =============================================================================

const float ORB_SPIN_SPEED = 0.22;
const float ORB_SPIN_SPEED_STEP = 0.07;
const float ORB_AXIAL_TILT = 0.34;
const float ORB_BAND_COUNT = 8.0;
const float ORB_BAND_WARP = 0.72;
const float ORB_BAND_LONGITUDE_FREQUENCY = 3.0;
const float ORB_BAND_FLOW_SPEED = 0.13;
const float ORB_BAND_CONTRAST = 0.48;
const float ORB_STORM_FREQUENCY = 6.0;
const float ORB_STORM_STRENGTH = 0.14;
const vec3 ORB_LIGHT_DIRECTION = vec3(-0.62, 0.72, 1.25);
const float ORB_AMBIENT_LIGHT = 0.14;
const float ORB_DIFFUSE_LIGHT = 0.86;
const float ORB_FRESNEL_POWER = 2.10;
const float ORB_FRESNEL_STRENGTH = 0.34;
const float ORB_SPECULAR_POWER = 42.0;
const float ORB_SPECULAR_STRENGTH = 0.72;
const float ORB_TERMINATOR_SOFTNESS = 0.16;

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
const float ORB_BODY_BLEND = 0.52;
const float ORB_BODY_OPACITY = 0.36;
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
const vec3 ORB_GOLD       = vec3(1.000, 0.700, 0.260);
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
    vec3 bodyColor;
    vec3 radiance;
    float coverage;
    float opacity;
};

OrbSample renderOrb(vec2 point, vec2 center, float radius, float identity) {
    vec2 local = (point - center) / max(radius, 0.0001);
    float radial = length(local);
    float sphereAa = max(fwidth(radial), 0.002);
    float sphereCoverage = 1.0 - smoothstep(1.0 - sphereAa, 1.0 + sphereAa, radial);
    vec3 bodyColor = vec3(0.0);
    vec3 radiance = vec3(0.0);
    float opacity = 0.0;

    if (radial < 1.0 + sphereAa * 2.0) {
        float z = sqrt(max(1.0 - dot(local, local), 0.0));
        vec3 normal = normalize(vec3(local, z));
        float spin = iTime * (ORB_SPIN_SPEED + identity * ORB_SPIN_SPEED_STEP);
        vec3 textureNormal = rotateY(rotateX(normal, ORB_AXIAL_TILT), spin);
        float longitude = atan(textureNormal.z, textureNormal.x);
        float latitude = asin(clamp(textureNormal.y, -1.0, 1.0));
        float bands = 0.5 + 0.5 * sin(
            latitude * ORB_BAND_COUNT
            + sin(longitude * ORB_BAND_LONGITUDE_FREQUENCY) * ORB_BAND_WARP
            + iTime * ORB_BAND_FLOW_SPEED
            + identity * 1.7
        );
        bands = mix(0.5, smoothstep(0.18, 0.82, bands), ORB_BAND_CONTRAST);
        float storm = 0.5 + 0.5 * sin(
            longitude * ORB_STORM_FREQUENCY
            + latitude * 3.0
            - iTime * ORB_BAND_FLOW_SPEED * 0.7
        );
        float paletteBase = identity * 0.29 + bands * 0.22 + storm * ORB_STORM_STRENGTH;
        vec3 darkColor = mix(ORB_VOID, orbPalette(paletteBase), 0.62);
        vec3 lightColor = orbPalette(paletteBase + 0.18);

        vec3 lightDirection = normalize(ORB_LIGHT_DIRECTION);
        float diffuseRaw = dot(normal, lightDirection);
        float diffuse = ORB_AMBIENT_LIGHT + ORB_DIFFUSE_LIGHT
            * smoothstep(-ORB_TERMINATOR_SOFTNESS, ORB_TERMINATOR_SOFTNESS, diffuseRaw);
        float fresnel = pow(1.0 - max(normal.z, 0.0), ORB_FRESNEL_POWER);
        float specular = pow(
            max(dot(reflect(-lightDirection, normal), vec3(0.0, 0.0, 1.0)), 0.0),
            ORB_SPECULAR_POWER
        );
        bodyColor = mix(darkColor, lightColor, diffuse * 0.66 + bands * 0.14);
        bodyColor *= mix(0.42, 1.08, diffuse);
        radiance += mix(ORB_CYAN, ORB_VIOLET, identity * 0.31)
            * fresnel * ORB_FRESNEL_STRENGTH * sphereCoverage;
        radiance += ORB_WHITE * specular * ORB_SPECULAR_STRENGTH
            * ORB_PROFILE_SPECULAR_GAIN * sphereCoverage;
        opacity = max(opacity, sphereCoverage * ORB_BODY_OPACITY);
    }

#if ORB_ENABLE_ATMOSPHERE
    float atmosphereBand = exp(
        -abs(radial - 1.0) / max(ORB_ATMOSPHERE_RIM_WIDTH, 0.001)
    ) * (1.0 - smoothstep(ORB_ATMOSPHERE_RADIUS, ORB_ATMOSPHERE_RADIUS + 0.08, radial));
    float atmosphereHalo = gaussianPoint(point - center, radius * ORB_ATMOSPHERE_HALO_RADIUS);
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
        float occlusion = mix(1.0, frontHalf, sphereCoverage);
        float ringStrength = pow(ORB_RING_STRENGTH_FALLOFF, index);
        vec3 ringColor = mix(
            mix(ORB_GOLD, ORB_ROSE, fract(identity * 0.31)),
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
        float moonOcclusion = 1.0 - behind * sphereCoverage;
        vec3 moonColor = mix(ORB_WHITE, orbPalette(identity * 0.29 + index * 0.23), 0.52);
        float moonShade = 0.35 + 0.65 * saturate(
            dot(normalize(vec3(moonDelta / max(moonRadius, 0.0001), 0.65)), normalize(ORB_LIGHT_DIRECTION))
        );
        float moonGlow = gaussianPoint(moonDelta, moonRadius * ORB_MOON_GLOW_RADIUS);
        radiance += moonColor * moonOcclusion * (
            moonCoverage * moonShade * ORB_MOON_BODY_STRENGTH
            + moonGlow * ORB_MOON_GLOW_STRENGTH
        );
        opacity = max(opacity, moonOcclusion * (moonCoverage * 0.42 + moonGlow * 0.035));
    }

    return OrbSample(bodyColor, radiance, sphereCoverage, saturate(opacity));
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
            vec3 bodyTarget = mix(ORB_VOID, sampleValue.bodyColor, 0.90);
            composite = mix(
                composite,
                bodyTarget,
                sampleValue.coverage * ORB_BODY_BLEND * backgroundMask
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
}
