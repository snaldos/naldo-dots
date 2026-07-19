// Ghostty combined shader — Strelizia Synchronization
//
// An original, abstract fan homage inspired by Zero Two, Hiro, and their
// shared FRANXX: crimson and cyan partner ribbons, a quiet cockpit HUD,
// wing-like light, and a dual-strand cursor trail that synchronizes at rest.
// No external artwork, textures, or shader code are used.
//
// Ghostty:
//   ghostty-shaders.sh set combined darling-strelizia
//   custom-shader-animation = true

// =============================================================================
// PERFORMANCE PROFILE
// =============================================================================

#define DARLING_GPU_ECO      0
#define DARLING_GPU_BALANCED 1
#define DARLING_GPU_QUALITY  2
#define DARLING_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
    #define GHOSTTY_GPU_PROFILE DARLING_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == DARLING_GPU_ECO
    #define STAR_LAYERS        2
    #define DRIFT_PARTICLES    3
    #define CURSOR_SPARKS      0
#elif GHOSTTY_GPU_PROFILE == DARLING_GPU_BALANCED
    #define STAR_LAYERS        3
    #define DRIFT_PARTICLES    5
    #define CURSOR_SPARKS      3
#elif GHOSTTY_GPU_PROFILE == DARLING_GPU_QUALITY
    #define STAR_LAYERS        4
    #define DRIFT_PARTICLES    8
    #define CURSOR_SPARKS      5
#else
    #define STAR_LAYERS        5
    #define DRIFT_PARTICLES    12
    #define CURSOR_SPARKS      8
#endif

// =============================================================================
// PALETTE AND TUNING
// =============================================================================

const vec3 NIGHT_INK       = vec3(0.008, 0.014, 0.040);
const vec3 ZERO_TWO_RED    = vec3(1.000, 0.035, 0.190);
const vec3 ZERO_TWO_PINK   = vec3(1.000, 0.260, 0.540);
const vec3 HIRO_BLUE       = vec3(0.025, 0.390, 1.000);
const vec3 HIRO_CYAN       = vec3(0.180, 0.870, 1.000);
const vec3 STRELIZIA_WHITE = vec3(0.940, 0.980, 1.000);
const vec3 COCKPIT_GOLD    = vec3(1.000, 0.720, 0.300);

const float PI  = 3.14159265359;
const float TAU = 6.28318530718;

const float BACKGROUND_DARKEN = 0.52;
const float SCENE_ALPHA_BOOST = 0.105;
const float CURSOR_DURATION   = 0.34;

