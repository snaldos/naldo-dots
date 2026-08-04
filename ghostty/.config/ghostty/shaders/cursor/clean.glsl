// Gold cursor movement shader for Ghostty.
//
// Behavior:
// - no glow while stationary
// - circular glow appears during movement
// - larger movement produces a larger glow
// - subtle trail between the old and new cursor positions
// - Ghostty transparency is preserved
//
// Recommended Ghostty settings:
//
// cursor-color = e0af68
// cursor-text = 1a1b26
// custom-shader-animation = true

// =============================================================================
// TWEAKABLE SETTINGS
// =============================================================================

// How long the movement effect remains visible, in seconds.
//
// Lower: faster and sharper
// Higher: slower and smoother
const float EFFECT_DURATION = 0.20;

// Minimum movement required to activate the effect.
//
// 0.0  = every cursor movement
// 0.5  = ignore very small movements
// 1.1  = ignore roughly one-cell movements
const float MIN_MOVEMENT = 0.0;

// Cursor movement distance at which the glow reaches maximum size.
//
// Lower: maximum radius reached more easily
// Higher: only large jumps produce the maximum radius
const float MAX_MOVEMENT_DISTANCE = 8.0;

// Circular glow radius for small movements.
const float HEAD_RADIUS_MIN = 0.90;

// Circular glow radius for large movements.
const float HEAD_RADIUS_MAX = 1.80;

// Additional expansion in the middle of the animation.
//
// 0.0  = no expansion animation
// 0.2  = subtle expansion
// 0.4  = pronounced expansion
const float EXPANSION_AMOUNT = 0.20;

// Strength of the circular glow around the destination cursor.
//
// 0.08 = faint
// 0.14 = balanced
// 0.25 = strong
const float HEAD_GLOW_STRENGTH = 0.14;

// Where the circular glow begins fading.
//
// Lower: brighter center and softer circle
// Higher: thinner ring-like appearance
const float HEAD_GLOW_INNER_RATIO = 0.25;

// Trail thickness for small movements.
const float TRAIL_RADIUS_MIN = 0.18;

// Trail thickness for large movements.
const float TRAIL_RADIUS_MAX = 0.34;

// Width of the soft trail glow.
//
// Higher: wider and softer trail
const float TRAIL_GLOW_WIDTH = 2.40;

// Strength of the soft outer trail.
const float TRAIL_GLOW_STRENGTH = 0.08;

// Strength of the brighter trail center.
const float TRAIL_CORE_STRENGTH = 0.24;

// How quickly the beginning of the trail fades.
//
// Lower: more of the old cursor position remains visible
// Higher: trail concentrates near the new cursor position
const float TRAIL_TAIL_FADE = 0.28;

// Fade curve.
//
// Higher: effect disappears more rapidly
// Lower: effect remains visible longer
const float FADE_POWER = 2.20;

// =============================================================================
// COLORS
// =============================================================================

// Tokyo Night-style gold.
const vec3 GOLD_BODY = vec3(0.88, 0.69, 0.41);

// Brighter trail center.
const vec3 GOLD_HOT = vec3(1.00, 0.84, 0.38);

// =============================================================================
// SHADER FUNCTIONS
// =============================================================================

float easeOutCubic(float x) {
    x = clamp(x, 0.0, 1.0);
    return 1.0 - pow(1.0 - x, 3.0);
}

float fadeOut(float x) {
    x = clamp(x, 0.0, 1.0);
    return pow(1.0 - x, FADE_POWER);
}

vec2 normalizeScreen(vec2 value, float isPosition) {
    return (
        value * 2.0
        - iResolution.xy * isPosition
    ) / iResolution.y;
}

float sdRectangle(
    vec2 point,
    vec2 center,
    vec2 halfSize
) {
    vec2 distanceVector =
        abs(point - center) - halfSize;

    return length(max(distanceVector, 0.0))
        + min(
            max(distanceVector.x, distanceVector.y),
            0.0
        );
}

float sdCapsule(
    vec2 point,
    vec2 startPoint,
    vec2 endPoint,
    float radius
) {
    vec2 relativePoint = point - startPoint;
    vec2 segment = endPoint - startPoint;

    float position = clamp(
        dot(relativePoint, segment)
            / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );

    return length(
        relativePoint - segment * position
    ) - radius;
}

float antialias(float distanceValue) {
    float pixelWidth =
        normalizeScreen(vec2(1.5), 0.0).x;

    return 1.0 - smoothstep(
        0.0,
        pixelWidth,
        distanceValue
    );
}

