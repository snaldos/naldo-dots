// Aspect-correct crystalline snowfall shader for Ghostty
//
// Snow geometry uses height-normalized coordinates. This ensures:
//   - flakes retain their shape at every aspect ratio;
//   - flake size remains consistent;
//   - wider terminals display more snow instead of stretched snow;
//   - snow density per screen area remains approximately constant.
//
// Uses only:
//   iChannel0
//   iResolution
//   iTime
//   mainImage

// =============================================================================
// USER CONTROLS
// =============================================================================

// Number of depth layers.
// Typical range: 12 to 80
#define LAYERS 40

// Probability that a potential flake is visible.
//
//   0.10 = sparse
//   0.25 = light snow
//   0.45 = normal snow
//   0.70 = heavy snow
#define SNOW_AMOUNT 0.10

// Overall snow contribution.
//
//   0.20 = subtle
//   0.50 = visible
//   0.80 = bright
#define SNOW_OPACITY 0.52

// Maximum accumulated snow brightness.
#define MAX_SNOW_BRIGHTNESS 0.82

// Base radius of each flake.
//
//   0.0025 = tiny
//   0.0040 = small
//   0.0070 = medium
//   0.0120 = large
#define FLAKE_SIZE 0.0070

// Random flake-size variation.
#define SIZE_VARIATION 0.50

// Width of the six primary arms relative to the flake radius.
//
//   0.04 = thin
//   0.07 = balanced
//   0.12 = thick
#define FLAKE_ARM_WIDTH 0.070

// Width of the smaller crystalline branches.
#define FLAKE_BRANCH_WIDTH 0.045

// Slow individual flake rotation.
//
//   0.00 = no rotation
//   0.05 = subtle
//   0.15 = clearly visible
#define FLAKE_SPIN_SPEED 0.08

// Downward movement speed.
#define FALL_SPEED 0.42

// Horizontal wind variation between layers.
#define WIND_STRENGTH 0.20

// Oscillating horizontal displacement.
#define GUST_STRENGTH 0.06

// Gust oscillation speed.
#define GUST_SPEED 0.22

// Separation between depth layers.
#define DEPTH_SPACING 0.45

// Depth-of-field strength.
//
// Lower values preserve more crystalline detail.
// Higher values make distant flakes softer.
#define DOF_STRENGTH 0.35

// Focus-plane animation speed.
// Use 0.0 for a stationary focus plane.
#define DOF_ANIMATION_SPEED 0.10

// Approximate layer that remains most focused.
//
// Keeping this near the front allows the larger flakes to retain their arms.
#define FOCUS_LAYER 1.0

// Brightness reduction for distant layers.
#define DISTANCE_FADE 0.025

// Snow tint.
#define SNOW_COLOR vec3(0.93, 0.96, 1.00)

// Protect bright terminal content from excessive snow.
//
//   0.00 = no protection
//   0.50 = moderate protection
//   1.00 = strong protection
#define TEXT_PROTECTION 0.38

// =============================================================================
// INTERNAL CONSTANTS
// =============================================================================

#define PI 3.14159265359
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
        hash13(
            value
            + vec3(17.17, 43.71, 11.13)
        ),
        hash13(
            value
            + vec3(83.91, 19.19, 61.73)
        )
    );
}

// =============================================================================
// CRYSTALLINE FLAKE SHAPE
// =============================================================================