// =============================================================================
// SHARED HELPERS
// =============================================================================

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float hash12(vec2 point) {
    vec3 p3 = fract(vec3(point.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 point) {
    float first = hash12(point);
    return vec2(first, hash12(point + first + 19.19));
}

mat2 rotation2D(float angle) {
    float cosineValue = cos(angle);
    float sineValue = sin(angle);
    return mat2(cosineValue, -sineValue, sineValue, cosineValue);
}

float segmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    float position = clamp(
        dot(point - startPoint, segment)
            / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );
    return length(point - startPoint - segment * position);
}

float softLine(float distanceValue, float width) {
    float safeWidth = max(width, 0.000001);
    return exp(-distanceValue * distanceValue / (safeWidth * safeWidth));
}

float ringMask(float distanceValue, float radius, float width) {
    float antialiasWidth = max(fwidth(distanceValue), width * 0.16);
    return 1.0 - smoothstep(
        width,
        width + antialiasWidth,
        abs(distanceValue - radius)
    );
}

float terminalBackgroundMask(vec4 terminalColor) {
    float colorDifference = length(terminalColor.rgb - iBackgroundColor);
    float colorSimilarity = 1.0 - smoothstep(0.035, 0.260, colorDifference);
    float transparentCell = 1.0 - smoothstep(0.22, 0.94, terminalColor.a);
    float darkFallback = 1.0 - smoothstep(0.10, 0.42, luminance(terminalColor.rgb));
    return clamp(
        max(transparentCell, max(colorSimilarity, darkFallback * 0.24)),
        0.0,
        1.0
    );
}

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

// =============================================================================
// BACKGROUND — PARTNER STARFIELD
// =============================================================================

vec3 partnerStars(vec2 world, float aspect) {
    vec3 color = vec3(0.0);

    for (int layerIndex = 0; layerIndex < STAR_LAYERS; ++layerIndex) {
        float layer = float(layerIndex);
        float scale = 8.0 + layer * 6.5;
        vec2 drift = vec2(
            iTime * (0.010 + layer * 0.002),
            -iTime * (0.004 + layer * 0.001)
        );
        vec2 gridPoint = world * scale + drift;
        vec2 cell = floor(gridPoint);
        vec2 local = fract(gridPoint) - 0.5;
        vec2 randomOffset = (hash22(cell + layer * 31.7) - 0.5) * 0.74;
        float randomValue = hash12(cell + layer * 73.1);
        float exists = step(0.79 + layer * 0.025, randomValue);
        float distanceToStar = length(local - randomOffset);
        float core = softLine(distanceToStar, 0.020 + 0.004 * layer);
        float halo = softLine(distanceToStar, 0.075 + 0.008 * layer);
        float twinkle = 0.72 + 0.28 * sin(
            iTime * (0.65 + randomValue * 1.8) + randomValue * 41.0
        );
        vec3 tint = mix(HIRO_CYAN, ZERO_TWO_PINK, hash12(cell + 9.7));
        tint = mix(tint, STRELIZIA_WHITE, 0.50 + 0.35 * randomValue);
        color += tint * exists * twinkle * (core * 0.70 + halo * 0.10);
    }

    float edgeFade = 1.0 - smoothstep(aspect * 0.44, aspect * 0.72, abs(world.x));
    return color * (0.45 + 0.55 * edgeFade);
}

// =============================================================================
// BACKGROUND — STRELIZIA HUD AND WINGS
// =============================================================================

vec3 synchronizationHud(vec2 world) {
    vec2 center = vec2(0.24, 0.015);
    vec2 point = world - center;
    float radius = length(point);
    float angle = atan(point.y, point.x);

    float outerRing = ringMask(radius, 0.285, 0.0027);
    float middleRing = ringMask(radius, 0.218, 0.0022);
    float innerRing = ringMask(radius, 0.104, 0.0018);

    float outerDashes = smoothstep(0.22, 0.78, 0.5 + 0.5 * sin(angle * 24.0 - iTime * 0.42));
    float middleDashes = smoothstep(0.08, 0.92, 0.5 + 0.5 * sin(angle * 12.0 + iTime * 0.27));
    float sweep = softLine(
        abs(mod(angle - iTime * 0.16 + PI, TAU) - PI),
        0.055
    ) * smoothstep(0.09, 0.28, radius);

    vec3 rings = HIRO_CYAN * outerRing * outerDashes * 0.25;
    rings += ZERO_TWO_PINK * middleRing * middleDashes * 0.24;
    rings += STRELIZIA_WHITE * innerRing * 0.20;
    rings += mix(HIRO_BLUE, ZERO_TWO_RED, 0.5 + 0.5 * sin(angle))
        * sweep
        * 0.17;

    // A subdued double-X synchronization sigil.
    vec2 sigilCenter = center;
    vec2 offset = vec2(0.030, 0.0);
    vec2 arm = vec2(0.038, 0.058);
    float firstX = min(
        segmentDistance(world, sigilCenter - offset - arm, sigilCenter - offset + arm),
        segmentDistance(
            world,
            sigilCenter - offset + vec2(-arm.x, arm.y),
            sigilCenter - offset + vec2(arm.x, -arm.y)
        )
    );
    float secondX = min(
        segmentDistance(world, sigilCenter + offset - arm, sigilCenter + offset + arm),
        segmentDistance(
            world,
            sigilCenter + offset + vec2(-arm.x, arm.y),
            sigilCenter + offset + vec2(arm.x, -arm.y)
        )
    );
    rings += ZERO_TWO_PINK * softLine(firstX, 0.0032) * 0.25;
    rings += HIRO_CYAN * softLine(secondX, 0.0032) * 0.25;

    // Mirrored light feathers suggest Strelizia without drawing literal art.
    vec2 wingPoint = world - center;
    float side = abs(wingPoint.x);
    float wingDomain = smoothstep(0.10, 0.17, side)
        * (1.0 - smoothstep(0.56, 0.72, side));
    float upperCurve = abs(
        wingPoint.y - (0.055 + 0.30 * pow(max(side - 0.08, 0.0), 0.78))
    );
    float lowerCurve = abs(
        wingPoint.y + (0.025 + 0.20 * pow(max(side - 0.10, 0.0), 0.86))
    );
    float featherCuts = 0.45 + 0.55 * smoothstep(
        -0.20,
        0.55,
        sin(side * 76.0 - abs(wingPoint.y) * 22.0)
    );
    vec3 wingTint = mix(HIRO_CYAN, ZERO_TWO_PINK, step(0.0, wingPoint.x));
    rings += wingTint
        * wingDomain
        * featherCuts
        * (softLine(upperCurve, 0.010) + softLine(lowerCurve, 0.008))
        * 0.105;

    return rings;
}

// =============================================================================
// BACKGROUND — ZERO TWO / HIRO ENERGY RIBBONS
// =============================================================================

vec3 partnerRibbons(vec2 world, float aspect) {
    vec2 point = rotation2D(-0.075) * (world - vec2(-0.08, -0.015));
    float envelope = 1.0 - smoothstep(aspect * 0.42, aspect * 0.62, abs(point.x));
    float breathing = 0.84 + 0.16 * sin(iTime * 0.31);
    float wave = 0.075
        * breathing
        * sin(point.x * 6.2 - iTime * 0.34)
        * (0.72 + 0.28 * cos(point.x * 2.1));

    float redDistance = abs(point.y - wave);
    float blueDistance = abs(point.y + wave);
    float redCore = softLine(redDistance, 0.0028);
    float blueCore = softLine(blueDistance, 0.0028);
    float redGlow = softLine(redDistance, 0.030);
    float blueGlow = softLine(blueDistance, 0.030);

    vec3 color = ZERO_TWO_PINK * (redCore * 0.25 + redGlow * 0.045);
    color += HIRO_CYAN * (blueCore * 0.25 + blueGlow * 0.045);

    float synchronization = softLine(abs(wave), 0.012)
        * softLine(abs(point.y), 0.020);
    color += STRELIZIA_WHITE * synchronization * 0.20;

    return color * envelope;
}

vec3 driftingEmbers(vec2 world, float aspect) {
    vec3 color = vec3(0.0);

    for (int particleIndex = 0; particleIndex < DRIFT_PARTICLES; ++particleIndex) {
        float indexValue = float(particleIndex);
        vec2 seed = hash22(vec2(indexValue * 17.13, indexValue * 41.71));
        float speed = 0.010 + hash12(seed + 4.2) * 0.018;
        vec2 wrappedPosition = fract(
            seed + vec2(speed * iTime, -speed * iTime * 0.37)
        );
        vec2 position = vec2(
            mix(-aspect * 0.56, aspect * 0.56, wrappedPosition.x),
            mix(-0.55, 0.55, wrappedPosition.y)
        );
        float size = mix(0.0020, 0.0048, hash12(seed + 8.8));
        float particle = softLine(length(world - position), size);
        vec3 tint = mix(ZERO_TWO_PINK, HIRO_CYAN, step(0.5, hash12(seed + 2.1)));
        color += tint * particle * 0.28;
    }

    return color;
}

vec4 renderStreliziaScene(vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    vec2 world = (fragCoord - 0.5 * resolution) / resolution.y;
    float aspect = resolution.x / resolution.y;
    vec4 terminal = texture(iChannel0, uv);
    float background = terminalBackgroundMask(terminal);

    vec3 scene = NIGHT_INK * 0.20;
    scene += partnerStars(world, aspect);
    scene += synchronizationHud(world);
    scene += partnerRibbons(world, aspect);
    scene += driftingEmbers(world, aspect);

    float vignette = 1.0 - 0.25 * smoothstep(
        0.32,
        0.92,
        length(world / vec2(max(aspect * 0.64, 0.01), 0.66))
    );
    scene *= vignette;
    scene = vec3(1.0) - exp(-scene * 1.08);

    vec3 base = mix(
        terminal.rgb,
        terminal.rgb * BACKGROUND_DARKEN,
        background * 0.72
    );
    vec3 finalColor = base + scene * background;
    float visibility = clamp(luminance(scene) * 2.5, 0.0, 1.0);
    float finalAlpha = max(
        terminal.a,
        background * SCENE_ALPHA_BOOST * visibility
    );

    return vec4(finalColor, finalAlpha);
}

// =============================================================================
// CURSOR — DUAL-PISTIL SYNCHRONIZATION
// =============================================================================

vec4 applyStreliziaCursor(
    vec4 sceneColor,
    vec4 terminalColor,
    vec2 fragCoord
) {
    if (
        iCursorVisible <= 0
        || iCurrentCursor.z <= 0.0
        || iCurrentCursor.w <= 0.0
    ) {
        return sceneColor;
    }

    vec2 head = cursorCenterPx(iCurrentCursor);
    vec2 tail = cursorCenterPx(iPreviousCursor);
    float cursorSize = max(iCurrentCursor.z, iCurrentCursor.w);
    float travel = length(head - tail);
    float age = clamp(
        (iTime - iTimeCursorChange) / CURSOR_DURATION,
        0.0,
        1.0
    );
    float movementLife = pow(1.0 - age, 2.1) * step(cursorSize * 0.20, travel);

    float effectRadius = cursorSize * 4.2;
    vec2 boundsMinimum = min(head, tail) - effectRadius;
    vec2 boundsMaximum = max(head, tail) + effectRadius;
    if (
        any(lessThan(fragCoord, boundsMinimum))
        || any(greaterThan(fragCoord, boundsMaximum))
    ) {
        return sceneColor;
    }

    float contentPermission = mix(
        0.16,
        1.0,
        terminalBackgroundMask(terminalColor)
    );
    vec3 result = sceneColor.rgb;

    // Persistent paired ring: pink and cyan halves rotate toward one another.
    vec2 headVector = fragCoord - head;
    float headDistance = length(headVector);
    float headAngle = atan(headVector.y, headVector.x);
    float idlePulse = 0.88 + 0.12 * sin(iTime * 2.2);
    float ring = ringMask(headDistance, cursorSize * 0.92 * idlePulse, cursorSize * 0.075);
    float sideMix = smoothstep(-0.22, 0.22, sin(headAngle + iTime * 0.46));
    vec3 pairedRingColor = mix(ZERO_TWO_PINK, HIRO_CYAN, sideMix);
    float ringStrength = ring * (0.105 + movementLife * 0.16);
    result = mix(result, pairedRingColor, ringStrength * contentPermission);

    float innerGlow = softLine(headDistance, cursorSize * 0.82);
    result += mix(ZERO_TWO_RED, HIRO_BLUE, 0.50)
        * innerGlow
        * 0.018
        * contentPermission;

    if (movementLife > 0.0001) {
        vec2 movement = head - tail;
        float movementLengthSquared = max(dot(movement, movement), 0.000001);
        float along = clamp(
            dot(fragCoord - tail, movement) / movementLengthSquared,
            0.0,
            1.0
        );
        vec2 pathCenter = mix(tail, head, along);
        vec2 direction = movement / max(travel, 0.000001);
        vec2 normal = vec2(-direction.y, direction.x);
        float braid = sin(along * PI)
            * sin(along * TAU * 1.5 + age * 4.0)
            * cursorSize
            * 0.34;
        vec2 redCenter = pathCenter + normal * braid;
        vec2 blueCenter = pathCenter - normal * braid;
        float redDistance = length(fragCoord - redCenter);
        float blueDistance = length(fragCoord - blueCenter);
        float tailFade = smoothstep(0.02, 0.30, along);
        float strandLife = movementLife * tailFade;

        float redCore = softLine(redDistance, cursorSize * 0.105);
        float blueCore = softLine(blueDistance, cursorSize * 0.105);
        float redGlow = softLine(redDistance, cursorSize * 0.48);
        float blueGlow = softLine(blueDistance, cursorSize * 0.48);

        result += ZERO_TWO_PINK
            * (redCore * 0.22 + redGlow * 0.055)
            * strandLife
            * contentPermission;
        result += HIRO_CYAN
            * (blueCore * 0.22 + blueGlow * 0.055)
            * strandLife
            * contentPermission;

        float joinedCore = min(redDistance, blueDistance);
        float syncFlash = softLine(joinedCore, cursorSize * 0.060)
            * softLine(abs(braid), cursorSize * 0.15);
        result += STRELIZIA_WHITE
            * syncFlash
            * strandLife
            * 0.22
            * contentPermission;

#if CURSOR_SPARKS > 0
        vec2 eventSeed = head * 0.071 + tail * 0.113
            + floor(iTimeCursorChange * 1000.0);
        for (int sparkIndex = 0; sparkIndex < CURSOR_SPARKS; ++sparkIndex) {
            float indexValue = float(sparkIndex);
            float sparkAlong = mix(
                0.12,
                0.96,
                hash12(eventSeed + vec2(indexValue * 13.7, indexValue * 31.1))
            );
            float sparkSide = (
                hash12(eventSeed + vec2(indexValue * 47.3, indexValue * 7.9)) * 2.0 - 1.0
            ) * cursorSize * 0.88 * sin(sparkAlong * PI);
            vec2 sparkPosition = mix(tail, head, sparkAlong) + normal * sparkSide;
            float sparkRadius = cursorSize * mix(
                0.055,
                0.115,
                hash12(eventSeed + indexValue * 19.3)
            );
            float spark = softLine(length(fragCoord - sparkPosition), sparkRadius);
            vec3 sparkTint = mix(
                ZERO_TWO_PINK,
                HIRO_CYAN,
                step(0.5, hash12(eventSeed + indexValue * 59.7))
            );
            result += mix(sparkTint, STRELIZIA_WHITE, 0.45)
                * spark
                * movementLife
                * 0.31
                * contentPermission;
        }
#endif
    }

    vec4 outputColor = vec4(result, sceneColor.a);
    float preserveCursor = insideCursorRectangle(fragCoord, iCurrentCursor);
    return mix(outputColor, sceneColor, preserveCursor);
}

// =============================================================================
// MAIN
// =============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / max(iResolution.xy, vec2(1.0));
    vec4 terminal = texture(iChannel0, uv);
    vec4 scene = renderStreliziaScene(fragCoord);
    fragColor = applyStreliziaCursor(scene, terminal, fragCoord);
}
