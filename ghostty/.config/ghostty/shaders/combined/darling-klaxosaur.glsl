// Ghostty combined shader — Klaxosaur Pulse
//
// An original, abstract fan homage inspired by Darling in the Franxx's darker
// side: subterranean blue cells, crimson horn-energy, a distant paired core,
// and a cursor that cuts forward like a synchronized lance.
// No external artwork, textures, or shader code are used.
//
// Ghostty:
//   ghostty-shaders.sh set combined darling-klaxosaur
//   custom-shader-animation = true

// =============================================================================
// PERFORMANCE PROFILE
// =============================================================================

#define KLAX_GPU_ECO      0
#define KLAX_GPU_BALANCED 1
#define KLAX_GPU_QUALITY  2
#define KLAX_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
    #define GHOSTTY_GPU_PROFILE KLAX_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == KLAX_GPU_ECO
    #define NOISE_OCTAVES    2
    #define CORE_PARTICLES   3
    #define LANCE_SPARKS     0
#elif GHOSTTY_GPU_PROFILE == KLAX_GPU_BALANCED
    #define NOISE_OCTAVES    3
    #define CORE_PARTICLES   5
    #define LANCE_SPARKS     3
#elif GHOSTTY_GPU_PROFILE == KLAX_GPU_QUALITY
    #define NOISE_OCTAVES    4
    #define CORE_PARTICLES   8
    #define LANCE_SPARKS     5
#else
    #define NOISE_OCTAVES    5
    #define CORE_PARTICLES   12
    #define LANCE_SPARKS     8
#endif

// =============================================================================
// PALETTE AND TUNING
// =============================================================================

const vec3 ABYSS          = vec3(0.004, 0.008, 0.025);
const vec3 KLAX_NAVY      = vec3(0.010, 0.055, 0.150);
const vec3 KLAX_BLUE      = vec3(0.000, 0.300, 1.000);
const vec3 KLAX_CYAN      = vec3(0.000, 0.880, 1.000);
const vec3 ZERO_CRIMSON   = vec3(1.000, 0.015, 0.130);
const vec3 ZERO_MAGENTA   = vec3(1.000, 0.090, 0.470);
const vec3 SYNCHRON_WHITE = vec3(0.920, 0.980, 1.000);
const vec3 CORE_GOLD      = vec3(1.000, 0.620, 0.200);

const float PI  = 3.14159265359;
const float TAU = 6.28318530718;

const float BACKGROUND_DARKEN = 0.46;
const float SCENE_ALPHA_BOOST = 0.110;
const float CURSOR_DURATION   = 0.27;

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
    return vec2(first, hash12(point + first + 17.17));
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

float valueNoise(vec2 point) {
    vec2 cell = floor(point);
    vec2 local = fract(point);
    local = local * local * (3.0 - 2.0 * local);
    float bottomLeft = hash12(cell);
    float bottomRight = hash12(cell + vec2(1.0, 0.0));
    float topLeft = hash12(cell + vec2(0.0, 1.0));
    float topRight = hash12(cell + vec2(1.0, 1.0));
    return mix(
        mix(bottomLeft, bottomRight, local.x),
        mix(topLeft, topRight, local.x),
        local.y
    );
}

float fbm(vec2 point) {
    float value = 0.0;
    float amplitude = 0.54;
    mat2 octaveTransform = mat2(1.62, 1.13, -1.13, 1.62);

    for (int octaveIndex = 0; octaveIndex < NOISE_OCTAVES; ++octaveIndex) {
        value += valueNoise(point) * amplitude;
        point = octaveTransform * point + vec2(13.1, 7.7);
        amplitude *= 0.49;
    }

    return value;
}

vec2 hexCell(vec2 point, out vec2 cellId) {
    vec2 spacing = vec2(1.0, 1.73205080757);
    vec2 halfSpacing = spacing * 0.5;
    vec2 first = mod(point, spacing) - halfSpacing;
    vec2 second = mod(point - halfSpacing, spacing) - halfSpacing;
    vec2 local = dot(first, first) < dot(second, second) ? first : second;
    cellId = point - local;
    return local;
}