float snowflakeShape(
    vec2 point,
    float antialiasWidth
) {
    float radialDistance =
        length(point);

    float angle =
        atan(
            point.y,
            point.x
        );

    // Fold the plane into one 60-degree sector. Anything drawn inside this
    // sector is repeated around all six sides of the snowflake.
    float foldedAngle =
        mod(
            angle + PI / 6.0,
            PI / 3.0
        )
        - PI / 6.0;

    float alongArm =
        radialDistance
        * cos(foldedAngle);

    float acrossArm =
        abs(
            radialDistance
            * sin(foldedAngle)
        );

    float aa =
        max(
            antialiasWidth,
            0.002
        );

    // -------------------------------------------------------------------------
    // Primary six arms
    // -------------------------------------------------------------------------

    // Make the arms slightly narrower toward their tips.
    float primaryArmWidth =
        FLAKE_ARM_WIDTH
        * mix(
            1.0,
            0.62,
            clamp(
                alongArm,
                0.0,
                1.0
            )
        );

    float primaryArm =
        1.0
        - smoothstep(
            primaryArmWidth,
            primaryArmWidth + aa,
            acrossArm
        );

    primaryArm *=
        1.0
        - smoothstep(
            0.90,
            1.02,
            alongArm
        );

    // -------------------------------------------------------------------------
    // Inner diagonal branches
    // -------------------------------------------------------------------------

    float innerSlope =
        0.72;

    float innerBranchDistance =
        abs(
            acrossArm
            - (
                alongArm - 0.32
            )
            * innerSlope
        )
        / sqrt(
            1.0
            + innerSlope
            * innerSlope
        );

    float innerBranches =
        1.0
        - smoothstep(
            FLAKE_BRANCH_WIDTH,
            FLAKE_BRANCH_WIDTH + aa,
            innerBranchDistance
        );

    innerBranches *=
        smoothstep(
            0.29,
            0.37,
            alongArm
        );

    innerBranches *=
        1.0
        - smoothstep(
            0.66,
            0.75,
            alongArm
        );

    // -------------------------------------------------------------------------
    // Outer diagonal branches
    // -------------------------------------------------------------------------

    float outerSlope =
        0.58;

    float outerBranchWidth =
        FLAKE_BRANCH_WIDTH
        * 0.88;

    float outerBranchDistance =
        abs(
            acrossArm
            - (
                alongArm - 0.57
            )
            * outerSlope
        )
        / sqrt(
            1.0
            + outerSlope
            * outerSlope
        );

    float outerBranches =
        1.0
        - smoothstep(
            outerBranchWidth,
            outerBranchWidth + aa,
            outerBranchDistance
        );

    outerBranches *=
        smoothstep(
            0.54,
            0.61,
            alongArm
        );

    outerBranches *=
        1.0
        - smoothstep(
            0.84,
            0.92,
            alongArm
        );

    // -------------------------------------------------------------------------
    // Central crystal
    // -------------------------------------------------------------------------

    float center =
        1.0
        - smoothstep(
            0.11,
            0.11 + aa,
            radialDistance
        );

    // Prevent the branches from extending beyond the flake radius.
    float outerFade =
        1.0
        - smoothstep(
            0.96,
            1.04,
            radialDistance
        );

    float shape =
        max(
            center,
            max(
                primaryArm,
                max(
                    innerBranches,
                    outerBranches
                )
            )
        );

    return shape * outerFade;
}

// =============================================================================
// MAIN
// =============================================================================

