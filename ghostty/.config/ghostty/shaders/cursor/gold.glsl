// Gold cursor with:
// - permanent faint static glow
// - larger movement glow and trail
// - damped expanding/contracting movement pulse
// - preserved Ghostty transparency
// - bounded shader work around the cursor and trail
//
// Recommended Ghostty settings:
//
// cursor-color = e0af68
// cursor-text = 1a1b26
// custom-shader-animation = true

const vec3 GOLD       = vec3(0.878, 0.686, 0.408); // #e0af68
const vec3 GOLD_HOT   = vec3(1.000, 0.840, 0.380);
const vec3 GOLD_LIGHT = vec3(1.000, 0.950, 0.720);

const float PI = 3.14159265359;

// Movement animation lifetime.
const float DURATION = 0.16;

// Number of expand/contract cycles during one movement.
const float PULSE_CYCLES = 2.0;

// Amount by which the movement glow changes size.
const float PULSE_SIZE = 0.24;

// Ignore ordinary one-character typing movement.
const float MIN_DISTANCE = 1.10;

// Faint glow while stationary.
const float STATIC_STRENGTH = 0.14;

// Additional glow during movement.
const float MOVEMENT_STRENGTH = 0.10;

float sdBox(vec2 point, vec2 halfSize) {
    vec2 distanceVector = abs(point) - halfSize;

    return length(max(distanceVector, vec2(0.0)))
        + min(max(distanceVector.x, distanceVector.y), 0.0);
}

float sdSegment(
    vec2 point,
    vec2 startPoint,
    vec2 endPoint
) {
    vec2 segment = endPoint - startPoint;
    vec2 relativePoint = point - startPoint;

    float denominator = max(
        dot(segment, segment),
        0.000001
    );

    float position = clamp(
        dot(relativePoint, segment) / denominator,
        0.0,
        1.0
    );

    return length(
        relativePoint - segment * position
    );
}

vec2 cursorCenter(vec4 cursor) {
    return cursor.xy
        + vec2(
            cursor.z * 0.5,
            -cursor.w * 0.5
        );
}

void mainImage(
    out vec4 fragColor,
    in vec2 fragCoord
) {
    vec2 uv = fragCoord / iResolution.xy;

    vec4 base = texture(iChannel0, uv);
    fragColor = base;

    if (
        iFocus < 0.5
        || iCursorVisible.x < 0.5
    ) {
        return;
    }

    vec2 currentCenter =
        cursorCenter(iCurrentCursor);

    vec2 previousCenter =
        cursorCenter(iPreviousCursor);

    vec2 cursorSize = max(
        iCurrentCursor.zw,
        vec2(1.0)
    );

    float cursorScale = max(
        min(cursorSize.x, cursorSize.y),
        1.0
    );

    float movementDistance = length(
        currentCenter - previousCenter
    );

    float age = max(
        iTime - iTimeCursorChange,
        0.0
    );

    bool moving =
        movementDistance > MIN_DISTANCE * cursorScale
        && age < DURATION;

    // -------------------------------------------------------------------------
    // Cheap bounds checks
    // -------------------------------------------------------------------------

    float staticRadius = max(
        cursorScale * 1.5,
        11.0
    );

    vec2 staticHalfBounds =
        cursorSize * 0.5
        + vec2(staticRadius);

    vec2 staticOffset =
        abs(fragCoord - currentCenter);

    bool insideStaticBounds =
        staticOffset.x <= staticHalfBounds.x
        && staticOffset.y <= staticHalfBounds.y;

    // Large enough to contain the movement glow at maximum expansion.
    float movementRadius = max(
        cursorScale * 4.2,
        30.0
    );

    vec2 movementMinimum =
        min(previousCenter, currentCenter)
        - vec2(movementRadius);

    vec2 movementMaximum =
        max(previousCenter, currentCenter)
        + vec2(movementRadius);

    bool insideMovementBounds =
        moving
        && fragCoord.x >= movementMinimum.x
        && fragCoord.y >= movementMinimum.y
        && fragCoord.x <= movementMaximum.x
        && fragCoord.y <= movementMaximum.y;

    if (
        !insideStaticBounds
        && !insideMovementBounds
    ) {
        return;
    }

    float cursorDistance = sdBox(
        fragCoord - currentCenter,
        cursorSize * 0.5
    );

    vec3 result = base.rgb;

    // -------------------------------------------------------------------------
    // Permanent faint cursor glow
    // -------------------------------------------------------------------------

    if (insideStaticBounds) {
        float staticGlow =
            1.0
            - smoothstep(
                0.0,
                staticRadius,
                max(cursorDistance, 0.0)
            );

        staticGlow *= staticGlow;

        result = mix(
            result,
            GOLD * base.a,
            staticGlow * STATIC_STRENGTH
        );
    }

    // -------------------------------------------------------------------------
    // Pulsing movement glow and trail
    // -------------------------------------------------------------------------

    if (insideMovementBounds) {
        float progress = clamp(
            age / DURATION,
            0.0,
            1.0
        );

        float life =
            1.0
            - smoothstep(
                0.0,
                1.0,
                progress
            );

        life *= life;

        // Begins at the normal size, expands and contracts, then settles.
        // The oscillation becomes weaker as the effect fades.
        float oscillation = sin(
            progress
            * 2.0
            * PI
            * PULSE_CYCLES
        );

        float dampedOscillation =
            oscillation
            * (1.0 - progress);

        float pulseScale =
            1.0
            + PULSE_SIZE
            * dampedOscillation;

        float pulseBrightness =
            1.0
            + 0.16
            * dampedOscillation;

        float headGlowRadius =
            max(
                cursorScale * 2.8,
                19.0
            )
            * pulseScale;

        float headGlow =
            1.0
            - smoothstep(
                0.0,
                headGlowRadius,
                max(cursorDistance, 0.0)
            );

        float trailDistance = sdSegment(
            fragCoord,
            previousCenter,
            currentCenter
        );

        float trailWidth =
            max(
                cursorScale * 0.46,
                2.0
            )
            * (
                1.0
                + 0.10 * dampedOscillation
            );

        float trailCore =
            1.0
            - smoothstep(
                trailWidth,
                trailWidth * 1.8,
                trailDistance
            );

        float trailGlow =
            1.0
            - smoothstep(
                trailWidth,
                trailWidth * 4.4 * pulseScale,
                trailDistance
            );

        float outerStrength =
            (
                headGlow * 0.78
                + trailGlow * 0.52
            )
            * life
            * pulseBrightness;

        float coreStrength =
            trailCore
            * life;

        // Large expanding and contracting outer glow.
        result = mix(
            result,
            GOLD * base.a,
            clamp(
                outerStrength * MOVEMENT_STRENGTH,
                0.0,
                0.78
            )
        );

        // Hot central trail.
        result = mix(
            result,
            GOLD_HOT * base.a,
            clamp(
                coreStrength * 0.78,
                0.0,
                0.84
            )
        );

        // Bright destination flash that follows the pulse.
        float highlight =
            headGlow
            * life
            * life
            * (
                0.24
                + 0.08 * max(dampedOscillation, 0.0)
            );

        result +=
            GOLD_LIGHT
            * base.a
            * highlight;
    }

    // Preserve the actual cursor block.
    float insideCursor =
        1.0
        - step(
            0.0,
            cursorDistance
        );

    fragColor.rgb = mix(
        result,
        base.rgb,
        insideCursor
    );

    fragColor.a = base.a;
}
