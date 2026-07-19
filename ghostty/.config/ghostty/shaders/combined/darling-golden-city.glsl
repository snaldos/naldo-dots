// Ghostty combined shader — Golden City
// Visual references: city_zero_two.png and city_zero_two_2.png.
// Original procedural interpretation: an immense amber metropolis, luminous
// towers, glass suspension lines, atmospheric haze, and a clean gold cursor.
// Source images are not embedded or sampled at runtime.
//
// Try: ghostty-shaders.sh set combined darling-golden-city

#define GPU_ECO 0
#define GPU_BALANCED 1
#define GPU_QUALITY 2
#define GPU_ULTRA 3
#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE GPU_QUALITY
#endif
#if GHOSTTY_GPU_PROFILE == GPU_ECO
#define CITY_LAYERS 3
#define STAR_LAYERS 1
#elif GHOSTTY_GPU_PROFILE == GPU_BALANCED
#define CITY_LAYERS 4
#define STAR_LAYERS 2
#elif GHOSTTY_GPU_PROFILE == GPU_QUALITY
#define CITY_LAYERS 6
#define STAR_LAYERS 3
#else
#define CITY_LAYERS 8
#define STAR_LAYERS 4
#endif

const vec3 NIGHT = vec3(0.008, 0.009, 0.012);
const vec3 UMBER = vec3(0.120, 0.060, 0.018);
const vec3 AMBER = vec3(1.000, 0.390, 0.015);
const vec3 GOLD = vec3(1.000, 0.690, 0.080);
const vec3 HOT_GOLD = vec3(1.000, 0.900, 0.420);
const vec3 IVORY = vec3(1.000, 0.970, 0.790);
const vec3 CURSOR_BODY = vec3(0.88, 0.69, 0.41);
const vec3 CURSOR_HOT = vec3(1.00, 0.84, 0.38);
const float PI = 3.14159265359;
const float CURSOR_DURATION = 0.20;

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

float valueNoise(vec2 point) {
    vec2 cell = floor(point);
    vec2 local = fract(point);
    local = local * local * (3.0 - 2.0 * local);
    return mix(
        mix(hash12(cell), hash12(cell + vec2(1.0, 0.0)), local.x),
        mix(hash12(cell + vec2(0.0, 1.0)), hash12(cell + vec2(1.0)), local.x),
        local.y
    );
}

float softPoint(float distanceValue, float radius) {
    radius = max(radius, 0.000001);
    return exp(-distanceValue * distanceValue / (radius * radius));
}

float sdBox(vec2 point, vec2 halfSize) {
    vec2 distanceVector = abs(point) - halfSize;
    return length(max(distanceVector, 0.0))
        + min(max(distanceVector.x, distanceVector.y), 0.0);
}

float segmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    float along = clamp(
        dot(point - startPoint, segment) / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );
    return length(point - startPoint - segment * along);
}

float backgroundMask(vec4 terminal) {
    float difference = length(terminal.rgb - iBackgroundColor);
    float similar = 1.0 - smoothstep(0.035, 0.25, difference);
    float transparent = 1.0 - smoothstep(0.22, 0.94, terminal.a);
    float dark = 1.0 - smoothstep(0.10, 0.42, luminance(terminal.rgb));
    return clamp(max(transparent, max(similar, dark * 0.22)), 0.0, 1.0);
}

vec3 cityLayer(vec2 uv, float layerIndex) {
    float depth = (layerIndex + 1.0) / float(CITY_LAYERS);
    float count = mix(42.0, 10.0, depth);
    float parallax = iTime * mix(0.0015, 0.0002, depth);
    float coordinate = uv.x * count + parallax + layerIndex * 19.31;
    float buildingId = floor(coordinate);
    float localX = fract(coordinate);
    float randomValue = hash12(vec2(buildingId, layerIndex * 7.7));
    float base = mix(0.19, 0.055, depth);
    float height = mix(0.10, 0.48, depth)
        * mix(0.30, 1.0, pow(randomValue, 1.45));
    float towerChance = step(0.91, hash12(vec2(buildingId * 2.3, layerIndex + 4.1)));
    height += towerChance * mix(0.08, 0.25, depth);
    float top = base + height;
    float margin = mix(0.12, 0.055, depth);
    float horizontalBody = step(margin, localX) * step(localX, 1.0 - margin);
    float verticalBody = step(base, uv.y) * (1.0 - step(top, uv.y));
    float body = horizontalBody * verticalBody;

    vec3 facade = mix(vec3(0.018, 0.016, 0.014), UMBER, 0.28 + depth * 0.34);
    float sideShade = mix(0.46, 1.0, smoothstep(margin, 0.72, localX));
    vec3 color = facade * body * sideShade;

    vec2 windowGrid = vec2(
        localX * mix(10.0, 5.0, depth),
        (uv.y - base) * mix(115.0, 42.0, depth)
    );
    vec2 windowCell = fract(windowGrid);
    vec2 windowId = floor(windowGrid);
    float windowShape = step(0.22, windowCell.x)
        * step(windowCell.x, 0.78)
        * step(0.22, windowCell.y)
        * step(windowCell.y, 0.72);
    float lit = step(
        mix(0.70, 0.46, depth),
        hash12(windowId + vec2(buildingId * 3.1, layerIndex * 13.7))
    );
    float flicker = 0.86 + 0.14 * sin(
        iTime * (0.25 + randomValue * 0.45) + buildingId
    );
    vec3 windowColor = mix(AMBER, HOT_GOLD, hash12(windowId + 8.4));
    color += windowColor * windowShape * lit * body * flicker * mix(0.16, 0.72, depth);

    float edge = softPoint(abs(localX - margin), mix(0.016, 0.008, depth))
        + softPoint(abs(localX - (1.0 - margin)), mix(0.016, 0.008, depth));
    color += GOLD * edge * verticalBody * mix(0.012, 0.11, depth);
    float roof = softPoint(abs(uv.y - top), mix(0.0045, 0.0018, depth));
    color += HOT_GOLD * roof * horizontalBody * mix(0.03, 0.20, depth);
    return color;
}

