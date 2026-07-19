// Ghostty combined shader — Underground Gold
// Inspired by the golden-city references, reimagined beneath a vast cavern:
// black rock, buried towers, molten avenues, drifting ore dust, clean cursor.
// Source images are not embedded or sampled at runtime.
//
// Try: ghostty-shaders.sh set combined darling-underground-gold

#define GPU_ECO 0
#define GPU_BALANCED 1
#define GPU_QUALITY 2
#define GPU_ULTRA 3
#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE GPU_QUALITY
#endif
#if GHOSTTY_GPU_PROFILE == GPU_ECO
#define NOISE_OCTAVES 2
#define CAVERN_DUST 3
#define CITY_ROWS 3
#elif GHOSTTY_GPU_PROFILE == GPU_BALANCED
#define NOISE_OCTAVES 3
#define CAVERN_DUST 5
#define CITY_ROWS 4
#elif GHOSTTY_GPU_PROFILE == GPU_QUALITY
#define NOISE_OCTAVES 4
#define CAVERN_DUST 8
#define CITY_ROWS 6
#else
#define NOISE_OCTAVES 5
#define CAVERN_DUST 12
#define CITY_ROWS 8
#endif

const vec3 VOID_COLOR = vec3(0.004, 0.004, 0.006);
const vec3 ROCK_COLOR = vec3(0.024, 0.018, 0.012);
const vec3 DEEP_GOLD = vec3(0.420, 0.130, 0.004);
const vec3 GOLD = vec3(1.000, 0.520, 0.025);
const vec3 HOT_GOLD = vec3(1.000, 0.860, 0.280);
const vec3 WHITE_GOLD = vec3(1.000, 0.970, 0.720);
const vec3 CURSOR_BODY = vec3(0.92, 0.58, 0.18);
const vec3 CURSOR_HOT = vec3(1.00, 0.90, 0.46);
const float PI = 3.14159265359;
const float CURSOR_DURATION = 0.20;

float luminance(vec3 color) { return dot(color, vec3(0.2126, 0.7152, 0.0722)); }

