// FRANXX Connected Wings — combined scenery and cursor shader for Ghostty
//
// An original fan-made symbolic portrait inspired by Zero Two and Hiro's bond
// in Darling in the Franxx. Two grounded, facing silhouettes are individually
// drawn (long pink hair and horns on the left; short blue-black hair on the
// right), their hands meet, and one coherent red/cyan connection joins their
// chest cores. Articulated feather-mecha wings grow from their backs beneath a
// moonlit vaulted horizon.
//
// Nothing is emitted as decorative particle confetti. Animation is limited to
// a slow shared breath in the wings, coherent clouds and water, light moving
// inside the established connection, and a short two-color cursor ribbon.
//
// Uses Ghostty's iChannel0, iResolution, iTime, and cursor uniforms.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_FBM_OCTAVES 3
#define PERF_WING_FEATHERS 7
#define PERF_CURVE_STEPS 8
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_FBM_OCTAVES 4
#define PERF_WING_FEATHERS 9
#define PERF_CURVE_STEPS 10
#elif GHOSTTY_GPU_PROFILE == 2
#define PERF_FBM_OCTAVES 5
#define PERF_WING_FEATHERS 11
#define PERF_CURVE_STEPS 12
#else
#define PERF_FBM_OCTAVES 5
#define PERF_WING_FEATHERS 13
#define PERF_CURVE_STEPS 16
#endif

const float PI = 3.14159265359;
const vec3 SKY_TOP = vec3(0.025, 0.035, 0.095);
const vec3 SKY_MID = vec3(0.110, 0.090, 0.180);
const vec3 SKY_ROSE = vec3(0.405, 0.145, 0.205);
const vec3 MOON = vec3(0.835, 0.855, 0.920);
const vec3 WATER = vec3(0.025, 0.045, 0.085);
const vec3 ZERO_RED = vec3(0.940, 0.075, 0.185);
const vec3 ZERO_PINK = vec3(0.850, 0.250, 0.400);
const vec3 HIRO_BLUE = vec3(0.080, 0.400, 0.720);
const vec3 HIRO_CYAN = vec3(0.235, 0.850, 0.940);
const vec3 FEATHER_WHITE = vec3(0.780, 0.805, 0.870);
const vec3 SKIN = vec3(0.710, 0.585, 0.590);
const vec3 UNIFORM_RED = vec3(0.250, 0.040, 0.085);
const vec3 UNIFORM_BLUE = vec3(0.035, 0.075, 0.145);
const vec3 HAIR_PINK = vec3(0.610, 0.115, 0.255);
const vec3 HAIR_BLUE = vec3(0.025, 0.055, 0.120);

float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * point;
}