vec2 cursorCenter(vec4 cursor) {
    return vec2(
        cursor.x + cursor.z * 0.5,
        cursor.y - cursor.w * 0.5
    );
}

// =============================================================================
// MAIN
// =============================================================================

void mainImage(
    out vec4 fragColor,
    in vec2 fragCoord
) {
    fragColor = texture(
        iChannel0,
        fragCoord.xy / iResolution.xy
    );

    vec4 originalColor = fragColor;

    vec2 point =
        normalizeScreen(fragCoord, 1.0);

    vec4 currentCursor = vec4(
        normalizeScreen(
            iCurrentCursor.xy,
            1.0
        ),
        normalizeScreen(
            iCurrentCursor.zw,
            0.0
        )
    );

    vec4 previousCursor = vec4(
        normalizeScreen(
            iPreviousCursor.xy,
            1.0
        ),
        normalizeScreen(
            iPreviousCursor.zw,
            0.0
        )
    );

    vec2 head =
        cursorCenter(currentCursor);

    vec2 tail =
        cursorCenter(previousCursor);

    float cursorSize = max(
        currentCursor.z,
        currentCursor.w
    );

    float distanceMoved =
        distance(head, tail);

    float age = clamp(
        (iTime - iTimeCursorChange)
            / EFFECT_DURATION,
        0.0,
        1.0
    );

    bool movementActive =
        distanceMoved
            > MIN_MOVEMENT * cursorSize
        && age < 1.0;

    // No shader effect while stationary.
    if (!movementActive) {
        return;
    }

    float life =
        fadeOut(easeOutCubic(age));

    // Expand once, then contract.
    float pulse =
        sin(age * 3.14159265);

    float expansion =
        1.0
        + EXPANSION_AMOUNT * pulse;

    // Convert movement distance into a 0–1 value.
    float movementFactor = smoothstep(
        MIN_MOVEMENT * cursorSize,
        MAX_MOVEMENT_DISTANCE * cursorSize,
        distanceMoved
    );

    // =========================================================================
    // Circular glow around destination cursor
    // =========================================================================

    float headRadius =
        cursorSize
        * mix(
            HEAD_RADIUS_MIN,
            HEAD_RADIUS_MAX,
            movementFactor
        )
        * expansion;

    float headDistance =
        distance(point, head);

    float headGlow =
        1.0
        - smoothstep(
            headRadius * HEAD_GLOW_INNER_RATIO,
            headRadius,
            headDistance
        );

    headGlow *= life;

    // =========================================================================
    // Trail
    // =========================================================================

    float trailRadius =
        cursorSize
        * mix(
            TRAIL_RADIUS_MIN,
            TRAIL_RADIUS_MAX,
            movementFactor
        );

    float trailDistance = sdCapsule(
        point,
        tail,
        head,
        trailRadius
    );

    vec2 movement =
        head - tail;

    float along = clamp(
        dot(point - tail, movement)
            / max(
                dot(movement, movement),
                0.000001
            ),
        0.0,
        1.0
    );

    float tailFade = smoothstep(
        0.0,
        TRAIL_TAIL_FADE,
        along
    );

    float trailCore =
        antialias(trailDistance)
        * life
        * tailFade;

    float trailGlow =
        (
            1.0
            - smoothstep(
                0.0,
                trailRadius * TRAIL_GLOW_WIDTH,
                max(trailDistance, 0.0)
            )
        )
        * life
        * tailFade;

    // =========================================================================
    // Color composition
    // =========================================================================

    vec4 outputColor =
        originalColor;

    // Circular destination glow.
    outputColor.rgb = mix(
        outputColor.rgb,
        GOLD_BODY,
        headGlow * HEAD_GLOW_STRENGTH
    );

    // Soft outer trail.
    outputColor.rgb = mix(
        outputColor.rgb,
        GOLD_BODY,
        trailGlow * TRAIL_GLOW_STRENGTH
    );

    // Brighter trail center.
    outputColor.rgb = mix(
        outputColor.rgb,
        GOLD_HOT,
        trailCore * TRAIL_CORE_STRENGTH
    );

    // Preserve the actual cursor block.
    float cursorDistance = sdRectangle(
        point,
        head,
        currentCursor.zw * 0.5
    );

    fragColor = mix(
        outputColor,
        originalColor,
        step(cursorDistance, 0.0)
    );

    // Preserve Ghostty's original transparency.
    fragColor.a = originalColor.a;
}
