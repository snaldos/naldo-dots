// Frozen cursor shader with one controlled change: adjustable, movement-aware
// intensity. Geometry, colors, layering, and cubic timing below are otherwise
// the same as shaders/cursor/frozen.glsl.
//
// This shader is deliberately identical across GPU profiles. Frozen has no
// expensive loops or quantities to reduce, so changing profile must not change
// its appearance.

#define CLEAN_FROST_GPU_ECO      0
#define CLEAN_FROST_GPU_BALANCED 1
#define CLEAN_FROST_GPU_QUALITY  2
#define CLEAN_FROST_GPU_ULTRA    3

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE CLEAN_FROST_GPU_QUALITY
#endif

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);

    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);

    return s * sqrt(d);
}

vec2 norm(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
    return 1. - smoothstep(0., norm(vec2(2., 2.), 0.).x, distance);
}

float determineStartVertexFactor(vec2 c, vec2 p) {
    // Conditions using step
    float condition1 = step(p.x, c.x) * step(c.y, p.y); // c.x < p.x && c.y > p.y
    float condition2 = step(c.x, p.x) * step(p.y, c.y); // c.x > p.x && c.y < p.y

    // If neither condition is met, return 1 (else case)
    return 1.0 - max(condition1, condition2);
}

float determineStartVertexFactor2(vec2 c, vec2 p) {
    // Conditions using step
    float condition1 = step(p.x, c.x) * step(c.y, p.y); // c.x < p.x && c.y > p.y
    float condition2 = step(c.x, p.x) * step(p.y, c.y); // c.x > p.x && c.y < p.y

    // If neither condition is met, return 1 (else case)
    return 1.0 - max(condition1, condition2);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}
float ease(float x) {
    return pow(1.0 - x, 3.0);
}

const vec4 TRAIL_COLOR = vec4(.502, 0.98, 1., 1.0);
const vec4 TRAIL_COLOR_ACCENT = vec4(.0, 0., 1., 1.0);
const float DURATION = 0.3; //IN SECONDS

// =============================================================================
// GLOW CONTROL
// =============================================================================

// Overall Frozen-effect intensity: 0.0 disables it, 1.0 is the exact original.
const float GLOW_STRENGTH = 0.72;

// 1.0 makes short moves dimmer and long moves brighter; 0.0 gives every move
// the same GLOW_STRENGTH and therefore reproduces Frozen exactly at 1.0 above.
const float GLOW_DISTANCE_RESPONSE = 1.0;

// Short movements use this fraction of GLOW_STRENGTH. The effect reaches full
// configured strength at FULL_GLOW_DISTANCE_CELLS cursor cells.
const float SMALL_MOVEMENT_GLOW_FACTOR = 0.35;
const float FULL_GLOW_DISTANCE_CELLS = 8.0;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    vec4 originalColor = fragColor;
    // Normalization for fragCoord to a space of -1 to 1;
    vec2 vu = norm(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    // Normalization for cursor position and size;
    // cursor xy has the postion in a space of -1 to 1;
    // zw has the width and height
    vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);
    // When drawing a parellelogram between cursors for the trail i need to determine where to start at the top-left or top-right vertex of the cursor
    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    // Set every vertex of my parellogram
    vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
    vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

    float sdfCurrentCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
    float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

    float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    float easedProgress = ease(progress);
    // Distance between cursors determine the total length of the parallelogram;
    float lineLength = distance(centerCC, centerCP);

    vec4 newColor = vec4(fragColor);
    // Compute fade factor based on distance along the trail
    float fadeFactor = 1.0 - smoothstep(lineLength, sdfCurrentCursor, easedProgress * lineLength);

    float mod = .007;
    //trailblaze
    vec4 trail = mix(TRAIL_COLOR_ACCENT, fragColor, 1. - smoothstep(0., sdfTrail + mod, 0.007));
    trail = mix(TRAIL_COLOR, trail, 1. - smoothstep(0., sdfTrail + mod, 0.006));
    trail = mix(trail, TRAIL_COLOR, step(sdfTrail + mod, 0.));
    //cursorblaze
    trail = mix(TRAIL_COLOR_ACCENT, trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
    trail = mix(TRAIL_COLOR, trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
    vec4 frozenColor = mix(trail, fragColor, 1. - smoothstep(0., sdfCurrentCursor, easedProgress * lineLength));

    // Measure displacement in cursor-cell units so horizontal and vertical
    // movement contribute consistently despite different cell dimensions.
    vec2 movementCells = (centerCC - centerCP) / max(
        currentCursor.zw,
        vec2(0.000001)
    );
    float movementDistanceCells = length(movementCells);
    float distanceFactor = mix(
        SMALL_MOVEMENT_GLOW_FACTOR,
        1.0,
        smoothstep(
            0.0,
            FULL_GLOW_DISTANCE_CELLS,
            movementDistanceCells
        )
    );
    float adaptiveFactor = mix(
        1.0,
        distanceFactor,
        clamp(GLOW_DISTANCE_RESPONSE, 0.0, 1.0)
    );
    float glowStrength = clamp(
        GLOW_STRENGTH * adaptiveFactor,
        0.0,
        1.0
    );

    fragColor = mix(originalColor, frozenColor, glowStrength);
}