float hash12(vec2 point) {
    vec3 p3 = fract(vec3(point.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 point) {
    float first = hash12(point);
    return vec2(first, hash12(point + first + 29.19));
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

float fbm(vec2 point) {
    float sum = 0.0;
    float amplitude = 0.55;
    mat2 transform = mat2(1.65, 1.15, -1.15, 1.65);
    for (int octave = 0; octave < NOISE_OCTAVES; ++octave) {
        sum += valueNoise(point) * amplitude;
        point = transform * point + vec2(13.7, 9.2);
        amplitude *= 0.48;
    }
    return sum;
}

float softPoint(float distanceValue, float radius) {
    radius = max(radius, 0.000001);
    return exp(-distanceValue * distanceValue / (radius * radius));
}

float backgroundMask(vec4 terminal) {
    float difference = length(terminal.rgb - iBackgroundColor);
    float similar = 1.0 - smoothstep(0.035, 0.25, difference);
    float transparent = 1.0 - smoothstep(0.22, 0.94, terminal.a);
    float dark = 1.0 - smoothstep(0.10, 0.42, luminance(terminal.rgb));
    return clamp(max(transparent, max(similar, dark * 0.22)), 0.0, 1.0);
}

vec3 cavernRock(vec2 uv) {
    float ceilingNoise = fbm(vec2(uv.x * 3.6, 4.2));
    float floorNoise = fbm(vec2(uv.x * 4.3 + 8.0, 12.7));
    float ceiling = 0.80 + 0.13 * (ceilingNoise - 0.50);
    float floorHeight = 0.055 + 0.08 * (floorNoise - 0.35);
    float ceilingMask = smoothstep(ceiling - 0.018, ceiling + 0.008, uv.y);
    float floorMask = 1.0 - smoothstep(floorHeight - 0.008, floorHeight + 0.020, uv.y);

    float xCell = floor(uv.x * 19.0);
    float localX = fract(uv.x * 19.0) - 0.5;
    float stalactiteLength = mix(0.03, 0.22, pow(hash12(vec2(xCell, 3.7)), 2.0));
    float stalactiteWidth = mix(0.06, 0.24, hash12(vec2(xCell, 9.1)));
    float stalactite = step(abs(localX), stalactiteWidth)
        * smoothstep(ceiling - stalactiteLength - 0.015, ceiling - stalactiteLength + 0.02, uv.y)
        * (1.0 - step(ceiling, uv.y));

    float rock = clamp(ceilingMask + floorMask + stalactite, 0.0, 1.0);
    float textureNoise = fbm(uv * vec2(8.0, 6.0));
    vec3 color = mix(VOID_COLOR, ROCK_COLOR * (0.55 + textureNoise * 0.45), rock);
    float rim = softPoint(abs(uv.y - ceiling), 0.012)
        + softPoint(abs(uv.y - floorHeight), 0.010);
    color += DEEP_GOLD * rim * 0.10;
    return color;
}

vec3 buriedCity(vec2 uv) {
    vec3 color = vec3(0.0);
    float horizon = 0.245;
    for (int rowIndex = 0; rowIndex < CITY_ROWS; ++rowIndex) {
        float row = float(rowIndex);
        float depth = (row + 1.0) / float(CITY_ROWS);
        float count = mix(38.0, 12.0, depth);
        float coordinate = uv.x * count + row * 17.7;
        float id = floor(coordinate);
        float localX = fract(coordinate);
        float randomValue = hash12(vec2(id, row * 5.1));
        float base = mix(0.16, 0.065, depth);
        float height = mix(0.08, 0.34, depth) * mix(0.32, 1.0, randomValue);
        float top = base + height;
        float margin = mix(0.14, 0.06, depth);
        float body = step(margin, localX) * step(localX, 1.0 - margin)
            * step(base, uv.y) * (1.0 - step(top, uv.y));
        color += vec3(0.020, 0.013, 0.007) * body;

        vec2 grid = vec2(localX * mix(9.0, 5.0, depth), (uv.y - base) * mix(100.0, 42.0, depth));
        vec2 cell = fract(grid);
        vec2 cellId = floor(grid);
        float windowShape = step(0.20, cell.x) * step(cell.x, 0.80)
            * step(0.20, cell.y) * step(cell.y, 0.68);
        float lit = step(mix(0.72, 0.43, depth), hash12(cellId + vec2(id * 2.1, row * 11.3)));
        color += mix(GOLD, HOT_GOLD, hash12(cellId + 4.8))
            * windowShape * lit * body * mix(0.15, 0.68, depth);
        color += HOT_GOLD * softPoint(abs(uv.y - top), mix(0.004, 0.0018, depth))
            * step(margin, localX) * step(localX, 1.0 - margin) * 0.16;
    }

    float haze = softPoint(abs(uv.y - horizon), 0.13);
    color += GOLD * haze * 0.055;
    return color;
}

vec3 moltenAvenue(vec2 uv) {
    float belowHorizon = 1.0 - smoothstep(0.235, 0.255, uv.y);
    float perspective = clamp((0.245 - uv.y) / 0.245, 0.0, 1.0);
    float center = 0.50 + 0.015 * sin(iTime * 0.08);
    float halfWidth = mix(0.008, 0.24, perspective);
    float distanceToEdge = abs(abs(uv.x - center) - halfWidth);
    float interior = 1.0 - smoothstep(halfWidth * 0.55, halfWidth, abs(uv.x - center));
    float riverNoise = fbm(vec2(uv.x * 28.0, uv.y * 55.0 - iTime * 0.16));
    vec3 color = DEEP_GOLD * interior * belowHorizon * 0.20;
    color += GOLD * interior * belowHorizon * pow(riverNoise, 4.0) * 0.30;
    color += WHITE_GOLD * softPoint(distanceToEdge, 0.004) * belowHorizon * 0.18;
    return color;
}

vec3 oreDust(vec2 uv) {
    vec3 color = vec3(0.0);
    for (int dustIndex = 0; dustIndex < CAVERN_DUST; ++dustIndex) {
        float indexValue = float(dustIndex);
        vec2 seed = hash22(vec2(indexValue * 17.7, indexValue * 41.3));
        vec2 position = fract(seed + vec2(0.012, 0.021) * iTime * (0.4 + seed.x));
        position.y = mix(0.12, 0.78, position.y);
        float dust = softPoint(length((uv - position) * vec2(iResolution.x / iResolution.y, 1.0)), 0.0025 + seed.y * 0.0025);
        color += mix(GOLD, WHITE_GOLD, seed.x) * dust * 0.25;
    }
    return color;
}

vec4 renderScene(vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = fragCoord / resolution;
    vec4 terminal = texture(iChannel0, uv);
    vec3 scene = cavernRock(uv);
    scene += buriedCity(uv);
    scene += moltenAvenue(uv);
    scene += oreDust(uv);
    float shaft = softPoint(abs(uv.x - 0.50), 0.10) * smoothstep(0.22, 0.84, uv.y);
    scene += HOT_GOLD * shaft * 0.018;
    scene *= 1.0 - 0.24 * smoothstep(0.45, 0.78, length((uv - 0.5) * vec2(1.0, 1.25)));
    scene = vec3(1.0) - exp(-scene * 1.24);
    float mask = backgroundMask(terminal);
    vec3 base = mix(terminal.rgb, terminal.rgb * 0.47, mask * 0.76);
    return vec4(base + scene * mask, terminal.a);
}

vec2 normalizeScreen(vec2 value, float position) {
    return (value * 2.0 - iResolution.xy * position) / max(iResolution.y, 1.0);
}

float sdCursorBox(vec2 point, vec2 center, vec2 halfSize) {
    vec2 distanceVector = abs(point - center) - halfSize;
    return length(max(distanceVector, 0.0)) + min(max(distanceVector.x, distanceVector.y), 0.0);
}

float sdCapsule(vec2 point, vec2 startPoint, vec2 endPoint, float radius) {
    vec2 segment = endPoint - startPoint;
    float along = clamp(dot(point - startPoint, segment) / max(dot(segment, segment), 0.000001), 0.0, 1.0);
    return length(point - startPoint - segment * along) - radius;
}

vec2 cursorCenter(vec4 cursor) { return vec2(cursor.x + cursor.z * 0.5, cursor.y - cursor.w * 0.5); }

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
    float radius = size * mix(0.90, 1.80, movement) * (1.0 + 0.20 * sin(age * PI));
    float headGlow = (1.0 - smoothstep(radius * 0.25, radius, distance(point, head))) * life;
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
    outputColor = mix(outputColor, original, step(sdCursorBox(point, head, current.zw * 0.5), 0.0));
    outputColor.a = original.a;
    return outputColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / max(iResolution.xy, vec2(1.0));
    vec4 terminal = texture(iChannel0, uv);
    fragColor = cleanCursor(renderScene(fragCoord), terminal, fragCoord);
}
