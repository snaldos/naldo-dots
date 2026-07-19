// FRANXX Windborne Feathers — perspective feather flight + connected crest cursor
//
// Feathers occupy a sparse three-dimensional field around an upper vanishing
// point. Constant forward camera motion decreases their depth, so each feather
// accelerates outward and grows naturally as it approaches the viewer. Shared
// gusts, drag-dominated flutter, independent pitch/roll foreshortening, and
// anatomically asymmetric vanes keep the motion from resembling flat sprites.
//
// Cursor movement unfurls a connected red/cyan pair of detailed feathers whose
// rachises form horn-like crests, while two braided connection filaments merge
// at the destination. The actual Ghostty cursor block remains untouched.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 2
#endif

#if GHOSTTY_GPU_PROFILE == 0
#define PERF_FBM_OCTAVES 3
#define PERF_FEATHER_COUNT 8
#elif GHOSTTY_GPU_PROFILE == 1
#define PERF_FBM_OCTAVES 4
#define PERF_FEATHER_COUNT 11
#elif GHOSTTY_GPU_PROFILE == 2
#define PERF_FBM_OCTAVES 5
#define PERF_FEATHER_COUNT 14
#else
#define PERF_FBM_OCTAVES 5
#define PERF_FEATHER_COUNT 18
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float FEATHER_FAR_DEPTH = 5.4;
const float FEATHER_NEAR_DEPTH = 0.34;
const vec2 FEATHER_FOCAL_UV = vec2(0.53, 0.63);
const float FEATHER_CAMERA_ROLL = 0.055;
const vec3 ZERO_RED = vec3(0.950, 0.060, 0.170);
const vec3 ZERO_PINK = vec3(0.835, 0.190, 0.350);
const vec3 HIRO_BLUE = vec3(0.065, 0.300, 0.645);
const vec3 HIRO_CYAN = vec3(0.205, 0.800, 0.920);
const vec3 FEATHER_PALE = vec3(0.760, 0.790, 0.870);
const vec3 RACHIS_LIGHT = vec3(0.950, 0.925, 0.940);

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
    float dark = 1.0 - smoothstep(0.14, 0.68, luminance(terminalColor.rgb));
    float transparentCell = 1.0 - smoothstep(0.76, 0.98, terminalColor.a);
    return dark * mix(0.38, 1.0, transparentCell);
}

vec2 perspectiveFocal(float aspect) {
    return (FEATHER_FOCAL_UV - 0.5) * vec2(aspect, 1.0);
}

vec2 projectFeatherPoint(vec2 planePoint, float depth, vec2 focal) {
    return focal + rotate2d(planePoint, FEATHER_CAMERA_ROLL)
        / max(depth, 0.001);
}

float depthNearFactor(float depth) {
    return saturate(
        (FEATHER_FAR_DEPTH - depth)
            / max(FEATHER_FAR_DEPTH - FEATHER_NEAR_DEPTH, 0.001)
    );
}

vec3 featherTint(int featherIndex, float variation) {
    int family = featherIndex - (featherIndex / 3) * 3;
    if (family == 0) {
        return mix(ZERO_PINK, ZERO_RED, variation);
    }
    if (family == 1) {
        return mix(HIRO_BLUE, HIRO_CYAN, variation);
    }
    return mix(FEATHER_PALE * 0.84, FEATHER_PALE, variation);
}

