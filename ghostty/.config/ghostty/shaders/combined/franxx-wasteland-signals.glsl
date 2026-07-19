// FRANXX Dustfront — ambient battlefield + capsule cursor for Ghostty
//
// This shader suggests the world outside without drawing a literal landscape:
// coherent airborne dust, sparse falling fragments, distant energy beams, and
// a rare low-horizon shockwave. The background remains the terminal itself and
// receives only restrained light, so it stays calm during normal work.
//
// The stronger thematic element is the cursor. While moving, it becomes a
// compact red/ivory deployment capsule with a cyan viewport and a dusty energy
// wake. The real Ghostty cursor block is preserved exactly.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_FBM_OCTAVES 3
#define PERF_DUST_LAYERS 4
#define PERF_DEBRIS_LAYERS 3
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_FBM_OCTAVES 4
#define PERF_DUST_LAYERS 6
#define PERF_DEBRIS_LAYERS 4
#elif GHOSTTY_GPU_PROFILE == 2
#define PERF_FBM_OCTAVES 5
#define PERF_DUST_LAYERS 8
#define PERF_DEBRIS_LAYERS 5
#else
#define PERF_FBM_OCTAVES 5
#define PERF_DUST_LAYERS 10
#define PERF_DEBRIS_LAYERS 6
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const vec3 DUST_UMBER = vec3(0.430, 0.205, 0.120);
const vec3 DUST_GOLD = vec3(0.790, 0.410, 0.185);
const vec3 EMBER_RED = vec3(1.000, 0.105, 0.175);
const vec3 BEAM_CYAN = vec3(0.230, 0.740, 0.900);
const vec3 POD_IVORY = vec3(0.790, 0.755, 0.675);
const vec3 POD_RED = vec3(0.820, 0.055, 0.110);
const vec3 POD_DARK = vec3(0.045, 0.038, 0.055);

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

