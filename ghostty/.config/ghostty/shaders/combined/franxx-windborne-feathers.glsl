// FRANXX Featherfall — ambient linked feathers + growing-horn cursor
//
// A quiet, symbolic background rather than a portrait: red, cyan, and pale
// feathers descend with gravity, drift, and slow rotation while two extremely
// faint resonance currents approach one another through the terminal. Every
// moving object is a feather with a shaft and tapered vanes; there is no generic
// particle confetti.
//
// Cursor movement grows two curved horns from the destination. Their red/cyan
// colors exchange with direction and time while twin linked wakes follow the
// cursor path. The real cursor block remains untouched.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_FBM_OCTAVES 3
#define PERF_FEATHER_COUNT 10
#define PERF_HORN_STEPS 8
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_FBM_OCTAVES 4
#define PERF_FEATHER_COUNT 14
#define PERF_HORN_STEPS 10
#elif GHOSTTY_GPU_PROFILE == 2
#define PERF_FBM_OCTAVES 5
#define PERF_FEATHER_COUNT 18
#define PERF_HORN_STEPS 12
#else
#define PERF_FBM_OCTAVES 5
#define PERF_FEATHER_COUNT 22
#define PERF_HORN_STEPS 14
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const vec3 ZERO_RED = vec3(0.950, 0.070, 0.180);
const vec3 ZERO_PINK = vec3(0.850, 0.240, 0.405);
const vec3 HIRO_BLUE = vec3(0.095, 0.410, 0.760);
const vec3 HIRO_CYAN = vec3(0.230, 0.840, 0.930);
const vec3 FEATHER_PALE = vec3(0.760, 0.790, 0.875);
const vec3 LINK_WHITE = vec3(0.920, 0.900, 0.940);

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
        point = rotate2d(point * 2.03, 0.41) + vec2(13.7, 7.9);
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
    float dark = 1.0 - smoothstep(0.15, 0.70, luminance(terminalColor.rgb));
    float transparentCell = 1.0 - smoothstep(0.76, 0.98, terminalColor.a);
    return dark * mix(0.42, 1.0, transparentCell);
}

float sdQuadraticBezier(
    vec2 point,
    vec2 startPoint,
    vec2 controlPoint,
    vec2 endPoint,
    out float closestParameter
) {
    float bestDistance = 1000.0;
    closestParameter = 0.0;
    vec2 previousPoint = startPoint;
    for (int stepIndex = 1; stepIndex <= PERF_HORN_STEPS; stepIndex++) {
        float parameter = float(stepIndex) / float(PERF_HORN_STEPS);
        float inverse = 1.0 - parameter;
        vec2 curvePoint = inverse * inverse * startPoint
            + 2.0 * inverse * parameter * controlPoint
            + parameter * parameter * endPoint;
        vec2 segment = curvePoint - previousPoint;
        float segmentParameter = clamp(
            dot(point - previousPoint, segment) / max(dot(segment, segment), 0.000001),
            0.0,
            1.0
        );
        float distanceValue = length(
            point - (previousPoint + segment * segmentParameter)
        );
        if (distanceValue < bestDistance) {
            bestDistance = distanceValue;
            closestParameter = (float(stepIndex - 1) + segmentParameter)
                / float(PERF_HORN_STEPS);
        }
        previousPoint = curvePoint;
    }
    return bestDistance;
}

vec3 featherColor(int featherIndex, float variation) {
    int family = featherIndex - (featherIndex / 3) * 3;
    if (family == 0) {
        return mix(ZERO_PINK, ZERO_RED, variation);
    }
    if (family == 1) {
        return mix(HIRO_BLUE, HIRO_CYAN, variation);
    }
    return mix(FEATHER_PALE, LINK_WHITE, variation * 0.55);
}

