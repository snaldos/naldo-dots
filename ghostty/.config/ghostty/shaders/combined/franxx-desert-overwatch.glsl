// FRANXX Desert Overwatch — oblique top-down battlefield + Strelizia cursor
//
// An original procedural Ghostty scene inspired by the aerial desert views and
// large mobile plantations of Darling in the Franxx. The camera looks down from
// high altitude: every screen pixel maps onto one continuous ground plane, so
// dunes, tracks, the circular base, top-view Klaxosaurs, FRANXX units, combat
// rays, explosions, shadows, drifting clouds, and windblown sand share one
// coherent pseudo-3D perspective.
//
// Cursor movement deploys a top-view Strelizia-inspired red/ivory machine with
// a cyan canopy, long spear, articulated fins, braided partner trails, thruster
// light, and a sand-pressure wake. The actual terminal cursor is restored after
// compositing, and foreground glyphs remain protected.
//
// No external textures, artwork, or shader code are used.
//
// Ghostty shader manager:
//   ghostty-shaders.sh set combined franxx-desert-overwatch
//   ghostty-shaders.sh set-profile balanced
//
// Uses iChannel0, iResolution, iTime, iBackgroundColor, cursor uniforms, and
// mainImage. custom-shader-animation must be enabled.

// =============================================================================
// GPU PERFORMANCE PROFILE
// =============================================================================

#define OVERWATCH_GPU_ECO      0
#define OVERWATCH_GPU_BALANCED 1
#define OVERWATCH_GPU_QUALITY  2
#define OVERWATCH_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE OVERWATCH_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == OVERWATCH_GPU_ECO
#define PERF_FBM_OCTAVES        3
#define PERF_MICRO_SAND_LAYERS  1
#define PERF_KLAXOSAURS         2
#define PERF_FRANXX_UNITS       2
#define PERF_EXPLOSION_SPARKS   2
#define PERF_CURSOR_SPARKS      1
#define PERF_SECOND_EXPLOSION   0
#define PERF_SECONDARY_LANCE    0
#elif GHOSTTY_GPU_PROFILE == OVERWATCH_GPU_BALANCED
#define PERF_FBM_OCTAVES        4
#define PERF_MICRO_SAND_LAYERS  2
#define PERF_KLAXOSAURS         3
#define PERF_FRANXX_UNITS       3
#define PERF_EXPLOSION_SPARKS   4
#define PERF_CURSOR_SPARKS      3
#define PERF_SECOND_EXPLOSION   1
#define PERF_SECONDARY_LANCE    1
#elif GHOSTTY_GPU_PROFILE == OVERWATCH_GPU_QUALITY
#define PERF_FBM_OCTAVES        5
#define PERF_MICRO_SAND_LAYERS  3
#define PERF_KLAXOSAURS         3
#define PERF_FRANXX_UNITS       4
#define PERF_EXPLOSION_SPARKS   6
#define PERF_CURSOR_SPARKS      5
#define PERF_SECOND_EXPLOSION   1
#define PERF_SECONDARY_LANCE    1
#else
#define PERF_FBM_OCTAVES        5
#define PERF_MICRO_SAND_LAYERS  4
#define PERF_KLAXOSAURS         4
#define PERF_FRANXX_UNITS       4
#define PERF_EXPLOSION_SPARKS   9
#define PERF_CURSOR_SPARKS      8
#define PERF_SECOND_EXPLOSION   1
#define PERF_SECONDARY_LANCE    1
#endif

// =============================================================================
// ART DIRECTION AND CAMERA
// =============================================================================

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

// Camera height and downward pitch create an oblique aerial projection. The
// upper edge remains ground rather than becoming a separate sky band.
const float CAMERA_HEIGHT = 2.10;
const float CAMERA_PITCH = 0.837758041; // 48 degrees below the horizon.
const float CAMERA_FOV = 0.94;

const float TERMINAL_BACKGROUND_DARKEN = 0.50;
const float AERIAL_SCENE_MIX = 0.84;
const float SCENE_ALPHA_BOOST = 0.075;
const float SCENE_EXPOSURE = 1.10;
const float VIGNETTE_STRENGTH = 0.13;

const vec3 SAND_DEEP       = vec3(0.110, 0.040, 0.030);
const vec3 SAND_BASE       = vec3(0.205, 0.078, 0.046);
const vec3 SAND_WARM       = vec3(0.360, 0.155, 0.078);
const vec3 SAND_LIGHT      = vec3(0.620, 0.330, 0.160);
const vec3 SAND_PALE       = vec3(0.850, 0.610, 0.350);
const vec3 FAR_HAZE        = vec3(0.185, 0.105, 0.105);
const vec3 CLOUD_SHADOW    = vec3(0.050, 0.040, 0.055);
const vec3 CLOUD_LIGHT     = vec3(0.540, 0.455, 0.420);
const vec3 ROAD_DARK       = vec3(0.070, 0.052, 0.052);
const vec3 BASE_DARK       = vec3(0.045, 0.046, 0.060);
const vec3 BASE_STEEL      = vec3(0.235, 0.235, 0.255);
const vec3 BASE_LIGHT      = vec3(0.570, 0.525, 0.455);
const vec3 BASE_AMBER      = vec3(1.000, 0.540, 0.120);
const vec3 KLAX_DARK       = vec3(0.004, 0.014, 0.038);
const vec3 KLAX_BLUE       = vec3(0.000, 0.300, 0.900);
const vec3 KLAX_CYAN       = vec3(0.000, 0.820, 1.000);
const vec3 FRANXX_DARK     = vec3(0.035, 0.028, 0.038);
const vec3 FRANXX_RED      = vec3(0.970, 0.018, 0.105);
const vec3 FRANXX_ROSE     = vec3(1.000, 0.170, 0.340);
const vec3 FRANXX_IVORY    = vec3(0.945, 0.890, 0.750);
const vec3 FRANXX_CYAN     = vec3(0.130, 0.760, 0.960);
const vec3 ENERGY_WHITE    = vec3(1.000, 0.975, 0.840);
const vec3 FIRE_GOLD       = vec3(1.000, 0.430, 0.050);
const vec3 FIRE_RED        = vec3(0.960, 0.030, 0.018);
const vec3 SMOKE_DUST      = vec3(0.160, 0.075, 0.050);

// =============================================================================
// SHARED HELPERS
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

float hash13(vec3 point) {
    point = fract(point * 0.1031);
    point += dot(point, point.yzx + 33.33);
    return fract((point.x + point.y) * point.z);
}

vec2 hash22(vec2 point) {
    float first = hash12(point);
    return vec2(first, hash12(point + first + 17.17));
}

vec2 hash23(vec3 point) {
    return vec2(
        hash13(point + vec3(17.17, 43.71, 11.13)),
        hash13(point + vec3(83.91, 19.19, 61.73))
    );
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * point;
}