vec2 hash23(vec3 value) {
    return vec2(
        hash13(value + vec3(17.17, 43.71, 11.13)),
        hash13(value + vec3(83.91, 19.19, 61.73))
    );
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
        point = rotate2d(point * 2.03, 0.39) + vec2(11.7, 7.3);
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

float sdEllipse(vec2 point, vec2 radii) {
    return (length(point / max(radii, vec2(0.0001))) - 1.0)
        * min(radii.x, radii.y);
}

float fillMask(float distanceValue, float aa) {
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float strokeMask(float distanceValue, float width, float aa) {
    return 1.0 - smoothstep(width - aa, width + aa, abs(distanceValue));
}

float smoothEvent(float phase, float start, float peak, float end) {
    return smoothstep(start, peak, phase)
        * (1.0 - smoothstep(peak, end, phase));
}

float backgroundProtection(vec4 terminalColor) {
    float dark = 1.0 - smoothstep(0.14, 0.68, luminance(terminalColor.rgb));
    float transparentCell = 1.0 - smoothstep(0.76, 0.98, terminalColor.a);
    return dark * mix(0.42, 1.0, transparentCell);
}

vec4 fallingFragment(
    vec2 point,
    float halfLength,
    float halfWidth,
    float slant,
    float aa
) {
    vec2 axis = normalize(vec2(-slant, 1.0));
    vec2 normal = vec2(axis.y, -axis.x);
    float along = dot(point, axis);
    float across = abs(dot(point, normal));
    float position = saturate((along + halfLength) / max(2.0 * halfLength, 0.0001));
    float taperedWidth = halfWidth * mix(1.20, 0.08, position);
    float lengthMask = smoothstep(-halfLength - aa, -halfLength + aa, along)
        * (1.0 - smoothstep(halfLength - aa, halfLength + aa, along));
    float core = (1.0 - smoothstep(taperedWidth, taperedWidth + aa, across))
        * lengthMask * pow(1.0 - position, 1.65);
    float glow = (1.0 - smoothstep(
        taperedWidth + halfWidth * 2.5,
        taperedWidth + halfWidth * 2.5 + aa * 2.0,
        across
    )) * lengthMask * pow(1.0 - position, 1.25);
    vec2 headCenter = -axis * halfLength;
    float headDistance = length(point - headCenter);
    float head = 1.0 - smoothstep(halfWidth * 1.2, halfWidth * 2.0 + aa, headDistance);
    float headGlow = exp(-headDistance * headDistance / max(halfWidth * halfWidth * 14.0, 0.000001));
    return vec4(core, glow, head, headGlow);
}

vec3 renderAmbientDust(vec2 world, float aspect, float aa) {
    vec3 effect = vec3(0.0);

    // Broad coherent dust sheets move together under one slow wind field.
    vec2 flowPoint = vec2(world.x * 0.82 - iTime * 0.010, world.y * 2.15);
    vec2 flowWarp = vec2(
        fbm(flowPoint * 0.62 + vec2(3.1, 9.7)),
        fbm(flowPoint * 0.58 + vec2(17.3, 4.2))
    ) - 0.5;
    float cloud = fbm(flowPoint + flowWarp * 0.48);
    float lowerAir = mix(0.32, 1.0, 1.0 - smoothstep(-0.18, 0.52, world.y));
    float veil = smoothstep(0.42, 0.78, cloud) * lowerAir;
    effect += mix(DUST_UMBER, DUST_GOLD, saturate(cloud)) * veil * 0.100;

    // Fine motes remain soft and wind-borne; they are not independent solid
    // decorations. Different depth layers share the same prevailing wind.
    for (int layer = 0; layer < PERF_DUST_LAYERS; layer++) {
        float index = float(layer);
        float depth = (index + 0.5) / float(PERF_DUST_LAYERS);
        float scale = mix(3.4, 10.5, depth);
        float speed = mix(0.040, 0.014, depth);
        vec2 q = world * scale;
        q += vec2(iTime * speed * scale, iTime * speed * 0.18 * scale);
        q.x += sin(iTime * 0.11 + index * 1.71 + world.y * 1.8) * 0.16;
        vec2 cell = floor(q);
        vec2 local = fract(q) - 0.5;
        vec3 seed = vec3(cell, index + 23.0);
        vec2 offset = (hash23(seed + 4.7) - 0.5) * vec2(0.72, 0.54);
        vec2 motePoint = rotate2d(local - offset, -0.16);
        float presence = step(
            1.0 - mix(0.15, 0.055, depth),
            hash13(seed + vec3(13.7, 31.1, 7.3))
        );
        float pixelScale = scale / max(iResolution.y, 1.0);
        float radius = mix(1.15, 0.48, depth) * pixelScale;
        float mote = exp(
            -motePoint.x * motePoint.x / max(radius * radius * 3.5, 0.000001)
            -motePoint.y * motePoint.y / max(radius * radius, 0.000001)
        );
        float brightness = mix(0.85, 0.28, depth)
            * mix(0.45, 1.0, hash13(seed + vec3(7.9, 5.3, 19.1)));
        effect += mix(DUST_GOLD, vec3(0.88, 0.68, 0.46), depth)
            * mote * presence * brightness * 0.150;
    }

    // Sparse hot fragments descend from the same distant conflict.
    for (int layer = 0; layer < PERF_DEBRIS_LAYERS; layer++) {
        float index = float(layer);
        float depth = (index + 0.5) / float(PERF_DEBRIS_LAYERS);
        float scale = mix(2.2, 6.8, depth);
        float slant = mix(0.22, 0.48, hash13(vec3(index, 8.1, 17.3)));
        float speed = mix(0.115, 0.050, depth);
        vec2 q = world * scale;
        q.y += iTime * speed * scale;
        q.x -= iTime * speed * slant * scale;
        vec2 cell = floor(q);
        vec2 local = fract(q) - 0.5;
        vec3 seed = vec3(cell, index + 71.0);
        vec2 offset = (hash23(seed + 9.1) - 0.5) * vec2(0.68, 0.42);
        float presence = step(
            1.0 - mix(0.012, 0.003, depth),
            hash13(seed + vec3(23.1, 51.7, 11.9))
        );
        float pixelScale = scale / max(iResolution.y, 1.0);
        float halfLength = mix(42.0, 12.0, depth) * pixelScale;
        float halfWidth = mix(0.90, 0.38, depth) * pixelScale;
        vec4 fragment = fallingFragment(
            local - offset,
            halfLength,
            halfWidth,
            slant,
            pixelScale
        ) * presence * mix(0.78, 0.30, depth);
        effect += mix(vec3(0.80, 0.73, 0.62), EMBER_RED, 0.32)
            * (fragment.x + fragment.y * 0.16 + fragment.z * 0.52 + fragment.w * 0.10)
            * 0.42;
    }

    // A distant beam appears briefly, then returns fully to darkness before
    // the deterministic event seed changes. This prevents any wrap pop.
    const float beamPeriod = 19.0;
    float beamCycle = floor(iTime / beamPeriod);
    float beamPhase = fract(iTime / beamPeriod);
    float beamEnvelope = smoothEvent(beamPhase, 0.60, 0.635, 0.705);
    float beamSeed = hash13(vec3(beamCycle, 41.7, 9.3));
    vec2 beamStart = vec2(mix(-0.48, 0.48, beamSeed) * aspect, 0.58);
    vec2 beamEnd = vec2(
        mix(-0.36, 0.36, hash13(vec3(beamCycle, 73.1, 18.7))) * aspect,
        -0.30
    );
    float beamDistance = sdCapsule(world, beamStart, beamEnd, aa * 0.75);
    float beamCore = fillMask(beamDistance, aa);
    float beamGlow = exp(-max(beamDistance, 0.0) / 0.015);
    vec3 beamColor = mix(EMBER_RED, BEAM_CYAN, step(0.58, beamSeed));
    effect += beamColor * beamEnvelope * (beamCore * 0.32 + beamGlow * 0.070);

    // One rare, soft shockwave. It is intentionally the only background event
    // allowed to attract attention.
    const float blastPeriod = 29.0;
    float blastCycle = floor(iTime / blastPeriod);
    float blastPhase = fract(iTime / blastPeriod);
    float blastEnvelope = smoothEvent(blastPhase, 0.70, 0.735, 0.90);
    float blastAge = saturate((blastPhase - 0.70) / 0.20);
    float blastX = mix(-0.34, 0.34, hash13(vec3(blastCycle, 12.7, 88.1))) * aspect;
    vec2 blastPoint = world - vec2(blastX, -0.315);
    vec2 flattened = blastPoint / vec2(1.0, 0.64);
    float blastRadius = mix(0.008, 0.155, sqrt(blastAge));
    float shockDistance = length(flattened) - blastRadius;
    float shockRing = strokeMask(shockDistance, 0.0045, aa);
    float centralFlash = exp(-dot(flattened, flattened) / max(0.003 + blastAge * 0.018, 0.0001))
        * exp(-blastAge * 8.0);
    float smoke = smoothstep(0.36, 0.76, fbm(blastPoint * 7.0 + vec2(blastCycle, -blastCycle)))
        * exp(-dot(flattened, flattened) / 0.035)
        * blastAge;
    effect += vec3(1.00, 0.58, 0.20) * shockRing * blastEnvelope * 0.42;
    effect += vec3(1.00, 0.25, 0.10) * centralFlash * blastEnvelope * 0.36;
    effect += DUST_UMBER * smoke * blastEnvelope * (1.0 - blastAge) * 0.08;

    return effect;
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition)
        / max(iResolution.y, 1.0);
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

void applyCapsuleCursor(inout vec4 color, vec2 fragCoord) {
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
    float age = saturate((iTime - iTimeCursorChange) / 0.30);
    if (moved <= cursorSize * 0.03 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.05);
    float movementFactor = smoothstep(cursorSize * 0.10, cursorSize * 8.0, moved);
    float effectRadius = cursorSize * 2.8;
    if (
        any(lessThan(point, min(head, tail) - vec2(effectRadius)))
        || any(greaterThan(point, max(head, tail) + vec2(effectRadius)))
    ) {
        return;
    }

    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    vec2 relative = point - head;
    vec2 local = vec2(dot(relative, direction), dot(relative, normal));
    float aa = 2.0 / max(iResolution.y, 1.0);

    float podHalfLength = cursorSize * mix(0.78, 1.12, movementFactor);
    float podRadius = cursorSize * 0.58;
    float podDistance = sdCapsule(
        local,
        vec2(-podHalfLength * 0.52, 0.0),
        vec2(podHalfLength * 0.52, 0.0),
        podRadius
    );
    float podGlow = exp(-max(podDistance, 0.0) / max(cursorSize * 0.72, 0.0001)) * life;
    float shell = strokeMask(podDistance, cursorSize * 0.095, aa) * life;

    float noseDistance = sdEllipse(
        local - vec2(podHalfLength * 0.45, 0.0),
        vec2(podHalfLength * 0.31, podRadius * 0.58)
    );
    float viewport = fillMask(noseDistance, aa) * life;
    float bandA = 1.0 - smoothstep(
        cursorSize * 0.055,
        cursorSize * 0.055 + aa,
        abs(local.x + podHalfLength * 0.18)
    );
    float bandB = 1.0 - smoothstep(
        cursorSize * 0.055,
        cursorSize * 0.055 + aa,
        abs(local.x - podHalfLength * 0.12)
    );
    float withinPod = fillMask(podDistance, aa);

    float trailDistance = sdCapsule(point, tail, head, cursorSize * 0.11);
    float along = saturate(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001)
    );
    float wake = exp(-max(trailDistance, 0.0) / max(cursorSize * 0.72, 0.0001))
        * smoothstep(0.0, 0.26, along) * life;
    float wakeCore = fillMask(trailDistance, aa)
        * smoothstep(0.0, 0.22, along) * life;

    color.rgb += DUST_GOLD * wake * 0.100;
    color.rgb += EMBER_RED * wakeCore * 0.22;
    color.rgb += POD_RED * podGlow * 0.120;
    color.rgb = mix(color.rgb, POD_IVORY, shell * 0.75);
    color.rgb = mix(color.rgb, POD_RED, (bandA + bandB) * withinPod * life * 0.58);
    color.rgb = mix(color.rgb, BEAM_CYAN, viewport * 0.42);

    float seam = 1.0 - smoothstep(
        cursorSize * 0.032,
        cursorSize * 0.032 + aa,
        abs(local.y)
    );
    color.rgb = mix(color.rgb, POD_DARK, seam * withinPod * life * 0.34);

    float rippleRadius = cursorSize * mix(0.90, 2.15, age);
    float ripple = strokeMask(length(relative) - rippleRadius, cursorSize * 0.055, aa)
        * life * (1.0 - age);
    color.rgb += BEAM_CYAN * ripple * 0.120;

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
    vec3 ambient = renderAmbientDust(world, aspect, aa);

    fragColor = vec4(
        clamp(terminalColor.rgb + ambient * protection, 0.0, 1.0),
        terminalColor.a
    );
    applyCapsuleCursor(fragColor, fragCoord);
}
