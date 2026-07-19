// FRANXX Wasteland Signals — perspective dust flight + combat capsule cursor
//
// The camera advances through a sparse ruined battlefield. Dust occupies
// repeating depth slices and expands away from a low vanishing point. Motes and
// incandescent debris are true projected 3D points: as their depth decreases,
// they accelerate outward, grow, and develop motion-aligned trails. Rare energy
// lances and distant noisy explosions retain the scene's combat signals without
// turning the terminal into a continuous spectacle.
//
// Cursor movement deploys a foreshortened red/ivory FRANXX transport capsule
// with armored fins, cyan canopy, hot exhaust, and a dust-pressure wake. The
// actual Ghostty cursor block is restored exactly after compositing.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_FBM_OCTAVES 3
#define PERF_DUST_SLICES 3
#define PERF_MOTE_COUNT 9
#define PERF_DEBRIS_COUNT 3
#define PERF_BLAST_SPARKS 0
#define PERF_CURSOR_SPARKS 1
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_FBM_OCTAVES 4
#define PERF_DUST_SLICES 4
#define PERF_MOTE_COUNT 14
#define PERF_DEBRIS_COUNT 4
#define PERF_BLAST_SPARKS 2
#define PERF_CURSOR_SPARKS 2
#elif GHOSTTY_GPU_PROFILE == 2
#define PERF_FBM_OCTAVES 5
#define PERF_DUST_SLICES 5
#define PERF_MOTE_COUNT 20
#define PERF_DEBRIS_COUNT 6
#define PERF_BLAST_SPARKS 4
#define PERF_CURSOR_SPARKS 3
#else
#define PERF_FBM_OCTAVES 5
#define PERF_DUST_SLICES 6
#define PERF_MOTE_COUNT 28
#define PERF_DEBRIS_COUNT 8
#define PERF_BLAST_SPARKS 6
#define PERF_CURSOR_SPARKS 4
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float DUST_FAR_DEPTH = 5.8;
const float DUST_NEAR_DEPTH = 0.52;
const float OBJECT_FAR_DEPTH = 5.2;
const float OBJECT_NEAR_DEPTH = 0.38;
const vec2 WASTELAND_FOCAL_UV = vec2(0.51, 0.57);
const float WASTELAND_CAMERA_ROLL = -0.075;
const vec3 DUST_DARK = vec3(0.245, 0.100, 0.062);
const vec3 DUST_AMBER = vec3(0.690, 0.315, 0.115);
const vec3 HOT_WHITE = vec3(1.000, 0.925, 0.720);
const vec3 FIRE_GOLD = vec3(1.000, 0.500, 0.120);
const vec3 FIRE_RED = vec3(0.950, 0.050, 0.065);
const vec3 BEAM_CYAN = vec3(0.170, 0.690, 0.880);
const vec3 POD_IVORY = vec3(0.830, 0.790, 0.690);
const vec3 POD_RED = vec3(0.850, 0.035, 0.090);
const vec3 POD_DARK = vec3(0.028, 0.026, 0.042);

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
        hash13(value + vec3(17.7, 3.1, 41.3)),
        hash13(value + vec3(7.3, 53.9, 11.7))
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
    return dark * mix(0.38, 1.0, transparentCell);
}

vec2 perspectiveFocal(float aspect) {
    return (WASTELAND_FOCAL_UV - 0.5) * vec2(aspect, 1.0);
}

vec2 projectWastelandPoint(vec2 planePoint, float depth, vec2 focal) {
    return focal + rotate2d(planePoint, WASTELAND_CAMERA_ROLL)
        / max(depth, 0.001);
}

float depthNearFactor(float depth, float farDepth, float nearDepth) {
    return saturate((farDepth - depth) / max(farDepth - nearDepth, 0.001));
}