void mainImage(
    out vec4 fragColor,
    in vec2 fragCoord
) {
    // Regular UV coordinates are used only for sampling the terminal texture.
    vec2 uv =
        fragCoord
        / iResolution.xy;

    // Height-normalized world coordinates.
    //
    // One coordinate unit has the same pixel size horizontally and vertically.
    // A wider terminal therefore reveals more world space instead of stretching
    // the existing snowfall.
    vec2 world =
        (
            fragCoord
            - 0.5 * iResolution.xy
        )
        / max(
            iResolution.y,
            1.0
        );

    float snowAccumulation =
        0.0;

    float focusMotion =
        5.0
        * sin(
            iTime
            * DOF_ANIMATION_SPEED
        )
        * DOF_STRENGTH;

    for (int i = 0; i < LAYERS; i++) {
        float fi =
            float(i);

        // Higher-index layers represent more distant snow.
        float depthScale =
            1.0
            + fi
            * DEPTH_SPACING;

        vec2 q =
            world
            * depthScale;

        // Give each depth layer a different horizontal direction.
        float layerRandom =
            hash13(
                vec3(
                    fi,
                    9.13,
                    17.71
                )
            );

        float layerWind =
            WIND_STRENGTH
            * (
                2.0
                * layerRandom
                - 1.0
            );

        float gustPhase =
            TAU
            * hash13(
                vec3(
                    fi,
                    31.73,
                    4.21
                )
            );

        float gust =
            sin(
                iTime
                * GUST_SPEED
                + gustPhase
                + world.y
                * 3.0
            )
            * GUST_STRENGTH;

        // Horizontal shear and slow wind movement.
        q.x +=
            q.y
            * layerWind
            + iTime
            * layerWind
            * 0.08
            + gust;

        // Adding time to the sampled coordinate makes the visible particles
        // move downward in screen space.
        q.y +=
            FALL_SPEED
            * iTime
            / (
                1.0
                + fi
                * DEPTH_SPACING
                * 0.03
            );

        vec2 cell =
            floor(q);

        vec2 localPosition =
            fract(q)
            - 0.5;

        vec3 seed =
            vec3(
                cell,
                fi + 17.0
            );

        // Independent density decision for every cell and depth layer.
        float keepFlake =
            step(
                1.0
                - clamp(
                    SNOW_AMOUNT,
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

        // Randomly position each flake inside its cell.
        vec2 flakeOffset =
            (
                hash23(seed)
                - 0.5
            )
            * 0.76;

        vec2 delta =
            localPosition
            - flakeOffset;

        // ---------------------------------------------------------------------
        // Flake size
        // ---------------------------------------------------------------------

        float sizeRandom =
            hash13(
                seed
                + vec3(
                    47.1,
                    5.7,
                    91.3
                )
            );

        float randomSize =
            mix(
                1.0
                - 0.60
                * SIZE_VARIATION,
                1.0
                + 0.85
                * SIZE_VARIATION,
                sizeRandom
            );

        float radius =
            FLAKE_SIZE
            * randomSize;

        // One screen pixel expressed in this layer's coordinate system.
        float pixelWidth =
            depthScale
            / max(
                iResolution.y,
                1.0
            );

        // ---------------------------------------------------------------------
        // Depth of field
        // ---------------------------------------------------------------------

        float focusDistance =
            abs(
                fi
                - FOCUS_LAYER
                - focusMotion
            );

        float defocus =
            min(
                focusDistance
                * DOF_STRENGTH,
                10.0
            );

        float softness =
            pixelWidth
            * (
                1.0
                + 0.32
                * defocus
            );

        // ---------------------------------------------------------------------
        // Individual flake rotation
        // ---------------------------------------------------------------------

        float rotationRandom =
            hash13(
                seed
                + vec3(
                    67.3,
                    11.9,
                    41.7
                )
            );

        float rotationDirection =
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

        float rotationAngle =
            TAU
            * rotationRandom
            + iTime
            * FLAKE_SPIN_SPEED
            * rotationDirection
            / (
                1.0
                + fi
                * 0.08
            );

        float rotationCos =
            cos(rotationAngle);

        float rotationSin =
            sin(rotationAngle);

        vec2 rotatedDelta =
            vec2(
                rotationCos
                    * delta.x
                    - rotationSin
                    * delta.y,
                rotationSin
                    * delta.x
                    + rotationCos
                    * delta.y
            );

        // Normalize the flake so its outer arm has a radius of approximately 1.
        vec2 flakePoint =
            rotatedDelta
            / max(
                radius,
                0.00001
            );

        // Express pixel-aware softness relative to the flake radius.
        //
        // The upper limit preserves the crystalline silhouette even when the
        // depth-of-field effect becomes strong.
        float normalizedSoftness =
            clamp(
                softness
                / max(
                    radius,
                    0.00001
                ),
                0.015,
                0.24
            );

        float flake =
            snowflakeShape(
                flakePoint,
                normalizedSoftness
            );

        // Blurred flakes cover more area, so reduce their peak intensity.
        float blurCompensation =
            radius
            / max(
                radius
                + softness
                * 0.75,
                0.00001
            );

        flake *=
            mix(
                1.0,
                blurCompensation,
                clamp(
                    defocus / 3.0,
                    0.0,
                    1.0
                )
            );

        // ---------------------------------------------------------------------
        // Brightness
        // ---------------------------------------------------------------------

        float randomBrightness =
            mix(
                0.45,
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
            1.0
            / (
                1.0
                + DISTANCE_FADE
                * fi
                * DEPTH_SPACING
            );

        snowAccumulation +=
            flake
            * randomBrightness
            * distanceBrightness
            * keepFlake;
    }

    // =========================================================================
    // TERMINAL COMPOSITING
    // =========================================================================

    vec4 terminalColor =
        texture(
            iChannel0,
            uv
        );

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

    snowAccumulation =
        min(
            snowAccumulation,
            MAX_SNOW_BRIGHTNESS
        );

    vec3 blendedColor =
        terminalColor.rgb
        + SNOW_COLOR
        * snowAccumulation
        * SNOW_OPACITY
        * protectionMask;

    fragColor =
        vec4(
            blendedColor,
            terminalColor.a
        );
}
