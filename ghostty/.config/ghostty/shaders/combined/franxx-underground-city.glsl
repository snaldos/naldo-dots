// FRANXX Golden Descent — ambient underground lights + acrobatic cursor
//
// A quiet abstraction of descending into the underground city: soft golden
// lamps recede around a vanishing point, faint shaft hoops drift outward, and
// warm haze moves through barely visible lift cables. No buildings or literal
// elevator are drawn; the terminal remains the dominant visual surface.
//
// During cursor movement, two gold/pink ribbons corkscrew around the path and
// resolve into rotating flip arcs at the destination, echoing Zero Two's early
// underground acrobatics without drawing a character.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_FBM_OCTAVES 3
#define PERF_SHAFT_RINGS 6
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_FBM_OCTAVES 4
#define PERF_SHAFT_RINGS 8
#elif GHOSTTY_GPU_PROFILE == 2
#define PERF_FBM_OCTAVES 5
#define PERF_SHAFT_RINGS 10
#else
#define PERF_FBM_OCTAVES 5
#define PERF_SHAFT_RINGS 12
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const vec3 AMBER_DARK = vec3(0.310, 0.135, 0.045);
const vec3 AMBER = vec3(0.880, 0.445, 0.125);
const vec3 GOLD = vec3(1.000, 0.710, 0.285);
const vec3 GOLD_HOT = vec3(1.000, 0.910, 0.590);
const vec3 ACROBAT_PINK = vec3(0.950, 0.105, 0.330);
const vec3 ACROBAT_RED = vec3(0.820, 0.035, 0.105);

float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * point;
}

float hash13(vec3 value) {
    value = fract(value * 0.1031);
    value += dot(value, value.yzx + 33.33);
    return fract((value.x + value.y) * value.z);
}