vec2 motePlanePosition(
    vec2 basePlane,
    float travel,
    float phase,
    float windStrength
) {
    float gust = 0.045 * sin(iTime * 0.075 + 0.4)
        + 0.022 * sin(iTime * 0.19 + 2.1);
    vec2 wind = vec2(gust * windStrength * travel, -0.045 * travel * travel);
    vec2 eddy = vec2(
        sin(travel * TAU * 1.3 + phase),
        cos(travel * TAU * 0.8 + phase * 1.7)
    ) * 0.008 * travel;
    return basePlane + wind + eddy;
}

vec2 debrisPlanePosition(
    vec2 basePlane,
    float travel,
    float phase,
    float lateralVelocity
) {
    float gust = 0.030 * sin(iTime * 0.075 + phase);
    return basePlane + vec2(
        lateralVelocity * travel + gust * travel,
        -0.145 * travel * travel + 0.018 * sin(travel * TAU + phase)
    );
}

vec3 renderPerspectiveDust(vec2 world, float aspect) {
    vec3 effect = vec3(0.0);
    vec2 focal = perspectiveFocal(aspect);
    vec2 cameraPoint = rotate2d(world - focal, -WASTELAND_CAMERA_ROLL);

    // Sampling the same physical dust plane through decreasing depth makes
    // every volume expand from the vanishing point instead of sliding in 2D.
    for (int sliceIndex = 0; sliceIndex < PERF_DUST_SLICES; sliceIndex++) {
        float index = float(sliceIndex);
        float layerOffset = (index + 0.5) / float(PERF_DUST_SLICES);
        float layerClock = iTime * mix(0.020, 0.027, layerOffset) + layerOffset;
        float travel = fract(layerClock);
        float generation = floor(layerClock);
        float depth = mix(DUST_FAR_DEPTH, DUST_NEAR_DEPTH, travel);
        float nearFactor = depthNearFactor(depth, DUST_FAR_DEPTH, DUST_NEAR_DEPTH);
        float lifecycle = smoothstep(0.0, 0.10, travel)
            * (1.0 - smoothstep(0.87, 1.0, travel));
        vec2 generationSeed = hash23(vec3(index, generation, 73.1));
        vec2 planePoint = cameraPoint * depth;
        planePoint += (generationSeed - 0.5) * vec2(7.0, 4.0);
        planePoint += vec2(-iTime * 0.010, iTime * 0.0025);
        planePoint.y *= mix(2.6, 3.9, layerOffset);
        float scale = mix(0.56, 1.25, layerOffset);
        vec2 warp = vec2(
            fbm(planePoint * scale * 0.55 + vec2(7.3, 17.1 + index)),
            fbm(planePoint * scale * 0.61 + vec2(23.7 + index, 4.9))
        ) - 0.5;
        float density = fbm(planePoint * scale + warp * 0.30);
        float body = smoothstep(mix(0.56, 0.64, layerOffset), 0.82, density);
        float horizonBias = mix(
            0.65,
            1.0,
            1.0 - smoothstep(-0.48, 0.36, world.y)
        );
        float brightness = mix(0.022, 0.065, nearFactor)
            * mix(1.0, 0.62, layerOffset);
        effect += mix(DUST_DARK, DUST_AMBER, density)
            * body * lifecycle * horizonBias * brightness;
    }

    return effect;
}