vec3 renderFeatherfall(vec2 world, float aspect, float aa) {
    vec3 effect = vec3(0.0);

    // Two broad currents start apart and approach one another toward the lower
    // screen. They are intentionally quieter than the feathers themselves.
    float vertical = saturate(world.y + 0.5);
    float currentSpread = mix(0.055, 0.32 * aspect, vertical);
    float sharedFlow = sin(world.y * 4.2 - iTime * 0.045) * 0.028;
    float leftCenter = -currentSpread + sharedFlow;
    float rightCenter = currentSpread - sharedFlow;
    float leftDistance = abs(world.x - leftCenter);
    float rightDistance = abs(world.x - rightCenter);
    float leftCurrent = exp(-leftDistance * leftDistance / 0.0075);
    float rightCurrent = exp(-rightDistance * rightDistance / 0.0075);
    float currentTexture = mix(
        0.55,
        1.0,
        fbm(vec2(world.y * 2.2 - iTime * 0.010, world.x * 1.4) + 7.3)
    );
    effect += ZERO_RED * leftCurrent * currentTexture * 0.013;
    effect += HIRO_CYAN * rightCurrent * currentTexture * 0.013;

    // Finite feather trajectories loop only while fully faded above/below the
    // viewport, so a new deterministic generation never pops into view.
    for (int featherIndex = 0; featherIndex < PERF_FEATHER_COUNT; featherIndex++) {
        float index = float(featherIndex);
        float depth = (index + 0.5) / float(PERF_FEATHER_COUNT);
        float baseSeed = hash13(vec3(index, 17.3, 61.7));
        float speed = mix(0.030, 0.078, 1.0 - depth)
            * mix(0.84, 1.16, baseSeed);
        float clock = iTime * speed + baseSeed * 11.0;
        float travel = fract(clock);
        float generation = floor(clock);
        float lifecycle = smoothstep(0.00, 0.09, travel)
            * (1.0 - smoothstep(0.88, 1.0, travel));

        float xSeed = hash13(vec3(index, generation, 29.1));
        float phaseSeed = hash13(vec3(index, generation, 83.7));
        float baseX = mix(-0.47, 0.47, xSeed) * aspect;
        float driftAmplitude = mix(0.025, 0.105, 1.0 - depth);
        float drift = sin(
            iTime * mix(0.18, 0.42, phaseSeed)
                + phaseSeed * TAU
                + travel * PI
        ) * driftAmplitude;
        float y = mix(0.66, -0.66, travel);
        vec2 featherCenter = vec2(baseX + drift, y);

        float rotation = mix(-0.75, 0.75, phaseSeed)
            + sin(iTime * mix(0.22, 0.48, 1.0 - depth) + index * 1.73) * 0.62;
        vec2 local = rotate2d(world - featherCenter, -rotation);

        float halfLengthPixels = mix(18.0, 7.0, depth)
            * mix(0.78, 1.22, hash13(vec3(index, generation, 44.3)));
        float halfLength = halfLengthPixels / max(iResolution.y, 1.0);
        float halfWidth = halfLength * mix(0.22, 0.31, phaseSeed);
        float along = local.y / max(2.0 * halfLength, 0.000001) + 0.5;
        float lengthMask = smoothstep(0.0, 0.055, along)
            * (1.0 - smoothstep(0.93, 1.0, along));
        float bend = sin(PI * saturate(along)) * halfWidth * mix(-0.48, 0.48, xSeed);
        float widthProfile = pow(max(sin(PI * saturate(along)), 0.0), 0.72)
            * mix(0.72, 1.0, along);
        float localWidth = halfWidth * widthProfile;
        float across = abs(local.x - bend);
        float vane = (1.0 - smoothstep(localWidth, localWidth + aa, across))
            * lengthMask;
        float edge = (1.0 - smoothstep(
            aa * 0.5,
            aa * 1.8,
            abs(across - localWidth)
        )) * lengthMask;
        float shaft = (1.0 - smoothstep(
            halfWidth * 0.055,
            halfWidth * 0.055 + aa,
            abs(local.x - bend)
        )) * lengthMask;

        // Gentle barb shading is carried by the vane, not emitted separately.
        float barbShade = 0.78 + 0.22 * sin(along * PI * 9.0 + phaseSeed * TAU);
        vec3 tint = featherColor(
            featherIndex,
            hash13(vec3(index, generation, 12.9))
        );
        float depthBrightness = mix(0.85, 0.34, depth);
        effect += tint * vane * barbShade * lifecycle * depthBrightness * 0.140;
        effect += mix(tint, LINK_WHITE, 0.52) * edge * lifecycle * depthBrightness * 0.100;
        effect += LINK_WHITE * shaft * lifecycle * depthBrightness * 0.150;
    }

    return effect;
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition)
        / max(iResolution.y, 1.0);
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