vec3 signatureTowers(vec2 uv) {
    vec3 color = vec3(0.0);
    vec2 leftPoint = uv - vec2(0.075, 0.54);
    vec2 rightPoint = uv - vec2(0.905, 0.57);
    float leftBody = 1.0 - smoothstep(0.0, 0.0025, sdBox(leftPoint, vec2(0.042, 0.47)));
    float rightBody = 1.0 - smoothstep(0.0, 0.0025, sdBox(rightPoint, vec2(0.050, 0.50)));
    color += vec3(0.055, 0.030, 0.012) * (leftBody + rightBody);

    float leftCore = softPoint(abs(leftPoint.x + 0.011), 0.006) * leftBody;
    float rightCore = softPoint(abs(rightPoint.x - 0.014), 0.007) * rightBody;
    color += HOT_GOLD * (leftCore + rightCore) * 0.64;
    color += AMBER * (
        softPoint(abs(leftPoint.x - 0.032), 0.0035) * leftBody
        + softPoint(abs(rightPoint.x + 0.041), 0.0035) * rightBody
    ) * 0.45;

    float leftWindows = step(0.68, hash12(floor((leftPoint + 1.0) * vec2(36.0, 90.0))))
        * step(0.14, fract(leftPoint.y * 90.0))
        * step(fract(leftPoint.y * 90.0), 0.62);
    float rightWindows = step(0.70, hash12(floor((rightPoint + 1.0) * vec2(34.0, 94.0))))
        * step(0.18, fract(rightPoint.y * 94.0))
        * step(fract(rightPoint.y * 94.0), 0.68);
    color += GOLD * (leftWindows * leftBody + rightWindows * rightBody) * 0.28;
    return color;
}

vec3 goldenSky(vec2 uv) {
    vec3 color = mix(NIGHT, vec3(0.16, 0.065, 0.012), pow(1.0 - uv.y, 2.3));
    float horizon = softPoint(abs(uv.y - 0.20), 0.13);
    color += AMBER * horizon * 0.075;

    for (int layerIndex = 0; layerIndex < STAR_LAYERS; ++layerIndex) {
        float layer = float(layerIndex);
        vec2 grid = uv * (vec2(85.0, 45.0) + layer * 31.0);
        vec2 cell = floor(grid);
        vec2 local = fract(grid) - 0.5;
        vec2 offset = (hash22(cell + layer * 17.3) - 0.5) * 0.75;
        float exists = step(0.965, hash12(cell + layer * 29.1));
        float star = softPoint(length(local - offset), 0.035 + layer * 0.005);
        color += IVORY * star * exists * (0.12 + 0.04 * sin(iTime + hash12(cell) * 20.0));
    }

    float cloudNoise = valueNoise(vec2(uv.x * 5.0 + iTime * 0.006, uv.y * 18.0));
    float clouds = smoothstep(0.59, 0.80, cloudNoise) * smoothstep(0.24, 0.58, uv.y);
    color += vec3(0.11, 0.065, 0.030) * clouds * 0.18;
    return color;
}

vec3 glassLines(vec2 uv) {
    vec3 color = vec3(0.0);
    float first = segmentDistance(uv, vec2(0.08, 1.02), vec2(0.42, 0.16));
    float second = segmentDistance(uv, vec2(0.92, 1.02), vec2(0.58, 0.16));
    float third = segmentDistance(uv, vec2(0.25, 1.02), vec2(0.50, 0.16));
    float fourth = segmentDistance(uv, vec2(0.75, 1.02), vec2(0.50, 0.16));
    color += AMBER * (
        softPoint(first, 0.0012) + softPoint(second, 0.0012)
        + softPoint(third, 0.0008) + softPoint(fourth, 0.0008)
    ) * 0.065;
    return color;
}

