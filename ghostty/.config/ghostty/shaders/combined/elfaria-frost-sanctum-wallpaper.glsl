// Elfaria Frost Sanctum — crystalline snowfall, ice needles, and frost quill
//
// A snow-magic wallpaper shader for Ghostty built from stable analytic shapes.
// Falling sixfold snow remains the main layer. Sparse ice needles use explicit
// continuous particle paths (no moving hash-grid cells), and cursor movement
// creates one bounded frost-quill stroke with stable event-seeded branches and
// tiny crystals (no segmented curves, hard culling, circles, blobs, or links to
// background objects).
//
// The complete magical layer is rendered first. Ghostty's terminal cells,
// glyphs, selection, and native cursor are composited above it unchanged.

// =============================================================================
// GPU PROFILE
// =============================================================================

#define EF_GPU_ECO 0
#define EF_GPU_BALANCED 1
#define EF_GPU_QUALITY 2
#define EF_GPU_ULTRA 3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE EF_GPU_QUALITY
#endif

#if GHOSTTY_GPU_PROFILE == EF_GPU_ECO
#define EF_SNOW_LAYERS 8
#define EF_NEEDLE_COUNT 5
#define EF_CURSOR_CRYSTALS 2
#elif GHOSTTY_GPU_PROFILE == EF_GPU_BALANCED
#define EF_SNOW_LAYERS 13
#define EF_NEEDLE_COUNT 9
#define EF_CURSOR_CRYSTALS 3
#elif GHOSTTY_GPU_PROFILE == EF_GPU_QUALITY
#define EF_SNOW_LAYERS 19
#define EF_NEEDLE_COUNT 14
#define EF_CURSOR_CRYSTALS 5
#else
#define EF_SNOW_LAYERS 26
#define EF_NEEDLE_COUNT 20
#define EF_CURSOR_CRYSTALS 7
#endif

// =============================================================================
// ART DIRECTION AND USER CONTROLS
// =============================================================================

#define EF_ENABLE_SNOW 1
#define EF_ENABLE_ICE_NEEDLES 1
#define EF_ENABLE_CURSOR_QUILL 1
#define EF_ENABLE_CURSOR_CRYSTALS 1

const float EF_MASTER_BRIGHTNESS = 1.20;
const float EF_BACKGROUND_DEPTH = 0.92;

const float EF_SNOW_STRENGTH = 1.08;
const float EF_SNOW_DENSITY = 0.24;
const float EF_SNOW_FALL_SPEED = 0.055;
const float EF_SNOW_WIND = 0.018;

const float EF_NEEDLE_STRENGTH = 0.50;
const float EF_NEEDLE_MIN_LENGTH_PIXELS = 4.0;
const float EF_NEEDLE_MAX_LENGTH_PIXELS = 10.0;
const float EF_NEEDLE_MIN_HALF_WIDTH_PIXELS = 0.55;
const float EF_NEEDLE_MAX_HALF_WIDTH_PIXELS = 1.05;
const float EF_NEEDLE_MIN_SPEED = 0.018;
const float EF_NEEDLE_MAX_SPEED = 0.042;

const float EF_CURSOR_DURATION = 0.40;
const float EF_CURSOR_FADE_POWER = 1.70;
const float EF_CURSOR_MIN_MOVEMENT_CELLS = 0.025;
const float EF_CURSOR_MAX_STROKE_CELLS = 5.5;
const float EF_CURSOR_MAX_EVENT_JUMP_CELLS = 80.0;
const float EF_CURSOR_CORE_STRENGTH = 1.10;
const float EF_CURSOR_EDGE_STRENGTH = 0.42;
const float EF_CURSOR_GLOW_STRENGTH = 0.16;
const float EF_CURSOR_BRANCH_STRENGTH = 0.64;
const float EF_CURSOR_TIP_STRENGTH = 0.70;
const float EF_CURSOR_CRYSTAL_STRENGTH = 0.86;

const vec3 EF_GLACIER = vec3(0.045, 0.250, 0.520);
const vec3 EF_ICE_BLUE = vec3(0.180, 0.700, 1.000);
const vec3 EF_FROST_CYAN = vec3(0.440, 0.920, 1.000);
const vec3 EF_SNOW_WHITE = vec3(0.930, 0.985, 1.000);
const vec3 EF_MOON_SILVER = vec3(0.700, 0.820, 1.000);
const vec3 EF_AURORA_VIOLET = vec3(0.520, 0.390, 1.000);

const float EF_PI = 3.14159265359;
const float EF_TAU = 6.28318530718;