vec3 renderPerspectiveMotes(vec2 world, float aspect, float aa) {
    vec3 effect = vec3(0.0);
    vec2 focal = perspectiveFocal(aspect);
    float pixel = 1.0 / max(iResolution.y, 1.0);

    for (int moteIndex = 0; moteIndex < PERF_MOTE_COUNT; moteIndex++) {
        float index = float(moteIndex);
        float layerOffset = (index + 0.5) / float(PERF_MOTE_COUNT);
        float identity = hash13(vec3(index, 31.7, 8.9));
        float speed = mix(0.068, 0.043, layerOffset)
            * mix(0.86, 1.14, identity);
        float clock = iTime * speed + layerOffset + identity * 3.0;
        float travel = fract(clock);
        float generation = floor(clock);
        float depth = mix(OBJECT_FAR_DEPTH, OBJECT_NEAR_DEPTH, travel);
        float nearFactor = depthNearFactor(depth, OBJECT_FAR_DEPTH, OBJECT_NEAR_DEPTH);
        float lifecycle = smoothstep(0.0, 0.07, travel)
            * (1.0 - smoothstep(0.87, 1.0, travel));
        vec2 seed = hash23(vec3(index, generation, 47.3));
        vec2 basePlane = vec2(
            mix(-0.34, 0.34, seed.x) * aspect,
            mix(-0.27, 0.25, seed.y)
        );
        float phase = TAU * hash13(vec3(index, generation, 91.1));
        vec2 plane = motePlanePosition(
            basePlane,
            travel,
            phase,
            mix(0.65, 1.25, identity)
        );
        vec2 center = projectWastelandPoint(plane, depth, focal);

        float previousTravel = max(travel - 0.012, 0.0);
        float previousDepth = mix(
            OBJECT_FAR_DEPTH,
            OBJECT_NEAR_DEPTH,
            previousTravel
        );
        vec2 previousPlane = motePlanePosition(
            basePlane,
            previousTravel,
            phase,
            mix(0.65, 1.25, identity)
        );
        vec2 previousCenter = projectWastelandPoint(
            previousPlane,
            previousDepth,
            focal
        );
        vec2 motion = center - previousCenter;
        float motionLength = length(motion);
        vec2 direction = motionLength > 0.00001
            ? motion / motionLength
            : normalize(center - focal + vec2(0.0001));
        float radius = mix(0.32, 1.55, pow(nearFactor, 1.15))
            * mix(0.72, 1.25, identity) * pixel;
        float trailLength = mix(0.0, 8.0, nearFactor * nearFactor) * pixel;
        vec2 tail = center - direction * trailLength;
        float distanceValue = sdCapsule(world, tail, center, radius);
        float core = fillMask(distanceValue, aa);
        float glow = exp(-max(distanceValue, 0.0) / max(radius * 2.8, pixel));
        float brightness = mix(0.028, 0.21, nearFactor)
            * mix(0.55, 1.0, identity) * lifecycle;
        effect += mix(DUST_AMBER, HOT_WHITE, nearFactor * 0.35)
            * (core * 0.42 + glow * 0.055) * brightness;
    }

    return effect;
}