float hash12(vec2 point) {
    vec3 p3 = fract(vec3(point.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
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
        point = rotate2d(point * 2.03, 0.39) + vec2(9.7, 13.1);
        amplitude *= 0.48;
    }
    return result;
}

float sdBox(vec2 point, vec2 halfSize) {
    vec2 q = abs(point) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float sdRoundBox(vec2 point, vec2 halfSize, float radius) {
    return sdBox(point, max(halfSize - radius, vec2(0.0))) - radius;
}

float sdCapsule(vec2 point, vec2 startPoint, vec2 endPoint, float radius) {
    vec2 pa = point - startPoint;
    vec2 ba = endPoint - startPoint;
    float along = clamp(dot(pa, ba) / max(dot(ba, ba), 0.000001), 0.0, 1.0);
    return length(pa - ba * along) - radius;
}

float sdEllipse(vec2 point, vec2 radii) {
    float normalizedRadius = length(point / max(radii, vec2(0.0001)));
    return (normalizedRadius - 1.0) * min(radii.x, radii.y);
}

float fillMask(float distanceValue, float aa) {
    return 1.0 - smoothstep(-aa, aa, distanceValue);
}

float strokeMask(float distanceValue, float width, float aa) {
    return 1.0 - smoothstep(width - aa, width + aa, abs(distanceValue));
}

void blendLayer(inout vec3 base, vec3 layer, float opacity) {
    base = mix(base, layer, saturate(opacity));
}

float sdQuadraticBezier(
    vec2 point,
    vec2 startPoint,
    vec2 controlPoint,
    vec2 endPoint,
    out float closestParameter
) {
    float closestDistance = 1000.0;
    closestParameter = 0.0;
    vec2 previousPoint = startPoint;

    for (int stepIndex = 1; stepIndex <= PERF_CURVE_STEPS; stepIndex++) {
        float parameter = float(stepIndex) / float(PERF_CURVE_STEPS);
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
        float distanceToSegment = length(point - (previousPoint + segment * segmentParameter));
        if (distanceToSegment < closestDistance) {
            closestDistance = distanceToSegment;
            closestParameter = (float(stepIndex - 1) + segmentParameter)
                / float(PERF_CURVE_STEPS);
        }
        previousPoint = curvePoint;
    }
    return closestDistance;
}

vec3 renderMoonlitWorld(vec2 uv, vec2 point, float aspect, float aa) {
    vec3 color = mix(SKY_ROSE, SKY_MID, smoothstep(0.20, 0.58, uv.y));
    color = mix(color, SKY_TOP, smoothstep(0.53, 0.96, uv.y));

    vec2 moonCenter = vec2(0.0, 0.165);
    vec2 moonPoint = point - moonCenter;
    float moonDistance = length(moonPoint);
    float moonDisc = 1.0 - smoothstep(0.205 - aa, 0.205 + aa, moonDistance);
    float moonTexture = fbm(moonPoint * 8.5 + vec2(6.3, 17.1));
    vec3 moonColor = MOON * mix(0.78, 1.04, moonTexture);
    float moonHalo = exp(-moonDistance * moonDistance / 0.115);
    blendLayer(color, moonColor, moonDisc * 0.86);
    color += vec3(0.245, 0.270, 0.430) * moonHalo * 0.18;

    // Two coherent cloud decks cross the moon slowly. Their continuous FBM
    // density reads as weather, never as detached particles.
    vec2 cloudPoint = vec2(point.x * 1.05 - iTime * 0.006, point.y * 5.0);
    float cloudNoise = fbm(cloudPoint + vec2(2.7, 11.4));
    float cloudBandA = exp(-pow((point.y - 0.050) * 7.0, 2.0));
    float cloudBandB = exp(-pow((point.y - 0.285) * 9.0, 2.0));
    float clouds = smoothstep(0.43, 0.76, cloudNoise)
        * (cloudBandA + cloudBandB * 0.52);
    blendLayer(color, vec3(0.095, 0.070, 0.135), clouds * 0.43);

    // A fixed bridge and plantation shell establish a real horizon beneath
    // the pair instead of an arbitrary strip of shapes.
    float horizon = -0.218;
    float bridgeDeck = fillMask(sdRoundBox(point - vec2(0.0, horizon), vec2(0.72, 0.012), 0.006), aa);
    blendLayer(color, vec3(0.034, 0.033, 0.060), bridgeDeck * 0.96);

    vec2 shellPoint = point - vec2(0.0, horizon + 0.045);
    float shellDistance = sdEllipse(shellPoint, vec2(0.245, 0.082));
    float shell = strokeMask(shellDistance, 0.006, aa) * smoothstep(-0.005, 0.025, shellPoint.y);
    blendLayer(color, vec3(0.135, 0.075, 0.100), shell * 0.68);

    for (int towerIndex = 0; towerIndex < 5; towerIndex++) {
        float index = float(towerIndex) - 2.0;
        vec2 towerCenter = vec2(index * 0.105, horizon + 0.030 + 0.018 * (2.0 - abs(index)));
        float tower = fillMask(
            sdRoundBox(point - towerCenter, vec2(0.025, 0.035 + 0.008 * (2.0 - abs(index))), 0.006),
            aa
        );
        blendLayer(color, vec3(0.045, 0.035, 0.060), tower * 0.92);
        float window = exp(-pow((point.x - towerCenter.x) / 0.010, 2.0))
            * exp(-pow((point.y - towerCenter.y) / 0.022, 2.0));
        color += vec3(0.770, 0.285, 0.210) * window * 0.10;
    }

    float waterMask = 1.0 - smoothstep(horizon - aa, horizon + aa, point.y);
    float waterDepth = saturate((horizon - point.y) / 0.30);
    vec3 waterColor = mix(vec3(0.055, 0.045, 0.090), WATER, waterDepth);
    blendLayer(color, waterColor, waterMask * 0.93);

    float moonReflectionWidth = mix(0.045, 0.20, waterDepth);
    float waterWave = 0.5 + 0.5 * sin(
        point.y * 130.0 + sin(point.x * 23.0) + iTime * 0.20
    );
    float moonReflection = exp(-pow(point.x / moonReflectionWidth, 2.0))
        * mix(0.20, 1.0, waterWave)
        * waterMask;
    color += MOON * moonReflection * 0.105;

    // The two wing colors reflect as broad, physically grounded columns.
    float redReflection = exp(-pow((point.x + 0.22) / 0.19, 2.0)) * waterMask * waterDepth;
    float blueReflection = exp(-pow((point.x - 0.22) / 0.19, 2.0)) * waterMask * waterDepth;
    color += ZERO_RED * redReflection * waterWave * 0.040;
    color += HIRO_CYAN * blueReflection * (1.0 - 0.35 * waterWave) * 0.035;

    return color;
}

void renderWing(
    inout vec3 color,
    vec2 point,
    vec2 root,
    float side,
    float aspect,
    vec3 primary,
    vec3 secondary,
    float aa
) {
    float sharedBreath = 1.0 + 0.018 * sin(iTime * 0.23);
    float maximumSpan = min(0.78, aspect * 0.47) * sharedBreath;

    // A continuous load-bearing spar makes every feather part of one wing.
    vec2 sparEnd = root + vec2(side * maximumSpan * 0.60, 0.185);
    float sparDistance = sdCapsule(point, root, sparEnd, 0.014);
    float spar = fillMask(sparDistance, aa);
    float sparGlow = exp(-max(sparDistance, 0.0) / 0.022);
    blendLayer(color, mix(primary, FEATHER_WHITE, 0.34), spar * 0.68);
    color += primary * sparGlow * 0.045;

    for (int featherIndex = 0; featherIndex < PERF_WING_FEATHERS; featherIndex++) {
        float u = (float(featherIndex) + 0.25) / float(PERF_WING_FEATHERS);
        float reach = mix(maximumSpan * 0.53, maximumSpan, u);
        vec2 featherRoot = root + vec2(side * maximumSpan * 0.075 * u, 0.115 * u);
        vec2 joint = root + vec2(
            side * reach * mix(0.40, 0.58, u),
            mix(0.205, 0.055, u) + 0.055 * sin(PI * u)
        );
        vec2 tip = root + vec2(
            side * reach,
            mix(0.320, -0.205, u) + 0.060 * sin(PI * u)
        );
        float featherWidth = mix(0.018, 0.034, u);
        float featherParameter;
        float curveDistance = sdQuadraticBezier(
            point,
            featherRoot,
            joint,
            tip,
            featherParameter
        );
        // A feather is narrow at its mechanical root, broad through the vane,
        // and tapers cleanly to its tip. This avoids the neon-rod appearance of
        // constant-width capsules while retaining the articulated design.
        float widthProfile = 0.34
            + 0.78 * sin(PI * featherParameter)
                * (1.0 - 0.42 * featherParameter);
        widthProfile *= 1.0 - 0.72 * smoothstep(0.72, 1.0, featherParameter);
        float featherDistance = curveDistance - featherWidth * widthProfile;
        float feather = fillMask(featherDistance, aa);
        float featherEdge = strokeMask(featherDistance, 0.0025, aa);
        float featherGlow = exp(-max(featherDistance, 0.0) / 0.018);

        vec3 featherColor = mix(secondary, primary, smoothstep(0.12, 0.92, u));
        blendLayer(color, featherColor, feather * mix(0.34, 0.58, u));
        blendLayer(color, FEATHER_WHITE, featherEdge * 0.34);
        color += primary * featherGlow * 0.020;

        // Each feather has a visible mechanical vane and a joint attached to
        // the common spar; these are structural details, not floating dots.
        float vane = 1.0 - smoothstep(0.0032 - aa, 0.0032 + aa, curveDistance);
        float jointMask = fillMask(sdEllipse(point - joint, vec2(0.0105)), aa);
        blendLayer(color, FEATHER_WHITE, vane * 0.30);
        blendLayer(color, primary, jointMask * 0.66);
    }

    float rootCoreDistance = length(point - root);
    float rootCore = 1.0 - smoothstep(0.012, 0.032, rootCoreDistance);
    float rootHalo = exp(-rootCoreDistance * rootCoreDistance / 0.0035);
    color += primary * (rootCore * 0.38 + rootHalo * 0.08);
}

void renderConnection(inout vec3 color, vec2 point, float aa) {
    vec2 leftCore = vec2(-0.105, -0.145);
    vec2 rightCore = vec2(0.105, -0.145);
    vec2 contact = vec2(0.0, -0.158);

    float leftParameter;
    float rightParameter;
    float leftCurve = sdQuadraticBezier(
        point,
        leftCore,
        vec2(-0.050, -0.075),
        contact,
        leftParameter
    );
    float rightCurve = sdQuadraticBezier(
        point,
        rightCore,
        vec2(0.050, -0.075),
        contact,
        rightParameter
    );

    float leftRibbon = 1.0 - smoothstep(0.004 - aa, 0.004 + aa, leftCurve);
    float rightRibbon = 1.0 - smoothstep(0.004 - aa, 0.004 + aa, rightCurve);
    float leftGlow = exp(-leftCurve / 0.024);
    float rightGlow = exp(-rightCurve / 0.024);

    // Light travels inside the already established ribbons toward the shared
    // contact; no particles detach from the connection.
    float leftPulsePosition = fract(iTime * 0.075);
    float rightPulsePosition = fract(iTime * 0.075 + 0.5);
    float leftPulseDistance = abs(leftParameter - leftPulsePosition);
    float rightPulseDistance = abs(rightParameter - rightPulsePosition);
    leftPulseDistance = min(leftPulseDistance, 1.0 - leftPulseDistance);
    rightPulseDistance = min(rightPulseDistance, 1.0 - rightPulseDistance);
    float leftPulse = exp(-pow(leftPulseDistance / 0.12, 2.0));
    float rightPulse = exp(-pow(rightPulseDistance / 0.12, 2.0));

    color += ZERO_RED * (leftGlow * 0.055 + leftRibbon * (0.23 + leftPulse * 0.30));
    color += HIRO_CYAN * (rightGlow * 0.055 + rightRibbon * (0.23 + rightPulse * 0.30));

    float contactDistance = length(point - contact);
    float sharedBreath = 0.84 + 0.10 * sin(iTime * 0.42);
    float contactCore = 1.0 - smoothstep(0.006, 0.017, contactDistance);
    float contactHalo = exp(-contactDistance * contactDistance / 0.0042);
    vec3 sharedColor = mix(ZERO_RED, HIRO_CYAN, 0.50);
    color += sharedColor * (contactCore * 0.58 + contactHalo * 0.12) * sharedBreath;
}

void renderCharacter(
    inout vec3 color,
    vec2 point,
    vec2 headCenter,
    float scale,
    float facing,
    bool isZeroTwo,
    float aa
) {
    // In local coordinates +X always points toward the other character.
    vec2 q = (point - headCenter) / scale;
    q.x *= facing;
    float localAa = aa / max(scale, 0.0001);
    vec3 hairColor = isZeroTwo ? HAIR_PINK : HAIR_BLUE;
    vec3 uniformColor = isZeroTwo ? UNIFORM_RED : UNIFORM_BLUE;
    vec3 accentColor = isZeroTwo ? ZERO_RED : HIRO_CYAN;

    if (isZeroTwo) {
        float backHair = sdEllipse(q - vec2(-0.105, -0.080), vec2(0.445, 0.535));
        float longHairA = sdCapsule(q, vec2(-0.245, -0.260), vec2(-0.485, -1.920), 0.255);
        float longHairB = sdCapsule(q, vec2(0.005, -0.300), vec2(-0.120, -1.855), 0.225);
        float hairMass = min(backHair, min(longHairA, longHairB));
        blendLayer(color, hairColor * 0.67, fillMask(hairMass, localAa) * 0.95);
    } else {
        float backHair = sdEllipse(q - vec2(-0.080, 0.025), vec2(0.405, 0.440));
        float spikeA = sdCapsule(q, vec2(-0.260, 0.220), vec2(-0.520, 0.520), 0.105);
        float spikeB = sdCapsule(q, vec2(-0.080, 0.320), vec2(-0.145, 0.630), 0.095);
        float spikeC = sdCapsule(q, vec2(0.080, 0.300), vec2(0.175, 0.545), 0.080);
        float hairMass = min(backHair, min(spikeA, min(spikeB, spikeC)));
        blendLayer(color, hairColor, fillMask(hairMass, localAa) * 0.98);
    }

    float torso = sdRoundBox(q - vec2(0.0, -1.455), vec2(0.325, 0.895), 0.145);
    float shoulder = sdEllipse(q - vec2(0.0, -0.825), vec2(0.405, 0.225));
    float body = min(torso, shoulder);
    float bodyMask = fillMask(body, localAa);
    blendLayer(color, uniformColor, bodyMask * 0.98);
    float uniformShadow = fillMask(
        sdRoundBox(q - vec2(-0.155, -1.455), vec2(0.170, 0.850), 0.120),
        localAa
    ) * bodyMask;
    blendLayer(color, uniformColor * 0.54, uniformShadow * 0.34);

    float collarLeft = sdCapsule(q, vec2(-0.220, -0.690), vec2(0.0, -0.900), 0.032);
    float collarRight = sdCapsule(q, vec2(0.220, -0.690), vec2(0.0, -0.900), 0.032);
    float collar = min(collarLeft, collarRight);
    blendLayer(color, FEATHER_WHITE, fillMask(collar, localAa) * 0.48);

    // The arm geometry terminates at the shared contact point for both mirrored
    // characters, so their connection is spatial rather than merely symbolic.
    vec2 shoulderPoint = vec2(0.285, -0.840);
    vec2 elbowPoint = vec2(0.485, -0.955);
    vec2 handPoint = vec2(0.750, -1.055);
    float upperArm = sdCapsule(q, shoulderPoint, elbowPoint, 0.105);
    float lowerArm = sdCapsule(q, elbowPoint, handPoint - vec2(0.075, 0.0), 0.088);
    blendLayer(color, uniformColor * 1.22, fillMask(min(upperArm, lowerArm), localAa) * 0.98);

    float hand = sdEllipse(q - handPoint, vec2(0.105, 0.085));
    blendLayer(color, SKIN, fillMask(hand, localAa) * 0.95);

    float neck = sdRoundBox(q - vec2(0.015, -0.535), vec2(0.125, 0.190), 0.055);
    blendLayer(color, SKIN * 0.88, fillMask(neck, localAa) * 0.96);

    float face = sdEllipse(q - vec2(0.045, -0.040), vec2(0.285, 0.365));
    float nose = sdEllipse(q - vec2(0.305, -0.065), vec2(0.085, 0.060));
    float faceMask = fillMask(min(face, nose), localAa);
    blendLayer(color, SKIN, faceMask * 0.98);

    if (isZeroTwo) {
        float crownHair = sdEllipse(q - vec2(-0.090, 0.200), vec2(0.365, 0.270));
        float bangA = sdCapsule(q, vec2(-0.130, 0.265), vec2(0.020, -0.165), 0.075);
        float bangB = sdCapsule(q, vec2(0.065, 0.255), vec2(0.170, -0.115), 0.062);
        float frontHair = min(crownHair, min(bangA, bangB));
        blendLayer(color, hairColor, fillMask(frontHair, localAa) * 0.96);
        float hairHighlight = sdCapsule(q, vec2(-0.235, 0.115), vec2(-0.385, -1.560), 0.030);
        blendLayer(color, ZERO_PINK, fillMask(hairHighlight, localAa) * 0.35);

        float hornA = sdCapsule(q, vec2(-0.185, 0.335), vec2(-0.245, 0.675), 0.040);
        float hornB = sdCapsule(q, vec2(0.070, 0.345), vec2(0.165, 0.625), 0.036);
        float horns = fillMask(min(hornA, hornB), localAa);
        blendLayer(color, ZERO_RED, horns * 0.98);
        float hornEdge = strokeMask(min(hornA, hornB), 0.010, localAa);
        blendLayer(color, vec3(1.0, 0.40, 0.46), hornEdge * 0.46);
    } else {
        float crownHair = sdEllipse(q - vec2(-0.060, 0.190), vec2(0.370, 0.270));
        float bangA = sdCapsule(q, vec2(-0.080, 0.260), vec2(0.065, -0.120), 0.072);
        float bangB = sdCapsule(q, vec2(0.105, 0.240), vec2(0.205, -0.085), 0.055);
        float frontHair = min(crownHair, min(bangA, bangB));
        blendLayer(color, hairColor, fillMask(frontHair, localAa) * 0.98);
        float hairHighlight = sdCapsule(q, vec2(-0.275, 0.245), vec2(0.070, 0.355), 0.025);
        blendLayer(color, HIRO_BLUE, fillMask(hairHighlight, localAa) * 0.34);
    }

    float eye = sdCapsule(q, vec2(0.145, 0.005), vec2(0.265, -0.010), 0.013);
    float eyeMask = fillMask(eye, localAa);
    blendLayer(color, accentColor, eyeMask * 0.90);

    float profileLine = sdCapsule(q, vec2(0.285, -0.155), vec2(0.225, -0.205), 0.009);
    blendLayer(color, vec3(0.280, 0.100, 0.135), fillMask(profileLine, localAa) * 0.52);

    float chestCoreDistance = length(q - vec2(0.0, -0.940));
    float chestCore = 1.0 - smoothstep(0.040, 0.105, chestCoreDistance);
    float chestHalo = exp(-chestCoreDistance * chestCoreDistance / 0.095);
    color += accentColor * (chestCore * 0.36 + chestHalo * 0.045);
}

vec3 renderConnectedWings(vec2 uv, vec2 point, float aspect, float aa) {
    vec3 color = renderMoonlitWorld(uv, point, aspect, aa);

    vec2 leftRoot = vec2(-0.120, -0.125);
    vec2 rightRoot = vec2(0.120, -0.125);
    renderWing(color, point, leftRoot, -1.0, aspect, ZERO_RED, ZERO_PINK, aa);
    renderWing(color, point, rightRoot, 1.0, aspect, HIRO_CYAN, HIRO_BLUE, aa);

    renderConnection(color, point, aa);
    renderCharacter(color, point, vec2(-0.105, -0.010), 0.140, 1.0, true, aa);
    renderCharacter(color, point, vec2(0.105, -0.010), 0.140, -1.0, false, aa);

    // A single shared pool of light grounds their touching hands.
    vec2 contact = vec2(0.0, -0.158);
    float groundLight = exp(-pow(point.x / 0.23, 2.0))
        * exp(-pow((point.y + 0.225) / 0.035, 2.0));
    color += mix(ZERO_RED, HIRO_CYAN, 0.5) * groundLight * 0.055;

    float vignette = 1.0 - 0.28 * smoothstep(
        0.28,
        0.84,
        length((uv - 0.5) * vec2(0.76, 1.0))
    );
    return clamp(color * vignette, 0.0, 1.0);
}

vec4 compositeBehindTerminal(vec3 scene, vec4 terminalColor) {
    float terminalCoverage = saturate(terminalColor.a);
    return vec4(mix(scene, terminalColor.rgb, terminalCoverage), terminalColor.a);
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition) / iResolution.y;
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

void applyConnectionCursor(inout vec4 color, vec2 fragCoord) {
    vec4 original = color;
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
    float cursorSize = max(current.z, current.w);
    float moved = distance(head, tail);
    float age = saturate((iTime - iTimeCursorChange) / 0.27);
    if (moved <= cursorSize * 0.02 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.15);
    vec2 movement = head - tail;
    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float along = clamp(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001),
        0.0,
        1.0
    );
    float entry = smoothstep(0.0, 0.24, along);

    // Mirrored ribbons remain attached to the actual cursor path and merge at
    // the destination, echoing the red/cyan connection in the scene.
    float separation = cursorSize * 0.24 * (1.0 - along);
    vec2 redStart = tail + normal * cursorSize * 0.24;
    vec2 blueStart = tail - normal * cursorSize * 0.24;
    vec2 localCenter = mix(tail, head, along);
    vec2 redCenter = localCenter + normal * separation;
    vec2 blueCenter = localCenter - normal * separation;
    float redDistance = distance(point, redCenter);
    float blueDistance = distance(point, blueCenter);
    float ribbonRadius = cursorSize * 0.10;
    float redRibbon = exp(-redDistance / max(ribbonRadius * 1.65, 0.0001)) * entry * life;
    float blueRibbon = exp(-blueDistance / max(ribbonRadius * 1.65, 0.0001)) * entry * life;

    // The projected centers above define the smooth ribbon field; the two
    // anchored capsules provide continuous cores even on long cursor jumps.
    float redCoreDistance = sdCapsule(point, redStart, head, cursorSize * 0.040);
    float blueCoreDistance = sdCapsule(point, blueStart, head, cursorSize * 0.040);
    float redCore = fillMask(redCoreDistance, 2.1 / iResolution.y) * life;
    float blueCore = fillMask(blueCoreDistance, 2.1 / iResolution.y) * life;

    color.rgb += ZERO_RED * (redRibbon * 0.085 + redCore * 0.16);
    color.rgb += HIRO_CYAN * (blueRibbon * 0.085 + blueCore * 0.16);

    float headDistance = distance(point, head);
    float unionHalo = exp(-headDistance * headDistance / max(cursorSize * cursorSize * 2.2, 0.000001));
    color.rgb += mix(ZERO_RED, HIRO_CYAN, 0.50) * unionHalo * life * 0.10;

    float cursorDistance = sdBox(point - head, current.zw * 0.5);
    color = mix(color, original, fillMask(cursorDistance, 1.5 / iResolution.y));
    color.a = original.a;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    float aspect = resolution.x / resolution.y;
    vec2 point = (fragCoord - 0.5 * resolution) / resolution.y;
    float aa = 1.35 / resolution.y;

    vec4 terminalColor = texture(iChannel0, uv);
    vec3 scene = renderConnectedWings(uv, point, aspect, aa);
    fragColor = compositeBehindTerminal(scene, terminalColor);
    applyConnectionCursor(fragColor, fragCoord);
}