float hexRadius(vec2 point) {
    point = abs(point);
    return max(point.y, dot(point, vec2(0.86602540378, 0.5)));
}

// =============================================================================
// BACKGROUND — LIVING KLAXOSAUR CELLS
// =============================================================================

vec3 livingCellField(vec2 world) {
    float slowTime = iTime * 0.045;
    float warpNoise = fbm(world * 2.2 + vec2(slowTime, -slowTime * 0.6));
    vec2 warped = world
        + 0.020 * vec2(
            sin(world.y * 8.0 + warpNoise * 4.0 + slowTime),
            cos(world.x * 7.0 - warpNoise * 3.0 - slowTime)
        );

    vec2 cellId;
    vec2 local = hexCell(warped * 7.4, cellId);
    float radius = hexRadius(local);
    float cellEdge = softPoint(abs(radius - 0.455), 0.018);
    float cellGlow = softPoint(abs(radius - 0.455), 0.070);
    float identity = hash12(cellId + 4.7);
    float pulse = 0.60 + 0.40 * sin(
        iTime * (0.22 + identity * 0.33) + identity * 31.0
    );

    vec3 color = KLAX_BLUE * cellEdge * pulse * 0.13;
    color += KLAX_CYAN * cellGlow * pulse * 0.018;

    float interior = 1.0 - smoothstep(0.18, 0.44, radius);
    float coreChance = step(0.88, identity);
    color += mix(KLAX_BLUE, ZERO_MAGENTA, identity)
        * interior
        * coreChance
        * pulse
        * 0.045;

    // Organic blue veins run beneath the geometric armor.
    float veinNoise = fbm(world * 4.1 + vec2(-slowTime * 1.3, slowTime));
    float vein = pow(clamp(1.0 - abs(veinNoise * 2.0 - 1.0), 0.0, 1.0), 7.0);
    color += KLAX_CYAN * vein * 0.055;
    return color;
}

// =============================================================================
// BACKGROUND — CRIMSON HORNS AND THE PAIRED CORE
// =============================================================================

vec3 hornSignal(vec2 world) {
    vec2 center = vec2(0.18, 0.015);
    vec2 local = world - center;
    vec2 mirrored = vec2(abs(local.x), local.y);
    float domain = smoothstep(0.035, 0.10, mirrored.x)
        * (1.0 - smoothstep(0.44, 0.62, mirrored.x));

    float hornCurve = 0.020
        + 0.88 * pow(max(mirrored.x - 0.015, 0.0), 1.48);
    float hornDistance = abs(mirrored.y - hornCurve);
    float lowerEchoDistance = abs(
        mirrored.y + 0.020 + 0.38 * pow(max(mirrored.x, 0.0), 1.30)
    );
    float hornPulse = 0.76 + 0.24 * sin(iTime * 0.58);

    vec3 sideTint = mix(KLAX_CYAN, ZERO_MAGENTA, step(0.0, local.x));
    vec3 color = sideTint
        * domain
        * (
            softPoint(hornDistance, 0.0040) * 0.30
            + softPoint(hornDistance, 0.026) * 0.055
        )
        * hornPulse;
    color += mix(KLAX_BLUE, ZERO_CRIMSON, 0.55)
        * domain
        * (
            softPoint(lowerEchoDistance, 0.0035) * 0.13
            + softPoint(lowerEchoDistance, 0.022) * 0.025
        );

    float coreDistance = length(local / vec2(1.0, 0.72));
    float outerCore = ringMask(coreDistance, 0.094, 0.0030);
    float innerCore = softPoint(coreDistance, 0.058);
    float split = smoothstep(-0.012, 0.012, local.x);
    vec3 splitColor = mix(KLAX_CYAN, ZERO_MAGENTA, split);
    color += splitColor * outerCore * 0.28;
    color += mix(KLAX_BLUE, ZERO_CRIMSON, split) * innerCore * 0.10;
    color += SYNCHRON_WHITE
        * softPoint(coreDistance, 0.016)
        * (0.50 + 0.50 * sin(iTime * 1.1))
        * 0.20;

    // Rotating synchronization ticks surround the core.
    float angle = atan(local.y, local.x);
    float tickRing = ringMask(coreDistance, 0.142, 0.0025);
    float ticks = smoothstep(0.30, 0.82, 0.5 + 0.5 * sin(angle * 18.0 - iTime * 0.40));
    color += mix(KLAX_CYAN, ZERO_MAGENTA, 0.5 + 0.5 * sin(angle))
        * tickRing
        * ticks
        * 0.15;

    return color;
}