vec3 renderIncomingDebris(vec2 world, float aspect, float aa) {
    vec3 effect = vec3(0.0);
    vec2 focal = perspectiveFocal(aspect);
    float pixel = 1.0 / max(iResolution.y, 1.0);

    for (int debrisIndex = 0; debrisIndex < PERF_DEBRIS_COUNT; debrisIndex++) {
        float index = float(debrisIndex);
        float layerOffset = (index + 0.5) / float(PERF_DEBRIS_COUNT);
        float identity = hash13(vec3(index, 57.1, 19.3));
        float clock = iTime * mix(0.075, 0.052, layerOffset)
            * mix(0.88, 1.14, identity)
            + layerOffset + identity * 4.0;
        float travel = fract(clock);
        float generation = floor(clock);
        float depth = mix(4.9, 0.42, travel);
        float nearFactor = depthNearFactor(depth, 4.9, 0.42);
        float present = step(0.28, hash13(vec3(index, generation, 77.3)));
        float lifecycle = smoothstep(0.0, 0.055, travel)
            * (1.0 - smoothstep(0.89, 1.0, travel)) * present;
        vec2 seed = hash23(vec3(index, generation, 31.7));
        vec2 basePlane = vec2(
            mix(-0.31, 0.31, seed.x) * aspect,
            mix(-0.20, 0.28, seed.y)
        );
        float phase = TAU * hash13(vec3(index, generation, 12.1));
        float lateralVelocity = mix(-0.060, 0.075, identity);
        vec2 plane = debrisPlanePosition(
            basePlane,
            travel,
            phase,
            lateralVelocity
        );
        vec2 center = projectWastelandPoint(plane, depth, focal);

        float previousTravel = max(travel - 0.018, 0.0);
        float previousDepth = mix(4.9, 0.42, previousTravel);
        vec2 previousPlane = debrisPlanePosition(
            basePlane,
            previousTravel,
            phase,
            lateralVelocity
        );
        vec2 previousCenter = projectWastelandPoint(
            previousPlane,
            previousDepth,
            focal
        );
        vec2 motion = center - previousCenter;
        float motionLength = length(motion);
        vec2 direction = motionLength > 0.00001
            ? motion / motionLength
            : normalize(center - focal + vec2(0.0001));
        float trailLength = mix(5.0, 58.0, nearFactor * nearFactor)
            * mix(0.65, 1.25, identity) * pixel;
        float width = mix(0.38, 1.55, nearFactor)
            * mix(0.75, 1.20, seed.y) * pixel;
        vec2 tail = center - direction * trailLength;
        vec2 normal = vec2(-direction.y, direction.x);
        vec2 delta = world - center;
        float along = dot(delta, -direction);
        float across = abs(dot(delta, normal));
        float trailPosition = saturate(along / max(trailLength, pixel));
        float localWidth = width * mix(1.0, 0.08, trailPosition);
        float trailWindow = smoothstep(-aa, aa, along)
            * (1.0 - smoothstep(trailLength - aa, trailLength + aa, along));
        float core = (1.0 - smoothstep(localWidth, localWidth + aa, across))
            * trailWindow * pow(1.0 - trailPosition, 1.25);
        float glow = exp(-across / max(width * 3.2, pixel))
            * trailWindow * pow(1.0 - trailPosition, 0.72);
        float head = exp(-dot(delta, delta) / max(width * width * 2.2, 0.000001));
        float brightness = lifecycle * mix(0.14, 0.88, pow(nearFactor, 0.75));
        effect += HOT_WHITE * (core * 0.52 + head * 0.50) * brightness;
        effect += FIRE_GOLD * glow * brightness * 0.14;
        effect += FIRE_RED * glow * brightness * 0.035;
    }

    return effect;
}

vec3 renderPerspectiveBeam(vec2 world, float aspect, float aa) {
    const float period = 29.0;
    float cycle = floor(iTime / period);
    float phase = fract(iTime / period);
    float envelope = smoothEvent(phase, 0.64, 0.675, 0.735);
    float age = saturate((phase - 0.64) / 0.095);
    vec2 focal = perspectiveFocal(aspect);
    vec2 seed = hash23(vec3(cycle, 41.7, 9.3));
    vec2 plane = vec2(
        mix(-0.27, 0.27, seed.x) * aspect,
        mix(-0.16, 0.20, seed.y)
    );
    float headDepth = mix(4.8, 0.62, age * age * (3.0 - 2.0 * age));
    vec2 farPoint = projectWastelandPoint(plane, 4.8, focal);
    vec2 headPoint = projectWastelandPoint(
        plane + vec2(0.025 * sin(age * PI), -0.035 * age),
        headDepth,
        focal
    );
    float distanceValue = sdCapsule(world, farPoint, headPoint, aa * 0.42);
    float core = fillMask(distanceValue, aa * 0.82);
    float innerBloom = exp(-max(distanceValue, 0.0) / 0.0042);
    float outerBloom = exp(-max(distanceValue, 0.0) / 0.017);
    float headGlow = exp(
        -dot(world - headPoint, world - headPoint) / 0.00038
    );
    vec3 tint = mix(FIRE_RED, BEAM_CYAN, step(0.52, seed.x));
    float pulse = 0.88 + 0.12 * sin(iTime * 37.0);
    return tint * envelope * pulse
        * (core * 0.30 + innerBloom * 0.075 + outerBloom * 0.020 + headGlow * 0.075);
}