vec4 renderScene(vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    vec4 terminal = texture(iChannel0, uv);
    vec3 scene = goldenSky(uv);
    for (int layerIndex = 0; layerIndex < CITY_LAYERS; ++layerIndex) {
        scene += cityLayer(uv, float(layerIndex));
    }
    scene += signatureTowers(uv);
    scene += glassLines(uv);

    float floorMask = 1.0 - smoothstep(0.02, 0.16, uv.y);
    float reflectionNoise = valueNoise(vec2(uv.x * 95.0, uv.y * 15.0 - iTime * 0.08));
    scene += GOLD * floorMask * pow(reflectionNoise, 5.0) * 0.13;
    scene *= 1.0 - 0.18 * smoothstep(0.58, 0.90, length((uv - 0.5) * vec2(1.0, 1.35)));
    scene = vec3(1.0) - exp(-scene * 1.18);

    float mask = backgroundMask(terminal);
    vec3 base = mix(terminal.rgb, terminal.rgb * 0.52, mask * 0.74);
    return vec4(base + scene * mask, terminal.a);
}

vec2 normalizeScreen(vec2 value, float position) {
    return (value * 2.0 - iResolution.xy * position) / max(iResolution.y, 1.0);
}

float sdCursorBox(vec2 point, vec2 center, vec2 halfSize) {
    vec2 distanceVector = abs(point - center) - halfSize;
    return length(max(distanceVector, 0.0))
        + min(max(distanceVector.x, distanceVector.y), 0.0);
}

float sdCapsule(vec2 point, vec2 startPoint, vec2 endPoint, float radius) {
    vec2 segment = endPoint - startPoint;
    float along = clamp(dot(point - startPoint, segment) / max(dot(segment, segment), 0.000001), 0.0, 1.0);
    return length(point - startPoint - segment * along) - radius;
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5);
}

vec4 cleanCursor(vec4 original, vec4 terminal, vec2 fragCoord) {
    if (iCursorVisible <= 0 || iCurrentCursor.z <= 0.0 || iCurrentCursor.w <= 0.0) return original;
    vec2 point = normalizeScreen(fragCoord, 1.0);
    vec4 current = vec4(normalizeScreen(iCurrentCursor.xy, 1.0), normalizeScreen(iCurrentCursor.zw, 0.0));
    vec4 previous = vec4(normalizeScreen(iPreviousCursor.xy, 1.0), normalizeScreen(iPreviousCursor.zw, 0.0));
    vec2 head = cursorCenter(current);
    vec2 tail = cursorCenter(previous);
    float size = max(current.z, current.w);
    float moved = distance(head, tail);
    float age = clamp((iTime - iTimeCursorChange) / CURSOR_DURATION, 0.0, 1.0);
    if (moved <= 0.0 || age >= 1.0) return original;

    float life = pow(1.0 - (1.0 - pow(1.0 - age, 3.0)), 2.2);
    float movement = smoothstep(0.0, 8.0 * size, moved);
    float headRadius = size * mix(0.90, 1.80, movement) * (1.0 + 0.20 * sin(age * PI));
    float headGlow = (1.0 - smoothstep(headRadius * 0.25, headRadius, distance(point, head))) * life;
    float trailRadius = size * mix(0.18, 0.34, movement);
    float trailDistance = sdCapsule(point, tail, head, trailRadius);
    vec2 travel = head - tail;
    float along = clamp(dot(point - tail, travel) / max(dot(travel, travel), 0.000001), 0.0, 1.0);
    float tailFade = smoothstep(0.0, 0.28, along);
    float pixel = normalizeScreen(vec2(1.5), 0.0).x;
    float core = (1.0 - smoothstep(0.0, pixel, trailDistance)) * life * tailFade;
    float glow = (1.0 - smoothstep(0.0, trailRadius * 2.4, max(trailDistance, 0.0))) * life * tailFade;
    float permission = mix(0.18, 1.0, backgroundMask(terminal));

    vec4 outputColor = original;
    outputColor.rgb = mix(outputColor.rgb, CURSOR_BODY, headGlow * 0.14 * permission);
    outputColor.rgb = mix(outputColor.rgb, CURSOR_BODY, glow * 0.08 * permission);
    outputColor.rgb = mix(outputColor.rgb, CURSOR_HOT, core * 0.24 * permission);
    float cursorDistance = sdCursorBox(point, head, current.zw * 0.5);
    outputColor = mix(outputColor, original, step(cursorDistance, 0.0));
    outputColor.a = original.a;
    return outputColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / max(iResolution.xy, vec2(1.0));
    vec4 terminal = texture(iChannel0, uv);
    vec4 scene = renderScene(fragCoord);
    fragColor = cleanCursor(scene, terminal, fragCoord);
}