vec3 risingCoreParticles(vec2 world, float aspect) {
    vec3 color = vec3(0.0);

    for (int particleIndex = 0; particleIndex < CORE_PARTICLES; ++particleIndex) {
        float indexValue = float(particleIndex);
        vec2 seed = hash22(vec2(indexValue * 19.7, indexValue * 47.3));
        float speed = mix(0.018, 0.050, hash12(seed + 3.4));
        vec2 wrapped = fract(vec2(
            seed.x + 0.025 * sin(iTime * 0.21 + indexValue),
            seed.y + iTime * speed
        ));
        vec2 position = vec2(
            mix(-aspect * 0.58, aspect * 0.58, wrapped.x),
            mix(-0.58, 0.58, wrapped.y)
        );
        float radius = mix(0.0020, 0.0050, hash12(seed + 8.1));
        float particle = softPoint(length(world - position), radius);
        vec3 tint = mix(KLAX_CYAN, ZERO_MAGENTA, step(0.58, hash12(seed + 11.9)));
        color += tint * particle * 0.34;
    }

    return color;
}

vec3 abyssScan(vec2 world, float aspect) {
    float scanCoordinate = fract(world.y * 72.0 - iTime * 0.30);
    float scanline = softPoint(abs(scanCoordinate - 0.5), 0.055);
    float sweepX = mix(-aspect * 0.60, aspect * 0.60, fract(iTime * 0.035));
    float sweep = softPoint(abs(world.x - sweepX), 0.012);
    return KLAX_BLUE * scanline * 0.010
        + mix(KLAX_BLUE, ZERO_CRIMSON, 0.35) * sweep * 0.018;
}

