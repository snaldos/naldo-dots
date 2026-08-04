// Cozy vertical-rain shader for Ghostty
//
// Features:
//   - nearly vertical rainfall;
//   - short, thin, softly tapered drops;
//   - multiple depth layers;
//   - subtle horizontal drift;
//   - restrained glow and refraction;
//   - aspect-correct rendering on ultrawide terminals.
//
// Uses:
//   iChannel0
//   iResolution
//   iTime
//   mainImage

// =============================================================================
// USER CONTROLS
// =============================================================================

// Number of rain depth layers.
// Lower this first if performance is poor.
#define LAYERS 20

// Probability that a potential drop is visible.
//
//   0.08 = sparse drizzle
//   0.14 = calm rain
//   0.20 = steady rain
//   0.30 = heavy rain
#define RAIN_AMOUNT 0.30

// Overall rain brightness.
#define RAIN_OPACITY 0.38

// Maximum accumulated brightness.
#define MAX_RAIN_BRIGHTNESS 0.62

// Overall falling speed.
//
//   0.20 = slow
//   0.35 = calm
//   0.55 = steady
#define FALL_SPEED 0.70

// Foreground and background streak lengths in screen pixels.
#define NEAR_DROP_LENGTH 24.0
#define FAR_DROP_LENGTH 6.0

// Foreground and background half-widths in screen pixels.
#define NEAR_DROP_WIDTH 0.72
#define FAR_DROP_WIDTH 0.34

// Random variation in drop length.
#define LENGTH_VARIATION 0.45

// Random variation in drop width.
#define WIDTH_VARIATION 0.28

// Small overall rain angle.
//
// Keep this near zero for vertical cozy rain.
//
//   0.00 = perfectly vertical
//   0.02 = subtle natural lean
//   0.08 = visibly windy
#define RAIN_SLANT 0.012

// Random variation around RAIN_SLANT.
#define SLANT_VARIATION 0.012

// Very small horizontal drift.
#define DRIFT_STRENGTH 0.010

// Slowly changing horizontal movement.
#define GUST_STRENGTH 0.006
#define GUST_SPEED 0.20

// Soft halo around each drop.
//
// Keep this low to avoid a meteor-like appearance.
#define RAIN_GLOW 0.12

// Terminal-image displacement behind foreground drops.
#define REFRACTION_STRENGTH 0.10

// Distant-layer brightness.
#define DISTANCE_BRIGHTNESS 0.42

// Rain tint.
#define RAIN_COLOR vec3(0.70, 0.80, 0.91)

// Protect bright terminal text.
#define TEXT_PROTECTION 0.50

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
// DROP SHAPE
// =============================================================================

// Returns:
//   x = drop core
//   y = soft glow
//   z = lower part used for subtle refraction
vec3 cozyRainDrop(
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

    // 0 at the lower end and 1 at the upper trailing end.
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

    // Slight taper toward the upper trailing end.
    float localWidth =
        halfWidth
        * mix(
            1.0,
            0.48,
            trailPosition
        );

    float widthMask =
        1.0
        - smoothstep(
            localWidth,
            localWidth + aa,
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

    // Gentle fade toward the top.
    float trailFade =
        mix(
            1.0,
            0.30,
            smoothstep(
                0.10,
                1.0,
                trailPosition
            )
        );

    float core =
        widthMask
        * lengthMask
        * trailFade;

    // Narrow glow rather than a large cinematic halo.
    float glowWidth =
        localWidth
        + halfWidth * 1.35;

    float glow =
        (
            1.0
                       - smoothstep(
                glowWidth,
                glowWidth + aa * 1.5,
                across
            )
        )
        * lengthMask
        * mix(
            0.55,
            0.10,
            trailPosition
        );

    // Restrict refraction to the lower half of the streak.
    float lowerDrop =
        core
        * (
            1.0
            - smoothstep(
                0.38,
                0.82,
                trailPosition
            )
        );

    return vec3(
        core,
        glow,
        lowerDrop
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

    // Height-normalized coordinates preserve physical shape on ultrawide
    // terminals.
    vec2 world =
        (
            fragCoord
            - 0.5 * iResolution.xy
        )
        / max(
            iResolution.y,
            1.0
        );

    float coreAccumulation =
        0.0;

    float glowAccumulation =
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

        // Distant layers use a denser coordinate grid.
        float layerScale =
            mix(
                2.8,
                9.5,
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

        // Foreground rain moves faster.
        float layerSpeed =
            FALL_SPEED
            * mix(
                1.18,
                0.48,
                depth
            )
            * mix(
                0.90,
                1.10,
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
                + world.y * 1.5
            )
            * GUST_STRENGTH;

        // Mostly vertical movement.
        q.y +=
            layerSpeed
            * iTime
            * layerScale;

        // Very small horizontal movement prevents the pattern from looking
        // mechanically fixed while retaining a vertical aesthetic.
        q.x -=
            DRIFT_STRENGTH
            * layerSpeed
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

        // Compensate for the larger number of distant cells.
        float layerAmount =
            RAIN_AMOUNT
            * mix(
                1.0,
                0.20,
                depth
            );

        float keepDrop =
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

        vec2 dropOffset =
            vec2(
                (
                    randomOffset.x
                    - 0.5
                )
                * 0.78,
                (
                    randomOffset.y
                    - 0.5
                )
                * 0.58
            );

        vec2 point =
            localPosition
            - dropOffset;

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
                - 0.55 * LENGTH_VARIATION,
                1.0
                + 0.70 * LENGTH_VARIATION,
                lengthRandom
            );

        float widthMultiplier =
            mix(
                1.0
                - 0.45 * WIDTH_VARIATION,
                1.0
                + 0.55 * WIDTH_VARIATION,
                widthRandom
            );

        float dropLengthPixels =
            mix(
                NEAR_DROP_LENGTH,
                FAR_DROP_LENGTH,
                depth
            )
            * lengthMultiplier;

        float dropWidthPixels =
            mix(
                NEAR_DROP_WIDTH,
                FAR_DROP_WIDTH,
                depth
            )
            * widthMultiplier;

        float halfLength =
            0.5
            * dropLengthPixels
            * pixelWidth;

        float halfWidth =
            dropWidthPixels
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

        float dropSlant =
            RAIN_SLANT
            + slantRandom
            * SLANT_VARIATION;

        float antialiasWidth =
            pixelWidth
            * mix(
                0.72,
                1.10,
                depth
            );

        vec3 drop =
            cozyRainDrop(
                point,
                halfLength,
                halfWidth,
                dropSlant,
                antialiasWidth
            );

        float brightnessRandom =
            mix(
                0.52,
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

        float distanceBrightness =
            mix(
                1.0,
                DISTANCE_BRIGHTNESS,
                depth
            );

        float brightness =
            brightnessRandom
            * distanceBrightness
            * keepDrop;

        coreAccumulation +=
            drop.x
            * brightness;

        glowAccumulation +=
            drop.y
            * brightness;

        vec2 axis =
            normalize(
                vec2(
                    -dropSlant,
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
            * drop.z
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

    float rainBrightness =
        coreAccumulation
        + glowAccumulation
        * RAIN_GLOW;

    rainBrightness =
        min(
            rainBrightness,
            MAX_RAIN_BRIGHTNESS
        );

    vec3 blendedColor =
        terminalColor.rgb
        + RAIN_COLOR
        * rainBrightness
        * RAIN_OPACITY
        * protectionMask;

    fragColor =
        vec4(
            blendedColor,
            terminalColor.a
        );
}