void applyHornCursor(inout vec4 color, vec2 fragCoord) {
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
    float age = saturate((iTime - iTimeCursorChange) / 0.34);
    if (moved <= cursorSize * 0.025 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.0);
    float growth = smoothstep(0.0, 0.18, age)
        * (1.0 - smoothstep(0.78, 1.0, age));
    float movementFactor = smoothstep(cursorSize * 0.08, cursorSize * 8.0, moved);
    float effectRadius = cursorSize * 3.3;
    if (
        any(lessThan(point, min(head, tail) - vec2(effectRadius)))
        || any(greaterThan(point, max(head, tail) + vec2(effectRadius)))
    ) {
        return;
    }

    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float heading = atan(direction.y, direction.x);
    float colorExchange = 0.5 + 0.5 * sin(iTime * 2.15 + heading * 1.7);
    vec3 leftColor = mix(ZERO_RED, HIRO_CYAN, colorExchange);
    vec3 rightColor = mix(HIRO_CYAN, ZERO_RED, colorExchange);
    float aa = 2.0 / max(iResolution.y, 1.0);

    // Twin linked wakes approach one another at the destination.
    float along = saturate(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001)
    );
    vec2 pathCenter = mix(tail, head, along);
    float separation = cursorSize * 0.24 * (1.0 - along);
    float across = dot(point - pathCenter, normal);
    float trailWindow = smoothstep(0.0, 0.20, along) * life;
    float leftWakeDistance = abs(across - separation);
    float rightWakeDistance = abs(across + separation);
    float wakeWidth = cursorSize * 0.060;
    float leftWake = 1.0 - smoothstep(wakeWidth, wakeWidth + aa, leftWakeDistance);
    float rightWake = 1.0 - smoothstep(wakeWidth, wakeWidth + aa, rightWakeDistance);
    float leftWakeGlow = exp(-leftWakeDistance / max(cursorSize * 0.42, 0.0001));
    float rightWakeGlow = exp(-rightWakeDistance / max(cursorSize * 0.42, 0.0001));
    color.rgb += leftColor * (leftWake * 0.22 + leftWakeGlow * 0.065) * trailWindow;
    color.rgb += rightColor * (rightWake * 0.22 + rightWakeGlow * 0.065) * trailWindow;

    // Horns remain upright relative to the terminal, while length and color
    // respond to motion. Their taper is derived from the Bézier parameter.
    vec2 leftStart = head + vec2(-0.28, 0.42) * cursorSize;
    vec2 rightStart = head + vec2(0.28, 0.42) * cursorSize;
    vec2 leftControl = leftStart + vec2(-0.62, 1.05) * cursorSize * growth;
    vec2 rightControl = rightStart + vec2(0.62, 1.05) * cursorSize * growth;
    vec2 leftEnd = leftStart + vec2(-1.15, 2.20) * cursorSize * growth;
    vec2 rightEnd = rightStart + vec2(1.15, 2.20) * cursorSize * growth;

    float leftParameter;
    float rightParameter;
    float leftCurve = sdQuadraticBezier(
        point,
        leftStart,
        leftControl,
        leftEnd,
        leftParameter
    );
    float rightCurve = sdQuadraticBezier(
        point,
        rightStart,
        rightControl,
        rightEnd,
        rightParameter
    );
    float leftWidth = cursorSize * 0.135 * mix(1.0, 0.22, leftParameter);
    float rightWidth = cursorSize * 0.135 * mix(1.0, 0.22, rightParameter);
    float leftHornDistance = leftCurve - leftWidth;
    float rightHornDistance = rightCurve - rightWidth;
    float leftHorn = fillMask(leftHornDistance, aa) * life;
    float rightHorn = fillMask(rightHornDistance, aa) * life;
    float leftHornEdge = strokeMask(leftHornDistance, cursorSize * 0.030, aa) * life;
    float rightHornEdge = strokeMask(rightHornDistance, cursorSize * 0.030, aa) * life;
    float leftGlow = exp(-max(leftHornDistance, 0.0) / max(cursorSize * 0.50, 0.0001)) * life;
    float rightGlow = exp(-max(rightHornDistance, 0.0) / max(cursorSize * 0.50, 0.0001)) * life;

    color.rgb += leftColor * leftGlow * 0.100;
    color.rgb += rightColor * rightGlow * 0.100;
    color.rgb = mix(color.rgb, leftColor, leftHorn * 0.72);
    color.rgb = mix(color.rgb, rightColor, rightHorn * 0.72);
    color.rgb = mix(color.rgb, LINK_WHITE, (leftHornEdge + rightHornEdge) * 0.35);

    float headDistance = length(point - head);
    float unionHalo = exp(-headDistance * headDistance / max(cursorSize * cursorSize * 2.5, 0.000001));
    float unionRing = strokeMask(
        headDistance - cursorSize * mix(0.88, 1.30, movementFactor),
        cursorSize * 0.055,
        aa
    ) * life;
    color.rgb += mix(leftColor, rightColor, 0.5) * unionHalo * life * 0.110;
    color.rgb += LINK_WHITE * unionRing * 0.140;

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
    vec3 ambient = renderFeatherfall(world, aspect, aa);
    fragColor = vec4(
        clamp(terminalColor.rgb + ambient * protection, 0.0, 1.0),
        terminalColor.a
    );
    applyHornCursor(fragColor, fragCoord);
}