vec4 renderKlaxosaurScene(vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    vec2 world = (fragCoord - 0.5 * resolution) / resolution.y;
    float aspect = resolution.x / resolution.y;
    vec4 terminal = texture(iChannel0, uv);
    float background = terminalBackgroundMask(terminal);

    vec3 scene = ABYSS * 0.40;
    scene += KLAX_NAVY * (0.035 + 0.020 * sin(world.y * 3.0 + iTime * 0.08));
    scene += livingCellField(world);
    scene += hornSignal(world);
    scene += risingCoreParticles(world, aspect);
    scene += abyssScan(world, aspect);

    float vignette = 1.0 - 0.31 * smoothstep(
        0.30,
        0.95,
        length(world / vec2(max(aspect * 0.64, 0.01), 0.68))
    );
    scene *= vignette;
    scene = vec3(1.0) - exp(-scene * 1.18);

    vec3 base = mix(
        terminal.rgb,
        terminal.rgb * BACKGROUND_DARKEN,
        background * 0.76
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
// CURSOR — SYNCHRONIZED LANCE
// =============================================================================

vec4 applyKlaxosaurCursor(
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
    float life = pow(1.0 - age, 2.35) * step(cursorSize * 0.28, travel);

    float effectRadius = cursorSize * 5.2;
    if (
        any(lessThan(fragCoord, min(head, tail) - effectRadius))
        || any(greaterThan(fragCoord, max(head, tail) + effectRadius))
    ) {
        return sceneColor;
    }

    float contentPermission = mix(
        0.14,
        1.0,
        terminalBackgroundMask(terminalColor)
    );
    vec3 result = sceneColor.rgb;

    // Hexagonal pilot-link around the destination, visible even at rest.
    vec2 headLocal = (fragCoord - head) / max(cursorSize, 0.001);
    float headHexRadius = hexRadius(headLocal);
    float idleHex = ringMask(
        headHexRadius,
        0.92 + 0.05 * sin(iTime * 1.7),
        0.060
    );
    float hexSide = smoothstep(-0.15, 0.15, headLocal.x);
    vec3 hexColor = mix(KLAX_CYAN, ZERO_MAGENTA, hexSide);
    result = mix(
        result,
        hexColor,
        idleHex * (0.085 + life * 0.17) * contentPermission
    );

    if (life > 0.0001) {
        vec2 movement = head - tail;
        vec2 direction = movement / max(travel, 0.000001);
        vec2 normal = vec2(-direction.y, direction.x);
        float movementLengthSquared = max(dot(movement, movement), 0.000001);
        float along = clamp(
            dot(fragCoord - tail, movement) / movementLengthSquared,
            0.0,
            1.0
        );
        vec2 pathCenter = mix(tail, head, along);
        float sideDistance = dot(fragCoord - pathCenter, normal);
        float pathDistance = length(fragCoord - pathCenter);
        float tailFade = smoothstep(0.0, 0.28, along);
        float lanceLife = life * tailFade;

        float core = softPoint(pathDistance, cursorSize * 0.085);
        float innerGlow = softPoint(pathDistance, cursorSize * 0.28);
        float outerGlow = softPoint(pathDistance, cursorSize * 0.75);
        vec3 sideColor = mix(KLAX_CYAN, ZERO_MAGENTA, step(0.0, sideDistance));
        result += sideColor
            * (innerGlow * 0.14 + outerGlow * 0.030)
            * lanceLife
            * contentPermission;
        result += SYNCHRON_WHITE
            * core
            * lanceLife
            * 0.31
            * contentPermission;

        // Expanding hex shockwave and two horn-prongs at the strike point.
        float shockRadius = mix(0.82, 2.55, 1.0 - pow(1.0 - age, 3.0));
        float shock = ringMask(headHexRadius, shockRadius, 0.065)
            * life
            * (1.0 - age);
        result = mix(
            result,
            mix(KLAX_CYAN, ZERO_MAGENTA, 0.5),
            shock * 0.24 * contentPermission
        );

        vec2 backward = -direction;
        vec2 firstHornTip = head
            + rotatePoint(backward, 0.58) * cursorSize * 1.45;
        vec2 secondHornTip = head
            + rotatePoint(backward, -0.58) * cursorSize * 1.45;
        float firstHorn = segmentDistance(fragCoord, head, firstHornTip);
        float secondHorn = segmentDistance(fragCoord, head, secondHornTip);
        result += ZERO_MAGENTA
            * softPoint(firstHorn, cursorSize * 0.080)
            * life
            * 0.20
            * contentPermission;
        result += KLAX_CYAN
            * softPoint(secondHorn, cursorSize * 0.080)
            * life
            * 0.20
            * contentPermission;

#if LANCE_SPARKS > 0
        vec2 eventSeed = head * 0.077 + tail * 0.129
            + floor(iTimeCursorChange * 1000.0);
        for (int sparkIndex = 0; sparkIndex < LANCE_SPARKS; ++sparkIndex) {
            float indexValue = float(sparkIndex);
            float sparkAlong = mix(
                0.18,
                0.98,
                hash12(eventSeed + vec2(indexValue * 23.1, indexValue * 41.7))
            );
            float sparkSide = (
                hash12(eventSeed + vec2(indexValue * 59.3, 13.7)) * 2.0 - 1.0
            ) * cursorSize * mix(0.45, 1.45, age + 0.15);
            vec2 sparkPosition = mix(tail, head, sparkAlong)
                + normal * sparkSide
                - direction * age * cursorSize * indexValue * 0.10;
            float sparkRadius = cursorSize * mix(
                0.045,
                0.105,
                hash12(eventSeed + indexValue * 31.9)
            );
            float spark = softPoint(length(fragCoord - sparkPosition), sparkRadius);
            vec3 sparkColor = mix(
                KLAX_CYAN,
                ZERO_MAGENTA,
                step(0.5, hash12(eventSeed + indexValue * 73.1))
            );
            result += mix(sparkColor, SYNCHRON_WHITE, 0.38)
                * spark
                * life
                * 0.32
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
    vec4 scene = renderKlaxosaurScene(fragCoord);
    fragColor = applyKlaxosaurCursor(scene, terminal, fragCoord);
}