vec3 renderPerspectiveExplosion(vec2 world, float aspect, float aa) {
    const float period = 37.0;
    float cycle = floor(iTime / period);
    float phase = fract(iTime / period);
    float envelope = smoothEvent(phase, 0.70, 0.735, 0.91);
    float age = saturate((phase - 0.70) / 0.21);
    vec2 focal = perspectiveFocal(aspect);
    vec2 seed = hash23(vec3(cycle, 12.7, 88.1));
    vec2 plane = vec2(
        mix(-0.27, 0.27, seed.x) * aspect,
        mix(-0.15, -0.02, seed.y)
    );
    float eventDepth = mix(2.9, 1.75, age);
    vec2 center = projectWastelandPoint(plane, eventDepth, focal);
    float perspectiveScale = 1.0 / eventDepth;
    vec2 flattened = (world - center) / vec2(1.0, 0.70);
    float radial = length(flattened);
    float angular = atan(flattened.y, flattened.x);
    vec2 angularPoint = vec2(cos(angular), sin(angular));
    float surfaceNoise = fbm(
        angularPoint * 2.4 + vec2(cycle * 0.31, age * 1.8 + radial * 12.0)
    ) - 0.5;

    float fireRadius = mix(0.010, 0.105, sqrt(age)) * perspectiveScale;
    float noisyFireRadius = fireRadius * (1.0 + surfaceNoise * 0.28);
    float fireDistance = radial - noisyFireRadius;
    float fireShell = strokeMask(fireDistance, mix(0.010, 0.0035, age) * perspectiveScale, aa);
    float fireInterior = 1.0 - smoothstep(
        noisyFireRadius * 0.18,
        noisyFireRadius + aa,
        radial
    );
    fireInterior *= mix(0.70, 1.18, saturate(surfaceNoise + 0.5));
    float hotCore = exp(
        -radial * radial / max(fireRadius * fireRadius * 0.22, 0.00001)
    ) * exp(-age * 5.0);
    float fireBloom = exp(
        -radial * radial / max(fireRadius * fireRadius * 8.0, 0.00001)
    ) * exp(-age * 2.6);

    float shockRadius = mix(0.018, 0.27, sqrt(age)) * perspectiveScale;
    float shockDistance = radial - shockRadius * (1.0 + surfaceNoise * 0.11);
    float shock = strokeMask(
        shockDistance,
        mix(0.0042, 0.0020, age) * perspectiveScale,
        aa
    ) * (1.0 - smoothstep(0.48, 1.0, age));
    float shockBloom = exp(-abs(shockDistance) / max(0.012 * perspectiveScale, 0.002))
        * (1.0 - smoothstep(0.34, 1.0, age));
    float smoke = smoothstep(
        0.49,
        0.76,
        fbm(flattened / max(fireRadius, 0.004) * 0.75 + vec2(cycle, -age * 1.8))
    ) * exp(-radial * radial / max(shockRadius * shockRadius * 0.65, 0.0001));
    smoke *= smoothstep(0.20, 0.48, age) * (1.0 - smoothstep(0.76, 1.0, age));

    vec3 effect = HOT_WHITE * hotCore * 0.78;
    effect += FIRE_GOLD * fireInterior * exp(-age * 3.2) * 0.48;
    effect += FIRE_GOLD * fireShell * exp(-age * 2.1) * 0.30;
    effect += FIRE_RED * fireBloom * 0.20;
    effect += HOT_WHITE * shock * 0.11;
    effect += FIRE_GOLD * shockBloom * 0.035;
    effect += DUST_AMBER * smoke * 0.055;

#if PERF_BLAST_SPARKS > 0
    for (int sparkIndex = 0; sparkIndex < PERF_BLAST_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        float angleSeed = hash13(vec3(index, cycle, 37.1));
        float speedSeed = hash13(vec3(index, cycle, 81.3));
        float sparkAngle = mix(0.16, PI - 0.16, angleSeed);
        vec2 direction = vec2(cos(sparkAngle), sin(sparkAngle));
        float distanceTravelled = mix(0.055, 0.17, speedSeed)
            * age * perspectiveScale;
        vec2 sparkCenter = center + direction * distanceTravelled
            + vec2(0.0, -0.12 * age * age * perspectiveScale);
        vec2 sparkTail = sparkCenter - direction
            * mix(0.010, 0.030, speedSeed) * perspectiveScale;
        float sparkDistance = sdCapsule(world, sparkTail, sparkCenter, aa * 0.42);
        float spark = fillMask(sparkDistance, aa)
            * (1.0 - smoothstep(0.40, 0.86, age));
        effect += mix(FIRE_GOLD, HOT_WHITE, speedSeed) * spark * 0.22;
    }
#endif

    return effect * envelope;
}

