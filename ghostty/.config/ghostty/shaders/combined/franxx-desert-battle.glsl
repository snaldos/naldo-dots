// FRANXX Desert Battle — cinematic sandstorm background + combat-lance cursor
//
// An original, one-pass Ghostty scene inspired by the post-apocalyptic desert
// battles of Darling in the Franxx. A dark ochre wasteland sits beneath a
// dust-choked rose sky while ruined structures, a distant blue creature, tiny
// airborne machines, energy lances, shock waves, fireballs, smoke, windblown
// sand, and foreground grains create several layers of depth.
//
// Cursor movement becomes a small red/ivory strike craft: two synchronized
// crimson/cyan trails braid through a dusty pressure wake, an energy spear and
// winglets form at the destination, and a restrained shock ring sheds sparks.
// The real Ghostty cursor and terminal foreground remain protected.
//
// No external textures or artwork are used. All motion and geometry are
// procedural and aspect-correct.
//
// Ghostty shader manager:
//   ghostty-shaders.sh set combined franxx-desert-battle
//   ghostty-shaders.sh set-profile balanced   # recommended for daily use
//
// Uses iChannel0, iResolution, iTime, iBackgroundColor, cursor uniforms, and
// mainImage. custom-shader-animation must be enabled.

// =============================================================================
// GPU PERFORMANCE PROFILE
// =============================================================================

#define DESERT_GPU_ECO      0
#define DESERT_GPU_BALANCED 1
#define DESERT_GPU_QUALITY  2
#define DESERT_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE DESERT_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == DESERT_GPU_ECO
#define PERF_FBM_OCTAVES       3
#define PERF_STORM_LAYERS      2
#define PERF_SAND_PARTICLES   20
#define PERF_MICRO_SAND_LAYERS 1
#define PERF_EXPLOSION_SPARKS  2
#define PERF_CURSOR_SPARKS     1
#define PERF_SECONDARY_RAY     0
#define PERF_SECOND_EXPLOSION  0
#elif GHOSTTY_GPU_PROFILE == DESERT_GPU_BALANCED
#define PERF_FBM_OCTAVES       4
#define PERF_STORM_LAYERS      3
#define PERF_SAND_PARTICLES   34
#define PERF_MICRO_SAND_LAYERS 2
#define PERF_EXPLOSION_SPARKS  4
#define PERF_CURSOR_SPARKS     3
#define PERF_SECONDARY_RAY     1
#define PERF_SECOND_EXPLOSION  1
#elif GHOSTTY_GPU_PROFILE == DESERT_GPU_QUALITY
#define PERF_FBM_OCTAVES       5
#define PERF_STORM_LAYERS      4
#define PERF_SAND_PARTICLES   52
#define PERF_MICRO_SAND_LAYERS 3
#define PERF_EXPLOSION_SPARKS  6
#define PERF_CURSOR_SPARKS     5
#define PERF_SECONDARY_RAY     1
#define PERF_SECOND_EXPLOSION  1
#else
#define PERF_FBM_OCTAVES       5
#define PERF_STORM_LAYERS      5
#define PERF_SAND_PARTICLES   72
#define PERF_MICRO_SAND_LAYERS 3
#define PERF_EXPLOSION_SPARKS  9
#define PERF_CURSOR_SPARKS     8
#define PERF_SECONDARY_RAY     1
#define PERF_SECOND_EXPLOSION  1
#endif

// =============================================================================
// ART DIRECTION / TERMINAL TUNING
// =============================================================================

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float DESERT_HORIZON = -0.105;

// Background cells are darkened before the scene is mixed in. Foreground
// glyphs and selection colors are detected separately and remain unchanged.
const float TERMINAL_BACKGROUND_DARKEN = 0.52;
const float DESERT_SCENE_MIX = 0.82;
const float SCENE_ALPHA_BOOST = 0.075;
const float SCENE_EXPOSURE = 1.13;
const float VIGNETTE_STRENGTH = 0.16;

const vec3 SKY_ZENITH      = vec3(0.018, 0.019, 0.046);
const vec3 SKY_MAUVE       = vec3(0.140, 0.048, 0.058);
const vec3 HORIZON_AMBER   = vec3(0.420, 0.140, 0.038);
const vec3 STORM_UMBRA     = vec3(0.072, 0.028, 0.038);
const vec3 STORM_OCHRE     = vec3(0.340, 0.125, 0.042);
const vec3 SAND_GOLD       = vec3(0.820, 0.390, 0.105);
const vec3 SAND_PALE       = vec3(0.950, 0.700, 0.340);
const vec3 FAR_DUNE        = vec3(0.105, 0.043, 0.043);
const vec3 MID_DUNE        = vec3(0.125, 0.052, 0.036);
const vec3 NEAR_DUNE       = vec3(0.090, 0.036, 0.025);
const vec3 RUIN_INK        = vec3(0.025, 0.023, 0.030);
const vec3 KLAX_INK        = vec3(0.004, 0.014, 0.035);
const vec3 KLAX_BLUE       = vec3(0.000, 0.310, 0.920);
const vec3 KLAX_CYAN       = vec3(0.000, 0.820, 1.000);
const vec3 FRANXX_RED      = vec3(0.970, 0.020, 0.105);
const vec3 FRANXX_ROSE     = vec3(1.000, 0.170, 0.325);
const vec3 FRANXX_IVORY    = vec3(0.940, 0.875, 0.720);
const vec3 ENERGY_WHITE    = vec3(1.000, 0.970, 0.830);
const vec3 FIRE_GOLD       = vec3(1.000, 0.440, 0.055);
const vec3 FIRE_RED        = vec3(0.950, 0.035, 0.020);
const vec3 SMOKE_BROWN     = vec3(0.105, 0.045, 0.032);

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