float valueNoise(vec2 point) {
    vec2 cell = floor(point);
    vec2 local = fract(point);
    local = local * local * (3.0 - 2.0 * local);
    float a = hash12(cell);
    float b = hash12(cell + vec2(1.0, 0.0));
    float c = hash12(cell + vec2(0.0, 1.0));
    float d = hash12(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fbm(vec2 point) {
    float result = 0.0;
    float amplitude = 0.52;
    for (int octave = 0; octave < PERF_FBM_OCTAVES; octave++) {
        result += amplitude * valueNoise(point);
        point = rotate2d(point * 2.03, 0.39) + vec2(11.7, 7.3);
        amplitude *= 0.48;
    }
    return result;
}

float sdBox(vec2 point, vec2 halfSize) {
    vec2 q = abs(point) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float sdEllipse(vec2 point, vec2 radii) {
    vec2 safeRadii = max(radii, vec2(0.000001));
    return (length(point / safeRadii) - 1.0)
        * min(safeRadii.x, safeRadii.y);
}

float segmentParameter(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    return clamp(
        dot(point - startPoint, segment)
            / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );
}

float segmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    float along = segmentParameter(point, startPoint, endPoint);
    return length(point - mix(startPoint, endPoint, along));
}

float sdCapsule(
    vec2 point,
    vec2 startPoint,
    vec2 endPoint,
    float radius
) {
    return segmentDistance(point, startPoint, endPoint) - radius;
}

float fillSdf(float distanceValue) {
    float aa = max(fwidth(distanceValue), 0.00012);
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float strokeSdf(float distanceValue, float width) {
    float aa = max(fwidth(distanceValue), 0.00012);
    return 1.0 - smoothstep(
        max(width - aa, 0.0),
        width + aa,
        abs(distanceValue)
    );
}

float softOutside(float distanceValue, float radius) {
    return exp(-max(distanceValue, 0.0) / max(radius, 0.000001));
}

float gaussianPoint(vec2 delta, float radius) {
    return exp(
        -dot(delta, delta) / max(radius * radius, 0.000001)
    );
}

float eventLife(float age) {
    float activeMask = step(0.0, age) * (1.0 - step(1.0, age));
    float boundedAge = saturate(age);
    return activeMask
        * smoothstep(0.0, 0.055, boundedAge)
        * (1.0 - smoothstep(0.68, 1.0, boundedAge));
}

float backgroundCellMask(vec4 terminalColor) {
    float colorDifference = length(terminalColor.rgb - iBackgroundColor);
    float colorMatch = 1.0 - smoothstep(0.028, 0.235, colorDifference);
    float darkFallback = 1.0 - smoothstep(
        0.10,
        0.54,
        luminance(terminalColor.rgb)
    );
    float transparent = 1.0 - smoothstep(0.74, 0.99, terminalColor.a);
    return saturate(max(colorMatch, darkFallback * transparent * 0.38));
}

// =============================================================================
// OBLIQUE AERIAL CAMERA
// =============================================================================

struct GroundView {
    vec2 point;
    float rayLength;
    float farFade;
};

GroundView groundFromScreen(vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 screen = (fragCoord / resolution - 0.5) * vec2(aspect, 1.0);
    // Zoom out isotropically in narrow splits. This keeps the plantation and
    // creatures visible instead of cropping them while retaining true ground
    // perspective and a downward-pointing ray at the upper edge.
    float narrowZoom = clamp(
        1.05 / max(aspect, 0.45),
        1.0,
        1.85
    );
    screen *= narrowZoom;

    float cosinePitch = cos(CAMERA_PITCH);
    float sinePitch = sin(CAMERA_PITCH);
    vec3 forward = vec3(0.0, cosinePitch, -sinePitch);
    vec3 cameraUp = vec3(0.0, sinePitch, cosinePitch);
    vec3 cameraRight = vec3(1.0, 0.0, 0.0);
    vec3 ray = normalize(
        forward
            + cameraRight * screen.x * CAMERA_FOV
            + cameraUp * screen.y * CAMERA_FOV
    );

    vec2 cameraDrift = vec2(
        0.055 * sin(iTime * 0.009),
        0.040 * sin(iTime * 0.0067 + 1.8)
    );
    float intersection = CAMERA_HEIGHT / max(-ray.z, 0.08);
    vec2 groundPoint = cameraDrift + ray.xy * intersection;
    float farFade = smoothstep(3.65, 5.25, groundPoint.y);
    return GroundView(groundPoint, intersection, farFade);
}

// =============================================================================
// DESERT GROUND: DUNES, WIND RIPPLES, AND AERIAL DEPTH
// =============================================================================

vec3 renderDesertGround(
    vec2 ground,
    float farFade,
    out float looseSand
) {
    vec2 broadPoint = ground * 0.34 + vec2(7.3, 19.1);
    float warp = fbm(ground * 0.16 + vec2(31.7, 4.9)) - 0.5;
    float broad = fbm(broadPoint + vec2(warp * 0.42, warp * 0.18));
    float medium = valueNoise(
        ground * 1.15 + vec2(warp * 2.0, 41.7)
    );

    vec2 windPoint = rotate2d(ground, 0.19);
    float dunePhase = windPoint.x * 5.7
        + windPoint.y * 0.72
        + broad * 5.2;
    float duneWave = 0.5 + 0.5 * sin(dunePhase);
    float crest = pow(max(duneWave, 0.0), 7.0);
    float lee = pow(max(1.0 - duneWave, 0.0), 2.2);

    // A directional finite difference suggests height and a low western sun
    // without constructing an actual displacement mesh.
    vec2 sunStep = normalize(vec2(-0.82, 0.36)) * 0.055;
    float lightSample = fbm(
        (ground + sunStep) * 0.34
            + vec2(7.3 + warp * 0.42, 19.1 + warp * 0.18)
    );
    float slopeLight = clamp((broad - lightSample) * 4.8 + 0.52, 0.0, 1.0);

    vec3 groundColor = mix(SAND_DEEP, SAND_BASE, broad);
    groundColor = mix(groundColor, SAND_WARM, slopeLight * 0.42);
    groundColor += SAND_LIGHT * crest * (0.040 + 0.060 * slopeLight);
    groundColor *= 1.0 - lee * 0.075;

    float mineralPatch = smoothstep(0.58, 0.83, medium)
        * smoothstep(0.36, 0.72, broad);
    groundColor = mix(
        groundColor,
        vec3(0.240, 0.105, 0.075),
        mineralPatch * 0.13
    );

    float ripple = 0.5 + 0.5 * sin(
        windPoint.x * 31.0
            + windPoint.y * 2.4
            - iTime * 0.22
            + valueNoise(ground * 2.2) * 4.0
    );
    ripple = smoothstep(0.84, 0.99, ripple);
    float rippleGate = smoothstep(0.34, 0.72, medium);
    groundColor += SAND_PALE * ripple * rippleGate * 0.018;

    float windSheet = fbm(
        vec2(
            windPoint.x * 0.72 - iTime * 0.055,
            windPoint.y * 2.8 + iTime * 0.010
        ) + vec2(53.1, 17.7)
    );
    looseSand = smoothstep(0.57, 0.79, windSheet)
        * (0.55 + 0.45 * rippleGate);
    groundColor = mix(groundColor, SAND_WARM, looseSand * 0.075);

    groundColor = mix(groundColor, FAR_HAZE, farFade * 0.52);
    return groundColor;
}

// =============================================================================
// DRIFTING HIGH CLOUDS AND THEIR GROUND SHADOWS
// =============================================================================

float cloudDensityAt(vec2 ground) {
    vec2 flow = vec2(iTime * 0.018, -iTime * 0.006);
    float warp = valueNoise(ground * 0.19 + flow * 0.37 + vec2(17.3, 91.7));
    float coarse = fbm(
        ground * 0.31
            + flow
            + vec2(warp * 0.42, -warp * 0.18)
            + vec2(63.1, 11.9)
    );
    float breakup = valueNoise(
        ground * 1.18 + flow * 2.3 + vec2(7.7, 41.3)
    );
    float envelope = smoothstep(0.54, 0.78, coarse);
    envelope *= mix(0.52, 1.18, breakup);

    // Two broad drifting clusters carry visible cloud puffs across the middle
    // distance, as in the aerial reference, while the same density sampled at
    // an offset produces their coherent shadows on the sand.
    vec2 clusterDrift = vec2(
        0.22 * sin(iTime * 0.009),
        0.10 * sin(iTime * 0.006 + 1.7)
    );
    vec2 clusterA = (
        ground - vec2(-1.45, 2.30) - clusterDrift
    ) / vec2(1.05, 0.62);
    vec2 clusterB = (
        ground - vec2(1.55, 3.42) - clusterDrift * 0.72
    ) / vec2(1.25, 0.74);
    float clusterEnvelope = max(
        1.0 - smoothstep(0.38, 1.16, length(clusterA)),
        1.0 - smoothstep(0.42, 1.20, length(clusterB))
    );
    float clusterTexture = mix(coarse, breakup, 0.38);
    float clusterPuffs = clusterEnvelope
        * smoothstep(0.36, 0.67, clusterTexture)
        * mix(0.62, 1.12, breakup);
    return saturate(max(envelope, clusterPuffs * 0.86));
}

// =============================================================================
// MOBILE PLANTATION / BASE
// =============================================================================

vec2 plantationPositionAt(float timeValue) {
    return vec2(
        0.20 + 0.13 * sin(timeValue * 0.0062),
        2.72 + 0.10 * sin(timeValue * 0.0047 + 1.2)
    );
}

float plantationAngleAt(float timeValue) {
    return -0.12 + 0.045 * sin(timeValue * 0.0051 + 0.7);
}

void renderPlantation(
    vec2 ground,
    out vec3 structureColor,
    out float structureCoverage,
    out vec3 structureLight,
    out float groundShadow,
    out float roadMask,
    out vec3 baseDust
) {
    vec2 center = plantationPositionAt(iTime);
    float angleValue = plantationAngleAt(iTime);
    vec2 local = rotate2d(ground - center, -angleValue);
    float radius = length(local);
    float polarAngle = atan(local.y, local.x);

    // Roads and crawler tracks extend beyond the circular platform and remain
    // on the ground plane, so perspective compresses them toward the top.
    float spokeDistance = abs(
        sin(polarAngle * 6.0 + 0.22)
    ) * radius;
    float spokes = 1.0 - smoothstep(0.025, 0.048, spokeDistance);
    spokes *= smoothstep(0.64, 0.82, radius)
        * (1.0 - smoothstep(2.10, 2.55, radius));
    float outerRoad = strokeSdf(radius - 1.13, 0.040);
    float serviceRoad = strokeSdf(radius - 1.58, 0.030);

    // Two long crawler marks and a soft dust wake imply that the enormous base
    // is mobile even though its actual translation is deliberately very slow.
    float leftTrack = sdCapsule(
        local,
        vec2(-0.43, -2.20),
        vec2(-0.43, -0.46),
        0.032
    );
    float rightTrack = sdCapsule(
        local,
        vec2(0.43, -2.20),
        vec2(0.43, -0.46),
        0.032
    );
    float crawlerTracks = max(fillSdf(leftTrack), fillSdf(rightTrack));
    roadMask = saturate(
        spokes * 0.56
            + outerRoad * 0.62
            + serviceRoad * 0.38
            + crawlerTracks * 0.46
    );

    float outerDisk = 1.0 - smoothstep(0.625, 0.675, radius);
    float centralCut = smoothstep(0.270, 0.330, radius);
    float mainAnnulus = outerDisk * centralCut;
    float innerPlatform = 1.0 - smoothstep(0.250, 0.290, radius);
    float outerRim = strokeSdf(radius - 0.650, 0.032);
    float innerRim = strokeSdf(radius - 0.310, 0.022);
    float trenchRing = strokeSdf(radius - 0.485, 0.018);

    float sectorWave = 0.5 + 0.5 * cos(polarAngle * 18.0);
    float sectorPanels = smoothstep(0.62, 0.92, sectorWave)
        * mainAnnulus;
    float radialSeams = 1.0 - smoothstep(
        0.012,
        0.025,
        abs(sin(polarAngle * 12.0)) * radius
    );
    radialSeams *= mainAnnulus;

    // Raised central gantry, viewed from above, with a separate ground shadow.
    float gantrySpine = sdCapsule(
        local,
        vec2(0.0, 0.08),
        vec2(0.0, 1.28),
        0.075
    );
    float gantryHead = sdBox(
        local - vec2(0.0, 1.31),
        vec2(0.210, 0.125)
    );
    float crossArmA = sdCapsule(
        local,
        vec2(-0.26, 0.64),
        vec2(0.26, 0.64),
        0.032
    );
    float crossArmB = sdCapsule(
        local,
        vec2(-0.19, 1.00),
        vec2(0.19, 1.00),
        0.027
    );
    float gantryDistance = min(
        min(gantrySpine, gantryHead),
        min(crossArmA, crossArmB)
    );
    float gantry = fillSdf(gantryDistance);
    float gantryEdge = strokeSdf(gantryDistance, 0.018);

    // Polar repetition creates service buildings around the ring without a
    // costly loop or icon-like hard rectangles.
    float sectorLocal = fract((polarAngle / TAU + 0.5) * 14.0) - 0.5;
    vec2 blockPoint = vec2(
        radius - 0.770,
        sectorLocal * radius * TAU / 14.0
    );
    float serviceBlockDistance = sdBox(blockPoint, vec2(0.080, 0.050));
    float serviceBlocks = fillSdf(serviceBlockDistance)
        * smoothstep(0.70, 0.73, radius)
        * (1.0 - smoothstep(0.82, 0.86, radius));

    structureCoverage = saturate(
        mainAnnulus * 0.86
            + innerPlatform * 0.92
            + outerRim
            + innerRim
            + trenchRing * 0.70
            + gantry
            + serviceBlocks * 0.82
    );

    vec3 platformColor = mix(BASE_DARK, BASE_STEEL, mainAnnulus * 0.72);
    platformColor = mix(platformColor, BASE_LIGHT, sectorPanels * 0.23);
    platformColor = mix(platformColor, BASE_DARK, radialSeams * 0.45);
    platformColor = mix(platformColor, BASE_DARK, trenchRing * 0.66);
    platformColor = mix(platformColor, BASE_STEEL, innerPlatform * 0.64);
    platformColor = mix(platformColor, BASE_LIGHT, gantry * 0.46);
    platformColor += BASE_LIGHT * gantryEdge * 0.16;
    platformColor = mix(platformColor, BASE_DARK, serviceBlocks * 0.26);
    structureColor = platformColor;

    float movingBeacon = 0.5 + 0.5 * cos(
        polarAngle * 12.0 - iTime * 0.48
    );
    movingBeacon = smoothstep(0.93, 0.995, movingBeacon)
        * outerRim;
    float centralCore = gaussianPoint(local, 0.135);
    float towerBeacon = gaussianPoint(local - vec2(0.0, 1.33), 0.085);
    structureLight = BASE_AMBER * movingBeacon * 0.19;
    structureLight += FRANXX_CYAN * centralCore * 0.080;
    structureLight += ENERGY_WHITE * towerBeacon * 0.11;

    vec2 shadowOffset = rotate2d(vec2(0.115, -0.085), -angleValue);
    vec2 shadowLocal = local - shadowOffset;
    float shadowRadius = length(shadowLocal);
    float diskShadow = 1.0 - smoothstep(0.61, 0.76, shadowRadius);
    float gantryShadow = fillSdf(sdCapsule(
        shadowLocal,
        vec2(0.0, 0.04),
        vec2(0.0, 1.42),
        0.105
    ));
    groundShadow = saturate(diskShadow * 0.40 + gantryShadow * 0.62);

    float wakeShape = exp(
        -local.x * local.x / 0.48
        -pow(max(-local.y - 0.28, 0.0), 2.0) / 1.45
    );
    wakeShape *= 1.0 - smoothstep(-0.42, -0.12, local.y);
    float wakeNoise = valueNoise(
        local * vec2(2.2, 1.1) + vec2(iTime * 0.08, 17.3)
    );
    float dustMask = wakeShape * smoothstep(0.34, 0.76, wakeNoise);
    baseDust = mix(SAND_WARM, SAND_PALE, 0.28) * dustMask * 0.080;
}

// =============================================================================
// TOP-VIEW KLAXOSAURS
// =============================================================================

void klaxosaurState(
    int creatureIndex,
    out vec2 position,
    out float orientation,
    out float creatureScale
) {
    float index = float(creatureIndex);
    if (creatureIndex == 0) {
        position = vec2(
            1.30 + 0.22 * sin(iTime * 0.027),
            1.62 + 0.16 * cos(iTime * 0.021)
        );
        orientation = 2.70 + 0.18 * sin(iTime * 0.019);
        creatureScale = 1.18;
    } else if (creatureIndex == 1) {
        position = vec2(
            -1.18 + 0.20 * sin(iTime * 0.021 + 2.1),
            3.38 + 0.18 * cos(iTime * 0.017 + 0.7)
        );
        orientation = -0.38 + 0.24 * sin(iTime * 0.015 + 1.4);
        creatureScale = 0.82;
    } else if (creatureIndex == 2) {
        position = vec2(
            0.72 + 0.25 * sin(iTime * 0.018 + 4.2),
            4.22 + 0.15 * cos(iTime * 0.014 + 2.4)
        );
        orientation = 2.25 + 0.20 * sin(iTime * 0.013 + 3.0);
        creatureScale = 0.62;
    } else {
        position = vec2(
            -2.10 + 0.18 * sin(iTime * 0.023 + index),
            1.32 + 0.14 * cos(iTime * 0.020 + index)
        );
        orientation = 0.32 + 0.18 * sin(iTime * 0.017 + index);
        creatureScale = 0.72;
    }
}

void renderTopKlaxosaur(
    vec2 ground,
    vec2 position,
    float orientation,
    float creatureScale,
    float identity,
    out vec3 creatureColor,
    out float creatureCoverage,
    out vec3 creatureLight,
    out float creatureShadow,
    out vec3 creatureDust
) {
    vec2 local = rotate2d(ground - position, -orientation) / creatureScale;

    float bodyDistance = sdEllipse(local, vec2(0.235, 0.105));
    float shoulderDistance = sdEllipse(
        local - vec2(0.135, 0.0),
        vec2(0.120, 0.090)
    );
    float headDistance = sdEllipse(
        local - vec2(0.260, 0.0),
        vec2(0.090, 0.070)
    );
    float tailDistance = sdCapsule(
        local,
        vec2(-0.190, 0.0),
        vec2(-0.500, 0.045 * sin(identity * TAU + iTime * 0.21)),
        0.032
    );
    float frontUpperLimb = sdCapsule(
        local,
        vec2(0.105, 0.055),
        vec2(0.030, 0.220),
        0.025
    );
    float frontLowerLimb = sdCapsule(
        local,
        vec2(0.105, -0.055),
        vec2(0.030, -0.220),
        0.025
    );
    float rearUpperLimb = sdCapsule(
        local,
        vec2(-0.115, 0.055),
        vec2(-0.205, 0.190),
        0.028
    );
    float rearLowerLimb = sdCapsule(
        local,
        vec2(-0.115, -0.055),
        vec2(-0.205, -0.190),
        0.028
    );
    float upperHorn = sdCapsule(
        local,
        vec2(0.285, 0.033),
        vec2(0.430, 0.105),
        0.013
    );
    float lowerHorn = sdCapsule(
        local,
        vec2(0.285, -0.033),
        vec2(0.430, -0.105),
        0.013
    );

    float creatureDistance = min(
        min(min(bodyDistance, shoulderDistance), min(headDistance, tailDistance)),
        min(
            min(frontUpperLimb, frontLowerLimb),
            min(
                min(rearUpperLimb, rearLowerLimb),
                min(upperHorn, lowerHorn)
            )
        )
    );
    float body = fillSdf(creatureDistance);
    float diffuseEdge = softOutside(creatureDistance, 0.042);
    creatureCoverage = saturate(body * 0.92 + diffuseEdge * 0.10);

    float armorBands = 0.5 + 0.5 * cos(local.x * 54.0 + identity * TAU);
    armorBands = smoothstep(0.80, 0.97, armorBands)
        * fillSdf(bodyDistance + 0.012);
    creatureColor = mix(KLAX_DARK, KLAX_BLUE * 0.22, armorBands * 0.34);

    float pulse = 0.66 + 0.34 * sin(iTime * 1.16 + identity * TAU);
    vec2 corePoint = local - vec2(0.045, 0.0);
    float coreDistance = sdEllipse(corePoint, vec2(0.058, 0.040));
    float coreRing = strokeSdf(coreDistance, 0.009);
    float coreGlow = gaussianPoint(corePoint, 0.105);
    float centralVein = segmentDistance(
        local,
        vec2(-0.205, 0.0),
        vec2(0.255, 0.0)
    );
    float branchVein = min(
        segmentDistance(local, vec2(-0.060, 0.0), vec2(-0.145, 0.105)),
        segmentDistance(local, vec2(0.105, 0.0), vec2(0.045, -0.110))
    );
    float veinDistance = min(centralVein, branchVein);
    float veinCore = 1.0 - smoothstep(0.006, 0.010, veinDistance);
    float veinGlow = exp(-veinDistance / 0.040);
    float eyeGlow = gaussianPoint(local - vec2(0.295, 0.0), 0.030);

    creatureLight = KLAX_BLUE * coreGlow * pulse * 0.14;
    creatureLight += KLAX_CYAN * coreRing * pulse * 0.36;
    creatureLight += KLAX_CYAN * veinCore * body * pulse * 0.24;
    creatureLight += KLAX_BLUE * veinGlow * body * pulse * 0.065;
    creatureLight += KLAX_CYAN * eyeGlow * pulse * 0.22;

    vec2 shadowPoint = rotate2d(
        ground - position - vec2(0.070, -0.050) * creatureScale,
        -orientation
    ) / creatureScale;
    float shadowDistance = sdEllipse(shadowPoint, vec2(0.31, 0.16));
    creatureShadow = fillSdf(shadowDistance) * 0.48;

    vec2 wakePoint = rotate2d(ground - position, -orientation) / creatureScale;
    float wake = exp(
        -wakePoint.y * wakePoint.y / 0.075
        -pow(max(-wakePoint.x - 0.18, 0.0), 2.0) / 0.42
    ) * (1.0 - smoothstep(-0.32, -0.08, wakePoint.x));
    float wakeNoise = valueNoise(
        wakePoint * vec2(2.0, 4.0) + vec2(iTime * 0.12, identity * 17.0)
    );
    creatureDust = SAND_WARM
        * wake
        * smoothstep(0.38, 0.78, wakeNoise)
        * 0.075;
}

// =============================================================================
// TOP-VIEW FRANXX UNITS
// =============================================================================

vec2 franxxPath(int unitIndex, float timeValue) {
    vec2 base = plantationPositionAt(timeValue);
    float index = float(unitIndex);
    if (unitIndex == 0) {
        return base + vec2(
            0.92 * cos(timeValue * 0.061),
            0.56 * sin(timeValue * 0.073)
        );
    } else if (unitIndex == 1) {
        return base + vec2(
            -0.78 * cos(timeValue * 0.049 + 1.8),
            0.72 * sin(timeValue * 0.058 + 0.6)
        );
    } else if (unitIndex == 2) {
        return base + vec2(
            1.30 * cos(timeValue * 0.038 + 3.2),
            0.90 * sin(timeValue * 0.047 + 2.1)
        );
    }
    return base + vec2(
        -1.42 * cos(timeValue * 0.033 + index),
        -0.78 * sin(timeValue * 0.041 + index * 1.7)
    );
}

void franxxState(
    int unitIndex,
    out vec2 position,
    out float orientation,
    out float unitScale
) {
    position = franxxPath(unitIndex, iTime);
    vec2 previous = franxxPath(unitIndex, iTime - 0.025);
    vec2 velocity = position - previous;
    orientation = atan(velocity.y, velocity.x);
    unitScale = unitIndex == 0 ? 1.0 : mix(
        0.72,
        0.88,
        hash12(vec2(float(unitIndex), 31.7))
    );
}

void renderTopFranxx(
    vec2 ground,
    vec2 position,
    float orientation,
    float unitScale,
    vec3 accent,
    out vec3 unitColor,
    out float unitCoverage,
    out vec3 unitLight,
    out float unitShadow,
    out vec3 unitWake
) {
    vec2 local = rotate2d(ground - position, -orientation) / unitScale;

    float bodyDistance = sdCapsule(
        local,
        vec2(-0.105, 0.0),
        vec2(0.125, 0.0),
        0.045
    );
    float noseDistance = sdCapsule(
        local,
        vec2(0.090, 0.0),
        vec2(0.205, 0.0),
        0.026
    );
    float upperShoulder = sdCapsule(
        local,
        vec2(-0.010, 0.025),
        vec2(-0.115, 0.145),
        0.030
    );
    float lowerShoulder = sdCapsule(
        local,
        vec2(-0.010, -0.025),
        vec2(-0.115, -0.145),
        0.030
    );
    float upperLeg = sdCapsule(
        local,
        vec2(-0.075, 0.035),
        vec2(-0.205, 0.105),
        0.022
    );
    float lowerLeg = sdCapsule(
        local,
        vec2(-0.075, -0.035),
        vec2(-0.205, -0.105),
        0.022
    );
    float lanceDistance = sdCapsule(
        local,
        vec2(0.120, -0.020),
        vec2(0.430, -0.020),
        0.010
    );
    float upperHorn = sdCapsule(
        local,
        vec2(0.145, 0.018),
        vec2(0.220, 0.075),
        0.010
    );
    float lowerHorn = sdCapsule(
        local,
        vec2(0.145, -0.018),
        vec2(0.220, -0.075),
        0.010
    );

    float machineDistance = min(
        min(bodyDistance, noseDistance),
        min(
            min(upperShoulder, lowerShoulder),
            min(
                min(upperLeg, lowerLeg),
                min(lanceDistance, min(upperHorn, lowerHorn))
            )
        )
    );
    float body = fillSdf(machineDistance);
    float diffuseEdge = softOutside(machineDistance, 0.035);
    unitCoverage = saturate(body * 0.94 + diffuseEdge * 0.08);

    float ivoryArmor = max(
        fillSdf(bodyDistance),
        fillSdf(noseDistance)
    );
    float redArmor = max(
        max(fillSdf(upperShoulder), fillSdf(lowerShoulder)),
        max(fillSdf(upperLeg), fillSdf(lowerLeg))
    );
    float lance = fillSdf(lanceDistance);
    unitColor = mix(FRANXX_DARK, FRANXX_IVORY, ivoryArmor * 0.78);
    unitColor = mix(unitColor, accent, redArmor * 0.82);
    unitColor = mix(unitColor, ENERGY_WHITE, lance * 0.78);

    float canopy = gaussianPoint(local - vec2(0.075, 0.0), 0.047);
    float engine = gaussianPoint(local - vec2(-0.135, 0.0), 0.070);
    float outline = softOutside(machineDistance, 0.055);
    unitLight = accent * outline * 0.070;
    unitLight += FRANXX_CYAN * canopy * 0.20;
    unitLight += mix(accent, ENERGY_WHITE, 0.62) * engine * 0.17;
    unitLight += ENERGY_WHITE * lance * 0.28;

    vec2 shadowLocal = rotate2d(
        ground - position - vec2(0.038, -0.030) * unitScale,
        -orientation
    ) / unitScale;
    float shadowDistance = sdEllipse(
        shadowLocal - vec2(-0.015, 0.0),
        vec2(0.265, 0.125)
    );
    unitShadow = fillSdf(shadowDistance) * 0.34;

    float trailDistance = sdCapsule(
        local,
        vec2(-0.780, 0.0),
        vec2(-0.100, 0.0),
        0.030
    );
    float trail = softOutside(trailDistance, 0.070)
        * smoothstep(-0.72, -0.10, local.x);
    unitWake = mix(SAND_WARM, accent, 0.20) * trail * 0.060;
}

// =============================================================================
// TOP-DOWN COMBAT LANCES
// =============================================================================

vec3 renderGroundLance(
    vec2 ground,
    vec2 startPoint,
    vec2 endPoint,
    float age,
    vec3 tint,
    float width,
    float noiseSeed
) {
    float life = eventLife(age);
    if (life <= 0.0) {
        return vec3(0.0);
    }

    float boundedAge = saturate(age);
    float extension = smoothstep(0.0, 0.24, boundedAge);
    extension = 1.0 - pow(1.0 - extension, 3.0);
    vec2 currentTip = mix(startPoint, endPoint, extension);
    float centerDistance = segmentDistance(ground, startPoint, currentTip);
    float along = segmentParameter(ground, startPoint, currentTip);
    float flicker = mix(
        0.82,
        1.15,
        valueNoise(vec2(along * 41.0 - iTime * 7.0, noiseSeed))
    );

    float core = 1.0 - smoothstep(
        width,
        width + max(fwidth(centerDistance), 0.001),
        centerDistance
    );
    float innerGlow = exp(-centerDistance / max(width * 3.8, 0.001));
    float outerGlow = exp(-centerDistance / max(width * 11.0, 0.001));
    float tipGlow = gaussianPoint(ground - currentTip, width * 9.0);
    float charge = gaussianPoint(ground - startPoint, width * 11.0)
        * (1.0 - smoothstep(0.16, 0.42, boundedAge));
    float dustScatter = valueNoise(vec2(
        ground.x * 8.0 - iTime * 0.4,
        ground.y * 13.0 + noiseSeed
    ));

    vec3 light = ENERGY_WHITE * core * life * flicker * 0.66;
    light += tint * innerGlow * life * flicker * 0.30;
    light += tint * outerGlow * life * 0.070;
    light += mix(tint, ENERGY_WHITE, 0.62) * tipGlow * life * 0.30;
    light += tint * charge * life * 0.22;
    light += tint
        * outerGlow
        * smoothstep(0.58, 0.84, dustScatter)
        * life
        * 0.050;
    return light;
}

void renderCombatLances(vec2 ground, out vec3 combatLight) {
    combatLight = vec3(0.0);

    vec2 strelizia = franxxPath(0, iTime);
    vec2 klaxPosition;
    float klaxOrientation;
    float klaxScaleValue;
    klaxosaurState(0, klaxPosition, klaxOrientation, klaxScaleValue);

    const float redPeriod = 13.7;
    float redClock = (iTime + 7.4) / redPeriod;
    float redPhase = fract(redClock);
    float redCycle = floor(redClock);
    float redAge = (redPhase - 0.27) / 0.145;
    combatLight += renderGroundLance(
        ground,
        strelizia,
        klaxPosition,
        redAge,
        FRANXX_RED,
        0.010,
        17.0 + redCycle
    );

    const float bluePeriod = 19.3;
    float blueClock = (iTime + 2.1) / bluePeriod;
    float bluePhase = fract(blueClock);
    float blueCycle = floor(blueClock);
    float blueAge = (bluePhase - 0.58) / 0.125;
    vec2 blueTarget = franxxPath(1, iTime)
        + vec2(-0.25, 0.18 * sin(blueCycle));
    combatLight += renderGroundLance(
        ground,
        klaxPosition,
        blueTarget,
        blueAge,
        KLAX_CYAN,
        0.012,
        71.0 + blueCycle
    );

#if PERF_SECONDARY_LANCE
    const float crossPeriod = 31.0;
    float crossClock = (iTime + 18.0) / crossPeriod;
    float crossPhase = fract(crossClock);
    float crossCycle = floor(crossClock);
    float crossAge = (crossPhase - 0.71) / 0.105;
    vec2 farKlax;
    float farAngle;
    float farScale;
    klaxosaurState(1, farKlax, farAngle, farScale);
    combatLight += renderGroundLance(
        ground,
        franxxPath(2, iTime),
        farKlax,
        crossAge,
        mix(FRANXX_ROSE, ENERGY_WHITE, 0.22),
        0.008,
        137.0 + crossCycle
    ) * 0.76;
#endif
}

// =============================================================================
// TOP-DOWN EXPLOSIONS, SHOCK RINGS, AND SCORCHED GROUND
// =============================================================================

void renderExplosionEvent(
    vec2 ground,
    float period,
    float timeOffset,
    float eventStart,
    float eventDuration,
    float seedBase,
    inout vec3 explosionLight,
    inout float smokeMask,
    inout float scorchMask
) {
    float clock = (iTime + timeOffset) / period;
    float phase = fract(clock);
    float cycle = floor(clock);
    float age = (phase - eventStart) / eventDuration;
    float activeMask = step(0.0, age) * (1.0 - step(1.0, age));
    if (activeMask <= 0.0) {
        return;
    }

    float boundedAge = saturate(age);
    vec2 randomValue = hash22(vec2(cycle + seedBase, seedBase * 3.17));
    vec2 baseCenter = plantationPositionAt(iTime);
    vec2 center = baseCenter + vec2(
        mix(-1.65, 1.65, randomValue.x),
        mix(-1.15, 1.20, randomValue.y)
    );
    float sizeVariation = mix(0.78, 1.22, hash12(randomValue + seedBase));

    vec2 delta = ground - center;
    float radial = length(delta);
    float angleValue = atan(delta.y, delta.x);
    vec2 angularPoint = vec2(cos(angleValue), sin(angleValue));
    float surfaceNoise = fbm(
        angularPoint * 2.2
            + vec2(cycle * 0.31 + seedBase, boundedAge * 1.8)
    ) - 0.5;

    float fireRadius = mix(0.030, 0.245, sqrt(boundedAge)) * sizeVariation;
    float noisyRadius = fireRadius * (1.0 + surfaceNoise * 0.28);
    float fireDistance = radial - noisyRadius;
    float fireFade = 1.0 - smoothstep(0.18, 0.86, boundedAge);
    float fireInterior = 1.0 - smoothstep(
        noisyRadius * 0.16,
        noisyRadius + max(fwidth(radial), 0.001),
        radial
    );
    fireInterior *= mix(0.70, 1.20, saturate(surfaceNoise + 0.5));
    float fireShell = strokeSdf(
        fireDistance,
        mix(0.030, 0.010, boundedAge) * sizeVariation
    );
    float hotCore = gaussianPoint(delta, max(fireRadius * 0.42, 0.025))
        * exp(-boundedAge * 5.2);
    float fireBloom = gaussianPoint(delta, max(fireRadius * 3.1, 0.10))
        * exp(-boundedAge * 2.0);

    float shockRadius = mix(0.055, 0.68, sqrt(boundedAge)) * sizeVariation;
    float shockDistance = radial - shockRadius;
    float shock = strokeSdf(
        shockDistance,
        mix(0.018, 0.007, boundedAge)
    ) * (1.0 - smoothstep(0.42, 0.92, boundedAge));
    float shockGlow = exp(-abs(shockDistance) / 0.045)
        * (1.0 - smoothstep(0.28, 0.84, boundedAge));

    explosionLight += ENERGY_WHITE * hotCore * 1.02;
    explosionLight += FIRE_GOLD * fireInterior * fireFade * 0.66;
    explosionLight += FIRE_GOLD * fireShell * fireFade * 0.42;
    explosionLight += FIRE_RED * fireBloom * 0.29;
    explosionLight += ENERGY_WHITE * shock * 0.20;
    explosionLight += SAND_LIGHT * shockGlow * 0.052;

    float smokeRadius = mix(0.10, 0.42, sqrt(boundedAge)) * sizeVariation;
    vec2 smokePoint = delta / max(smokeRadius, 0.001);
    smokePoint += vec2(
        -0.16 * boundedAge,
        0.11 * sin(cycle + seedBase) * boundedAge
    );
    float smokeNoise = fbm(
        smokePoint * 1.18
            + vec2(cycle * 0.73 + seedBase, -boundedAge * 1.25)
    );
    float smokeEnvelope = 1.0 - smoothstep(0.50, 1.20, length(smokePoint));
    float smoke = smoothstep(0.43, 0.72, smokeNoise)
        * smokeEnvelope
        * smoothstep(0.13, 0.34, boundedAge)
        * (1.0 - smoothstep(0.82, 1.0, boundedAge));
    smokeMask = max(smokeMask, smoke * 0.78);

    float scorch = gaussianPoint(delta, max(fireRadius * 1.25, 0.06))
        * smoothstep(0.12, 0.35, boundedAge)
        * (1.0 - smoothstep(0.88, 1.0, boundedAge));
    scorchMask = max(scorchMask, scorch * 0.62);

#if PERF_EXPLOSION_SPARKS > 0
    for (int sparkIndex = 0; sparkIndex < PERF_EXPLOSION_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        float angleSeed = hash13(vec3(index, cycle + seedBase, 37.1));
        float speedSeed = hash13(vec3(index, cycle + seedBase, 81.3));
        float sparkAngle = angleSeed * TAU;
        vec2 direction = vec2(cos(sparkAngle), sin(sparkAngle));
        float travelled = mix(0.10, 0.52, speedSeed)
            * boundedAge * sizeVariation;
        vec2 sparkCenter = center + direction * travelled;
        vec2 sparkTail = sparkCenter
            - direction * mix(0.035, 0.110, speedSeed) * sizeVariation;
        float sparkDistance = sdCapsule(
            ground,
            sparkTail,
            sparkCenter,
            0.006
        );
        float spark = fillSdf(sparkDistance)
            * (1.0 - smoothstep(0.48, 0.88, boundedAge));
        explosionLight += mix(FIRE_GOLD, ENERGY_WHITE, speedSeed)
            * spark * 0.28;
    }
#endif
}

void renderExplosions(
    vec2 ground,
    out vec3 explosionLight,
    out float smokeMask,
    out float scorchMask
) {
    explosionLight = vec3(0.0);
    smokeMask = 0.0;
    scorchMask = 0.0;
    renderExplosionEvent(
        ground,
        17.0,
        3.7,
        0.46,
        0.205,
        11.0,
        explosionLight,
        smokeMask,
        scorchMask
    );
#if PERF_SECOND_EXPLOSION
    renderExplosionEvent(
        ground,
        29.0,
        19.0,
        0.66,
        0.155,
        53.0,
        explosionLight,
        smokeMask,
        scorchMask
    );
#endif
}

// =============================================================================
// GROUND-COHERENT WINDBLOWN SAND
// =============================================================================

vec3 renderMicroSand(vec2 ground, float looseSand) {
    vec3 sandLight = vec3(0.0);

    for (int layerIndex = 0; layerIndex < PERF_MICRO_SAND_LAYERS; layerIndex++) {
        float layer = float(layerIndex);
        float depth = (layer + 0.5) / float(PERF_MICRO_SAND_LAYERS);
        float scale = mix(18.0, 42.0, depth);
        vec2 flowPoint = rotate2d(ground, -0.10) * scale;
        flowPoint += vec2(
            -iTime * mix(1.6, 5.2, depth),
            0.22 * sin(iTime * 0.11 + layer * 2.7)
        );
        vec2 cell = floor(flowPoint);
        vec2 local = fract(flowPoint) - 0.5;
        float pixelWidth = max(fwidth(flowPoint.x), fwidth(flowPoint.y));

        for (int neighborY = -1; neighborY <= 1; neighborY++) {
            for (int neighborX = -1; neighborX <= 1; neighborX++) {
                vec2 neighbor = vec2(float(neighborX), float(neighborY));
                vec2 particleCell = cell + neighbor;
                vec2 offset = (
                    hash22(particleCell + layer * 37.1) - 0.5
                ) * 0.50;
                vec2 grainPoint = local - neighbor - offset;
                float identity = hash12(particleCell + layer * 83.7);
                float present = step(mix(0.81, 0.88, depth), identity);
                float halfLength = mix(0.10, 0.34, depth)
                    * mix(0.70, 1.30, hash12(particleCell + 11.3));
                float halfWidth = max(
                    mix(0.025, 0.050, depth),
                    pixelWidth * 0.52
                );
                float lengthMask = 1.0 - smoothstep(
                    halfLength,
                    halfLength + pixelWidth,
                    abs(grainPoint.x)
                );
                float widthMask = exp(
                    -grainPoint.y * grainPoint.y
                        / max(halfWidth * halfWidth, 0.000001)
                );
                float grain = lengthMask * widthMask * present;
                float brightness = mix(0.40, 1.0, depth)
                    * mix(0.56, 1.0, identity)
                    * mix(0.68, 1.25, looseSand);
                vec3 tint = mix(SAND_WARM, SAND_PALE, depth * 0.66);
                sandLight += tint
                    * grain
                    * brightness
                    * mix(0.030, 0.080, depth);
            }
        }
    }
    return sandLight;
}

// =============================================================================
// COMPLETE AERIAL SCENE
// =============================================================================

vec4 renderAerialScene(vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    float aspect = resolution.x / resolution.y;
    GroundView view = groundFromScreen(fragCoord);
    vec2 ground = view.point;

    float looseSand;
    vec3 scene = renderDesertGround(ground, view.farFade, looseSand);

    float cloudShadowDensity = cloudDensityAt(
        ground + vec2(-0.24, 0.16)
    );
    scene = mix(
        scene,
        CLOUD_SHADOW,
        cloudShadowDensity * 0.19
    );

    vec3 baseColor;
    float baseCoverage;
    vec3 baseLight;
    float baseShadow;
    float roadMask;
    vec3 baseDust;
    renderPlantation(
        ground,
        baseColor,
        baseCoverage,
        baseLight,
        baseShadow,
        roadMask,
        baseDust
    );
    scene = mix(scene, ROAD_DARK, roadMask * 0.34);
    scene = mix(scene, CLOUD_SHADOW, baseShadow * 0.26);
    scene += baseDust;
    scene = mix(scene, baseColor, baseCoverage * 0.91);
    scene += baseLight;

    for (int creatureIndex = 0; creatureIndex < PERF_KLAXOSAURS; creatureIndex++) {
        vec2 creaturePosition;
        float creatureOrientation;
        float creatureScale;
        klaxosaurState(
            creatureIndex,
            creaturePosition,
            creatureOrientation,
            creatureScale
        );
        vec3 creatureColor;
        float creatureCoverage;
        vec3 creatureLight;
        float creatureShadow;
        vec3 creatureDust;
        renderTopKlaxosaur(
            ground,
            creaturePosition,
            creatureOrientation,
            creatureScale,
            hash12(vec2(float(creatureIndex), 17.3)),
            creatureColor,
            creatureCoverage,
            creatureLight,
            creatureShadow,
            creatureDust
        );
        scene = mix(scene, CLOUD_SHADOW, creatureShadow * 0.22);
        scene += creatureDust;
        scene = mix(scene, creatureColor, creatureCoverage * 0.92);
        scene += creatureLight;
    }

    for (int unitIndex = 0; unitIndex < PERF_FRANXX_UNITS; unitIndex++) {
        vec2 unitPosition;
        float unitOrientation;
        float unitScale;
        franxxState(unitIndex, unitPosition, unitOrientation, unitScale);
        vec3 accent = unitIndex == 0
            ? FRANXX_RED
            : mix(
                FRANXX_CYAN,
                FRANXX_ROSE,
                hash12(vec2(float(unitIndex), 71.3))
            );
        vec3 unitColor;
        float unitCoverage;
        vec3 unitLight;
        float unitShadow;
        vec3 unitWake;
        renderTopFranxx(
            ground,
            unitPosition,
            unitOrientation,
            unitScale,
            accent,
            unitColor,
            unitCoverage,
            unitLight,
            unitShadow,
            unitWake
        );
        scene = mix(scene, CLOUD_SHADOW, unitShadow * 0.18);
        scene += unitWake;
        scene = mix(scene, unitColor, unitCoverage * 0.94);
        scene += unitLight;
    }

    vec3 combatLight;
    renderCombatLances(ground, combatLight);
    scene += combatLight;

    vec3 explosionLight;
    float smokeMask;
    float scorchMask;
    renderExplosions(ground, explosionLight, smokeMask, scorchMask);
    scene = mix(scene, vec3(0.045, 0.024, 0.024), scorchMask * 0.76);
    scene *= 1.0 - smokeMask * 0.46;
    scene += SMOKE_DUST * smokeMask * 0.075;
    scene += explosionLight;

    scene += renderMicroSand(ground, looseSand);

    // Clouds are composited last: they soften every ground object and reinforce
    // the high-altitude camera rather than behaving like painted terrain.
    float cloudDensity = cloudDensityAt(ground);
    float cloudEdge = smoothstep(0.03, 0.32, cloudDensity)
        * (1.0 - smoothstep(0.62, 0.96, cloudDensity));
    scene = mix(scene, CLOUD_LIGHT, cloudDensity * 0.19);
    scene += vec3(0.34, 0.29, 0.29) * cloudEdge * 0.035;

    // Distance haze diffuses all silhouettes near the upper edge, matching the
    // reference's aerial scale while preserving a ground-only composition.
    scene = mix(scene, FAR_HAZE, view.farFade * 0.31);

    float vignette = 1.0 - VIGNETTE_STRENGTH * smoothstep(
        0.30,
        1.18,
        length((uv - 0.5) * vec2(aspect, 1.0))
    );
    scene *= vignette;
    scene = vec3(1.0) - exp(-max(scene, vec3(0.0)) * SCENE_EXPOSURE);

    float visibility = saturate(
        luminance(scene) * 1.8
            + luminance(baseLight + combatLight + explosionLight) * 0.62
    );
    return vec4(scene, visibility);
}

// =============================================================================
// CURSOR: MOVING TOP-VIEW STRELIZIA
// =============================================================================

vec2 cursorCenterPx(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}

float insideCursorRectangle(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(
        cursorRectangle.x,
        cursorRectangle.y - cursorRectangle.w
    );
    vec2 maximumPoint = vec2(
        cursorRectangle.x + cursorRectangle.z,
        cursorRectangle.y
    );
    return step(minimumPoint.x, point.x)
        * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x)
        * step(point.y, maximumPoint.y);
}

float pixelFill(float distanceValue, float aa) {
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float pixelStroke(float distanceValue, float width, float aa) {
    return 1.0 - smoothstep(
        max(width - aa, 0.0),
        width + aa,
        abs(distanceValue)
    );
}

void applyStreliziaCursor(inout vec4 color, vec2 fragCoord) {
    vec4 untouched = color;
    if (iCursorVisible == 0) {
        return;
    }

    vec2 head = cursorCenterPx(iCurrentCursor);
    vec2 tail = cursorCenterPx(iPreviousCursor);
    vec2 movement = head - tail;
    float moved = length(movement);
    float cursorSize = max(iCurrentCursor.z, iCurrentCursor.w);
    float age = saturate((iTime - iTimeCursorChange) / 0.34);
    if (
        cursorSize <= 0.0
        || moved <= cursorSize * 0.025
        || age >= 1.0
    ) {
        return;
    }

    float movementFactor = smoothstep(
        cursorSize * 0.10,
        cursorSize * 9.0,
        moved
    );
    float effectRadius = cursorSize * mix(3.0, 4.5, movementFactor);
    if (
        any(lessThan(fragCoord, min(head, tail) - vec2(effectRadius)))
        || any(greaterThan(fragCoord, max(head, tail) + vec2(effectRadius)))
    ) {
        return;
    }

    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - easedAge, 1.58);
    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float along = segmentParameter(fragCoord, tail, head);
    vec2 pathCenter = mix(tail, head, along);
    float signedAcross = dot(fragCoord - pathCenter, normal);
    float pathWindow = smoothstep(0.0, 0.18, along) * life;
    float tailTaper = mix(0.16, 1.0, pow(along, 0.72));

    vec2 uv = clamp(
        fragCoord / max(iResolution.xy, vec2(1.0)),
        vec2(0.0),
        vec2(1.0)
    );
    float contentProtection = mix(
        0.20,
        1.0,
        backgroundCellMask(texture(iChannel0, uv))
    );

    float braidAmplitude = cursorSize
        * mix(0.18, 0.38, movementFactor)
        * (1.0 - along)
        * sin(along * TAU * 1.85 - easedAge * PI);
    float ribbonRadius = cursorSize * mix(0.060, 0.115, movementFactor);
    float redRibbon = exp(
        -abs(signedAcross - braidAmplitude) / max(ribbonRadius, 0.5)
    ) * pathWindow * tailTaper;
    float cyanRibbon = exp(
        -abs(signedAcross + braidAmplitude) / max(ribbonRadius, 0.5)
    ) * pathWindow * tailTaper;
    float synchronizedCore = exp(
        -abs(signedAcross) / max(cursorSize * 0.060, 0.5)
    ) * pathWindow * smoothstep(0.46, 1.0, along);
    float pressureWake = exp(
        -abs(signedAcross)
            / max(cursorSize * mix(1.05, 0.36, along), 0.5)
    ) * pathWindow * (0.55 + 0.45 * sin(along * PI));

    color.rgb = mix(
        color.rgb,
        SAND_WARM,
        pressureWake * 0.11 * contentProtection
    );
    color.rgb += FRANXX_RED
        * redRibbon * 0.32 * contentProtection;
    color.rgb += FRANXX_CYAN
        * cyanRibbon * 0.27 * contentProtection;
    color.rgb += ENERGY_WHITE
        * synchronizedCore * 0.30 * contentProtection;

    vec2 relative = fragCoord - head;
    vec2 local = vec2(dot(relative, direction), dot(relative, normal));
    float aa = 1.15;
    float bodyLength = cursorSize * mix(0.82, 1.22, movementFactor);
    float bodyRadius = cursorSize * 0.21;

    // Soft ground shadow separates the top-view machine from its dusty wake.
    vec2 shadowLocal = local - vec2(cursorSize * 0.16, -cursorSize * 0.13);
    float shadowDistance = sdEllipse(
        shadowLocal,
        vec2(bodyLength * 1.28, cursorSize * 0.96)
    );
    float shadow = pixelFill(shadowDistance, aa) * life;
    color.rgb = mix(
        color.rgb,
        vec3(0.020, 0.018, 0.026),
        shadow * 0.20 * contentProtection
    );

    float bodyDistance = sdCapsule(
        local,
        vec2(-bodyLength * 0.48, 0.0),
        vec2(bodyLength * 0.40, 0.0),
        bodyRadius
    );
    float noseDistance = sdCapsule(
        local,
        vec2(bodyLength * 0.22, 0.0),
        vec2(bodyLength * 0.70, 0.0),
        cursorSize * 0.115
    );
    float body = max(
        pixelFill(bodyDistance, aa),
        pixelFill(noseDistance, aa)
    ) * life;
    float bodyShell = pixelStroke(
        min(bodyDistance, noseDistance),
        cursorSize * 0.075,
        aa
    ) * life;

    float upperShoulderDistance = sdCapsule(
        local,
        vec2(-bodyLength * 0.08, bodyRadius * 0.35),
        vec2(-bodyLength * 0.48, cursorSize * 0.95),
        cursorSize * 0.095
    );
    float lowerShoulderDistance = sdCapsule(
        local,
        vec2(-bodyLength * 0.08, -bodyRadius * 0.35),
        vec2(-bodyLength * 0.48, -cursorSize * 0.95),
        cursorSize * 0.095
    );
    float upperLegDistance = sdCapsule(
        local,
        vec2(-bodyLength * 0.30, bodyRadius * 0.25),
        vec2(-bodyLength * 0.78, cursorSize * 0.62),
        cursorSize * 0.075
    );
    float lowerLegDistance = sdCapsule(
        local,
        vec2(-bodyLength * 0.30, -bodyRadius * 0.25),
        vec2(-bodyLength * 0.78, -cursorSize * 0.62),
        cursorSize * 0.075
    );
    float redArmor = max(
        max(
            pixelFill(upperShoulderDistance, aa),
            pixelFill(lowerShoulderDistance, aa)
        ),
        max(
            pixelFill(upperLegDistance, aa),
            pixelFill(lowerLegDistance, aa)
        )
    ) * life;

    float spearDistance = sdCapsule(
        local,
        vec2(bodyLength * 0.28, -cursorSize * 0.10),
        vec2(bodyLength * 1.35, -cursorSize * 0.10),
        cursorSize * 0.045
    );
    float spear = pixelFill(spearDistance, aa) * life;
    float spearGlow = exp(
        -max(spearDistance, 0.0) / max(cursorSize * 0.25, 0.5)
    ) * life;

    float upperHornDistance = sdCapsule(
        local,
        vec2(bodyLength * 0.45, cursorSize * 0.06),
        vec2(bodyLength * 0.78, cursorSize * 0.33),
        cursorSize * 0.050
    );
    float lowerHornDistance = sdCapsule(
        local,
        vec2(bodyLength * 0.45, -cursorSize * 0.06),
        vec2(bodyLength * 0.78, -cursorSize * 0.33),
        cursorSize * 0.050
    );
    float horns = max(
        pixelFill(upperHornDistance, aa),
        pixelFill(lowerHornDistance, aa)
    ) * life;

    float canopyDistance = sdEllipse(
        local - vec2(bodyLength * 0.20, 0.0),
        vec2(bodyLength * 0.25, bodyRadius * 0.68)
    );
    float canopy = pixelFill(canopyDistance, aa) * life;
    float engine = gaussianPoint(
        local - vec2(-bodyLength * 0.52, 0.0),
        cursorSize * 0.42
    ) * life;
    float destinationGlow = gaussianPoint(
        relative,
        cursorSize * mix(1.15, 1.85, movementFactor)
    ) * life;

    color.rgb += FRANXX_ROSE
        * destinationGlow * 0.080 * contentProtection;
    color.rgb += FRANXX_RED
        * spearGlow * 0.090 * contentProtection;
    vec3 streliziaBody = mix(FRANXX_DARK, FRANXX_IVORY, 0.68);
    color.rgb = mix(
        color.rgb,
        streliziaBody,
        body * 0.58 * contentProtection
    );
    color.rgb = mix(
        color.rgb,
        ENERGY_WHITE,
        bodyShell * 0.76 * contentProtection
    );
    color.rgb = mix(
        color.rgb,
        FRANXX_RED,
        max(redArmor, horns) * 0.88 * contentProtection
    );
    color.rgb = mix(
        color.rgb,
        FRANXX_CYAN,
        canopy * 0.58 * contentProtection
    );
    color.rgb += ENERGY_WHITE
        * spear * 0.64 * contentProtection;
    color.rgb += mix(FRANXX_RED, ENERGY_WHITE, 0.62)
        * engine * 0.18 * contentProtection;

    float shockRadius = cursorSize * mix(0.82, 2.70, easedAge);
    float shockDistance = length(relative) - shockRadius;
    float shock = pixelStroke(
        shockDistance,
        cursorSize * 0.058,
        aa
    ) * life * (1.0 - easedAge);
    color.rgb += mix(FRANXX_ROSE, ENERGY_WHITE, 0.58)
        * shock * 0.20 * contentProtection;

#if PERF_CURSOR_SPARKS > 0
    for (int sparkIndex = 0; sparkIndex < PERF_CURSOR_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        vec2 eventSeed = head * 0.037 + tail * 0.091;
        float alongSeed = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
        float sideSeed = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
        float sparkAlong = mix(0.10, 0.84, alongSeed);
        vec2 sparkCenter = mix(tail, head, sparkAlong)
            + normal * (sideSeed - 0.5) * cursorSize * 1.45;
        vec2 sparkTail = sparkCenter
            - direction * cursorSize * mix(0.16, 0.44, sideSeed);
        float sparkDistance = sdCapsule(
            fragCoord,
            sparkTail,
            sparkCenter,
            max(cursorSize * 0.029, 0.55)
        );
        float spark = pixelFill(sparkDistance, 1.0)
            * life
            * smoothstep(0.0, 0.20, sparkAlong);
        color.rgb += mix(SAND_LIGHT, ENERGY_WHITE, sideSeed)
            * spark * 0.24 * contentProtection;
    }
#endif

    float cursorCoverage = insideCursorRectangle(
        fragCoord,
        iCurrentCursor
    );
    color = mix(color, untouched, cursorCoverage);
    color.a = untouched.a;
}

// =============================================================================
// MAIN COMPOSITION
// =============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec4 aerial = renderAerialScene(fragCoord);

    float backgroundMask = backgroundCellMask(terminalColor);
    vec3 darkTerminal = terminalColor.rgb * TERMINAL_BACKGROUND_DARKEN;
    vec3 aerialBackground = mix(
        darkTerminal,
        aerial.rgb,
        AERIAL_SCENE_MIX
    );
    vec3 composite = mix(
        terminalColor.rgb,
        aerialBackground,
        backgroundMask
    );
    float outputAlpha = max(
        terminalColor.a,
        backgroundMask * SCENE_ALPHA_BOOST * aerial.a
    );

    fragColor = vec4(clamp(composite, 0.0, 1.0), outputAlpha);
    applyStreliziaCursor(fragColor, fragCoord);
}