vec3 renderWastelandSignals(vec2 world, float aspect, float aa) {
    vec3 effect = renderPerspectiveDust(world, aspect);
    effect += renderPerspectiveMotes(world, aspect, aa);
    effect += renderIncomingDebris(world, aspect, aa);
    effect += renderPerspectiveBeam(world, aspect, aa);
    effect += renderPerspectiveExplosion(world, aspect, aa);
    return effect;
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition)
        / max(iResolution.y, 1.0);
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

void applyCombatCapsuleCursor(inout vec4 color, vec2 fragCoord) {
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
    float age = saturate((iTime - iTimeCursorChange) / 0.32);
    if (moved <= cursorSize * 0.025 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.05);
    float movementFactor = smoothstep(cursorSize * 0.08, cursorSize * 8.0, moved);
    float effectRadius = cursorSize * 3.4;
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
    float halfLength = cursorSize * mix(0.90, 1.28, movementFactor);
    float radius = cursorSize * mix(0.49, 0.58, movementFactor);
    float podDistance = sdCapsule(
        local,
        vec2(-halfLength * 0.54, 0.0),
        vec2(halfLength * 0.54, 0.0),
        radius
    );
    float podFill = fillMask(podDistance, aa) * life;
    float armorShell = strokeMask(podDistance, cursorSize * 0.085, aa) * life;
    float armorInset = strokeMask(
        podDistance + cursorSize * 0.14,
        cursorSize * 0.032,
        aa
    ) * life;
    float podBloom = exp(-max(podDistance, 0.0) / max(cursorSize * 0.62, 0.0001)) * life;

    float canopyDistance = sdEllipse(
        local - vec2(halfLength * 0.40, radius * 0.02),
        vec2(halfLength * 0.29, radius * 0.50)
    );
    float canopy = fillMask(canopyDistance, aa) * life;
    float canopyEdge = strokeMask(canopyDistance, cursorSize * 0.030, aa) * life;
    float canopyGlint = exp(-pow(
        length((local - vec2(halfLength * 0.47, radius * 0.17))
            / vec2(halfLength * 0.18, radius * 0.18)),
        2.0
    )) * canopy;

    vec2 upperFinPoint = rotate2d(
        local - vec2(-halfLength * 0.20, radius * 0.72),
        -0.34
    );
    vec2 lowerFinPoint = rotate2d(
        local - vec2(-halfLength * 0.20, -radius * 0.72),
        0.34
    );
    float upperFin = fillMask(
        sdBox(upperFinPoint, vec2(halfLength * 0.31, radius * 0.13)),
        aa
    ) * life;
    float lowerFin = fillMask(
        sdBox(lowerFinPoint, vec2(halfLength * 0.31, radius * 0.13)),
        aa
    ) * life;
    float fins = max(upperFin, lowerFin);

    float panelA = 1.0 - smoothstep(
        cursorSize * 0.038,
        cursorSize * 0.038 + aa,
        abs(local.x + halfLength * 0.22)
    );
    float panelB = 1.0 - smoothstep(
        cursorSize * 0.038,
        cursorSize * 0.038 + aa,
        abs(local.x - halfLength * 0.08)
    );
    float centerSeam = 1.0 - smoothstep(
        cursorSize * 0.026,
        cursorSize * 0.026 + aa,
        abs(local.y)
    );

    float pathAlong = saturate(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001)
    );
    vec2 pathCenter = mix(tail, head, pathAlong);
    float pathAcross = abs(dot(point - pathCenter, normal));
    float pathWindow = smoothstep(0.0, 0.20, pathAlong) * life;
    float convergingWidth = cursorSize * mix(0.035, 0.12, pathAlong);
    float exhaustCore = 1.0 - smoothstep(
        convergingWidth,
        convergingWidth + aa,
        pathAcross
    );
    float exhaustGlow = exp(-pathAcross / max(cursorSize * 0.56, 0.0001));
    float pressureOffset = cursorSize * mix(0.10, 0.62, pathAlong);
    float pressureLines = exp(
        -abs(pathAcross - pressureOffset) / max(cursorSize * 0.075, 0.0001)
    );

    color.rgb += DUST_AMBER * pressureLines * pathWindow * 0.060;
    color.rgb += FIRE_RED * exhaustGlow * pathWindow * 0.070;
    color.rgb += FIRE_GOLD * exhaustCore * pathWindow * 0.20;
    color.rgb += POD_RED * podBloom * 0.095;
    color.rgb = mix(color.rgb, POD_DARK, podFill * 0.28);
    color.rgb = mix(color.rgb, POD_IVORY, armorShell * 0.82);
    color.rgb = mix(color.rgb, POD_DARK, armorInset * 0.52);
    color.rgb = mix(color.rgb, POD_RED, fins * 0.78);
    color.rgb = mix(
        color.rgb,
        POD_RED,
        (panelA + panelB) * podFill * life * 0.56
    );
    color.rgb = mix(color.rgb, BEAM_CYAN, canopy * 0.48);
    color.rgb = mix(color.rgb, HOT_WHITE, canopyEdge * 0.36);
    color.rgb += HOT_WHITE * canopyGlint * 0.20;
    color.rgb = mix(color.rgb, POD_DARK, centerSeam * podFill * life * 0.34);