float fillMask(float distanceValue, float aa) {
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float strokeMask(float distanceValue, float width, float aa) {
    return 1.0 - smoothstep(
        max(width - aa, 0.0),
        width + aa,
        abs(distanceValue)
    );
}

float gaussianPoint(vec2 delta, float radius) {
    return exp(
        -dot(delta, delta)
            / max(radius * radius, 0.000001)
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
    // Color matching is the primary test because background-opacity-cells can
    // give text and background the same alpha. Alpha is only a weak fallback.
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
// SKY AND VOLUMETRIC SANDSTORM
// =============================================================================

vec3 renderStormSky(
    vec2 world,
    float aspect,
    out float stormDensity
) {
    float skyHeight = saturate(
        (world.y - DESERT_HORIZON) / max(0.50 - DESERT_HORIZON, 0.001)
    );
    vec3 sky = mix(SKY_MAUVE, SKY_ZENITH, pow(skyHeight, 0.72));

    float horizonGlow = exp(-abs(world.y - DESERT_HORIZON) * 8.5);
    sky += HORIZON_AMBER * horizonGlow * 0.46;

    // A muted red sun remains behind the storm rather than reading as a clean
    // graphic circle. Its broad halo also supplies plausible horizon light.
    vec2 sunCenter = vec2(-0.285 * aspect, 0.205);
    vec2 sunDelta = (world - sunCenter) / vec2(1.0, 0.88);
    float sunDistance = length(sunDelta);
    float sunDisc = 1.0 - smoothstep(0.036, 0.057, sunDistance);
    float sunHalo = exp(-sunDistance * 7.8);

    float accumulatedDust = 0.0;
    float illuminatedDust = 0.0;
    float darkShelf = 0.0;

    for (int layerIndex = 0; layerIndex < PERF_STORM_LAYERS; layerIndex++) {
        float layer = float(layerIndex);
        float depth = (layer + 0.5) / float(PERF_STORM_LAYERS);
        float scale = mix(0.85, 2.35, depth);
        float speed = mix(0.017, 0.052, depth);
        float phase = TAU * hash13(vec3(layer, 19.7, 53.1));

        vec2 stormPoint = vec2(
            world.x * scale - iTime * speed,
            world.y * scale * mix(2.2, 4.8, depth)
        );
        stormPoint.x += 0.16 * sin(
            world.y * mix(5.0, 11.0, depth)
                + iTime * 0.025
                + phase
        );
        float warp = valueNoise(
            stormPoint * 0.72 + vec2(phase, -iTime * 0.010)
        ) - 0.5;
        stormPoint += vec2(warp * 0.42, warp * 0.11);

        float cloud = fbm(
            stormPoint + vec2(layer * 13.7, layer * 7.1)
        );
        float filament = valueNoise(
            vec2(
                stormPoint.x * 3.4 - stormPoint.y * 0.45,
                stormPoint.y * 8.0 + layer * 17.3
            )
        );
        float density = smoothstep(
            mix(0.50, 0.58, depth),
            mix(0.77, 0.84, depth),
            cloud
        );
        density *= mix(0.58, 1.28, filament);

        float lowerAir = 1.0 - smoothstep(0.29, 0.56, world.y);
        float layerWeight = mix(0.38, 0.88, depth)
            * mix(0.58, 1.0, lowerAir);
        accumulatedDust += density * layerWeight;
        illuminatedDust += density
            * layerWeight
            * smoothstep(0.48, 0.90, filament);

        float shelfBand = exp(-pow(
            (world.y - mix(0.06, 0.26, depth))
                / mix(0.10, 0.19, depth),
            2.0
        ));
        darkShelf += density * shelfBand * mix(0.05, 0.12, depth);
    }

    stormDensity = saturate(
        accumulatedDust / max(float(PERF_STORM_LAYERS) * 0.55, 0.001)
    );
    float sunTexture = valueNoise(
        sunDelta * 17.0 + vec2(-iTime * 0.018, iTime * 0.006)
    );
    float sunOcclusion = mix(1.0, 0.14, stormDensity)
        * mix(0.38, 1.0, smoothstep(0.30, 0.76, sunTexture));
    sky += mix(FIRE_RED, SAND_GOLD, 0.38)
        * sunDisc * sunOcclusion * 0.38;
    sky += HORIZON_AMBER * sunHalo * sunOcclusion * 0.15;

    vec3 stormTint = mix(STORM_UMBRA, STORM_OCHRE, horizonGlow);
    float stormVisual = pow(max(stormDensity, 0.0), 0.62);
    sky = mix(sky, stormTint, stormVisual * 0.52);
    float litStorm = illuminatedDust
        / max(float(PERF_STORM_LAYERS), 1.0);
    sky += mix(STORM_OCHRE, SAND_GOLD, horizonGlow)
        * litStorm
        * (0.120 + horizonGlow * 0.105);
    sky *= 1.0 - saturate(darkShelf * 1.35);

    // Long, very faint wind strata make the atmosphere read at terminal scale.
    float windBand = 0.5 + 0.5 * sin(
        world.y * 82.0
            + world.x * 4.0
            - iTime * 0.19
            + valueNoise(world * vec2(1.3, 5.0)) * 5.0
    );
    windBand = smoothstep(0.70, 0.96, windBand)
        * (1.0 - smoothstep(0.34, 0.54, world.y));
    sky += STORM_OCHRE * windBand * (0.016 + stormDensity * 0.052);
    return sky;
}

// =============================================================================
// DESERT TERRAIN AND RUINS
// =============================================================================

float terrainHeight(
    float x,
    float baseHeight,
    float amplitude,
    float frequency,
    float seed,
    float drift
) {
    float sampleX = x * frequency + iTime * drift;
    float broad = valueNoise(vec2(sampleX, seed));
    float detail = valueNoise(vec2(sampleX * 2.17 + 9.3, seed + 31.7));
    float wave = sin(sampleX * 1.31 + seed) * 0.5 + 0.5;
    return baseHeight + amplitude * (
        (broad - 0.5) * 1.42
            + (detail - 0.5) * 0.38
            + (wave - 0.5) * 0.24
    );
}

float terrainBelow(vec2 world, float height, float aa) {
    return 1.0 - smoothstep(height - aa, height + aa, world.y);
}

void renderRuinedOutposts(
    vec2 world,
    float aa,
    out float ruinMask,
    out vec3 ruinLights
) {
    const float spacing = 0.205;
    float slowPan = 0.006 * sin(iTime * 0.013);
    float gridCoordinate = (world.x + slowPan) / spacing;
    float cell = floor(gridCoordinate);
    float localCell = fract(gridCoordinate) - 0.5;
    float identity = hash12(vec2(cell, 17.3));
    float present = step(0.44, identity);

    float width = spacing * mix(0.075, 0.175, hash12(vec2(cell, 31.9)));
    float height = mix(0.026, 0.115, hash12(vec2(cell, 71.1)));
    float base = DESERT_HORIZON - 0.006;
    float centerY = base + height * 0.5;
    float lean = mix(-0.20, 0.20, hash12(vec2(cell, 43.7)));
    float localX = localCell * spacing
        - (world.y - base) * lean;

    float towerDistance = sdBox(
        vec2(localX, world.y - centerY),
        vec2(width, height * 0.5)
    );
    float tower = fillMask(towerDistance, aa) * present;

    // Remove an asymmetric bite from some roof lines to imply abandoned,
    // broken plantation infrastructure rather than a clean skyline.
    float brokenSide = step(0.50, hash12(vec2(cell, 89.3))) * 2.0 - 1.0;
    vec2 biteCenter = vec2(
        brokenSide * width * 0.72,
        base + height * 0.93
    );
    float roofBite = fillMask(
        sdBox(
            vec2(localX - biteCenter.x, world.y - biteCenter.y),
            vec2(width * 0.46, height * 0.16)
        ),
        aa
    );
    tower *= 1.0 - roofBite * step(0.67, identity);

    float towerCenterX = world.x - localCell * spacing;
    float mastDistance = sdCapsule(
        world,
        vec2(
            towerCenterX + lean * height * 0.86,
            base + height * 0.86
        ),
        vec2(
            towerCenterX + lean * height * 1.36,
            base + height * 1.36
        ),
        aa * 0.72
    );
    float mast = fillMask(mastDistance, aa) * present
        * step(0.62, hash12(vec2(cell, 12.5)));
    ruinMask = max(tower, mast);

    float row = fract((world.y - base) / max(height, 0.001) * 5.0);
    float column = fract((localX / max(width, 0.001) + 1.0) * 2.5);
    float aperture = (1.0 - smoothstep(0.14, 0.27, abs(row - 0.5)))
        * (1.0 - smoothstep(0.12, 0.24, abs(column - 0.5)));
    float powered = step(0.84, hash12(vec2(cell, 113.9)));
    float lampGlow = exp(
        -abs(localX) / max(width * 2.4, 0.001)
        -abs(world.y - (base + height * 0.62)) / max(height * 0.36, 0.001)
    );
    ruinLights = SAND_GOLD
        * (aperture * tower * powered * 0.11 + lampGlow * powered * 0.018);
}

// =============================================================================
// DISTANT KLAXOSAUR AND FRANXX SILHOUETTES
// =============================================================================

float klaxosaurScale(float aspect) {
    // Keep the distant subject legible in ordinary windows, but shrink it in
    // narrow terminal splits instead of letting its horns leave the viewport.
    return clamp(aspect / 1.25, 0.52, 1.0);
}

vec2 klaxosaurCenter(float aspect) {
    vec2 center = vec2(0.245 * aspect, -0.052);
    center += vec2(
        0.006 * sin(iTime * 0.031),
        0.003 * sin(iTime * 0.057 + 1.3)
    );
    return center;
}

vec2 klaxosaurCore(float aspect) {
    return klaxosaurCenter(aspect)
        + vec2(0.018, 0.020) * klaxosaurScale(aspect);
}

void renderDistantKlaxosaur(
    vec2 world,
    float aspect,
    float aa,
    out float creatureMask,
    out vec3 creatureLight
) {
    vec2 center = klaxosaurCenter(aspect);
    float subjectScale = klaxosaurScale(aspect);
    vec2 point = (world - center) / subjectScale;
    float localAa = aa / subjectScale;
    float breathe = 1.0 + 0.025 * sin(iTime * 0.34);

    float bodyDistance = sdEllipse(
        point - vec2(-0.018, 0.005),
        vec2(0.115 * breathe, 0.052 * breathe)
    );
    float shoulderDistance = sdEllipse(
        point - vec2(0.067, 0.017),
        vec2(0.060, 0.045)
    );
    float neckDistance = sdCapsule(
        point,
        vec2(0.052, 0.015),
        vec2(0.112, 0.041),
        0.029
    );
    float headDistance = sdEllipse(
        point - vec2(0.128, 0.044),
        vec2(0.045, 0.029)
    );

    float frontLeg = sdCapsule(
        point,
        vec2(0.074, -0.010),
        vec2(0.092, -0.105),
        0.014
    );
    float rearLeg = sdCapsule(
        point,
        vec2(-0.075, -0.014),
        vec2(-0.091, -0.095),
        0.017
    );
    float tailDistance = sdCapsule(
        point,
        vec2(-0.095, 0.014),
        vec2(-0.185, 0.052),
        0.013
    );

    float hornUpper = sdCapsule(
        point,
        vec2(0.140, 0.060),
        vec2(0.200, 0.112),
        0.006
    );
    float hornForward = sdCapsule(
        point,
        vec2(0.151, 0.049),
        vec2(0.214, 0.064),
        0.005
    );
    float dorsalA = sdCapsule(
        point,
        vec2(-0.058, 0.041),
        vec2(-0.074, 0.086),
        0.007
    );
    float dorsalB = sdCapsule(
        point,
        vec2(-0.010, 0.051),
        vec2(-0.013, 0.101),
        0.008
    );
    float dorsalC = sdCapsule(
        point,
        vec2(0.035, 0.047),
        vec2(0.047, 0.090),
        0.007
    );

    float creatureDistance = min(
        min(min(bodyDistance, shoulderDistance), min(neckDistance, headDistance)),
        min(
            min(min(frontLeg, rearLeg), tailDistance),
            min(min(hornUpper, hornForward), min(dorsalA, min(dorsalB, dorsalC)))
        )
    );
    creatureMask = fillMask(creatureDistance, localAa);

    float pulse = 0.68 + 0.32 * sin(iTime * 1.35 + 0.8);
    vec2 localCore = point - vec2(0.018, 0.020);
    float coreDistance = sdEllipse(localCore, vec2(0.022, 0.015));
    float coreRing = strokeMask(coreDistance, 0.0022, localAa);
    float coreGlow = gaussianPoint(localCore, 0.039);

    float veinDistance = min(
        segmentDistance(point, vec2(-0.079, 0.015), vec2(0.015, 0.021)),
        min(
            segmentDistance(point, vec2(0.015, 0.021), vec2(0.087, 0.039)),
            min(
                segmentDistance(point, vec2(-0.012, 0.020), vec2(-0.044, -0.031)),
                segmentDistance(point, vec2(0.053, 0.029), vec2(0.130, 0.049))
            )
        )
    );
    float veinCore = 1.0 - smoothstep(
        0.0012,
        0.0012 + localAa,
        veinDistance
    );
    float veinGlow = exp(-veinDistance / 0.010);
    float eyeGlow = gaussianPoint(point - vec2(0.150, 0.052), 0.010);

    // Armor ridges are dim enough to read as volume without outlining a mascot.
    float armorRidge = strokeMask(
        bodyDistance + 0.010,
        0.0013,
        localAa
    )
        * (0.55 + 0.45 * sin(point.x * 110.0));
    creatureLight = KLAX_BLUE * armorRidge * 0.08;
    creatureLight += KLAX_BLUE * coreGlow * pulse * 0.15;
    creatureLight += KLAX_CYAN * coreRing * pulse * 0.32;
    creatureLight += KLAX_CYAN * veinCore * creatureMask * pulse * 0.23;
    creatureLight += KLAX_BLUE * veinGlow * creatureMask * pulse * 0.070;
    creatureLight += KLAX_CYAN * eyeGlow * pulse * 0.24;
}

vec2 franxxPosition(float aspect, float phaseOffset) {
    float timeValue = iTime;
    return vec2(
        -0.115 * aspect
            + 0.082 * sin(timeValue * 0.083 + phaseOffset)
            + 0.022 * sin(timeValue * 0.191 + phaseOffset * 1.7),
        0.010
            + 0.050 * sin(timeValue * 0.107 + 1.1 + phaseOffset)
            + 0.014 * cos(timeValue * 0.233 + phaseOffset)
    );
}

vec2 franxxVelocity(float phaseOffset) {
    float timeValue = iTime;
    return vec2(
        0.082 * 0.083 * cos(timeValue * 0.083 + phaseOffset)
            + 0.022 * 0.191 * cos(timeValue * 0.191 + phaseOffset * 1.7),
        0.050 * 0.107 * cos(timeValue * 0.107 + 1.1 + phaseOffset)
            - 0.014 * 0.233 * sin(timeValue * 0.233 + phaseOffset)
    );
}

void renderTinyFranxx(
    vec2 world,
    float aspect,
    float phaseOffset,
    vec3 accent,
    float aa,
    out float machineMask,
    out vec3 machineLight
) {
    vec2 center = franxxPosition(aspect, phaseOffset);
    vec2 direction = normalize(franxxVelocity(phaseOffset) + vec2(0.018, 0.0));
    vec2 normal = vec2(-direction.y, direction.x);
    vec2 delta = world - center;
    vec2 local = vec2(dot(delta, direction), dot(delta, normal));

    float bodyDistance = sdCapsule(
        local,
        vec2(-0.014, 0.0),
        vec2(0.014, 0.0),
        0.0065
    );
    float upperWing = sdCapsule(
        local,
        vec2(-0.010, 0.002),
        vec2(-0.034, 0.025),
        0.0026
    );
    float lowerWing = sdCapsule(
        local,
        vec2(-0.010, -0.002),
        vec2(-0.034, -0.025),
        0.0026
    );
    float lance = sdCapsule(
        local,
        vec2(0.010, 0.0),
        vec2(0.043, 0.0),
        0.0017
    );
    float machineDistance = min(
        min(bodyDistance, min(upperWing, lowerWing)),
        lance
    );
    machineMask = fillMask(machineDistance, aa);

    float engine = gaussianPoint(local - vec2(-0.017, 0.0), 0.012);
    float canopy = gaussianPoint(local - vec2(0.009, 0.001), 0.006);
    float lineGlow = exp(-max(machineDistance, 0.0) / 0.009);
    machineLight = accent * lineGlow * 0.085;
    machineLight += accent * engine * 0.19;
    machineLight += ENERGY_WHITE * canopy * 0.16;
    machineLight += ENERGY_WHITE
        * fillMask(lance, aa)
        * 0.28;
}

// =============================================================================
// DISTANT COMBAT RAYS
// =============================================================================

vec3 energyLance(
    vec2 world,
    vec2 startPoint,
    vec2 endPoint,
    float age,
    vec3 tint,
    float coreWidth,
    float aa,
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
    float centerDistance = segmentDistance(world, startPoint, currentTip);
    float along = segmentParameter(world, startPoint, currentTip);
    float flicker = mix(
        0.80,
        1.15,
        valueNoise(vec2(
            along * 47.0 - iTime * 8.0,
            noiseSeed
        ))
    );

    float core = 1.0 - smoothstep(
        coreWidth,
        coreWidth + aa,
        centerDistance
    );
    float innerGlow = exp(-centerDistance / max(coreWidth * 3.8, aa));
    float outerGlow = exp(-centerDistance / max(coreWidth * 12.0, aa));
    float tipGlow = gaussianPoint(
        world - currentTip,
        coreWidth * 10.0
    );

    // A grainy outer shaft is light scattered toward the camera by dust.
    float scatterNoise = valueNoise(vec2(
        world.x * 22.0 - iTime * 0.7,
        world.y * 41.0 + noiseSeed
    ));
    float scatter = outerGlow
        * smoothstep(0.43, 0.82, scatterNoise)
        * (0.55 + 0.45 * sin(along * PI));

    float charge = gaussianPoint(
        world - startPoint,
        coreWidth * mix(15.0, 7.0, boundedAge)
    ) * (1.0 - smoothstep(0.18, 0.43, boundedAge));

    vec3 result = ENERGY_WHITE * core * life * flicker * 0.72;
    result += tint * innerGlow * life * flicker * 0.30;
    result += tint * outerGlow * life * 0.075;
    result += mix(tint, ENERGY_WHITE, 0.65) * tipGlow * life * 0.34;
    result += tint * scatter * life * 0.060;
    result += tint * charge * life * 0.24;
    return result;
}

void renderCombatSignals(
    vec2 world,
    float aspect,
    float aa,
    out vec3 combatLight
) {
    combatLight = vec3(0.0);

    // A red/ivory FRANXX thrust reaches toward the blue core.
    const float redPeriod = 13.7;
    float redClock = (iTime + 7.4) / redPeriod;
    float redPhase = fract(redClock);
    float redCycle = floor(redClock);
    float redAge = (redPhase - 0.27) / 0.145;
    vec2 redSeed = hash22(vec2(redCycle, 41.7));
    vec2 redStart = franxxPosition(aspect, 0.0)
        + vec2(-0.020, mix(-0.010, 0.010, redSeed.y));
    vec2 redEnd = klaxosaurCore(aspect)
        + vec2(
            mix(-0.018, 0.018, redSeed.x),
            mix(-0.014, 0.014, redSeed.y)
        );
    combatLight += energyLance(
        world,
        redStart,
        redEnd,
        redAge,
        FRANXX_RED,
        0.00135,
        aa,
        17.0 + redCycle
    );

    float redImpact = eventLife(redAge)
        * smoothstep(0.22, 0.38, saturate(redAge));
    combatLight += mix(FRANXX_RED, ENERGY_WHITE, 0.58)
        * gaussianPoint(world - redEnd, 0.020)
        * redImpact
        * 0.22;

    // The creature answers with a long cyan beam that exits the battlefield.
    const float bluePeriod = 19.3;
    float blueClock = (iTime + 2.1) / bluePeriod;
    float bluePhase = fract(blueClock);
    float blueCycle = floor(blueClock);
    float blueAge = (bluePhase - 0.58) / 0.125;
    vec2 blueSeed = hash22(vec2(blueCycle, 83.1));
    vec2 blueStart = klaxosaurCore(aspect);
    vec2 blueEnd = vec2(
        mix(-0.50, -0.34, blueSeed.x) * aspect,
        mix(0.02, 0.25, blueSeed.y)
    );
    combatLight += energyLance(
        world,
        blueStart,
        blueEnd,
        blueAge,
        KLAX_CYAN,
        0.00165,
        aa,
        73.0 + blueCycle
    );

#if PERF_SECONDARY_RAY
    // A rarer crossing slash keeps the sky alive without making every frame
    // look like a firefight.
    const float crossPeriod = 31.0;
    float crossClock = (iTime + 18.0) / crossPeriod;
    float crossPhase = fract(crossClock);
    float crossCycle = floor(crossClock);
    float crossAge = (crossPhase - 0.71) / 0.105;
    vec2 crossSeed = hash22(vec2(crossCycle, 121.9));
    vec2 crossStart = vec2(
        mix(-0.43, -0.12, crossSeed.x) * aspect,
        mix(0.18, 0.34, crossSeed.y)
    );
    vec2 crossEnd = vec2(
        mix(0.10, 0.46, crossSeed.y) * aspect,
        mix(-0.02, 0.16, crossSeed.x)
    );
    combatLight += energyLance(
        world,
        crossStart,
        crossEnd,
        crossAge,
        mix(FRANXX_ROSE, ENERGY_WHITE, 0.24),
        0.00105,
        aa,
        137.0 + crossCycle
    ) * 0.72;
#endif
}

// =============================================================================
// FIREBALLS, SHOCK WAVES, SMOKE, AND EJECTA
// =============================================================================

void renderExplosionEvent(
    vec2 world,
    float aspect,
    float aa,
    float period,
    float timeOffset,
    float eventStart,
    float eventDuration,
    float seedBase,
    inout vec3 explosionLight,
    inout float smokeOcclusion
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
    float sizeVariation = mix(0.78, 1.24, hash12(randomValue + seedBase));
    vec2 center = vec2(
        mix(-0.39, 0.34, randomValue.x) * aspect,
        DESERT_HORIZON + mix(-0.008, 0.070, randomValue.y)
    );

    vec2 delta = world - center;
    vec2 flattened = delta / vec2(1.0, 0.78);
    float radial = length(flattened);
    float angle = atan(flattened.y, flattened.x);
    vec2 directionPoint = vec2(cos(angle), sin(angle));
    float surfaceNoise = fbm(
        directionPoint * 2.25
            + vec2(cycle * 0.31 + seedBase, boundedAge * 1.8)
    ) - 0.5;

    float fireRadius = mix(0.006, 0.092, sqrt(boundedAge)) * sizeVariation;
    float noisyRadius = fireRadius * (1.0 + surfaceNoise * 0.28);
    float fireDistance = radial - noisyRadius;
    float fireFade = 1.0 - smoothstep(0.18, 0.86, boundedAge);
    float fireInterior = 1.0 - smoothstep(
        noisyRadius * 0.18,
        noisyRadius + aa,
        radial
    );
    fireInterior *= mix(0.72, 1.18, saturate(surfaceNoise + 0.5));
    float fireShell = strokeMask(
        fireDistance,
        mix(0.0080, 0.0025, boundedAge) * sizeVariation,
        aa
    );
    float hotCore = gaussianPoint(
        flattened,
        max(fireRadius * 0.42, 0.004)
    ) * exp(-boundedAge * 5.4);
    float fireBloom = gaussianPoint(
        flattened,
        max(fireRadius * 3.4, 0.018)
    ) * exp(-boundedAge * 2.1);

    float shockRadius = mix(0.016, 0.265, sqrt(boundedAge)) * sizeVariation;
    float shockDistance = length(delta / vec2(1.0, 0.58)) - shockRadius;
    float shock = strokeMask(
        shockDistance,
        mix(0.0040, 0.0015, boundedAge),
        aa
    ) * (1.0 - smoothstep(0.42, 0.92, boundedAge));
    float shockGlow = exp(-abs(shockDistance) / 0.011)
        * (1.0 - smoothstep(0.26, 0.82, boundedAge));

    float flash = (1.0 - smoothstep(0.0, 0.24, boundedAge));
    explosionLight += ENERGY_WHITE * hotCore * 1.05;
    explosionLight += FIRE_GOLD * fireInterior * fireFade * 0.68;
    explosionLight += FIRE_GOLD * fireShell * fireFade * 0.43;
    explosionLight += FIRE_RED * fireBloom * 0.31;
    explosionLight += ENERGY_WHITE * shock * 0.22;
    explosionLight += SAND_GOLD * shockGlow * 0.058;
    explosionLight += mix(FIRE_GOLD, ENERGY_WHITE, 0.52)
        * gaussianPoint(flattened, 0.13 * sizeVariation)
        * flash
        * 0.18;

    // Smoke rises, spreads, and is domain-warped independently from the fire.
    vec2 smokeCenter = center + vec2(
        0.018 * sin(cycle + seedBase) * boundedAge,
        mix(0.010, 0.090, boundedAge)
    );
    float smokeRadius = mix(0.020, 0.105, sqrt(boundedAge)) * sizeVariation;
    vec2 smokePoint = (world - smokeCenter) / max(smokeRadius, 0.001);
    smokePoint.x += 0.22 * sin(smokePoint.y * 2.1 + boundedAge * 2.0);
    float smokeNoise = fbm(
        smokePoint * 1.20
            + vec2(cycle * 0.73 + seedBase, -boundedAge * 1.35)
    );
    float smokeEnvelope = 1.0 - smoothstep(0.52, 1.18, length(smokePoint));
    float smokeCloud = smoothstep(0.43, 0.72, smokeNoise)
        * smokeEnvelope
        * smoothstep(0.13, 0.34, boundedAge)
        * (1.0 - smoothstep(0.82, 1.0, boundedAge));
    smokeOcclusion = max(smokeOcclusion, smokeCloud * 0.72);
    explosionLight += mix(SMOKE_BROWN, STORM_OCHRE, 0.24)
        * smokeCloud * 0.090;

#if PERF_EXPLOSION_SPARKS > 0
    for (int sparkIndex = 0; sparkIndex < PERF_EXPLOSION_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        float angleSeed = hash13(vec3(index, cycle + seedBase, 37.1));
        float speedSeed = hash13(vec3(index, cycle + seedBase, 81.3));
        float sparkAngle = mix(0.10, PI - 0.10, angleSeed);
        vec2 direction = vec2(cos(sparkAngle), sin(sparkAngle));
        float distanceTravelled = mix(0.045, 0.170, speedSeed)
            * boundedAge * sizeVariation;
        vec2 sparkCenter = center
            + direction * distanceTravelled
            + vec2(0.0, -0.115 * boundedAge * boundedAge * sizeVariation);
        vec2 sparkTail = sparkCenter
            - direction * mix(0.010, 0.034, speedSeed) * sizeVariation;
        float sparkDistance = sdCapsule(
            world,
            sparkTail,
            sparkCenter,
            aa * 0.44
        );
        float spark = fillMask(sparkDistance, aa)
            * (1.0 - smoothstep(0.48, 0.88, boundedAge));
        float sparkGlow = exp(-max(sparkDistance, 0.0) / max(aa * 4.0, 0.001));
        explosionLight += mix(FIRE_GOLD, ENERGY_WHITE, speedSeed)
            * (spark * 0.31 + sparkGlow * 0.040)
            * spark;
    }
#endif
}

void renderExplosions(
    vec2 world,
    float aspect,
    float aa,
    out vec3 explosionLight,
    out float smokeOcclusion
) {
    explosionLight = vec3(0.0);
    smokeOcclusion = 0.0;
    renderExplosionEvent(
        world,
        aspect,
        aa,
        17.0,
        3.7,
        0.46,
        0.205,
        11.0,
        explosionLight,
        smokeOcclusion
    );

#if PERF_SECOND_EXPLOSION
    renderExplosionEvent(
        world,
        aspect,
        aa,
        29.0,
        19.0,
        0.66,
        0.155,
        53.0,
        explosionLight,
        smokeOcclusion
    );
#endif
}

// =============================================================================
// FOREGROUND WINDBLOWN SAND
// =============================================================================

vec3 renderMicroSand(vec2 world) {
    vec3 sandLight = vec3(0.0);
    float resolutionHeight = max(iResolution.y, 1.0);

    // Fine grains use translated random cells instead of independent temporal
    // noise. The complete field therefore advects continuously with the wind
    // and never flickers between unrelated frames.
    for (int layerIndex = 0; layerIndex < PERF_MICRO_SAND_LAYERS; layerIndex++) {
        float layer = float(layerIndex);
        float depth = (layer + 0.5) / float(PERF_MICRO_SAND_LAYERS);
        float scale = mix(72.0, 142.0, depth);
        vec2 flowPoint = rotate2d(world, -0.070) * scale;
        flowPoint += vec2(
            -iTime * mix(5.0, 14.0, depth),
            0.35 * sin(iTime * 0.11 + layer * 2.7)
        );

        vec2 cell = floor(flowPoint);
        vec2 local = fract(flowPoint) - 0.5;
        float pixelWidth = scale / resolutionHeight;
        float halfWidth = max(
            mix(0.030, 0.052, depth),
            pixelWidth * 0.62
        );
        float verticalFade = 1.0 - smoothstep(0.34, 0.52, world.y);
        vec3 tint = mix(STORM_OCHRE, SAND_PALE, depth * 0.68);

        // Neighbouring cells are sampled because foreground streaks can cross
        // a cell edge. Without this 3x3 support they would pop at the boundary
        // instead of moving continuously with the translated wind field.
        for (int neighborY = -1; neighborY <= 1; neighborY++) {
            for (int neighborX = -1; neighborX <= 1; neighborX++) {
                vec2 neighbor = vec2(float(neighborX), float(neighborY));
                vec2 particleCell = cell + neighbor;
                vec2 offset = (
                    hash22(particleCell + layer * 37.1) - 0.5
                ) * 0.50;
                vec2 grainPoint = local - neighbor - offset;
                float identity = hash12(particleCell + layer * 83.7);
                float present = step(mix(0.82, 0.89, depth), identity);
                float halfLength = mix(0.10, 0.32, depth)
                    * mix(
                        0.72,
                        1.28,
                        hash12(particleCell + 11.3)
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
                float brightness = mix(0.42, 1.0, depth)
                    * mix(0.58, 1.0, identity)
                    * verticalFade;
                sandLight += tint
                    * grain
                    * brightness
                    * mix(0.026, 0.070, depth);
            }
        }
    }
    return sandLight;
}

vec3 renderSandParticles(vec2 world, float aspect, float aa) {
    vec3 sandLight = vec3(0.0);
    vec2 windDirection = normalize(vec2(1.0, 0.075));
    float pixel = 1.0 / max(iResolution.y, 1.0);

    for (int particleIndex = 0; particleIndex < PERF_SAND_PARTICLES; particleIndex++) {
        float index = float(particleIndex);
        float identity = hash13(vec3(index, 31.7, 9.1));
        float baseSpeed = mix(0.055, 0.22, identity);
        float clock = iTime * baseSpeed + identity * 9.0;
        float travel = fract(clock);
        float generation = floor(clock);
        vec2 randomValue = hash23(vec3(index, generation, 73.7));
        float depth = hash13(vec3(index, generation, 117.1));
        float nearFactor = pow(depth, 1.45);

        float x = mix(-0.64 * aspect, 0.64 * aspect, travel);
        float y = mix(-0.46, 0.38, randomValue.y);
        float gust = sin(
            travel * TAU * mix(0.7, 1.8, identity)
                + index * 2.1
                + iTime * 0.17
        );
        y += gust * mix(0.004, 0.024, nearFactor);
        y += 0.018 * sin(iTime * 0.043 + generation + index) * travel;
        vec2 center = vec2(x, y);

        float lengthPixels = mix(2.0, 30.0, nearFactor)
            * mix(0.72, 1.24, randomValue.x);
        float widthPixels = mix(0.38, 1.45, nearFactor);
        vec2 tail = center - windDirection * lengthPixels * pixel;
        float particleDistance = sdCapsule(
            world,
            tail,
            center,
            widthPixels * pixel
        );
        float core = fillMask(particleDistance, aa);
        float glow = exp(
            -max(particleDistance, 0.0)
                / max(widthPixels * pixel * 3.5, pixel)
        );
        float lifecycle = smoothstep(0.0, 0.055, travel)
            * (1.0 - smoothstep(0.93, 1.0, travel));
        float verticalFade = 1.0 - smoothstep(0.36, 0.52, y);
        float brightness = lifecycle * verticalFade
            * mix(0.26, 1.00, nearFactor)
            * mix(0.58, 1.0, identity);
        vec3 tint = mix(STORM_OCHRE, SAND_PALE, nearFactor * 0.78);
        sandLight += tint * (core * 0.25 + glow * 0.036) * brightness;
    }
    return sandLight;
}

// =============================================================================
// COMPLETE DESERT SCENE
// =============================================================================

vec4 renderDesertScene(vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    float aspect = resolution.x / resolution.y;
    vec2 world = (fragCoord - 0.5 * resolution) / resolution.y;
    float aa = 1.25 / resolution.y;

    // A tiny coherent camera drift keeps the landscape alive while all layers
    // retain a shared horizon and therefore still feel physically connected.
    vec2 cameraDrift = vec2(
        0.004 * sin(iTime * 0.018),
        0.002 * sin(iTime * 0.013 + 1.7)
    );
    vec2 sceneWorld = world + cameraDrift;

    float stormDensity;
    vec3 scene = renderStormSky(sceneWorld, aspect, stormDensity);

    float farHeight = terrainHeight(
        sceneWorld.x,
        DESERT_HORIZON + 0.014,
        0.058,
        1.72,
        7.3,
        -0.0010
    );
    float farMask = terrainBelow(sceneWorld, farHeight, aa * 1.4);
    vec3 farColor = mix(FAR_DUNE, STORM_UMBRA, stormDensity * 0.28);
    scene = mix(scene, farColor, farMask);
    float farRim = exp(
        -abs(sceneWorld.y - farHeight) / max(0.0055, aa * 3.0)
    );
    scene += HORIZON_AMBER * farRim * 0.032;

    float ruinMask;
    vec3 ruinLights;
    renderRuinedOutposts(sceneWorld, aa, ruinMask, ruinLights);
    scene = mix(scene, RUIN_INK, ruinMask * 0.88);

    float creatureMask;
    vec3 creatureLight;
    renderDistantKlaxosaur(
        sceneWorld,
        aspect,
        aa,
        creatureMask,
        creatureLight
    );
    vec3 creatureBody = KLAX_INK + KLAX_BLUE * 0.012;
    scene = mix(scene, creatureBody, creatureMask * 0.94);

    float franxxMaskA;
    vec3 franxxLightA;
    renderTinyFranxx(
        sceneWorld,
        aspect,
        0.0,
        FRANXX_RED,
        aa,
        franxxMaskA,
        franxxLightA
    );
    scene = mix(scene, vec3(0.025, 0.020, 0.025), franxxMaskA * 0.76);

    float franxxMaskB;
    vec3 franxxLightB;
    renderTinyFranxx(
        sceneWorld,
        aspect,
        2.8,
        mix(KLAX_CYAN, FRANXX_IVORY, 0.52),
        aa,
        franxxMaskB,
        franxxLightB
    );
    scene = mix(scene, vec3(0.020, 0.024, 0.030), franxxMaskB * 0.72);

    float midHeight = terrainHeight(
        sceneWorld.x,
        DESERT_HORIZON - 0.052,
        0.073,
        2.48,
        31.9,
        -0.0022
    );
    float midMask = terrainBelow(sceneWorld, midHeight, aa * 1.35);
    vec3 midColor = MID_DUNE * mix(0.82, 1.15, stormDensity);
    scene = mix(scene, midColor, midMask);
    float midRim = exp(
        -abs(sceneWorld.y - midHeight) / max(0.0045, aa * 2.6)
    );
    scene += SAND_GOLD * midRim * 0.021;

    float nearHeight = terrainHeight(
        sceneWorld.x,
        DESERT_HORIZON - 0.205,
        0.105,
        1.28,
        67.1,
        -0.0036
    );
    float nearMask = terrainBelow(sceneWorld, nearHeight, aa * 1.5);
    float groundDepth = max(DESERT_HORIZON - sceneWorld.y, 0.0);
    float rippleNoise = valueNoise(vec2(
        sceneWorld.x * 5.0 - iTime * 0.014,
        groundDepth * 27.0
    ));
    float sandRipple = 0.5 + 0.5 * sin(
        groundDepth * 132.0
            + sceneWorld.x * 8.5 / max(groundDepth + 0.10, 0.10)
            + rippleNoise * 4.0
    );
    sandRipple = smoothstep(0.80, 0.98, sandRipple)
        * smoothstep(0.02, 0.34, groundDepth);
    vec3 nearColor = NEAR_DUNE
        + SAND_GOLD * sandRipple * 0.020;
    scene = mix(scene, nearColor, nearMask);
    float nearRim = exp(
        -abs(sceneWorld.y - nearHeight) / max(0.0040, aa * 2.4)
    );
    scene += SAND_GOLD * nearRim * 0.014;

    vec3 combatLight;
    renderCombatSignals(sceneWorld, aspect, aa, combatLight);

    vec3 explosionLight;
    float smokeOcclusion;
    renderExplosions(
        sceneWorld,
        aspect,
        aa,
        explosionLight,
        smokeOcclusion
    );

    // Atmospheric perspective dims distant silhouettes and turns their light
    // into a small warm/cyan halo instead of laying clean vectors over the sky.
    float battleTransmission = mix(1.0, 0.58, stormDensity);
    vec3 distantLight = ruinLights
        + creatureLight
        + franxxLightA
        + franxxLightB
        + combatLight;
    distantLight *= battleTransmission;

    scene *= 1.0 - smokeOcclusion * 0.52;
    scene += SMOKE_BROWN * smokeOcclusion * 0.045;
    scene += distantLight;
    scene += explosionLight;

    // A front sheet of dust veils every distant layer, while individual grains
    // remain sharp because they are composited after it.
    float frontHaze = stormDensity
        * (1.0 - smoothstep(0.31, 0.53, sceneWorld.y));
    scene = mix(scene, STORM_OCHRE, frontHaze * 0.145);
    scene += renderMicroSand(sceneWorld);
    scene += renderSandParticles(sceneWorld, aspect, aa);

    float vignette = 1.0 - VIGNETTE_STRENGTH * smoothstep(
        0.28,
        1.12,
        length((uv - 0.5) * vec2(aspect, 1.0))
    );
    scene *= vignette;
    scene = vec3(1.0) - exp(-max(scene, vec3(0.0)) * SCENE_EXPOSURE);

    float visibility = saturate(
        luminance(scene) * 2.0
            + luminance(distantLight + explosionLight) * 0.65
    );
    return vec4(scene, visibility);
}

// =============================================================================
// MOVING CURSOR — SYNCHRONIZED STRIKE CRAFT
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

void applyStrikeCursor(inout vec4 color, vec2 fragCoord) {
    vec4 untouched = color;
    if (iCursorVisible == 0) {
        return;
    }

    vec2 head = cursorCenterPx(iCurrentCursor);
    vec2 tail = cursorCenterPx(iPreviousCursor);
    vec2 movement = head - tail;
    float moved = length(movement);
    float cursorSize = max(iCurrentCursor.z, iCurrentCursor.w);
    float age = saturate((iTime - iTimeCursorChange) / 0.31);

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
    float effectRadius = cursorSize * mix(2.5, 3.8, movementFactor);
    if (
        any(lessThan(fragCoord, min(head, tail) - vec2(effectRadius)))
        || any(greaterThan(fragCoord, max(head, tail) + vec2(effectRadius)))
    ) {
        return;
    }

    float easedAge = 1.0 - pow(1.0 - age, 3.0);
    float life = pow(1.0 - easedAge, 1.65);
    float pulse = sin(age * PI);
    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float along = segmentParameter(fragCoord, tail, head);
    vec2 pathCenter = mix(tail, head, along);
    float signedAcross = dot(fragCoord - pathCenter, normal);
    float pathWindow = smoothstep(0.0, 0.18, along) * life;
    float tailTaper = mix(0.18, 1.0, pow(along, 0.72));

    vec2 uv = clamp(
        fragCoord / max(iResolution.xy, vec2(1.0)),
        vec2(0.0),
        vec2(1.0)
    );
    vec4 terminalSample = texture(iChannel0, uv);
    float contentProtection = mix(
        0.20,
        1.0,
        backgroundCellMask(terminalSample)
    );

    // Two partner-colored trails oscillate toward one another and synchronize
    // at the cursor. Their phase is fixed to movement age, not wall-clock time,
    // so each keystroke creates a coherent gesture.
    float braidAmplitude = cursorSize
        * mix(0.16, 0.34, movementFactor)
        * (1.0 - along)
        * sin(along * TAU * 1.75 - easedAge * PI);
    float ribbonRadius = cursorSize * mix(0.055, 0.105, movementFactor);
    float redDistance = abs(signedAcross - braidAmplitude);
    float blueDistance = abs(signedAcross + braidAmplitude);
    float redRibbon = exp(-redDistance / max(ribbonRadius, 0.5))
        * pathWindow * tailTaper;
    float blueRibbon = exp(-blueDistance / max(ribbonRadius, 0.5))
        * pathWindow * tailTaper;
    float synchronizedCore = exp(
        -abs(signedAcross) / max(cursorSize * 0.055, 0.5)
    ) * pathWindow * smoothstep(0.48, 1.0, along);

    float dustWake = exp(
        -abs(signedAcross)
            / max(cursorSize * mix(0.85, 0.32, along), 0.5)
    ) * pathWindow
      * (0.55 + 0.45 * sin(along * PI));
    color.rgb = mix(
        color.rgb,
        STORM_OCHRE,
        dustWake * 0.090 * contentProtection
    );
    color.rgb += FRANXX_RED
        * redRibbon * 0.27 * contentProtection;
    color.rgb += KLAX_CYAN
        * blueRibbon * 0.22 * contentProtection;
    color.rgb += ENERGY_WHITE
        * synchronizedCore * 0.28 * contentProtection;

    // Destination craft in movement-aligned coordinates.
    vec2 relative = fragCoord - head;
    vec2 local = vec2(dot(relative, direction), dot(relative, normal));
    float bodyLength = cursorSize * mix(0.72, 1.08, movementFactor);
    float bodyRadius = cursorSize * 0.19;
    float bodyDistance = sdCapsule(
        local,
        vec2(-bodyLength * 0.48, 0.0),
        vec2(bodyLength * 0.34, 0.0),
        bodyRadius
    );
    float body = fillMask(bodyDistance, 1.15) * life;
    float bodyShell = strokeMask(bodyDistance, cursorSize * 0.075, 1.15)
        * life;

    float upperWingDistance = sdCapsule(
        local,
        vec2(-bodyLength * 0.20, bodyRadius * 0.20),
        vec2(-bodyLength * 0.58, cursorSize * 0.78),
        cursorSize * 0.075
    );
    float lowerWingDistance = sdCapsule(
        local,
        vec2(-bodyLength * 0.20, -bodyRadius * 0.20),
        vec2(-bodyLength * 0.58, -cursorSize * 0.78),
        cursorSize * 0.075
    );
    float wings = max(
        fillMask(upperWingDistance, 1.15),
        fillMask(lowerWingDistance, 1.15)
    ) * life;

    float spearDistance = sdCapsule(
        local,
        vec2(bodyLength * 0.18, 0.0),
        vec2(bodyLength * 1.06, 0.0),
        cursorSize * 0.045
    );
    float spear = fillMask(spearDistance, 1.05) * life;
    float spearGlow = exp(
        -max(spearDistance, 0.0) / max(cursorSize * 0.25, 0.5)
    ) * life;

    float canopyDistance = sdEllipse(
        local - vec2(bodyLength * 0.12, 0.0),
        vec2(bodyLength * 0.24, bodyRadius * 0.72)
    );
    float canopy = fillMask(canopyDistance, 1.15) * life;
    float destinationGlow = gaussianPoint(
        relative,
        cursorSize * mix(1.0, 1.65, movementFactor)
    ) * life;

    color.rgb += FRANXX_ROSE
        * destinationGlow * 0.075 * contentProtection;
    color.rgb += FRANXX_RED
        * spearGlow * 0.085 * contentProtection;
    color.rgb = mix(
        color.rgb,
        vec3(0.032, 0.027, 0.035),
        body * 0.54 * contentProtection
    );
    color.rgb = mix(
        color.rgb,
        FRANXX_IVORY,
        bodyShell * 0.72 * contentProtection
    );
    color.rgb = mix(
        color.rgb,
        FRANXX_RED,
        wings * 0.72 * contentProtection
    );
    color.rgb = mix(
        color.rgb,
        KLAX_CYAN,
        canopy * 0.43 * contentProtection
    );
    color.rgb += ENERGY_WHITE
        * spear * 0.58 * contentProtection;

    float shockRadius = cursorSize * mix(0.72, 2.45, easedAge);
    float shockDistance = length(relative) - shockRadius;
    float shockRing = strokeMask(
        shockDistance,
        cursorSize * 0.055,
        1.15
    ) * life * (1.0 - easedAge);
    color.rgb += mix(FRANXX_ROSE, ENERGY_WHITE, 0.56)
        * shockRing * 0.20 * contentProtection;

#if PERF_CURSOR_SPARKS > 0
    for (int sparkIndex = 0; sparkIndex < PERF_CURSOR_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        vec2 eventSeed = head * 0.037 + tail * 0.091;
        float alongSeed = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
        float sideSeed = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
        float sparkAlong = mix(0.10, 0.82, alongSeed);
        vec2 sparkCenter = mix(tail, head, sparkAlong)
            + normal * (sideSeed - 0.5) * cursorSize * 1.35;
        vec2 sparkTail = sparkCenter
            - direction * cursorSize * mix(0.16, 0.42, sideSeed);
        float sparkDistance = sdCapsule(
            fragCoord,
            sparkTail,
            sparkCenter,
            max(cursorSize * 0.028, 0.55)
        );
        float spark = fillMask(sparkDistance, 1.0)
            * life
            * smoothstep(0.0, 0.20, sparkAlong);
        color.rgb += mix(SAND_GOLD, ENERGY_WHITE, sideSeed)
            * spark * 0.23 * contentProtection;
    }
#endif

    // Restore the exact terminal cursor rectangle after every additive and mix
    // operation, including its text color and alpha.
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
    vec4 desert = renderDesertScene(fragCoord);

    float backgroundMask = backgroundCellMask(terminalColor);
    vec3 darkTerminal = terminalColor.rgb * TERMINAL_BACKGROUND_DARKEN;
    vec3 desertBackground = mix(
        darkTerminal,
        desert.rgb,
        DESERT_SCENE_MIX
    );
    vec3 composite = mix(
        terminalColor.rgb,
        desertBackground,
        backgroundMask
    );

    float outputAlpha = max(
        terminalColor.a,
        backgroundMask * SCENE_ALPHA_BOOST * desert.a
    );
    fragColor = vec4(clamp(composite, 0.0, 1.0), outputAlpha);
    applyStrikeCursor(fragColor, fragCoord);
}