vec3 realisticFeather(
    vec2 localPoint,
    float halfLength,
    float halfWidth,
    float curvature,
    float asymmetry,
    float notchPhase,
    vec3 tint,
    float aa
) {
    vec2 q = vec2(
        localPoint.x / max(halfWidth, 0.000001),
        localPoint.y / max(halfLength, 0.000001)
    );
    float localAa = aa / max(halfWidth, 0.000001);
    float parameter = q.y * 0.5 + 0.5;
    float boundedParameter = saturate(parameter);
    float lengthMask = smoothstep(-0.015, 0.025, parameter)
        * (1.0 - smoothstep(0.965, 1.015, parameter));

    // A quadratic bow displaces the rachis most strongly through the middle.
    float spineX = curvature
        * 4.0 * boundedParameter * (1.0 - boundedParameter)
        + curvature * 0.16 * boundedParameter * boundedParameter;
    float relativeX = q.x - spineX;

    // Unequal vane widths and actual missing edge sections avoid a leaf-like
    // symmetric silhouette. The broadest region lies above the midpoint.
    float widthEnvelope = pow(max(sin(PI * boundedParameter), 0.0), 0.68)
        * mix(0.62, 1.08, smoothstep(0.0, 0.58, boundedParameter))
        * mix(1.0, 0.72, smoothstep(0.68, 1.0, boundedParameter));
    float leftWidth = widthEnvelope * (1.0 + asymmetry * 0.23);
    float rightWidth = widthEnvelope * (1.0 - asymmetry * 0.23);
    float leftNotches = smoothstep(
        0.77,
        0.98,
        sin(boundedParameter * PI * 8.0 + notchPhase)
    ) * smoothstep(0.23, 0.91, boundedParameter);
    float rightNotches = smoothstep(
        0.79,
        0.98,
        sin(boundedParameter * PI * 7.0 + notchPhase + 1.9)
    ) * smoothstep(0.29, 0.89, boundedParameter);
    leftWidth *= 1.0 - leftNotches * 0.14;
    rightWidth *= 1.0 - rightNotches * 0.12;

    float edgeDistance = relativeX < 0.0
        ? -relativeX - leftWidth
        : relativeX - rightWidth;
    float vane = (1.0 - smoothstep(-localAa, localAa, edgeDistance)) * lengthMask;
    float edge = (1.0 - smoothstep(
        localAa * 0.30,
        localAa * 1.55,
        abs(edgeDistance)
    )) * lengthMask;

    float sideSign = relativeX < 0.0 ? -1.0 : 1.0;
    float normalizedAcross = relativeX / max(
        relativeX < 0.0 ? leftWidth : rightWidth,
        0.08
    );
    float barbCoordinate = fract(
        boundedParameter * 11.0
            + normalizedAcross * sideSign * 0.23
            + notchPhase / TAU
    );
    float barbs = (1.0 - smoothstep(0.035, 0.095, abs(barbCoordinate - 0.5)))
        * vane
        * smoothstep(0.10, 0.28, boundedParameter)
        * (1.0 - smoothstep(0.90, 0.99, boundedParameter));

    float rachisWidth = mix(0.072, 0.018, boundedParameter);
    float rachis = (1.0 - smoothstep(
        rachisWidth,
        rachisWidth + localAa,
        abs(relativeX)
    )) * lengthMask;
    float calamusDistance = sdCapsule(
        q,
        vec2(curvature * 0.02, -1.17),
        vec2(spineX * 0.32, -0.66),
        0.046
    );
    float calamus = fillMask(calamusDistance, localAa);

    float vaneLight = mix(0.60, 1.10, saturate(0.5 + normalizedAcross * 0.34));
    vec3 color = tint * vane * vaneLight * 0.23;
    color += mix(tint, RACHIS_LIGHT, 0.42) * edge * 0.11;
    color += tint * barbs * 0.065;
    color += RACHIS_LIGHT * rachis * 0.25;
    color += mix(RACHIS_LIGHT, tint, 0.35) * calamus * 0.21;
    return color;
}

vec2 featherPlanePosition(
    vec2 basePlane,
    float travel,
    float phase,
    float flutterStrength,
    float turbulence
) {
    float globalWind = 0.048 * sin(iTime * 0.080 + 0.4)
        + 0.022 * sin(iTime * 0.195 + 2.1);
    float flutterPhase = travel * TAU * 1.55 + phase;
    vec2 flutter = vec2(
        sin(flutterPhase),
        cos(flutterPhase * 0.71 + 0.8)
    ) * flutterStrength * mix(0.35, 1.0, travel);
    vec2 wind = vec2(
        globalWind * travel + turbulence * 0.022 * travel,
        -0.050 * travel * travel
    );
    return basePlane + wind + flutter;
}