#if PERF_CURSOR_SPARKS > 0
    for (int sparkIndex = 0; sparkIndex < PERF_CURSOR_SPARKS; sparkIndex++) {
        float index = float(sparkIndex);
        float alongSeed = hash13(vec3(index, head.x * 17.0, tail.y * 31.0));
        float sideSeed = hash13(vec3(index, head.y * 23.0, tail.x * 11.0));
        float sparkAlong = mix(0.08, 0.70, alongSeed);
        vec2 sparkCenter = mix(tail, head, sparkAlong)
            + normal * (sideSeed - 0.5) * cursorSize * 1.15;
        float sparkRadius = cursorSize * mix(0.030, 0.065, sideSeed);
        float spark = exp(
            -dot(point - sparkCenter, point - sparkCenter)
                / max(sparkRadius * sparkRadius, 0.000001)
        ) * life;
        color.rgb += mix(FIRE_GOLD, HOT_WHITE, sideSeed) * spark * 0.20;
    }
#endif

    float shockRadius = cursorSize * mix(0.82, 2.10, age);
    float shock = strokeMask(length(relative) - shockRadius, cursorSize * 0.045, aa)
        * life * (1.0 - age);
    color.rgb += mix(DUST_AMBER, HOT_WHITE, 0.28) * shock * 0.11;

    float cursorDistance = sdBox(point - head, current.zw * 0.5);
    color = mix(color, untouched, fillMask(cursorDistance, aa));
    color.a = untouched.a;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    vec2 world = (fragCoord - 0.5 * resolution) / resolution.y;
    float aspect = resolution.x / resolution.y;
    float aa = 1.25 / resolution.y;

    vec4 terminalColor = texture(iChannel0, uv);
    vec3 signals = renderWastelandSignals(world, aspect, aa)
        * backgroundProtection(terminalColor);
    fragColor = vec4(
        clamp(terminalColor.rgb + signals, 0.0, 1.0),
        terminalColor.a
    );
    applyCombatCapsuleCursor(fragColor, fragCoord);
}