float valueNoise(vec2 point) {
    vec2 cell = floor(point);
    vec2 local = fract(point);
    local = local * local * (3.0 - 2.0 * local);
    float a = hash13(vec3(cell, 1.0));
    float b = hash13(vec3(cell + vec2(1.0, 0.0), 1.0));
    float c = hash13(vec3(cell + vec2(0.0, 1.0), 1.0));
    float d = hash13(vec3(cell + vec2(1.0, 1.0), 1.0));
    return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fbm(vec2 point) {
    float result = 0.0;
    float amplitude = 0.52;
    for (int octave = 0; octave < PERF_FBM_OCTAVES; octave++) {
        result += amplitude * valueNoise(point);
        point = rotate2d(point * 2.02, 0.37) + vec2(7.1, 13.9);
        amplitude *= 0.48;
    }
    return result;
}

float sdBox(vec2 point, vec2 halfSize) {
    vec2 q = abs(point) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float sdCapsule(vec2 point, vec2 startPoint, vec2 endPoint, float radius) {
    vec2 pa = point - startPoint;
    vec2 ba = endPoint - startPoint;
    float along = clamp(dot(pa, ba) / max(dot(ba, ba), 0.000001), 0.0, 1.0);
    return length(pa - ba * along) - radius;
}

float fillMask(float distanceValue, float aa) {
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float strokeMask(float distanceValue, float width, float aa) {
    return 1.0 - smoothstep(width - aa, width + aa, abs(distanceValue));
}

float backgroundProtection(vec4 terminalColor) {
    float dark = 1.0 - smoothstep(0.16, 0.72, luminance(terminalColor.rgb));
    float transparentCell = 1.0 - smoothstep(0.76, 0.98, terminalColor.a);
    return dark * mix(0.40, 1.0, transparentCell);
}

vec3 renderGoldenDescent(vec2 world, float aspect, float aa) {
    vec3 effect = vec3(0.0);
    vec2 vanishingPoint = vec2(0.0, 0.075);

    // Warm atmospheric lift column. Its FBM moves continuously and is almost
    // invisible except where it catches the shaft lights.
    vec2 hazePoint = vec2(world.x * 1.25, world.y * 2.4 + iTime * 0.008);
    float hazeNoise = fbm(hazePoint + vec2(4.7, 19.3));
    float column = exp(-pow(world.x / max(aspect * 0.32, 0.18), 2.0));
    float haze = smoothstep(0.40, 0.78, hazeNoise) * column;
    effect += AMBER_DARK * haze * 0.032;

    // Four cables converge on the same vanishing point. They are light traces,
    // not solid architecture, and stay deliberately near the visibility floor.
    vec2 cableTargets[4];
    cableTargets[0] = vec2(-0.48 * aspect, -0.62);
    cableTargets[1] = vec2(-0.24 * aspect, -0.62);
    cableTargets[2] = vec2(0.24 * aspect, -0.62);
    cableTargets[3] = vec2(0.48 * aspect, -0.62);
    for (int cable = 0; cable < 4; cable++) {
        float cableDistance = sdCapsule(world, vanishingPoint, cableTargets[cable], aa * 0.32);
        float cableGlow = exp(-max(cableDistance, 0.0) / 0.008);
        effect += AMBER * cableGlow * 0.015;
    }

    // Receding hoops expand past the viewer while paired lamps remain attached
    // to each hoop. This single perspective motion conveys descent without an
    // illustrated elevator car or cityscape.
    for (int ringIndex = 0; ringIndex < PERF_SHAFT_RINGS; ringIndex++) {
        float index = float(ringIndex);
        float offset = (index + 0.5) / float(PERF_SHAFT_RINGS);
        float clock = iTime * 0.034 + offset;
        float depth = fract(clock);
        float generation = floor(clock);
        float lifecycle = smoothstep(0.02, 0.12, depth)
            * (1.0 - smoothstep(0.80, 0.99, depth));
        float easedDepth = depth * depth;
        float radius = mix(0.022, 1.12, easedDepth);

        vec2 ringPoint = world - vanishingPoint;
        vec2 ellipticalPoint = vec2(ringPoint.x, ringPoint.y / 0.64);
        float ringDistance = length(ellipticalPoint) - radius;
        float ringWidth = mix(0.0010, 0.0032, depth);
        float ringCore = strokeMask(ringDistance, ringWidth, aa);
        float ringGlow = exp(-abs(ringDistance) / mix(0.008, 0.026, depth));

        float angle = atan(ellipticalPoint.y, ellipticalPoint.x);
        float structuralSegments = 0.26 + 0.74 * pow(abs(cos(angle * 4.0)), 7.0);
        float ringBrightness = lifecycle * mix(0.20, 0.82, depth);
        effect += AMBER * ringCore * structuralSegments * ringBrightness * 0.055;
        effect += AMBER_DARK * ringGlow * lifecycle * 0.018;

        // Symmetric lamps are anchored to the hoop at deterministic angles.
        float lampAngle = mix(0.42, 1.12, hash13(vec3(index, generation, 31.7)));
        for (int sideIndex = 0; sideIndex < 2; sideIndex++) {
            float side = sideIndex == 0 ? -1.0 : 1.0;
            vec2 lampPosition = vanishingPoint + vec2(
                side * cos(lampAngle) * radius,
                sin(lampAngle) * radius * 0.64
            );
            float lampDistance = length(world - lampPosition);
            float lampRadius = mix(0.0025, 0.012, depth);
            float lampCore = 1.0 - smoothstep(lampRadius * 0.20, lampRadius * 0.58 + aa, lampDistance);
            float lampGlow = exp(
                -lampDistance * lampDistance
                    / max(lampRadius * lampRadius * 7.5, 0.000001)
            );
            float lampVariation = mix(
                0.65,
                1.0,
                hash13(vec3(index, generation, 73.1 + float(sideIndex)))
            );
            effect += GOLD_HOT * (lampCore * 0.22 + lampGlow * 0.065)
                * lifecycle * lampVariation;
        }
    }

    // A soft overhead glow gives the vanishing point the feel of a distant
    // elevator landing while remaining fully abstract.
    vec2 landingPoint = world - vanishingPoint;
    float landingGlow = exp(
        -landingPoint.x * landingPoint.x / max(aspect * aspect * 0.018, 0.0001)
        -landingPoint.y * landingPoint.y / 0.0035
    );
    effect += GOLD * landingGlow * 0.055;

    return effect;
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition)
        / max(iResolution.y, 1.0);
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

void applyAcrobaticCursor(inout vec4 color, vec2 fragCoord) {
    vec4 untouched = color;
    vec2 point = normalizeScreen(fragCoord, 1.0);
    vec4 current = vec4(
        normalizeScreen(iCurrentCursor.xy, 1.0),
        normalizeScreen(iCurrentCursor.zw, 0.0)
    );
    vec4 previous = vec4(
        normalizeScreen(iPreviousCursor.xy, 1.0),
        normalizeScreen(iPreviousCursor.zw, 0.0)
    );
    vec2 head = cursorCenter(current);
    vec2 tail = cursorCenter(previous);
    vec2 movement = head - tail;
    float moved = length(movement);
    float cursorSize = max(current.z, current.w);
    float age = saturate((iTime - iTimeCursorChange) / 0.36);
    if (moved <= cursorSize * 0.025 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.15);
    float movementFactor = smoothstep(cursorSize * 0.10, cursorSize * 8.0, moved);
    float maximumReach = cursorSize * 3.1;
    if (
        any(lessThan(point, min(head, tail) - vec2(maximumReach)))
        || any(greaterThan(point, max(head, tail) + vec2(maximumReach)))
    ) {
        return;
    }

    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float along = saturate(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001)
    );
    vec2 pathCenter = mix(tail, head, along);
    float across = dot(point - pathCenter, normal);
    float pathWindow = smoothstep(0.0, 0.08, along)
        * (1.0 - smoothstep(0.96, 1.0, along));
    float flipEnvelope = sin(PI * along);
    float flipPhase = along * TAU * mix(1.15, 2.05, movementFactor)
        - age * TAU * 1.35;
    float flipAmplitude = cursorSize * mix(0.42, 1.18, movementFactor)
        * flipEnvelope;
    float goldOffset = sin(flipPhase) * flipAmplitude;
    float pinkOffset = sin(flipPhase + PI) * flipAmplitude;
    float ribbonWidth = cursorSize * mix(0.055, 0.085, movementFactor);
    float aa = 2.0 / max(iResolution.y, 1.0);

    float goldRibbon = 1.0 - smoothstep(
        ribbonWidth,
        ribbonWidth + aa,
        abs(across - goldOffset)
    );
    float pinkRibbon = 1.0 - smoothstep(
        ribbonWidth,
        ribbonWidth + aa,
        abs(across - pinkOffset)
    );
    float goldGlow = exp(-abs(across - goldOffset) / max(cursorSize * 0.42, 0.0001));
    float pinkGlow = exp(-abs(across - pinkOffset) / max(cursorSize * 0.42, 0.0001));

    color.rgb += GOLD * goldGlow * pathWindow * life * 0.075;
    color.rgb += ACROBAT_PINK * pinkGlow * pathWindow * life * 0.065;
    color.rgb += GOLD_HOT * goldRibbon * pathWindow * life * 0.28;
    color.rgb += ACROBAT_PINK * pinkRibbon * pathWindow * life * 0.25;

    // Rotating elliptical afterimages complete the flip at the destination.
    vec2 relative = point - head;
    float heading = atan(direction.y, direction.x);
    vec2 orbitA = rotate2d(relative, -heading - age * TAU * 1.65);
    vec2 orbitB = rotate2d(relative, -heading + age * TAU * 1.15 + 0.75);
    float headRadius = cursorSize * mix(1.05, 1.72, movementFactor);
    float ellipseA = length(vec2(orbitA.x, orbitA.y * 2.30));
    float ellipseB = length(vec2(orbitB.x, orbitB.y * 1.85));
    float ringA = strokeMask(ellipseA - headRadius, cursorSize * 0.060, aa) * life;
    float ringB = strokeMask(ellipseB - headRadius * 1.28, cursorSize * 0.052, aa) * life;
    float angleA = atan(orbitA.y, orbitA.x);
    float angleB = atan(orbitB.y, orbitB.x);
    ringA *= 0.35 + 0.65 * smoothstep(-0.35, 0.55, sin(angleA * 1.5 + age * TAU));
    ringB *= 0.30 + 0.70 * smoothstep(-0.50, 0.40, cos(angleB * 1.5 - age * TAU));
    color.rgb += GOLD_HOT * ringA * 0.32;
    color.rgb += ACROBAT_PINK * ringB * 0.28;

    // A compact landing diamond frames, but never repaints, the real cursor.
    vec2 diamondPoint = rotate2d(relative, -heading);
    float diamondDistance = abs(diamondPoint.x) + abs(diamondPoint.y)
        - cursorSize * mix(0.72, 1.18, movementFactor);
    float diamond = strokeMask(diamondDistance, cursorSize * 0.048, aa) * life;
    float headGlow = exp(-dot(relative, relative) / max(cursorSize * cursorSize * 2.6, 0.000001));
    color.rgb += GOLD * diamond * 0.28;
    color.rgb += mix(ACROBAT_PINK, GOLD_HOT, age) * headGlow * life * 0.120;

    float cursorDistance = sdBox(point - head, current.zw * 0.5);
    color = mix(color, untouched, fillMask(cursorDistance, aa));
    color.a = untouched.a;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    vec2 world = (fragCoord - 0.5 * resolution) / resolution.y;
    float aspect = resolution.x / resolution.y;
    float aa = 1.35 / resolution.y;

    vec4 terminalColor = texture(iChannel0, uv);
    float protection = backgroundProtection(terminalColor);
    vec3 ambient = renderGoldenDescent(world, aspect, aa);
    fragColor = vec4(
        clamp(terminalColor.rgb + ambient * protection, 0.0, 1.0),
        terminalColor.a
    );
    applyAcrobaticCursor(fragColor, fragCoord);
}
