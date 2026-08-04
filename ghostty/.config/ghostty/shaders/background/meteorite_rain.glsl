// Meteorite-rain shader for Ghostty
//
// Features:
//   - long diagonal trails;
//   - bright rounded meteor heads;
//   - layered parallax and speed;
//   - cool trails with warmer impact heads;
//   - strong glow and subtle refraction;
//   - aspect-correct ultrawide rendering.
//
// Uses:
//   iChannel0
//   iResolution
//   iTime
//   mainImage

// =============================================================================
// USER CONTROLS
// =============================================================================

#define LAYERS 18

// Probability of a potential meteor appearing.
#define METEOR_AMOUNT 0.005

// Overall effect brightness.
#define METEOR_OPACITY 0.62

// Maximum accumulated brightness.
#define MAX_METEOR_BRIGHTNESS 0.92

// Overall falling speed.
#define FALL_SPEED 0.14

// Trail length in screen pixels.
#define NEAR_TRAIL_LENGTH 92.0
#define FAR_TRAIL_LENGTH 20.0

// Trail half-width in screen pixels.
#define NEAR_TRAIL_WIDTH 1.35
#define FAR_TRAIL_WIDTH 0.55

#define LENGTH_VARIATION 0.65
#define WIDTH_VARIATION 0.42

// Diagonal trajectory.
//
//   0.25 = slight angle
//   0.45 = balanced meteor rain
//   0.75 = dramatic diagonal motion
#define METEOR_SLANT 0.48

// Variation in individual meteor angles.
#define SLANT_VARIATION 0.10

// Slowly changing global gust.
#define GUST_STRENGTH 0.020
#define GUST_SPEED 0.32

// Glow around trails and heads.
#define TRAIL_GLOW 0.58
#define HEAD_GLOW 0.82

// Terminal-image displacement near meteor heads.
#define REFRACTION_STRENGTH 0.42

#define DISTANCE_BRIGHTNESS 0.40

// Cool trail color.
#define TRAIL_COLOR vec3(0.66, 0.80, 1.00)

// Warmer meteor-head color.
#define HEAD_COLOR vec3(1.00, 0.76, 0.46)

#define TEXT_PROTECTION 0.42

// =============================================================================
// INTERNAL CONSTANTS
// =============================================================================

#define TAU 6.28318530718

// =============================================================================
// RANDOM HELPERS
// =============================================================================

float hash13(vec3 value) {
    value = fract(value * 0.1031);
    value += dot(value, value.yzx + 33.33);

    return fract(
        (value.x + value.y) * value.z
    );
}

vec2 hash23(vec3 value) {
    return vec2(
        hash13(value + vec3(17.17, 43.71, 11.13)),
        hash13(value + vec3(83.91, 19.19, 61.73))
    );
}

// =============================================================================
// METEOR SHAPE
// =============================================================================

// Returns:
//   x = bright trail core
//   y = trail glow
//   z = meteor head
//   w = meteor-head glow
vec4 meteorShape(
    vec2 point,
    float halfLength,
    float halfWidth,
    float slant,
    float antialiasWidth
) {
    vec2 axis =
        normalize(
            vec2(
                -slant,
                1.0
            )
        );

    vec2 normal =
        vec2(
            axis.y,
            -axis.x
        );

    float along =
        dot(
            point,
            axis
        );

    float across =
        abs(
            dot(
                point,
                normal
            )
        );

    float aa =
        max(
            antialiasWidth,
            0.00001
        );

    // Lower endpoint is the leading meteor head.
    float trailPosition =
        clamp(
            (
                along
                + halfLength
            )
            / max(
                2.0 * halfLength,
                0.00001
            ),
            0.0,
            1.0
        );

    float taperedWidth =
        halfWidth
        * mix(
            1.25,
            0.10,
            trailPosition
        );

    float widthMask =
        1.0
        - smoothstep(
            taperedWidth,
            taperedWidth + aa,
            across
        );

    float lowerMask =
        smoothstep(
            -halfLength - aa,
            -halfLength + aa,
            along
        );

    float upperMask =
        1.0
        - smoothstep(
            halfLength - aa,
            halfLength + aa,
            along
        );

    float lengthMask =
        lowerMask
        * upperMask;

    float trailFade =
        pow(
            1.0 - trailPosition,
            1.75
        );

    float trailCore =
        widthMask
        * lengthMask
        * trailFade;

    float glowWidth =
        taperedWidth
        + halfWidth * 3.1
        + aa;

    float trailGlow =
        (
            1.0
            - smoothstep(
                glowWidth,
                glowWidth + aa * 2.0,
                across
            )
        )
        * lengthMask
        * pow(
            1.0 - trailPosition,
            1.30
        );

    vec2 headCenter =
        -axis
        * halfLength;

    float headRadius =
        halfWidth
        * 1.75;

    float headDistance =
        length(
            point
            - headCenter
        );

    float head =
        1.0
        - smoothstep(
            headRadius,
            headRadius + aa,
            headDistance
        );

    float headGlow =
        1.0
        - smoothstep(
            headRadius * 1.2,
            headRadius * 4.4 + aa,
            headDistance
        );

    return vec4(
        max(
            trailCore,
            head * 0.65
        ),
        trailGlow,
        head,
        headGlow
    );
}

