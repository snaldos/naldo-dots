// Calm mathematical rain for Ghostty + Pi.
//
// This is a post-processing shader: it never writes terminal escape sequences,
// moves the cursor, or changes terminal text. Sparse low-opacity symbols are
// blended below a clear header region so the foreground remains dominant.

const vec2 CELL_SIZE = vec2(32.0, 40.0);
const float TOP_CLEAR_FRACTION = 0.30;
const float EFFECT_STRENGTH = 0.12;
const float CYCLE_LENGTH = 22.0;

const vec3 BLUE = vec3(0.478, 0.635, 0.969);
const vec3 PURPLE = vec3(0.733, 0.604, 0.969);
const vec3 GREEN = vec3(0.620, 0.808, 0.416);
const vec3 MUTED = vec3(0.604, 0.647, 0.808);

float hash11(float value) {
    return fract(sin(value * 127.1 + 311.7) * 43758.5453123);
}

float hash21(vec2 value) {
    return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453123);
}

float sdSegment(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 relative = point - startPoint;
    vec2 segment = endPoint - startPoint;
    float position = clamp(
        dot(relative, segment) / max(dot(segment, segment), 0.00001),
        0.0,
        1.0
    );
    return length(relative - segment * position);
}

float stroke(float distanceValue, float width) {
    return 1.0 - smoothstep(width, width + 0.035, distanceValue);
}

float piSymbol(vec2 point) {
    float distanceValue = min(
        sdSegment(point, vec2(-0.34, 0.31), vec2(0.34, 0.31)),
        min(
            sdSegment(point, vec2(-0.20, 0.31), vec2(-0.23, -0.31)),
            sdSegment(point, vec2(0.20, 0.31), vec2(0.17, -0.31))
        )
    );
    return stroke(distanceValue, 0.055);
}

float sigmaSymbol(vec2 point) {
    float distanceValue = min(
        sdSegment(point, vec2(-0.31, 0.32), vec2(0.30, 0.32)),
        min(
            sdSegment(point, vec2(-0.31, 0.32), vec2(0.16, 0.0)),
            min(
                sdSegment(point, vec2(0.16, 0.0), vec2(-0.31, -0.32)),
                sdSegment(point, vec2(-0.31, -0.32), vec2(0.30, -0.32))
            )
        )
    );
    return stroke(distanceValue, 0.052);
}

float integralSymbol(vec2 point) {
    float curve = point.x - 0.16 * sin(point.y * 4.4);
    float body = abs(curve);
    float caps = min(
        sdSegment(point, vec2(0.0, 0.31), vec2(0.19, 0.35)),
        sdSegment(point, vec2(0.0, -0.31), vec2(-0.19, -0.35))
    );
    return max(stroke(body, 0.052), stroke(caps, 0.05));
}

float nablaSymbol(vec2 point) {
    float distanceValue = min(
        sdSegment(point, vec2(-0.34, 0.28), vec2(0.34, 0.28)),
        min(
            sdSegment(point, vec2(-0.34, 0.28), vec2(0.0, -0.34)),
            sdSegment(point, vec2(0.34, 0.28), vec2(0.0, -0.34))
        )
    );
    return stroke(distanceValue, 0.052);
}

float lambdaSymbol(vec2 point) {
    float distanceValue = min(
        sdSegment(point, vec2(-0.27, -0.34), vec2(0.02, 0.34)),
        sdSegment(point, vec2(0.02, 0.34), vec2(0.32, -0.34))
    );
    return stroke(distanceValue, 0.055);
}

float xSymbol(vec2 point) {
    float distanceValue = min(
        sdSegment(point, vec2(-0.27, 0.28), vec2(0.27, -0.28)),
        sdSegment(point, vec2(0.27, 0.28), vec2(-0.27, -0.28))
    );
    return stroke(distanceValue, 0.05);
}

float plusSymbol(vec2 point) {
    float distanceValue = min(
        sdSegment(point, vec2(-0.29, 0.0), vec2(0.29, 0.0)),
        sdSegment(point, vec2(0.0, 0.29), vec2(0.0, -0.29))
    );
    return stroke(distanceValue, 0.05);
}

float symbolMask(float symbol, vec2 point) {
    if (symbol < 1.0) return piSymbol(point);
    if (symbol < 2.0) return sigmaSymbol(point);
    if (symbol < 3.0) return integralSymbol(point);
    if (symbol < 4.0) return nablaSymbol(point);
    if (symbol < 5.0) return lambdaSymbol(point);
    if (symbol < 6.0) return xSymbol(point);
    return plusSymbol(point);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 textureCoordinate = fragCoord / iResolution.xy;
    vec4 originalColor = texture(iChannel0, textureCoordinate);
    fragColor = originalColor;

    // Keep the header, composer, and initial status region visually quiet.
    if (fragCoord.y > iResolution.y * (1.0 - TOP_CLEAR_FRACTION)) {
        return;
    }

    vec2 grid = fragCoord / CELL_SIZE;
    float column = floor(grid.x);
    float screenRow = floor(grid.y);
    vec2 local = fract(grid) - 0.5;
    local.x *= CELL_SIZE.x / CELL_SIZE.y;

    // Only a restrained subset of columns rains; the rest stay untouched.
    if (hash11(column + 91.0) < 0.72) {
        return;
    }

    float speed = mix(1.4, 3.4, hash11(column + 3.0));
    float offset = hash11(column + 17.0) * CYCLE_LENGTH;
    float phase = mod(screenRow - iTime * speed + offset, CYCLE_LENGTH);
    float trail = 1.0 - smoothstep(0.0, 4.5, phase);
    trail *= step(phase, 4.5);

    float movingRow = floor(screenRow - iTime * speed);
    float symbol = floor(hash21(vec2(column, movingRow)) * 7.0);
    float mask = symbolMask(symbol, local);

    // Symbols are sparse and low-opacity. The upper UI region is excluded
    // entirely, while normal terminal text remains dominant elsewhere.
    float emptyCell = 1.0;

    float colorChoice = hash11(column + 71.0);
    vec3 symbolColor = colorChoice < 0.45
        ? BLUE
        : colorChoice < 0.70
            ? MUTED
            : colorChoice < 0.86
                ? PURPLE
                : GREEN;

    float head = 1.0 - smoothstep(0.0, 1.2, phase);
    float intensity = mask * trail * emptyCell * mix(0.45, 1.0, head) * EFFECT_STRENGTH;
    fragColor.rgb = mix(originalColor.rgb, symbolColor, intensity);
    fragColor.a = originalColor.a;
}