// =============================================================================
// COMMON MATH
// =============================================================================

float efSaturate(float value) {
    return clamp(value, 0.0, 1.0);
}

float efHash11(float value) {
    value = fract(value * 0.1031);
    value *= value + 33.33;
    value *= value + value;
    return fract(value);
}

float efHash12(vec2 value) {
    vec3 p3 = fract(vec3(value.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 efHash22(vec2 value) {
    return vec2(
        efHash12(value + vec2(17.17, 43.71)),
        efHash12(value + vec2(83.91, 19.19))
    );
}

vec2 efRotate(vec2 point, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return vec2(
        cosine * point.x - sine * point.y,
        sine * point.x + cosine * point.y
    );
}

float efSegmentParameter(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    return clamp(
        dot(point - startPoint, segment)
            / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );
}

float efSegmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    float along = efSegmentParameter(point, startPoint, endPoint);
    return length(point - mix(startPoint, endPoint, along));
}

float efLine(float distanceValue, float width, float antialiasWidth) {
    return 1.0 - smoothstep(
        width,
        width + max(antialiasWidth, 0.000001),
        abs(distanceValue)
    );
}

float efGaussian(vec2 delta, float radius) {
    return exp(-dot(delta, delta) / max(radius * radius, 0.000001));
}

vec2 efScenePoint(vec2 pixelPoint) {
    return (
        pixelPoint - 0.5 * iResolution.xy
    ) / max(iResolution.y, 1.0);
}

vec2 efCursorCenterPixels(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}

// =============================================================================
// SIXFOLD SNOW CRYSTAL
// =============================================================================

vec2 efSixfoldCoordinates(vec2 point) {
    float radius = length(point);
    float angle = atan(point.y, point.x);
    float foldedAngle = mod(angle + EF_PI / 6.0, EF_PI / 3.0) - EF_PI / 6.0;
    return vec2(
        radius * cos(foldedAngle),
        abs(radius * sin(foldedAngle))
    );
}

float efSnowCrystal(vec2 point, float antialiasWidth) {
    vec2 folded = efSixfoldCoordinates(point);
    float along = folded.x;
    float across = folded.y;
    float radius = length(point);
    float aa = max(antialiasWidth, 0.002);

    float mainArm = efLine(across, 0.035, aa)
        * smoothstep(0.07, 0.14, along)
        * (1.0 - smoothstep(0.88, 1.02, along));

    float innerBranchDistance = abs(across - (along - 0.30) * 0.70)
        / sqrt(1.0 + 0.70 * 0.70);
    float innerBranches = efLine(innerBranchDistance, 0.026, aa)
        * smoothstep(0.29, 0.37, along)
        * (1.0 - smoothstep(0.62, 0.72, along));

    float outerBranchDistance = abs(across - (along - 0.54) * 0.56)
        / sqrt(1.0 + 0.56 * 0.56);
    float outerBranches = efLine(outerBranchDistance, 0.022, aa)
        * smoothstep(0.53, 0.60, along)
        * (1.0 - smoothstep(0.80, 0.90, along));

    float center = 1.0 - smoothstep(0.105, 0.105 + aa, radius);
    float outerFade = 1.0 - smoothstep(0.96, 1.04, radius);

    return max(center, max(mainArm, max(innerBranches, outerBranches)))
        * outerFade;
}

// =============================================================================
// FALLING CRYSTALLINE SNOW — KNOWN-GOOD BASE LAYER
// =============================================================================

vec3 efSnowLight(vec2 point) {
#if EF_ENABLE_SNOW
    vec3 accumulation = vec3(0.0);

    for (int layerIndex = 0; layerIndex < EF_SNOW_LAYERS; layerIndex++) {
        float layer = float(layerIndex);
        float depth = 1.65 + layer * 0.38;
        float layerSeed = layer * 19.17 + 7.31;
        float windDirection = 2.0 * efHash11(layerSeed + 3.7) - 1.0;

        vec2 samplePoint = point * depth;
        samplePoint.x += iTime * EF_SNOW_WIND * windDirection
            + 0.035 * sin(iTime * 0.15 + point.y * 3.0 + layerSeed);
        samplePoint.y += iTime * EF_SNOW_FALL_SPEED
            * mix(0.72, 1.28, efHash11(layerSeed + 11.0));

        vec2 cell = floor(samplePoint);
        vec2 local = fract(samplePoint) - 0.5;
        vec2 seed = cell + vec2(layerSeed, layerSeed * 0.37);
        float visible = step(1.0 - EF_SNOW_DENSITY, efHash12(seed + 17.9));
        vec2 offset = (efHash22(seed + 4.3) - 0.5) * 0.72;
        vec2 delta = local - offset;

        float sizeRandom = efHash12(seed + 31.7);
        float flakeRadius = mix(0.018, 0.040, sizeRandom);
        float spinDirection = 2.0 * efHash12(seed + 71.1) - 1.0;
        float spin = EF_TAU * efHash12(seed + 9.7)
            + iTime * spinDirection * mix(0.035, 0.11, sizeRandom);
        vec2 flakePoint = efRotate(delta / flakeRadius, spin);

        float pixel = depth / max(iResolution.y, 1.0)
            / max(flakeRadius, 0.00001);
        float crystal = efSnowCrystal(
            flakePoint,
            clamp(pixel, 0.018, 0.20)
        );
        float halo = efGaussian(flakePoint, 0.70);
        float depthFade = 1.0 / (1.0 + layer * 0.055);
        float twinkle = 0.76 + 0.24 * sin(
            iTime * mix(0.45, 1.05, sizeRandom)
            + layerSeed
            + cell.x * 1.7
        );

        vec3 flakeColor = mix(
            EF_ICE_BLUE,
            EF_SNOW_WHITE,
            0.48 + 0.42 * sizeRandom
        );
        accumulation += visible * depthFade * twinkle * (
            flakeColor * crystal * 0.82
            + EF_FROST_CYAN * halo * 0.055
        );
    }

    return vec3(1.0) - exp(-accumulation * EF_SNOW_STRENGTH);
#else
    return vec3(0.0);
#endif
}

// =============================================================================
// CONTINUOUS ICE NEEDLES
// =============================================================================

vec3 efIceNeedleLight(vec2 fragCoord) {
#if EF_ENABLE_ICE_NEEDLES
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec3 accumulation = vec3(0.0);

    // Every needle has one permanent identity and follows a continuous path.
    // It wraps only while fully outside the screen margin, so there is no
    // hash-cell teleportation or shape flicker.
    for (int needleIndex = 0; needleIndex < EF_NEEDLE_COUNT; needleIndex++) {
        float identity = float(needleIndex);
        float seed = 53.17 + identity * 29.31;
        float depth = mix(0.45, 1.0, efHash11(seed + 2.7));
        float speed = mix(
            EF_NEEDLE_MIN_SPEED,
            EF_NEEDLE_MAX_SPEED,
            efHash11(seed + 7.1)
        );
        float phase = fract(efHash11(seed + 13.9) + iTime * speed);

        float marginPixels = 28.0;
        float xBase = efHash11(seed + 19.3);
        float xDrift = (2.0 * efHash11(seed + 31.7) - 1.0)
            * resolution.x * 0.035;
        float xWander = sin(iTime * 0.11 + seed)
            * resolution.x * 0.008;
        vec2 center = vec2(
            xBase * resolution.x + xDrift * (phase - 0.5) + xWander,
            mix(-marginPixels, resolution.y + marginPixels, phase)
        );

        float sizeRandom = efHash11(seed + 43.1);
        float halfLength = mix(
            EF_NEEDLE_MIN_LENGTH_PIXELS,
            EF_NEEDLE_MAX_LENGTH_PIXELS,
            sizeRandom
        ) * mix(0.72, 1.0, depth);
        float halfWidth = mix(
            EF_NEEDLE_MIN_HALF_WIDTH_PIXELS,
            EF_NEEDLE_MAX_HALF_WIDTH_PIXELS,
            efHash11(seed + 59.7)
        );
        float angle = mix(-0.58, 0.58, efHash11(seed + 67.3))
            + 0.10 * sin(iTime * 0.17 + seed);
        vec2 local = efRotate(fragCoord - center, -angle);

        float diamondDistance = abs(local.y) / max(halfLength, 0.001)
            + abs(local.x) / max(halfWidth, 0.001)
            - 1.0;
        float antialiasWidth = max(fwidth(diamondDistance), 0.08);
        float body = 1.0 - smoothstep(0.0, antialiasWidth, diamondDistance);

        float lengthGate = 1.0 - smoothstep(
            halfLength * 0.82,
            halfLength,
            abs(local.y)
        );
        float core = exp(-abs(local.x) / max(halfWidth * 0.48, 0.25))
            * lengthGate;
        float halo = exp(
            -dot(local, local)
                / max(halfLength * halfLength * 0.72, 1.0)
        ) * 0.055;
        float twinkle = 0.70 + 0.30 * sin(iTime * 0.62 + seed);
        vec3 color = mix(EF_MOON_SILVER, EF_FROST_CYAN, sizeRandom * 0.52);

        accumulation += color * depth * twinkle
            * (body * 0.54 + core * 0.16 + halo);
    }

    return accumulation * EF_NEEDLE_STRENGTH;
#else
    return vec3(0.0);
#endif
}

// =============================================================================
// BOUNDED ANALYTIC FROST-QUILL CURSOR
// =============================================================================

vec3 efCursorSnowCrystal(
    vec2 fragCoord,
    vec2 center,
    float radiusPixels,
    float angle,
    vec3 color
) {
    vec2 local = efRotate(
        (fragCoord - center) / max(radiusPixels, 0.001),
        angle
    );
    float antialiasWidth = clamp(
        1.25 / max(radiusPixels, 1.0),
        0.018,
        0.24
    );
    float crystal = efSnowCrystal(local, antialiasWidth);
    float glint = efGaussian(local, 0.52);
    return color * (crystal * 0.82 + glint * 0.070);
}

vec3 efCursorQuillLight(vec2 fragCoord) {
#if EF_ENABLE_CURSOR_QUILL
    vec2 head = efCursorCenterPixels(iCurrentCursor);
    vec2 previous = efCursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    if (cursorPixels <= 0.0) return vec3(0.0);

    vec2 movementVector = head - previous;
    float movedPixels = length(movementVector);
    float movedCells = movedPixels / max(cursorPixels, 1.0);
    float age = clamp(
        (iTime - iTimeCursorChange) / EF_CURSOR_DURATION,
        0.0,
        1.0
    );
    if (
        movedCells <= EF_CURSOR_MIN_MOVEMENT_CELLS
        || movedCells >= EF_CURSOR_MAX_EVENT_JUMP_CELLS
        || age >= 1.0
    ) return vec3(0.0);

    vec2 direction = movementVector / max(movedPixels, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float visibleLength = min(
        movedPixels,
        cursorPixels * EF_CURSOR_MAX_STROKE_CELLS
    );
    vec2 tail = head - direction * visibleLength;
    float life = pow(1.0 - age, EF_CURSOR_FADE_POWER);
    float movementFactor = smoothstep(
        cursorPixels * 0.10,
        cursorPixels * EF_CURSOR_MAX_STROKE_CELLS,
        visibleLength
    );

    // Stable event seed: it does not change during the cursor animation.
    float eventSeed = floor(iTimeCursorChange * 1000.0) * 0.013;

    vec2 relative = fragCoord - tail;
    float alongPixels = dot(relative, direction);
    float along = clamp(
        alongPixels / max(visibleLength, 0.001),
        0.0,
        1.0
    );
    float across = abs(dot(relative, normal));
    float endpointMask = smoothstep(0.0, 0.10, along)
        * (1.0 - smoothstep(0.97, 1.0, along));
    float taper = pow(max(sin(EF_PI * along), 0.0), 0.42);
    float halfWidth = cursorPixels * mix(0.045, 0.095, movementFactor)
        * mix(0.34, 1.0, taper);
    float pixelWidth = max(fwidth(across), 0.70);
    float core = 1.0 - smoothstep(
        halfWidth,
        halfWidth + pixelWidth,
        across
    );
    float edge = exp(-abs(across - halfWidth * 1.55)
        / max(halfWidth * 0.65, 0.55));
    float glow = exp(-across * across
        / max(halfWidth * halfWidth * 16.0, 1.0));

    float flow = 0.78 + 0.22 * sin(along * 26.0 - age * 9.0 + eventSeed);
    vec3 strokeColor = mix(EF_AURORA_VIOLET, EF_FROST_CYAN, along);
    strokeColor = mix(
        strokeColor,
        EF_SNOW_WHITE,
        smoothstep(0.62, 1.0, along) * 0.54
    );
    vec3 light = strokeColor * life * endpointMask * flow * (
        core * EF_CURSOR_CORE_STRENGTH
        + edge * EF_CURSOR_EDGE_STRENGTH
        + glow * EF_CURSOR_GLOW_STRENGTH
    );

    // Three short alternating frost barbs turn the bounded stroke into an ice
    // quill. They use direct segment distances—the same stable primitive as the
    // working cursor shaders in this repository.
    for (int branchIndex = 0; branchIndex < 3; branchIndex++) {
        float index = float(branchIndex);
        float branchAlong = 0.34 + index * 0.19;
        vec2 root = mix(tail, head, branchAlong);
        float side = mod(index + floor(efHash11(eventSeed) * 2.0), 2.0) < 1.0
            ? -1.0
            : 1.0;
        float branchLength = cursorPixels
            * mix(0.42, 0.72, efHash11(eventSeed + index * 17.1));
        vec2 tip = root
            - direction * branchLength * 0.38
            + normal * side * branchLength;
        float branchDistance = efSegmentDistance(fragCoord, root, tip);
        float branchCore = 1.0 - smoothstep(
            0.65,
            0.65 + max(fwidth(branchDistance), 0.65),
            branchDistance
        );
        float branchGlow = exp(-branchDistance * branchDistance / 8.0);
        light += mix(EF_ICE_BLUE, EF_SNOW_WHITE, branchAlong)
            * life * (branchCore + branchGlow * 0.14)
            * EF_CURSOR_BRANCH_STRENGTH;
    }

#if EF_ENABLE_CURSOR_CRYSTALS && EF_CURSOR_CRYSTALS > 0
    for (int crystalIndex = 0; crystalIndex < EF_CURSOR_CRYSTALS; crystalIndex++) {
        float index = float(crystalIndex);
        float crystalAlong = mix(
            0.16,
            0.94,
            efHash11(eventSeed + index * 23.7 + 5.1)
        );
        float sideRandom = 2.0 * efHash11(eventSeed + index * 41.3 + 9.7) - 1.0;
        float sizeRandom = efHash11(eventSeed + index * 61.9 + 13.1);
        vec2 center = mix(tail, head, crystalAlong)
            + normal * sideRandom * cursorPixels
                * mix(0.42, 1.10, movementFactor) * (0.45 + age)
            - direction * cursorPixels * age * mix(0.10, 0.55, sizeRandom);
        float radiusPixels = cursorPixels * mix(0.13, 0.26, sizeRandom)
            * (1.0 + age * 0.24);
        float angle = EF_TAU * sideRandom + iTime * (0.20 + sizeRandom * 0.25);
        vec3 color = mix(EF_FROST_CYAN, EF_SNOW_WHITE, 0.44 + sizeRandom * 0.48);
        light += efCursorSnowCrystal(
            fragCoord,
            center,
            radiusPixels,
            angle,
            color
        ) * life * EF_CURSOR_CRYSTAL_STRENGTH;
    }
#endif

    // Compact leading diamond: no circular aura and no stationary effect.
    vec2 tipLocal = fragCoord - head;
    float tipAlong = dot(tipLocal, direction);
    float tipAcross = dot(tipLocal, normal);
    float tipHalfLength = cursorPixels * mix(0.48, 0.78, movementFactor);
    float tipHalfWidth = cursorPixels * 0.115;
    float tipDiamond = abs(tipAlong) / max(tipHalfLength, 0.001)
        + abs(tipAcross) / max(tipHalfWidth, 0.001)
        - 1.0;
    float tipBody = 1.0 - smoothstep(
        0.0,
        max(fwidth(tipDiamond), 0.08),
        tipDiamond
    );
    float tipCross = exp(-abs(tipAlong) / max(cursorPixels * 0.42, 0.5))
        * exp(-abs(tipAcross) / max(cursorPixels * 0.055, 0.5));
    light += EF_SNOW_WHITE * life * EF_CURSOR_TIP_STRENGTH
        * (tipBody * 0.72 + tipCross * 0.28);

    return light;
#else
    return vec3(0.0);
#endif
}

// =============================================================================
// WALLPAPER COMPOSITION — MAGIC BEHIND EXACT TERMINAL FOREGROUND
// =============================================================================

vec4 efCompositeBehindTerminal(vec3 magicalLayer, vec4 terminalColor) {
    float terminalCoverage = efSaturate(terminalColor.a);
    return vec4(
        mix(magicalLayer, terminalColor.rgb, terminalCoverage),
        terminalColor.a
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 point = efScenePoint(fragCoord);

    vec3 magicalLayer = iBackgroundColor * EF_BACKGROUND_DEPTH;
    magicalLayer += efSnowLight(point);
    magicalLayer += efIceNeedleLight(fragCoord);
    magicalLayer += efCursorQuillLight(fragCoord);
    magicalLayer = vec3(1.0) - exp(
        -max(magicalLayer, vec3(0.0)) * EF_MASTER_BRIGHTNESS
    );

    fragColor = efCompositeBehindTerminal(
        clamp(magicalLayer, 0.0, 1.0),
        terminalColor
    );
}