// =============================================================================
// MAIN
// =============================================================================

void mainImage(
    out vec4 fragColor,
    in vec2 fragCoord
) {
    vec2 uv =
        fragCoord
        / iResolution.xy;

    vec2 world =
        (
            fragCoord
            - 0.5 * iResolution.xy
        )
        / max(
            iResolution.y,
            1.0
        );

    float trailAccumulation =
        0.0;

    float trailGlowAccumulation =
        0.0;

    float headAccumulation =
        0.0;

    float headGlowAccumulation =
        0.0;

    vec2 refractionAccumulation =
        vec2(0.0);

    for (int i = 0; i < LAYERS; i++) {
        float fi =
            float(i);

        float depth =
            (
                fi + 0.5
            )
            / float(LAYERS);

        float layerScale =
            mix(
                2.1,
                7.8,
                depth
            );

        vec2 q =
            world
            * layerScale;

        float layerRandom =
            hash13(
                vec3(
                    fi,
                    19.31,
                    47.73
                )
            );

        float layerSpeed =
            FALL_SPEED
            * mix(
                1.38,
                0.46,
                depth
            )
            * mix(
                0.86,
                1.16,
                layerRandom
            );

        float gustPhase =
            TAU
            * hash13(
                vec3(
                    fi,
                    7.71,
                    91.17
                )
            );

        float gust =
            sin(
                iTime * GUST_SPEED
                + gustPhase
                + world.y * 2.0
            )
            * GUST_STRENGTH;

        // Diagonal meteor movement.
        q.y +=
            layerSpeed
            * iTime
            * layerScale;

        q.x -=
            layerSpeed
            * METEOR_SLANT
            * iTime
            * layerScale;

        q.x +=
            gust
            * layerScale;

        vec2 cell =
            floor(q);

        vec2 localPosition =
            fract(q)
            - 0.5;

        vec3 seed =
            vec3(
                cell,
                fi + 31.0
            );

        float layerAmount =
            METEOR_AMOUNT
            * mix(
                1.0,
                0.18,
                depth
            );

        float keepMeteor =
            step(
                1.0
                - clamp(
                    layerAmount,
                    0.0,
                    1.0
                ),
                hash13(
                    seed
                    + vec3(
                        13.7,
                        71.3,
                        29.1
                    )
                )
            );

        vec2 randomOffset =
            hash23(
                seed
                + vec3(
                    5.3,
                    41.9,
                    17.1
                )
            );

        vec2 meteorOffset =
            vec2(
                (
                    randomOffset.x
                    - 0.5
                )
                * 0.66,
                (
                    randomOffset.y
                    - 0.5
                )
                * 0.38
            );

        vec2 point =
            localPosition
            - meteorOffset;

        float pixelWidth =
            layerScale
            / max(
                iResolution.y,
                1.0
            );

        float lengthRandom =
            hash13(
                seed
                + vec3(
                    47.1,
                    5.7,
                    91.3
                )
            );

        float widthRandom =
            hash13(
                seed
                + vec3(
                    67.3,
                    11.9,
                    41.7
                )
            );

        float lengthMultiplier =
            mix(
                1.0
                - 0.58 * LENGTH_VARIATION,
                1.0
                + 0.88 * LENGTH_VARIATION,
                lengthRandom
            );

        float widthMultiplier =
            mix(
                1.0
                - 0.45 * WIDTH_VARIATION,
                1.0
                + 0.70 * WIDTH_VARIATION,
                widthRandom
            );

        float trailLengthPixels =
            mix(
                NEAR_TRAIL_LENGTH,
                FAR_TRAIL_LENGTH,
                depth
            )
            * lengthMultiplier;

        float trailWidthPixels =
            mix(
                NEAR_TRAIL_WIDTH,
                FAR_TRAIL_WIDTH,
                depth
            )
            * widthMultiplier;

        float halfLength =
            0.5
            * trailLengthPixels
            * pixelWidth;

        float halfWidth =
            trailWidthPixels
            * pixelWidth;

        float slantRandom =
            2.0
            * hash13(
                seed
                + vec3(
                    23.1,
                    89.7,
                    3.9
                )
            )
            - 1.0;

        float meteorSlant =
            METEOR_SLANT
            + slantRandom
            * SLANT_VARIATION;

        float antialiasWidth =
            pixelWidth
            * mix(
                0.78,
                1.25,
                depth
            );

        vec4 meteor =
            meteorShape(
                point,
                halfLength,
                halfWidth,
                meteorSlant,
                antialiasWidth
            );

        float brightnessRandom =
            mix(
                0.48,
                1.0,
                hash13(
                    seed
                    + vec3(
                        7.3,
                        59.1,
                        23.7
                    )
                )
            );

        // Small flicker gives the head a burning appearance.
        float flickerPhase =
            TAU
            * hash13(
                seed
                + vec3(
                    101.3,
                    31.7,
                    9.1
                )
            );

        float flicker =
            mix(
                0.82,
                1.12,
                0.5
                + 0.5
                * sin(
                    iTime * 8.0
                    + flickerPhase
                )
            );

        float distanceBrightness =
            mix(
                1.0,
                DISTANCE_BRIGHTNESS,
                depth
            );

        float brightness =
            brightnessRandom
            * distanceBrightness
            * keepMeteor;

        trailAccumulation +=
            meteor.x
            * brightness;

        trailGlowAccumulation +=
            meteor.y
            * brightness;

        headAccumulation +=
            meteor.z
            * brightness
            * flicker;

        headGlowAccumulation +=
            meteor.w
            * brightness
            * flicker;

        vec2 axis =
            normalize(
                vec2(
                    -meteorSlant,
                    1.0
                )
            );

        vec2 normal =
            vec2(
                axis.y,
                -axis.x
            );

        float refractionDirection =
            2.0 * widthRandom - 1.0;

        refractionAccumulation +=
            normal
            * refractionDirection
            * meteor.z
            * brightness;
    }

    // =========================================================================
    // TERMINAL REFRACTION
    // =========================================================================

    refractionAccumulation =
        clamp(
            refractionAccumulation,
            vec2(-1.0),
            vec2(1.0)
        );

    vec2 refractedUv =
        clamp(
            uv
            + refractionAccumulation
            * REFRACTION_STRENGTH
            / max(
                iResolution.xy,
                vec2(1.0)
            ),
            vec2(0.0),
            vec2(1.0)
        );

    vec4 terminalColor =
        texture(
            iChannel0,
            refractedUv
        );

    // =========================================================================
    // TEXT PROTECTION
    // =========================================================================

    float terminalLuma =
        dot(
            terminalColor.rgb,
            vec3(
                0.299,
                0.587,
                0.114
            )
        );

    float protectionMask =
        mix(
            1.0,
            1.0
            - smoothstep(
                0.20,
                0.90,
                terminalLuma
            ),
            clamp(
                TEXT_PROTECTION,
                0.0,
                1.0
            )
        );

    // =========================================================================
    // FINAL COMPOSITING
    // =========================================================================

    float trailBrightness =
        trailAccumulation
        + trailGlowAccumulation
        * TRAIL_GLOW;

    float headBrightness =
        headAccumulation
        + headGlowAccumulation
        * HEAD_GLOW;

    float totalBrightness =
        min(
            trailBrightness
            + headBrightness,
            MAX_METEOR_BRIGHTNESS
        );

    vec3 effectColor =
        TRAIL_COLOR
        * trailBrightness
        + HEAD_COLOR
        * headBrightness;

    effectColor *=
        MAX_METEOR_BRIGHTNESS
        / max(
            totalBrightness,
            MAX_METEOR_BRIGHTNESS
        );

    vec3 blendedColor =
        terminalColor.rgb
        + effectColor
        * METEOR_OPACITY
        * protectionMask;

    fragColor =
        vec4(
            blendedColor,
            terminalColor.a
        );
}
