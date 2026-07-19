// Ghostty combined shader — The Promise
//
// An original, abstract fan homage inspired by Zero Two and Hiro: a quiet
// indigo dawn, paired stars, a braided promise-thread, drifting blossom
// petals, and a cursor that leaves two luminous paths but one destination.
// No external artwork, textures, or shader code are used.
//
// Ghostty:
//   ghostty-shaders.sh set combined darling-promise
//   custom-shader-animation = true

// =============================================================================
// PERFORMANCE PROFILE
// =============================================================================

#define PROMISE_GPU_ECO      0
#define PROMISE_GPU_BALANCED 1
#define PROMISE_GPU_QUALITY  2
#define PROMISE_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
    #define GHOSTTY_GPU_PROFILE PROMISE_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == PROMISE_GPU_ECO
    #define SKY_STAR_LAYERS  1
    #define PETAL_COUNT      5
    #define CURSOR_PETALS    0
#elif GHOSTTY_GPU_PROFILE == PROMISE_GPU_BALANCED
    #define SKY_STAR_LAYERS  2
    #define PETAL_COUNT      9
    #define CURSOR_PETALS    3
#elif GHOSTTY_GPU_PROFILE == PROMISE_GPU_QUALITY
    #define SKY_STAR_LAYERS  3
    #define PETAL_COUNT      14
    #define CURSOR_PETALS    5
#else
    #define SKY_STAR_LAYERS  4
    #define PETAL_COUNT      20
    #define CURSOR_PETALS    8
#endif

// =============================================================================
// PALETTE AND TUNING
// =============================================================================

const vec3 DEEP_INDIGO  = vec3(0.010, 0.012, 0.055);
const vec3 DAWN_VIOLET  = vec3(0.155, 0.080, 0.250);
const vec3 DAWN_ROSE    = vec3(0.520, 0.105, 0.230);
const vec3 ZERO_PINK    = vec3(1.000, 0.250, 0.520);
const vec3 PETAL_BLUSH  = vec3(1.000, 0.650, 0.780);
const vec3 HIRO_CYAN    = vec3(0.200, 0.820, 1.000);
const vec3 MEMORY_BLUE  = vec3(0.190, 0.330, 0.920);
const vec3 MOON_WHITE   = vec3(0.890, 0.930, 1.000);
const vec3 PROMISE_GOLD = vec3(1.000, 0.760, 0.380);

const float PI  = 3.14159265359;
const float TAU = 6.28318530718;

const float BACKGROUND_DARKEN = 0.56;
const float SCENE_ALPHA_BOOST = 0.090;
const float CURSOR_DURATION   = 0.52;

// =============================================================================
// HELPERS
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
    return vec2(first, hash12(point + first + 23.17));
}

vec2 rotatePoint(vec2 point, float angle) {
    float cosineValue = cos(angle);
    float sineValue = sin(angle);
    return vec2(
        cosineValue * point.x - sineValue * point.y,
        sineValue * point.x + cosineValue * point.y
    );
}