vec3 renderPerspectiveFeathers(vec2 world, float aspect, float aa) {
    vec3 effect = vec3(0.0);
    vec2 focal = perspectiveFocal(aspect);
    float resolutionHeight = max(iResolution.y, 1.0);

    for (int featherIndex = 0; featherIndex < PERF_FEATHER_COUNT; featherIndex++) {
        float index = float(featherIndex);
        float layerOffset = (index + 0.5) / float(PERF_FEATHER_COUNT);
        float identity = hash13(vec3(index, 17.3, 61.7));
        float speed = mix(0.067, 0.050, layerOffset)
            * mix(0.88, 1.13, identity);
        float clock = iTime * speed + layerOffset + identity * 3.4;
        float travel = fract(clock);
        float generation = floor(clock);
        float depth = mix(FEATHER_FAR_DEPTH, FEATHER_NEAR_DEPTH, travel);
        float nearFactor = depthNearFactor(depth);
        float lifecycle = smoothstep(0.0, 0.075, travel)
            * (1.0 - smoothstep(0.86, 1.0, travel));

        vec2 positionSeed = hash23(vec3(index, generation, 29.1));
        float phaseSeed = hash13(vec3(index, generation, 83.7));
        float shapeSeed = hash13(vec3(index, generation, 44.3));
        vec2 basePlane = vec2(
            mix(-0.31, 0.31, positionSeed.x) * aspect,
            mix(-0.24, 0.23, positionSeed.y)
        );
        float turbulence = fbm(vec2(
            basePlane.x * 2.2 + generation * 0.43,
            iTime * 0.040 + index * 0.31
        )) - 0.5;
        float phase = phaseSeed * TAU;
        float flutterStrength = mix(0.006, 0.017, shapeSeed);
        vec2 plane = featherPlanePosition(
            basePlane,
            travel,
            phase,
            flutterStrength,
            turbulence
        );
        vec2 center = projectFeatherPoint(plane, depth, focal);

        // Independent pitch and roll produce real foreshortening. A feather can
        // become an edge-on sliver before opening broadside again as it nears.
        float tumbleRate = mix(0.62, 1.20, phaseSeed);
        float tumble = travel * TAU * tumbleRate + phase;
        float lengthView = mix(0.55, 1.0, abs(cos(tumble * 0.61 + 0.4)));
        float widthView = mix(0.36, 1.0, abs(cos(tumble * 0.83 + 1.3)));
        float physicalHalfLength = mix(12.0, 18.0, shapeSeed);
        float halfLengthPixels = min(
            physicalHalfLength / max(depth, 0.001),
            42.0
        ) * lengthView;
        float halfLength = halfLengthPixels / resolutionHeight;
        float halfWidth = halfLength
            * mix(0.19, 0.27, phaseSeed)
            * widthView;

        float radialAngle = atan(center.y - focal.y, center.x - focal.x);
        float aerodynamicBias = (radialAngle - PI * 0.5) * 0.16;
        float rotation = mix(-0.46, 0.46, shapeSeed)
            + sin(tumble) * mix(0.34, 0.82, 1.0 - widthView)
            + sin(tumble * 0.47 + 0.7) * 0.24
            + aerodynamicBias;
        vec2 localPoint = rotate2d(world - center, -rotation);

        float curvature = mix(-0.17, 0.17, positionSeed.x);
        float asymmetry = mix(-0.58, 0.58, phaseSeed);
        vec3 tint = featherTint(
            featherIndex,
            hash13(vec3(index, generation, 12.9))
        );
        float lightFacing = mix(0.58, 1.0, widthView);
        float distanceBrightness = mix(0.25, 1.08, pow(nearFactor, 0.70));
        effect += realisticFeather(
            localPoint,
            halfLength,
            max(halfWidth, 0.22 / resolutionHeight),
            curvature,
            asymmetry,
            phase,
            tint,
            aa
        ) * lifecycle * distanceBrightness * lightFacing;
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

float featherAxisRotation(vec2 axis) {
    return atan(-axis.x, axis.y);
}

void applyConnectedFeatherCursor(inout vec4 color, vec2 fragCoord) {
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
    float age = saturate((iTime - iTimeCursorChange) / 0.38);
    if (moved <= cursorSize * 0.025 || age >= 1.0) {
        return;
    }

    float life = pow(1.0 - age, 2.0);
    float growth = smoothstep(0.0, 0.16, age)
        * (1.0 - smoothstep(0.76, 1.0, age));
    float movementFactor = smoothstep(cursorSize * 0.08, cursorSize * 8.0, moved);
    float effectRadius = cursorSize * 4.0;
    if (
        any(lessThan(point, min(head, tail) - vec2(effectRadius)))
        || any(greaterThan(point, max(head, tail) + vec2(effectRadius)))
    ) {
        return;
    }

    vec2 direction = movement / max(moved, 0.000001);
    vec2 normal = vec2(-direction.y, direction.x);
    float heading = atan(direction.y, direction.x);
    float exchange = 0.5 + 0.5 * sin(iTime * 1.75 + heading * 1.4);
    vec3 leftColor = mix(ZERO_RED, HIRO_CYAN, exchange);
    vec3 rightColor = mix(HIRO_CYAN, ZERO_RED, exchange);
    float aa = 2.0 / max(iResolution.y, 1.0);

    // Two connection filaments braid around the cursor trajectory and merge at
    // its destination, echoing the paired control system rather than a generic
    // comet trail.
    float along = saturate(
        dot(point - tail, movement) / max(dot(movement, movement), 0.000001)
    );
    vec2 pathCenter = mix(tail, head, along);
    float across = dot(point - pathCenter, normal);
    float braidEnvelope = sin(PI * along) * cursorSize * 0.34;
    float braidPhase = along * TAU * 1.65 - age * TAU * 0.8;
    float leftOffset = sin(braidPhase) * braidEnvelope;
    float rightOffset = sin(braidPhase + PI) * braidEnvelope;
    float wakeWidth = cursorSize * 0.050;
    float leftWake = 1.0 - smoothstep(
        wakeWidth,
        wakeWidth + aa,
        abs(across - leftOffset)
    );
    float rightWake = 1.0 - smoothstep(
        wakeWidth,
        wakeWidth + aa,
        abs(across - rightOffset)
    );
    float leftGlow = exp(-abs(across - leftOffset) / max(cursorSize * 0.36, 0.0001));
    float rightGlow = exp(-abs(across - rightOffset) / max(cursorSize * 0.36, 0.0001));
    float trailWindow = smoothstep(0.0, 0.18, along) * life;
    color.rgb += leftColor * (leftWake * 0.22 + leftGlow * 0.050) * trailWindow;
    color.rgb += rightColor * (rightWake * 0.22 + rightGlow * 0.050) * trailWindow;

    // The two destination feathers act as polished horn-like crests: their bare
    // calami begin at the cursor and open into asymmetric colored vanes.
    vec2 leftAxis = normalize(-direction * 0.58 + normal * 0.82);
    vec2 rightAxis = normalize(-direction * 0.58 - normal * 0.82);
    float crestHalfLength = cursorSize
        * mix(0.86, 1.55, movementFactor)
        * max(growth, 0.001);
    float crestHalfWidth = crestHalfLength * 0.235;
    vec2 leftCenter = head + leftAxis * crestHalfLength * 0.70;
    vec2 rightCenter = head + rightAxis * crestHalfLength * 0.70;
    vec2 leftLocal = rotate2d(
        point - leftCenter,
        -featherAxisRotation(leftAxis)
    );
    vec2 rightLocal = rotate2d(
        point - rightCenter,
        -featherAxisRotation(rightAxis)
    );
    vec3 leftFeather = realisticFeather(
        leftLocal,
        crestHalfLength,
        crestHalfWidth,
        -0.13,
        0.42,
        age * TAU + 0.4,
        leftColor,
        aa
    );
    vec3 rightFeather = realisticFeather(
        rightLocal,
        crestHalfLength,
        crestHalfWidth,
        0.13,
        -0.42,
        age * TAU + 2.1,
        rightColor,
        aa
    );
    color.rgb += (leftFeather + rightFeather) * life * 3.15;

    float leftShaftDistance = sdCapsule(
        point,
        head,
        head + leftAxis * crestHalfLength * 0.55,
        cursorSize * 0.045
    );
    float rightShaftDistance = sdCapsule(
        point,
        head,
        head + rightAxis * crestHalfLength * 0.55,
        cursorSize * 0.045
    );
    float leftShaft = fillMask(leftShaftDistance, aa) * life;
    float rightShaft = fillMask(rightShaftDistance, aa) * life;
    color.rgb = mix(color.rgb, mix(leftColor, RACHIS_LIGHT, 0.56), leftShaft * 0.52);
    color.rgb = mix(color.rgb, mix(rightColor, RACHIS_LIGHT, 0.56), rightShaft * 0.52);

    float headDistance = length(point - head);
    float knotRadius = cursorSize * mix(0.78, 1.16, movementFactor);
    float knot = strokeMask(
        headDistance - knotRadius,
        cursorSize * 0.050,
        aa
    ) * life;
    float halo = exp(
        -headDistance * headDistance / max(cursorSize * cursorSize * 2.5, 0.000001)
    );
    color.rgb += mix(leftColor, rightColor, 0.5) * halo * life * 0.085;
    color.rgb += RACHIS_LIGHT * knot * 0.15;

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
    vec3 feathers = renderPerspectiveFeathers(world, aspect, aa)
        * backgroundProtection(terminalColor);
    fragColor = vec4(
        clamp(terminalColor.rgb + feathers, 0.0, 1.0),
        terminalColor.a
    );
    applyConnectedFeatherCursor(fragColor, fragCoord);
}