float softPoint(float distanceValue, float radius) {
    float safeRadius = max(radius, 0.000001);
    return exp(-distanceValue * distanceValue / (safeRadius * safeRadius));
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

float ringMask(float distanceValue, float radius, float width) {
    float antialiasWidth = max(fwidth(distanceValue), width * 0.18);
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

float blossomPetal(vec2 point, float angle, float size) {
    vec2 local = rotatePoint(point, angle) / max(size, 0.000001);
    local.y += 0.08;
    float body = 1.0 - smoothstep(
        0.86,
        1.08,
        length(local * vec2(0.72, 1.18))
    );
    float cleft = softPoint(length(local - vec2(0.0, 0.78)), 0.24);
    float centerVein = softPoint(abs(local.x), 0.085)
        * (1.0 - smoothstep(-0.65, 0.75, local.y));
    return clamp(body * (1.0 - cleft * 0.64) + centerVein * body * 0.12, 0.0, 1.0);
}

// Classic implicit heart curve: (x^2 + y^2 - 1)^3 - x^2 y^3 = 0.
float heartCurve(vec2 point) {
    point *= vec2(1.04, 0.96);
    float xSquared = point.x * point.x;
    float ySquared = point.y * point.y;
    float body = xSquared + ySquared - 0.72;
    return body * body * body - xSquared * point.y * ySquared;
}

// =============================================================================
// BACKGROUND — INDIGO DAWN AND PAIRED STARS
// =============================================================================

vec3 dawnSky(vec2 world, float aspect) {
    float vertical = clamp(world.y + 0.50, 0.0, 1.0);
    vec3 gradient = mix(DAWN_ROSE, DAWN_VIOLET, smoothstep(0.02, 0.46, vertical));
    gradient = mix(gradient, DEEP_INDIGO, smoothstep(0.30, 0.98, vertical));
    float horizon = softPoint(abs(world.y + 0.35), 0.16);
    gradient += DAWN_ROSE * horizon * 0.045;

    vec3 stars = vec3(0.0);
    for (int layerIndex = 0; layerIndex < SKY_STAR_LAYERS; ++layerIndex) {
        float layer = float(layerIndex);
        float scale = 11.0 + layer * 8.0;
        vec2 grid = world * scale
            + vec2(iTime * (0.003 + layer * 0.001), 0.0);
        vec2 cell = floor(grid);
        vec2 local = fract(grid) - 0.5;
        vec2 offset = (hash22(cell + layer * 29.7) - 0.5) * 0.80;
        float randomValue = hash12(cell + layer * 71.1);
        float exists = step(0.86 + layer * 0.018, randomValue);
        float star = softPoint(length(local - offset), 0.026 + 0.004 * layer);
        float twinkle = 0.68 + 0.32 * sin(iTime * 0.55 + randomValue * 37.0);
        vec3 tint = mix(MOON_WHITE, PETAL_BLUSH, hash12(cell + 6.9) * 0.35);
        stars += tint * star * exists * twinkle * 0.62;
    }

    float skyMask = smoothstep(-0.38, 0.02, world.y);
    float horizontalFade = 1.0 - smoothstep(aspect * 0.46, aspect * 0.64, abs(world.x));
    return gradient * 0.10 + stars * skyMask * (0.55 + 0.45 * horizontalFade);
}

vec3 promiseMoon(vec2 world) {
    vec2 moonCenter = vec2(0.34, 0.255);
    float distanceToMoon = length(world - moonCenter);
    float moonDisk = 1.0 - smoothstep(0.128, 0.132, distanceToMoon);
    float moonHalo = softPoint(distanceToMoon, 0.235);

    // A soft rose shadow turns the disk into a near-crescent at the edge.
    float shadowDisk = 1.0 - smoothstep(
        0.111,
        0.119,
        length(world - moonCenter - vec2(-0.045, 0.020))
    );
    float litMoon = moonDisk * (1.0 - shadowDisk * 0.70);
    vec3 color = MOON_WHITE * litMoon * 0.23;
    color += mix(MEMORY_BLUE, PETAL_BLUSH, 0.35) * moonHalo * 0.045;

    // Two stars orbit the same center and periodically align.
    float orbitPhase = iTime * 0.18;
    vec2 orbit = vec2(cos(orbitPhase), sin(orbitPhase)) * vec2(0.185, 0.075);
    vec2 zeroStarPosition = moonCenter + orbit;
    vec2 hiroStarPosition = moonCenter - orbit;
    float zeroStar = softPoint(length(world - zeroStarPosition), 0.010);
    float hiroStar = softPoint(length(world - hiroStarPosition), 0.010);
    color += ZERO_PINK * zeroStar * 0.48;
    color += HIRO_CYAN * hiroStar * 0.48;

    float orbitRadius = length((world - moonCenter) / vec2(1.0, 0.405));
    color += mix(ZERO_PINK, HIRO_CYAN, 0.5)
        * ringMask(orbitRadius, 0.185, 0.0018)
        * 0.065;

    return color;
}

// =============================================================================
// BACKGROUND — BRAIDED PROMISE THREAD AND WING GLYPH
// =============================================================================

vec3 promiseThread(vec2 world, float aspect) {
    vec2 point = rotatePoint(world - vec2(0.0, -0.12), -0.025);
    float baseWave = 0.034 * sin(point.x * 4.6 + iTime * 0.18)
        + 0.015 * sin(point.x * 9.1 - iTime * 0.12);
    float braid = 0.012 * sin(point.x * 18.0 - iTime * 0.28);
    float pinkDistance = abs(point.y - baseWave - braid);
    float cyanDistance = abs(point.y - baseWave + braid);
    float envelope = 1.0 - smoothstep(aspect * 0.46, aspect * 0.64, abs(point.x));

    vec3 color = ZERO_PINK
        * (softPoint(pinkDistance, 0.0024) * 0.22
            + softPoint(pinkDistance, 0.020) * 0.032);
    color += HIRO_CYAN
        * (softPoint(cyanDistance, 0.0024) * 0.20
            + softPoint(cyanDistance, 0.020) * 0.030);
    float meeting = softPoint(abs(braid), 0.0035)
        * softPoint(abs(point.y - baseWave), 0.009);
    color += MOON_WHITE * meeting * 0.12;
    return color * envelope;
}

vec3 pairedWingGlyph(vec2 world) {
    vec2 center = vec2(-0.30, 0.16);
    vec2 local = world - center;
    float side = sign(local.x);
    vec2 mirrored = vec2(abs(local.x), local.y);
    float domain = smoothstep(0.025, 0.070, mirrored.x)
        * (1.0 - smoothstep(0.30, 0.40, mirrored.x));

    float upper = abs(
        mirrored.y - (0.020 + 0.31 * pow(max(mirrored.x, 0.0), 0.72))
    );
    float middle = abs(
        mirrored.y - (-0.012 + 0.20 * pow(max(mirrored.x, 0.0), 0.78))
    );
    float lower = abs(
        mirrored.y - (-0.034 + 0.10 * pow(max(mirrored.x, 0.0), 0.88))
    );
    float featherRhythm = 0.50 + 0.50 * smoothstep(
        -0.45,
        0.60,
        sin(mirrored.x * 82.0 - mirrored.y * 18.0)
    );
    float wing = domain
        * featherRhythm
        * (
            softPoint(upper, 0.006)
            + softPoint(middle, 0.005)
            + softPoint(lower, 0.004)
        );
    vec3 tint = mix(HIRO_CYAN, ZERO_PINK, step(0.0, side));
    return tint * wing * 0.085;
}

vec3 driftingPetals(vec2 world, float aspect) {
    vec3 color = vec3(0.0);

    for (int petalIndex = 0; petalIndex < PETAL_COUNT; ++petalIndex) {
        float indexValue = float(petalIndex);
        vec2 seed = hash22(vec2(indexValue * 17.7, indexValue * 53.3));
        float fallSpeed = mix(0.010, 0.028, hash12(seed + 2.7));
        float swaySpeed = mix(0.14, 0.34, hash12(seed + 7.1));
        vec2 wrapped = fract(vec2(
            seed.x + 0.035 * sin(iTime * swaySpeed + indexValue),
            seed.y - iTime * fallSpeed
        ));
        vec2 position = vec2(
            mix(-aspect * 0.57, aspect * 0.57, wrapped.x),
            mix(-0.57, 0.57, wrapped.y)
        );
        float size = mix(0.006, 0.012, hash12(seed + 11.9));
        float angle = iTime * mix(-0.42, 0.42, hash12(seed + 19.4))
            + indexValue * 2.1;
        float petal = blossomPetal(world - position, angle, size);
        vec3 tint = mix(PETAL_BLUSH, MOON_WHITE, hash12(seed + 31.5) * 0.45);
        color += tint * petal * 0.16;
    }

    return color;
}

vec4 renderPromiseScene(vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    vec2 world = (fragCoord - 0.5 * resolution) / resolution.y;
    float aspect = resolution.x / resolution.y;
    vec4 terminal = texture(iChannel0, uv);
    float background = terminalBackgroundMask(terminal);

    vec3 scene = dawnSky(world, aspect);
    scene += promiseMoon(world);
    scene += promiseThread(world, aspect);
    scene += pairedWingGlyph(world);
    scene += driftingPetals(world, aspect);

    float vignette = 1.0 - 0.22 * smoothstep(
        0.34,
        0.96,
        length(world / vec2(max(aspect * 0.65, 0.01), 0.70))
    );
    scene *= vignette;
    scene = vec3(1.0) - exp(-scene * 1.12);

    vec3 base = mix(
        terminal.rgb,
        terminal.rgb * BACKGROUND_DARKEN,
        background * 0.70
    );
    vec3 finalColor = base + scene * background;
    float visibility = clamp(luminance(scene) * 2.7, 0.0, 1.0);
    float finalAlpha = max(
        terminal.a,
        background * SCENE_ALPHA_BOOST * visibility
    );
    return vec4(finalColor, finalAlpha);
}

// =============================================================================
// CURSOR — TWO PATHS, ONE DESTINATION
// =============================================================================

vec4 applyPromiseCursor(
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
    float life = pow(1.0 - age, 2.0) * step(cursorSize * 0.20, travel);

    float effectRadius = cursorSize * 4.8;
    if (
        any(lessThan(fragCoord, min(head, tail) - effectRadius))
        || any(greaterThan(fragCoord, max(head, tail) + effectRadius))
    ) {
        return sceneColor;
    }

    float contentPermission = mix(
        0.15,
        1.0,
        terminalBackgroundMask(terminalColor)
    );
    vec3 result = sceneColor.rgb;

    // A small heart-line around the destination, intentionally restrained.
    vec2 heartPoint = (fragCoord - head) / max(cursorSize * 1.45, 0.001);
    heartPoint.y -= 0.06;
    float heartCurveValue = heartCurve(heartPoint);
    float heartAntialias = max(fwidth(heartCurveValue), 0.018);
    float heartOutline = 1.0 - smoothstep(
        heartAntialias * 0.65,
        heartAntialias * 1.85,
        abs(heartCurveValue)
    );
    float heartPhase = 0.5 + 0.5 * sin(iTime * 1.25);
    vec3 heartColor = mix(ZERO_PINK, HIRO_CYAN, heartPhase);
    result = mix(
        result,
        heartColor,
        heartOutline * (0.070 + life * 0.15) * contentPermission
    );

    float destinationGlow = softPoint(length(fragCoord - head), cursorSize * 1.15);
    result += PROMISE_GOLD
        * destinationGlow
        * (0.012 + life * 0.045)
        * contentPermission;

    if (life > 0.0001) {
        vec2 movement = head - tail;
        float movementLengthSquared = max(dot(movement, movement), 0.000001);
        float along = clamp(
            dot(fragCoord - tail, movement) / movementLengthSquared,
            0.0,
            1.0
        );
        vec2 direction = movement / max(travel, 0.000001);
        vec2 normal = vec2(-direction.y, direction.x);
        vec2 pathCenter = mix(tail, head, along);
        float braid = sin(along * PI)
            * sin(along * TAU * 1.25 + age * 3.0)
            * cursorSize
            * 0.25;
        float pinkDistance = length(fragCoord - pathCenter - normal * braid);
        float cyanDistance = length(fragCoord - pathCenter + normal * braid);
        float tailFade = smoothstep(0.0, 0.34, along);
        float threadLife = life * tailFade;

        float pinkCore = softPoint(pinkDistance, cursorSize * 0.075);
        float cyanCore = softPoint(cyanDistance, cursorSize * 0.075);
        float pinkHalo = softPoint(pinkDistance, cursorSize * 0.34);
        float cyanHalo = softPoint(cyanDistance, cursorSize * 0.34);
        result += ZERO_PINK
            * (pinkCore * 0.20 + pinkHalo * 0.040)
            * threadLife
            * contentPermission;
        result += HIRO_CYAN
            * (cyanCore * 0.20 + cyanHalo * 0.040)
            * threadLife
            * contentPermission;

#if CURSOR_PETALS > 0
        vec2 eventSeed = head * 0.091 + tail * 0.137
            + floor(iTimeCursorChange * 1000.0);
        for (int petalIndex = 0; petalIndex < CURSOR_PETALS; ++petalIndex) {
            float indexValue = float(petalIndex);
            float petalAlong = mix(
                0.10,
                0.94,
                hash12(eventSeed + vec2(indexValue * 17.1, indexValue * 43.7))
            );
            float side = hash12(eventSeed + vec2(indexValue * 61.9, 7.3)) * 2.0 - 1.0;
            float drift = side * cursorSize * mix(
                0.45,
                1.30,
                hash12(eventSeed + indexValue * 29.4)
            ) * (0.35 + age);
            vec2 petalPosition = mix(tail, head, petalAlong)
                + normal * drift
                - direction * age * cursorSize * (0.5 + indexValue * 0.08);
            float petalSize = cursorSize * mix(
                0.11,
                0.19,
                hash12(eventSeed + indexValue * 37.2)
            );
            float petal = blossomPetal(
                fragCoord - petalPosition,
                indexValue * 1.7 + age * (3.0 + side),
                petalSize
            );
            vec3 petalTint = mix(
                PETAL_BLUSH,
                MOON_WHITE,
                hash12(eventSeed + indexValue * 71.5) * 0.50
            );
            result += petalTint
                * petal
                * life
                * 0.23
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
    vec4 scene = renderPromiseScene(fragCoord);
    fragColor = applyPromiseCursor(scene, terminal, fragCoord);
}
