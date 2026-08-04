// BUILD: wallpaper geometry, exact terminal foreground, configurable cursor
// Geometric Cosmos — nine mathematical worlds with a shape-shifting cursor
//
// Background families (type IDs):
//   0 tesseract, 1 octahedral gem, 2 orbital world, 3 stellated crystal,
//   4 torus knot, 5 Mobius ribbon, 6 Sierpinski tetrahedra,
//   7 icosahedral cage, 8 Lorenz attractor.
//
// One instance of every family drifts through the default scene. The movement-
// reactive cursor changes family over time using a stable deterministic random
// sequence and crossfades instead of popping. Normal, wallpaper, and background-
// only builds differ only through the two mode switches immediately below.

#ifndef GHOSTTY_GPU_PROFILE
#define GHOSTTY_GPU_PROFILE 1
#endif
#define GC_GPU_ECO 0
#define GC_GPU_BALANCED 1
#define GC_GPU_QUALITY 2
#define GC_GPU_ULTRA 3

#ifndef GC_WALLPAPER_MODE
#define GC_WALLPAPER_MODE 1              // 1: exact terminal foreground over scene
#endif
#ifndef GC_ENABLE_CURSOR_STAGE
#define GC_ENABLE_CURSOR_STAGE 1         // 0: background-only build
#endif
#ifndef GC_ENABLE_BACKGROUND_STAGE
#define GC_ENABLE_BACKGROUND_STAGE 1     // 0: standalone cursor build
#endif

#if GHOSTTY_GPU_PROFILE == GC_GPU_ECO
#define GC_CURVE_SEGMENTS 20
#define GC_MOBIUS_SEGMENTS 16
#define GC_LORENZ_SEGMENTS 18
#define GC_FRACTAL_DEPTH 1
#define GC_FRACTAL_CHILD_COUNT 4
#define GCC_SPARK_COUNT 0
#define GCC_ECHO_COUNT 0
#elif GHOSTTY_GPU_PROFILE == GC_GPU_BALANCED
#define GC_CURVE_SEGMENTS 28
#define GC_MOBIUS_SEGMENTS 22
#define GC_LORENZ_SEGMENTS 24
#define GC_FRACTAL_DEPTH 2
#define GC_FRACTAL_CHILD_COUNT 16
#define GCC_SPARK_COUNT 2
#define GCC_ECHO_COUNT 0
#elif GHOSTTY_GPU_PROFILE == GC_GPU_QUALITY
#define GC_CURVE_SEGMENTS 38
#define GC_MOBIUS_SEGMENTS 30
#define GC_LORENZ_SEGMENTS 32
#define GC_FRACTAL_DEPTH 2
#define GC_FRACTAL_CHILD_COUNT 16
#define GCC_SPARK_COUNT 4
#define GCC_ECHO_COUNT 1
#else
#define GC_CURVE_SEGMENTS 48
#define GC_MOBIUS_SEGMENTS 38
#define GC_LORENZ_SEGMENTS 42
#define GC_FRACTAL_DEPTH 2
#define GC_FRACTAL_CHILD_COUNT 16
#define GCC_SPARK_COUNT 7
#define GCC_ECHO_COUNT 1
#endif

// =============================================================================
// BACKGROUND QUANTITY, SCALE, PATH, AND COMPOSITION
// =============================================================================

#define GC_GEOMETRY_TYPE_COUNT 9
#define GC_OBJECT_LIMIT 18               // total configured instances must be <= 18

// FAMILY SELECTION: set ENABLE to 0 or INSTANCES to 0 to remove a family.
// Cursor scheduling and style-1 constellations automatically skip removed types.
// Example: three enabled families with counts 2, 1, and 3 produce six objects.
#define GC_ENABLE_TESSERACT 1
#define GC_ENABLE_GEM 1
#define GC_ENABLE_ORBITAL 1
#define GC_ENABLE_CRYSTAL 1
#define GC_ENABLE_TORUS_KNOT 1
#define GC_ENABLE_MOBIUS 1
#define GC_ENABLE_FRACTAL_TETRA 1
#define GC_ENABLE_ICOSAHEDRON 1
#define GC_ENABLE_LORENZ 1

#define GC_TESSERACT_INSTANCES 1
#define GC_GEM_INSTANCES 1
#define GC_ORBITAL_INSTANCES 1
#define GC_CRYSTAL_INSTANCES 1
#define GC_TORUS_KNOT_INSTANCES 1
#define GC_MOBIUS_INSTANCES 1
#define GC_FRACTAL_TETRA_INSTANCES 1
#define GC_ICOSAHEDRON_INSTANCES 1
#define GC_LORENZ_INSTANCES 1

// These expressions are compile-time constants, preserving the original loop cost.
#define GC_TESSERACT_ACTIVE_INSTANCES ((GC_ENABLE_TESSERACT != 0 && GC_TESSERACT_INSTANCES > 0) ? GC_TESSERACT_INSTANCES : 0)
#define GC_GEM_ACTIVE_INSTANCES ((GC_ENABLE_GEM != 0 && GC_GEM_INSTANCES > 0) ? GC_GEM_INSTANCES : 0)
#define GC_ORBITAL_ACTIVE_INSTANCES ((GC_ENABLE_ORBITAL != 0 && GC_ORBITAL_INSTANCES > 0) ? GC_ORBITAL_INSTANCES : 0)
#define GC_CRYSTAL_ACTIVE_INSTANCES ((GC_ENABLE_CRYSTAL != 0 && GC_CRYSTAL_INSTANCES > 0) ? GC_CRYSTAL_INSTANCES : 0)
#define GC_TORUS_KNOT_ACTIVE_INSTANCES ((GC_ENABLE_TORUS_KNOT != 0 && GC_TORUS_KNOT_INSTANCES > 0) ? GC_TORUS_KNOT_INSTANCES : 0)
#define GC_MOBIUS_ACTIVE_INSTANCES ((GC_ENABLE_MOBIUS != 0 && GC_MOBIUS_INSTANCES > 0) ? GC_MOBIUS_INSTANCES : 0)
#define GC_FRACTAL_TETRA_ACTIVE_INSTANCES ((GC_ENABLE_FRACTAL_TETRA != 0 && GC_FRACTAL_TETRA_INSTANCES > 0) ? GC_FRACTAL_TETRA_INSTANCES : 0)
#define GC_ICOSAHEDRON_ACTIVE_INSTANCES ((GC_ENABLE_ICOSAHEDRON != 0 && GC_ICOSAHEDRON_INSTANCES > 0) ? GC_ICOSAHEDRON_INSTANCES : 0)
#define GC_LORENZ_ACTIVE_INSTANCES ((GC_ENABLE_LORENZ != 0 && GC_LORENZ_INSTANCES > 0) ? GC_LORENZ_INSTANCES : 0)
#define GC_CONFIGURED_OBJECT_COUNT (GC_TESSERACT_ACTIVE_INSTANCES + GC_GEM_ACTIVE_INSTANCES + GC_ORBITAL_ACTIVE_INSTANCES + GC_CRYSTAL_ACTIVE_INSTANCES + GC_TORUS_KNOT_ACTIVE_INSTANCES + GC_MOBIUS_ACTIVE_INSTANCES + GC_FRACTAL_TETRA_ACTIVE_INSTANCES + GC_ICOSAHEDRON_ACTIVE_INSTANCES + GC_LORENZ_ACTIVE_INSTANCES)

#if GC_ENABLE_TESSERACT != 0 && GC_TESSERACT_INSTANCES == 1 \
    && GC_ENABLE_GEM != 0 && GC_GEM_INSTANCES == 1 \
    && GC_ENABLE_ORBITAL != 0 && GC_ORBITAL_INSTANCES == 1 \
    && GC_ENABLE_CRYSTAL != 0 && GC_CRYSTAL_INSTANCES == 1 \
    && GC_ENABLE_TORUS_KNOT != 0 && GC_TORUS_KNOT_INSTANCES == 1 \
    && GC_ENABLE_MOBIUS != 0 && GC_MOBIUS_INSTANCES == 1 \
    && GC_ENABLE_FRACTAL_TETRA != 0 && GC_FRACTAL_TETRA_INSTANCES == 1 \
    && GC_ENABLE_ICOSAHEDRON != 0 && GC_ICOSAHEDRON_INSTANCES == 1 \
    && GC_ENABLE_LORENZ != 0 && GC_LORENZ_INSTANCES == 1
#define GC_DEFAULT_FAMILY_LAYOUT 1
#else
#define GC_DEFAULT_FAMILY_LAYOUT 0
#endif

const float GC_MASTER_BRIGHTNESS = 1.00;
const float GC_BASE_SIZE = 0.048;
const float GC_SIZE_VARIATION = 0.12;
const float GC_NARROW_REFERENCE_ASPECT = 1.20;
const float GC_NARROW_MIN_SCALE = 0.58;
const float GC_CAMERA_DISTANCE = 4.30;
const float GC_CULL_RADIUS = 2.45;
const float GC_CULL_FEATHER = 0.52;
const float GC_BREATHE_AMOUNT = 0.055;
const float GC_BREATHE_SPEED = 1.05;
const float GC_OBJECT_PHASE_STEP = 2.39996322973; // golden angle

const vec2 GC_PATH_AMPLITUDE = vec2(0.43, 0.37);
const float GC_PATH_ORBIT_WEIGHT = 0.72;
const float GC_PATH_WANDER_WEIGHT = 0.28;
const float GC_PATH_ORBIT_SPEED = 0.032;
const float GC_PATH_WANDER_SPEED_X = 0.091;
const float GC_PATH_WANDER_SPEED_Y = 0.073;
const float GC_PATH_SPEED_STEP = 0.0025;

const vec3 GC_ROTATION_BASE = vec3(0.58, -0.66, 0.10);
const vec3 GC_ROTATION_SPEED = vec3(0.13, 0.19, 0.095);
const vec3 GC_ROTATION_PHASE_STEP = vec3(0.73, 1.07, 0.61);

const float GC_EDGE_CORE_WIDTH = 0.012;
const float GC_EDGE_GLOW_WIDTH = 0.052;
const float GC_EDGE_CORE_STRENGTH = 0.58;
const float GC_EDGE_GLOW_STRENGTH = 0.095;
const float GC_NEAR_WHITE_MIX = 0.30;
const float GC_NODE_RADIUS = 0.040;
const float GC_NODE_STRENGTH = 0.24;
const float GC_CORE_GLOW_STRENGTH = 0.060;
const float GC_EXPOSURE = 1.18;
const float GC_ALPHA_MAX = 0.48;
const float GC_LIGHT_ALPHA_GAIN = 0.68;
const float GC_BACKGROUND_TOLERANCE_LOW = 0.030;
const float GC_BACKGROUND_TOLERANCE_HIGH = 0.245;
const float GC_TRANSPARENT_CELL_GAIN = 0.48;

const vec3 GC_VOID = vec3(0.006, 0.005, 0.030);
const vec3 GC_BLUE = vec3(0.080, 0.290, 1.000);
const vec3 GC_CYAN = vec3(0.090, 0.880, 1.000);
const vec3 GC_TEAL = vec3(0.080, 0.740, 0.650);
const vec3 GC_VIOLET = vec3(0.650, 0.220, 1.000);
const vec3 GC_ROSE = vec3(0.980, 0.180, 0.610);
const vec3 GC_WHITE = vec3(0.990, 0.970, 1.000);
// Unified animated geometry palette: every family uses both gradients.
const vec3 GC_GEOMETRY_BLUE_DEEP = vec3(0.025, 0.110, 0.500);
const vec3 GC_GEOMETRY_BLUE_BRIGHT = vec3(0.120, 0.590, 1.000);
const vec3 GC_GEOMETRY_PINK_DEEP = vec3(0.500, 0.025, 0.300);
const vec3 GC_GEOMETRY_PINK_BRIGHT = vec3(1.000, 0.290, 0.780);
const float GC_GEOMETRY_PALETTE_FLOW_SPEED = 0.16;
const float GC_GEOMETRY_PALETTE_PHASE_STEP = 0.73;
const float GC_PI = 3.14159265359;
const float GC_TAU = 6.28318530718;

// Type-specific relative dimensions.
const float GC_TESSERACT_SCALE = 1.00;
const float GC_GEM_SCALE = 0.92;
const float GC_ORBITAL_SCALE = 0.92;
const float GC_ORBITAL_LATITUDE_COUNT = 7.0;
const float GC_ORBITAL_LONGITUDE_COUNT = 12.0;
const float GC_ORBITAL_GRID_CORE_WIDTH = 0.030;
const float GC_ORBITAL_GRID_GLOW_WIDTH = 0.105;
const float GC_ORBITAL_GRID_CORE_STRENGTH = 0.52;
const float GC_ORBITAL_GRID_GLOW_STRENGTH = 0.095;
const float GC_ORBITAL_GRID_BACK_STRENGTH = 0.24;
const float GC_ORBITAL_GRID_POLE_FADE_START = 0.055;
const float GC_ORBITAL_GRID_POLE_FADE_END = 0.20;
const float GC_ORBITAL_SILHOUETTE_CORE_WIDTH = 0.020;
const float GC_ORBITAL_SILHOUETTE_GLOW_WIDTH = 0.080;
const float GC_ORBITAL_SILHOUETTE_CORE_STRENGTH = 0.60;
const float GC_ORBITAL_SILHOUETTE_GLOW_STRENGTH = 0.12;
const float GC_ORBITAL_BACK_RING_VISIBILITY = 0.30;
const float GC_ORBITAL_BACK_MOON_VISIBILITY = 0.24;
const float GC_ORBITAL_AXIAL_TILT = 0.34;
const float GC_ORBITAL_SPIN_SPEED = 0.28;

const float GC_ICOSA_CAGE_AURA_RADIUS = 1.04;
const float GC_ICOSA_CAGE_AURA_WIDTH = 0.24;
const float GC_ICOSA_CAGE_AURA_STRENGTH = 0.040;
const float GC_ICOSA_CAGE_AURA_OPACITY = 0.065;
const float GC_CRYSTAL_SCALE = 1.00;
const float GC_KNOT_SCALE = 0.78;
const float GC_MOBIUS_SCALE = 0.88;
const float GC_FRACTAL_SCALE = 1.02;
const float GC_ICOSAHEDRON_SCALE = 0.96;
const float GC_LORENZ_SCALE = 1.10;

// =============================================================================
// SHAPE-SHIFTING CURSOR, TRAIL, CONNECTION, AND RANDOMNESS
// =============================================================================

#define GCC_CURSOR_STYLE 0               // 0 time-varying shape, 1 all-family constellation
#define GCC_CURSOR_MODE 1                // style 0: 0 fixed, 1 shuffled, 2 sequential
#define GCC_FIXED_TYPE 0                 // type ID used when mode == 0
#define GCC_CURSOR_WEIGHT_BY_INSTANCES 0 // 1 weights style-0 scheduling by family counts
#define GCC_ENABLE_TRAIL 1
#define GCC_ENABLE_SPARKS 1
#define GCC_ENABLE_OBJECT_LINKS 1        // 0 removes every cursor-object connection
#define GCC_LINK_TARGET_MODE 2           // 0 all equal; 1 cursor family only; 2 soft all + strong match
#define GCC_LINK_ALL_OBJECTS 1           // all qualifying instances; 0 first one only
#define GCC_LINK_LIMIT GC_OBJECT_LIMIT   // maximum number of connected instances

const float GCC_RANDOM_SEED = 37.17;
const float GCC_SHAPE_HOLD_SECONDS = 3.40;
const float GCC_SHAPE_TRANSITION_SECONDS = 0.55;
const float GCC_EFFECT_DURATION = 0.42;
const float GCC_FADE_POWER = 1.65;
const float GCC_MIN_MOVEMENT_CELLS = 0.025;
const float GCC_GROWTH_START_CELLS = 0.08;
const float GCC_GROWTH_FULL_CELLS = 8.00;
const float GCC_SIZE_MIN = 1.05;
const float GCC_SIZE_MAX = 2.35;
const float GCC_SIZE_PULSE = 0.11;
const float GCC_CULL_RADIUS_MIN = 4.5;
const float GCC_CULL_RADIUS_MAX = 9.0;
const float GCC_CONTENT_PROTECTION = 0.18;
const float GCC_MASTER_BRIGHTNESS = 1.00;
const float GCC_ALPHA_MAX = 0.60;
const float GCC_ALPHA_GAIN = 1.35;

// Style 1 arranges one miniature of every geometry around a shared sigil.
const float GCC_CONSTELLATION_ORBIT_RADIUS = 1.45;
const float GCC_CONSTELLATION_MINI_SCALE = 0.34;
const float GCC_CONSTELLATION_COUNT_SCALE_MIN = 0.62;
const float GCC_CONSTELLATION_COUNT_SCALE_MAX = 1.28;
const float GCC_CONSTELLATION_ROTATION_SPEED = 0.22;
const float GCC_CONSTELLATION_FAMILY_STRENGTH = 0.88;
const float GCC_CONSTELLATION_RING_WIDTH = 0.014;
const float GCC_CONSTELLATION_RING_GLOW_WIDTH = 0.060;
const float GCC_CONSTELLATION_RING_STRENGTH = 0.24;
const float GCC_CONSTELLATION_CORE_STRENGTH = 0.18;

const float GCC_ECHO_START_SCALE = 1.06;
const float GCC_ECHO_END_SCALE = 1.90;
const float GCC_ECHO_STRENGTH = 0.11;
const float GCC_TRAIL_WIDTH_MIN = 0.11;
const float GCC_TRAIL_WIDTH_MAX = 0.25;
const float GCC_TRAIL_GLOW_MULTIPLIER = 4.10;
const float GCC_TRAIL_CORE_STRENGTH = 0.23;
const float GCC_TRAIL_GLOW_STRENGTH = 0.054;
const float GCC_SPARK_RADIUS = 0.072;
const float GCC_SPARK_SPREAD = 1.85;
const float GCC_SPARK_STRENGTH = 0.24;

const float GCC_LINK_WIDTH = 0.055;
const float GCC_LINK_GLOW_WIDTH = 0.23;
const float GCC_LINK_CORE_STRENGTH = 0.032;
const float GCC_LINK_GLOW_STRENGTH = 0.008;
const float GCC_LINK_DASH_COUNT = 19.0;
const float GCC_LINK_DASH_SPEED = 1.62;
const float GCC_LINK_SECONDARY_FALLOFF = 0.88;
const float GCC_LINK_COLOR_PHASE_STEP = 0.12;
const float GCC_LINK_TYPE_SWITCH_MIN_GAIN = 0.28;
// Mode 2 context rays remain visible but subordinate to the matching family.
const float GCC_LINK_CONTEXT_WIDTH_SCALE = 0.55;
const float GCC_LINK_CONTEXT_GLOW_WIDTH_SCALE = 0.65;
const float GCC_LINK_CONTEXT_INTENSITY_SCALE = 0.16;
const float GCC_LINK_CONTEXT_OPACITY_SCALE = 0.12;
const float GCC_LINK_CONTEXT_DASH_DENSITY_SCALE = 0.72;
const float GCC_LINK_CONTEXT_DASH_SPEED_SCALE = 0.75;
// Movement factor 0..1 also drives link thickness, glow, energy, and dash density.
// MIN values apply to tiny cursor moves; MAX values apply at GROWTH_FULL_CELLS.
const float GCC_LINK_MOVEMENT_POWER = 1.15;
const float GCC_LINK_WIDTH_MIN_SCALE = 0.28;
const float GCC_LINK_WIDTH_MAX_SCALE = 1.35;
const float GCC_LINK_GLOW_WIDTH_MIN_SCALE = 0.22;
const float GCC_LINK_GLOW_WIDTH_MAX_SCALE = 1.45;
const float GCC_LINK_INTENSITY_MIN_SCALE = 0.10;
const float GCC_LINK_INTENSITY_MAX_SCALE = 1.25;
const float GCC_LINK_OPACITY_MIN_SCALE = 0.08;
const float GCC_LINK_OPACITY_MAX_SCALE = 1.30;
const float GCC_LINK_DASH_DENSITY_MIN_SCALE = 0.42;
const float GCC_LINK_DASH_DENSITY_MAX_SCALE = 1.30;
const float GCC_LINK_DASH_SPEED_MIN_SCALE = 0.40;
const float GCC_LINK_DASH_SPEED_MAX_SCALE = 1.25;
const float GCC_LINK_CULL_MIN_SCALE = 0.55;
const float GCC_LINK_CULL_MAX_SCALE = 1.70;
const float GCC_LINK_CULL_MIN_PIXELS = 4.0;

// =============================================================================
// SHARED MATHEMATICS AND RASTER HELPERS
// =============================================================================

float saturate(float value) { return clamp(value, 0.0, 1.0); }
float luminance(vec3 color) { return dot(color, vec3(0.2126, 0.7152, 0.0722)); }
vec3 geometryBlueTone(float phase) {
    float flow = 0.5 + 0.5 * sin(
        iTime * GC_GEOMETRY_PALETTE_FLOW_SPEED + phase
    );
    return mix(GC_GEOMETRY_BLUE_DEEP, GC_GEOMETRY_BLUE_BRIGHT, flow);
}
vec3 geometryPinkTone(float phase) {
    float flow = 0.5 + 0.5 * sin(
        iTime * GC_GEOMETRY_PALETTE_FLOW_SPEED + phase + 2.1
    );
    return mix(GC_GEOMETRY_PINK_DEEP, GC_GEOMETRY_PINK_BRIGHT, flow);
}
#define GC_GEOMETRY_BLUE geometryBlueTone(0.0)
#define GC_GEOMETRY_PINK geometryPinkTone(1.7)
float hash11(float value) {
    return fract(sin(value * 127.1 + 311.7) * 43758.5453123);
}
float hash12(vec2 value) {
    vec3 p = fract(vec3(value.xyx) * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}
float gaussianPoint(vec2 point, float radius) {
    float safeRadius = max(radius, 0.00001);
    return exp(-dot(point, point) / (2.0 * safeRadius * safeRadius));
}
float segmentParameter(vec2 point, vec2 startPoint, vec2 endPoint) {
    vec2 segment = endPoint - startPoint;
    return clamp(
        dot(point - startPoint, segment) / max(dot(segment, segment), 0.000001),
        0.0,
        1.0
    );
}
float segmentDistance(vec2 point, vec2 startPoint, vec2 endPoint) {
    return length(point - mix(
        startPoint,
        endPoint,
        segmentParameter(point, startPoint, endPoint)
    ));
}
vec3 rotateX(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(point.x, c * point.y - s * point.z, s * point.y + c * point.z);
}
vec3 rotateY(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(c * point.x + s * point.z, point.y, -s * point.x + c * point.z);
}
vec3 rotateZ(vec3 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(c * point.x - s * point.y, s * point.x + c * point.y, point.z);
}
vec3 rotateXYZ(vec3 point, vec3 angle) {
    return rotateZ(rotateY(rotateX(point, angle.x), angle.y), angle.z);
}
vec2 rotate2d(vec2 point, float angle) {
    float c = cos(angle), s = sin(angle);
    return mat2(c, -s, s, c) * point;
}
vec2 projectPoint(
    vec3 point,
    vec2 center,
    float scaleValue,
    float cameraDistance,
    out float depth
) {
    depth = max(cameraDistance - point.z, 0.12);
    return center + point.xy * scaleValue * cameraDistance / depth;
}
vec2 scenePoint(vec2 pixelPoint) {
    return (pixelPoint - 0.5 * iResolution.xy) / max(iResolution.y, 1.0);
}
vec2 cursorCenterPixels(vec4 cursorRectangle) {
    return vec2(
        cursorRectangle.x + cursorRectangle.z * 0.5,
        cursorRectangle.y - cursorRectangle.w * 0.5
    );
}
float insideCursor(vec2 point, vec4 cursorRectangle) {
    vec2 minimumPoint = vec2(cursorRectangle.x, cursorRectangle.y - cursorRectangle.w);
    vec2 maximumPoint = vec2(cursorRectangle.x + cursorRectangle.z, cursorRectangle.y);
    return step(minimumPoint.x, point.x) * step(minimumPoint.y, point.y)
        * step(point.x, maximumPoint.x) * step(point.y, maximumPoint.y);
}
float backgroundCellMask(vec4 terminalColor) {
    float difference = length(terminalColor.rgb - iBackgroundColor);
    float colorMatch = 1.0 - smoothstep(
        GC_BACKGROUND_TOLERANCE_LOW,
        GC_BACKGROUND_TOLERANCE_HIGH,
        difference
    );
    float darkFallback = 1.0 - smoothstep(0.12, 0.58, luminance(terminalColor.rgb));
    float transparentCell = 1.0 - smoothstep(0.76, 0.995, terminalColor.a);
    return saturate(max(
        colorMatch,
        darkFallback * transparentCell * GC_TRANSPARENT_CELL_GAIN
    ));
}

struct GeometrySample {
    vec3 radiance;
    float opacity;
    float darken;
};

GeometrySample emptyGeometrySample() {
    return GeometrySample(vec3(0.0), 0.0, 0.0);
}

vec3 typeColorA(int typeIndex) {
    return geometryBlueTone(float(typeIndex) * GC_GEOMETRY_PALETTE_PHASE_STEP);
}

vec3 typeColorB(int typeIndex) {
    return geometryPinkTone(float(typeIndex) * GC_GEOMETRY_PALETTE_PHASE_STEP + 1.7);
}

float typeScale(int typeIndex) {
    if (typeIndex == 0) return GC_TESSERACT_SCALE;
    if (typeIndex == 1) return GC_GEM_SCALE;
    if (typeIndex == 2) return GC_ORBITAL_SCALE;
    if (typeIndex == 3) return GC_CRYSTAL_SCALE;
    if (typeIndex == 4) return GC_KNOT_SCALE;
    if (typeIndex == 5) return GC_MOBIUS_SCALE;
    if (typeIndex == 6) return GC_FRACTAL_SCALE;
    if (typeIndex == 7) return GC_ICOSAHEDRON_SCALE;
    return GC_LORENZ_SCALE;
}

int configuredInstancesForType(int typeIndex) {
#if GC_DEFAULT_FAMILY_LAYOUT
    return typeIndex >= 0 && typeIndex < GC_GEOMETRY_TYPE_COUNT ? 1 : 0;
#else
    if (typeIndex == 0) return GC_TESSERACT_ACTIVE_INSTANCES;
    if (typeIndex == 1) return GC_GEM_ACTIVE_INSTANCES;
    if (typeIndex == 2) return GC_ORBITAL_ACTIVE_INSTANCES;
    if (typeIndex == 3) return GC_CRYSTAL_ACTIVE_INSTANCES;
    if (typeIndex == 4) return GC_TORUS_KNOT_ACTIVE_INSTANCES;
    if (typeIndex == 5) return GC_MOBIUS_ACTIVE_INSTANCES;
    if (typeIndex == 6) return GC_FRACTAL_TETRA_ACTIVE_INSTANCES;
    if (typeIndex == 7) return GC_ICOSAHEDRON_ACTIVE_INSTANCES;
    if (typeIndex == 8) return GC_LORENZ_ACTIVE_INSTANCES;
    return 0;
#endif
}

bool typeEnabled(int typeIndex) {
#if GC_DEFAULT_FAMILY_LAYOUT
    return typeIndex >= 0 && typeIndex < GC_GEOMETRY_TYPE_COUNT;
#else
    return configuredInstancesForType(typeIndex) > 0;
#endif
}

int enabledTypeCount() {
#if GC_DEFAULT_FAMILY_LAYOUT
    return GC_GEOMETRY_TYPE_COUNT;
#else
    return (GC_TESSERACT_ACTIVE_INSTANCES > 0 ? 1 : 0)
        + (GC_GEM_ACTIVE_INSTANCES > 0 ? 1 : 0)
        + (GC_ORBITAL_ACTIVE_INSTANCES > 0 ? 1 : 0)
        + (GC_CRYSTAL_ACTIVE_INSTANCES > 0 ? 1 : 0)
        + (GC_TORUS_KNOT_ACTIVE_INSTANCES > 0 ? 1 : 0)
        + (GC_MOBIUS_ACTIVE_INSTANCES > 0 ? 1 : 0)
        + (GC_FRACTAL_TETRA_ACTIVE_INSTANCES > 0 ? 1 : 0)
        + (GC_ICOSAHEDRON_ACTIVE_INSTANCES > 0 ? 1 : 0)
        + (GC_LORENZ_ACTIVE_INSTANCES > 0 ? 1 : 0);
#endif
}

int enabledTypeForOrdinal(int ordinal) {
#if GC_DEFAULT_FAMILY_LAYOUT
    int wrappedOrdinal = ordinal % GC_GEOMETRY_TYPE_COUNT;
    return wrappedOrdinal < 0 ? wrappedOrdinal + GC_GEOMETRY_TYPE_COUNT : wrappedOrdinal;
#else
    int count = enabledTypeCount();
    if (count <= 0) return -1;
    int remainingOrdinal = ordinal % count;
    if (remainingOrdinal < 0) remainingOrdinal += count;
    if (GC_TESSERACT_ACTIVE_INSTANCES > 0) {
        if (remainingOrdinal == 0) return 0;
        remainingOrdinal--;
    }
    if (GC_GEM_ACTIVE_INSTANCES > 0) {
        if (remainingOrdinal == 0) return 1;
        remainingOrdinal--;
    }
    if (GC_ORBITAL_ACTIVE_INSTANCES > 0) {
        if (remainingOrdinal == 0) return 2;
        remainingOrdinal--;
    }
    if (GC_CRYSTAL_ACTIVE_INSTANCES > 0) {
        if (remainingOrdinal == 0) return 3;
        remainingOrdinal--;
    }
    if (GC_TORUS_KNOT_ACTIVE_INSTANCES > 0) {
        if (remainingOrdinal == 0) return 4;
        remainingOrdinal--;
    }
    if (GC_MOBIUS_ACTIVE_INSTANCES > 0) {
        if (remainingOrdinal == 0) return 5;
        remainingOrdinal--;
    }
    if (GC_FRACTAL_TETRA_ACTIVE_INSTANCES > 0) {
        if (remainingOrdinal == 0) return 6;
        remainingOrdinal--;
    }
    if (GC_ICOSAHEDRON_ACTIVE_INSTANCES > 0) {
        if (remainingOrdinal == 0) return 7;
        remainingOrdinal--;
    }
    if (GC_LORENZ_ACTIVE_INSTANCES > 0 && remainingOrdinal == 0) return 8;
    return -1;
#endif
}

int configuredGeometryObjectCount() {
    return GC_CONFIGURED_OBJECT_COUNT;
}

int geometryObjectType(int objectIndex) {
#if GC_DEFAULT_FAMILY_LAYOUT
    return objectIndex >= 0 && objectIndex < GC_GEOMETRY_TYPE_COUNT
        ? objectIndex : -1;
#else
    if (objectIndex < 0 || objectIndex >= GC_CONFIGURED_OBJECT_COUNT) return -1;
    int boundary = GC_TESSERACT_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return 0;
    boundary += GC_GEM_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return 1;
    boundary += GC_ORBITAL_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return 2;
    boundary += GC_CRYSTAL_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return 3;
    boundary += GC_TORUS_KNOT_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return 4;
    boundary += GC_MOBIUS_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return 5;
    boundary += GC_FRACTAL_TETRA_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return 6;
    boundary += GC_ICOSAHEDRON_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return 7;
    return 8;
#endif
}

int geometryObjectInstanceIndex(int objectIndex) {
#if GC_DEFAULT_FAMILY_LAYOUT
    return objectIndex >= 0 && objectIndex < GC_GEOMETRY_TYPE_COUNT ? 0 : -1;
#else
    if (objectIndex < 0 || objectIndex >= GC_CONFIGURED_OBJECT_COUNT) return -1;
    int familyStart = 0;
    int boundary = GC_TESSERACT_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return objectIndex;
    familyStart = boundary;
    boundary += GC_GEM_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return objectIndex - familyStart;
    familyStart = boundary;
    boundary += GC_ORBITAL_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return objectIndex - familyStart;
    familyStart = boundary;
    boundary += GC_CRYSTAL_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return objectIndex - familyStart;
    familyStart = boundary;
    boundary += GC_TORUS_KNOT_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return objectIndex - familyStart;
    familyStart = boundary;
    boundary += GC_MOBIUS_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return objectIndex - familyStart;
    familyStart = boundary;
    boundary += GC_FRACTAL_TETRA_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return objectIndex - familyStart;
    familyStart = boundary;
    boundary += GC_ICOSAHEDRON_ACTIVE_INSTANCES;
    if (objectIndex < boundary) return objectIndex - familyStart;
    return objectIndex - boundary;
#endif
}

int firstGeometryObjectIndexForType(int requestedType) {
#if GC_DEFAULT_FAMILY_LAYOUT
    return requestedType >= 0 && requestedType < GC_GEOMETRY_TYPE_COUNT
        ? requestedType : -1;
#else
    if (!typeEnabled(requestedType)) return -1;
    if (requestedType == 0) return 0;
    int firstIndex = GC_TESSERACT_ACTIVE_INSTANCES;
    if (requestedType == 1) return firstIndex;
    firstIndex += GC_GEM_ACTIVE_INSTANCES;
    if (requestedType == 2) return firstIndex;
    firstIndex += GC_ORBITAL_ACTIVE_INSTANCES;
    if (requestedType == 3) return firstIndex;
    firstIndex += GC_CRYSTAL_ACTIVE_INSTANCES;
    if (requestedType == 4) return firstIndex;
    firstIndex += GC_TORUS_KNOT_ACTIVE_INSTANCES;
    if (requestedType == 5) return firstIndex;
    firstIndex += GC_MOBIUS_ACTIVE_INSTANCES;
    if (requestedType == 6) return firstIndex;
    firstIndex += GC_FRACTAL_TETRA_ACTIVE_INSTANCES;
    if (requestedType == 7) return firstIndex;
    firstIndex += GC_ICOSAHEDRON_ACTIVE_INSTANCES;
    return requestedType == 8 ? firstIndex : -1;
#endif
}

vec3 geometryAngle(float identity, int typeIndex) {
    float typePhase = float(typeIndex) * 0.31;
    return GC_ROTATION_BASE
        + iTime * GC_ROTATION_SPEED * (1.0 + typePhase * 0.08)
        + identity * GC_ROTATION_PHASE_STEP;
}

vec2 geometryUv(float timeValue, float identity) {
    float orbitPhase = identity * GC_OBJECT_PHASE_STEP
        + timeValue * (GC_PATH_ORBIT_SPEED + identity * GC_PATH_SPEED_STEP);
    vec2 orbit = vec2(cos(orbitPhase), sin(orbitPhase));
    vec2 wander = vec2(
        sin(timeValue * GC_PATH_WANDER_SPEED_X + identity * 1.71),
        sin(timeValue * GC_PATH_WANDER_SPEED_Y + identity * 2.13)
    );
    return vec2(0.5) + GC_PATH_AMPLITUDE * (
        orbit * GC_PATH_ORBIT_WEIGHT + wander * GC_PATH_WANDER_WEIGHT
    );
}

void addProjectedEdge(
    inout GeometrySample sampleValue,
    vec2 point,
    vec2 first,
    vec2 second,
    float firstDepth,
    float secondDepth,
    float sizeValue,
    vec3 colorA,
    vec3 colorB,
    float strength
) {
    float edgeDistance = segmentDistance(point, first, second);
    float core = exp(-edgeDistance / max(sizeValue * GC_EDGE_CORE_WIDTH, 0.00010));
    float glow = exp(-edgeDistance / max(sizeValue * GC_EDGE_GLOW_WIDTH, 0.00028));
    float nearFactor = saturate(
        (GC_CAMERA_DISTANCE + 0.86 - 0.5 * (firstDepth + secondDepth)) / 1.8
    );
    vec3 color = mix(colorA, colorB, nearFactor);
    color = mix(color, GC_WHITE, nearFactor * GC_NEAR_WHITE_MIX);
    sampleValue.radiance += color * strength * (
        core * GC_EDGE_CORE_STRENGTH + glow * GC_EDGE_GLOW_STRENGTH
    );
    sampleValue.opacity = max(
        sampleValue.opacity,
        strength * max(core, glow * 0.34)
    );
}

void addProjectedNode(
    inout GeometrySample sampleValue,
    vec2 point,
    vec2 nodeCenter,
    float sizeValue,
    vec3 color,
    float strength
) {
    float node = gaussianPoint(point - nodeCenter, sizeValue * GC_NODE_RADIUS);
    sampleValue.radiance += color * node * GC_NODE_STRENGTH * strength;
    sampleValue.opacity = max(sampleValue.opacity, node * 0.42 * strength);
}

// =============================================================================
// GEOMETRY FAMILIES 0..3 — TESSERACT, GEM, ORBITAL WORLD, CRYSTAL
// =============================================================================

GeometrySample renderTesseract(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec2 projected[16];
    float depth[16];
    vec3 angle = geometryAngle(identity, 0);
    float innerScale = 0.52 + 0.07 * sin(iTime * 0.74 + identity);
    float innerTwist = 0.34 * sin(iTime * 0.52 + identity * 1.7);
    for (int vertexIndex = 0; vertexIndex < 16; vertexIndex++) {
        int corner = vertexIndex & 7;
        vec3 vertex = vec3(
            (corner & 1) != 0 ? 1.0 : -1.0,
            (corner & 2) != 0 ? 1.0 : -1.0,
            (corner & 4) != 0 ? 1.0 : -1.0
        ) * 0.70;
        if (vertexIndex >= 8) {
            vertex *= innerScale;
            vertex = rotateZ(rotateY(vertex, -innerTwist * 0.72), innerTwist);
        }
        vertex = rotateXYZ(vertex, angle);
        projected[vertexIndex] = projectPoint(
            vertex, center, sizeValue, GC_CAMERA_DISTANCE, depth[vertexIndex]
        );
    }
    const int edgeA[32] = int[32](
        0,1,3,2, 4,5,7,6, 0,1,2,3,
        8,9,11,10, 12,13,15,14, 8,9,10,11,
        0,1,2,3,4,5,6,7
    );
    const int edgeB[32] = int[32](
        1,3,2,0, 5,7,6,4, 4,5,6,7,
        9,11,10,8, 13,15,14,12, 12,13,14,15,
        8,9,10,11,12,13,14,15
    );
    for (int edgeIndex = 0; edgeIndex < 32; edgeIndex++) {
        int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
        addProjectedEdge(
            sampleValue, point,
            projected[first], projected[second],
            depth[first], depth[second], sizeValue,
            GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK,
            edgeIndex >= 24 ? 0.78 : 1.0
        );
    }
    float core = gaussianPoint(point - center, sizeValue * 0.68);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.55)
        * core * GC_CORE_GLOW_STRENGTH;
    sampleValue.opacity = max(sampleValue.opacity, core * 0.16);
    return sampleValue;
}

vec3 gemVertex(int index) {
    if (index == 0) return vec3( 1.0, 0.0, 0.0);
    if (index == 1) return vec3(-1.0, 0.0, 0.0);
    if (index == 2) return vec3(0.0,  1.18, 0.0);
    if (index == 3) return vec3(0.0, -1.18, 0.0);
    if (index == 4) return vec3(0.0, 0.0,  0.92);
    return vec3(0.0, 0.0, -0.92);
}

GeometrySample renderGem(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec2 projected[6];
    float depth[6];
    vec3 angle = geometryAngle(identity, 1);
    for (int vertexIndex = 0; vertexIndex < 6; vertexIndex++) {
        vec3 vertex = rotateXYZ(gemVertex(vertexIndex), angle);
        projected[vertexIndex] = projectPoint(
            vertex, center, sizeValue, GC_CAMERA_DISTANCE, depth[vertexIndex]
        );
    }
    const int edgeA[12] = int[12](0,0,0,0, 1,1,1,1, 2,2,3,3);
    const int edgeB[12] = int[12](2,3,4,5, 2,3,4,5, 4,5,4,5);
    for (int edgeIndex = 0; edgeIndex < 12; edgeIndex++) {
        int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
        addProjectedEdge(
            sampleValue, point,
            projected[first], projected[second],
            depth[first], depth[second], sizeValue,
            GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 1.0
        );
    }
    float body = gaussianPoint(point - center, sizeValue * 0.62);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.46) * body * 0.095;
    sampleValue.darken = max(sampleValue.darken, body * 0.10);
    sampleValue.opacity = max(sampleValue.opacity, body * 0.20);
    return sampleValue;
}

float gcPeriodicGridDistance(float phase) {
    return abs(fract(phase + 0.5) - 0.5);
}

void gcSphericalGridMask(
    vec3 surfaceNormal,
    float pixelRadius,
    out float core,
    out float glow
) {
    float latitude = asin(clamp(surfaceNormal.y, -1.0, 1.0));
    float longitude = atan(surfaceNormal.z, surfaceNormal.x);
    float latitudePhase = (latitude / GC_PI + 0.5) * GC_ORBITAL_LATITUDE_COUNT;
    float longitudePhase = (longitude / GC_TAU + 0.5) * GC_ORBITAL_LONGITUDE_COUNT;
    float latitudeDistance = gcPeriodicGridDistance(latitudePhase);
    float longitudeDistance = gcPeriodicGridDistance(longitudePhase);
    float latitudeAa = 0.72 * GC_ORBITAL_LATITUDE_COUNT
        / max(GC_PI * pixelRadius, 1.0);
    float longitudeAa = 0.72 * GC_ORBITAL_LONGITUDE_COUNT
        / max(GC_TAU * pixelRadius, 1.0);
    float latitudeCore = 1.0 - smoothstep(
        GC_ORBITAL_GRID_CORE_WIDTH,
        GC_ORBITAL_GRID_CORE_WIDTH + latitudeAa,
        latitudeDistance
    );
    float latitudeGlow = 1.0 - smoothstep(
        GC_ORBITAL_GRID_GLOW_WIDTH,
        GC_ORBITAL_GRID_GLOW_WIDTH + latitudeAa,
        latitudeDistance
    );
    float poleFade = smoothstep(
        GC_ORBITAL_GRID_POLE_FADE_START,
        GC_ORBITAL_GRID_POLE_FADE_END,
        length(surfaceNormal.xz)
    );
    float longitudeCore = poleFade * (1.0 - smoothstep(
        GC_ORBITAL_GRID_CORE_WIDTH,
        GC_ORBITAL_GRID_CORE_WIDTH + longitudeAa,
        longitudeDistance
    ));
    float longitudeGlow = poleFade * (1.0 - smoothstep(
        GC_ORBITAL_GRID_GLOW_WIDTH,
        GC_ORBITAL_GRID_GLOW_WIDTH + longitudeAa,
        longitudeDistance
    ));
    core = max(latitudeCore, longitudeCore);
    glow = max(latitudeGlow, longitudeGlow);
}

GeometrySample renderOrbital(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec2 local = (point - center) / max(sizeValue, 0.0001);
    const float sphereRadius = 0.88;
    float radial = length(local);
    float sphereAa = max(1.0 / max(sizeValue * iResolution.y, 1.0), 0.002);
    float sphereCoverage = 1.0 - smoothstep(
        sphereRadius - sphereAa,
        sphereRadius + sphereAa,
        radial
    );
    if (radial < sphereRadius + sphereAa * 2.0) {
        vec2 spherePoint = local / sphereRadius;
        float z = sqrt(max(1.0 - dot(spherePoint, spherePoint), 0.0));
        vec3 frontNormal = normalize(vec3(spherePoint, z));
        vec3 backNormal = normalize(vec3(spherePoint, -z));
        float spin = iTime * GC_ORBITAL_SPIN_SPEED + identity * 0.37;
        vec3 frontGridNormal = rotateY(
            rotateX(frontNormal, GC_ORBITAL_AXIAL_TILT),
            spin
        );
        vec3 backGridNormal = rotateY(
            rotateX(backNormal, GC_ORBITAL_AXIAL_TILT),
            spin
        );
        float frontCore, frontGlow, backCore, backGlow;
        float pixelRadius = max(sizeValue * sphereRadius * iResolution.y, 1.0);
        gcSphericalGridMask(frontGridNormal, pixelRadius, frontCore, frontGlow);
        gcSphericalGridMask(backGridNormal, pixelRadius, backCore, backGlow);
        vec3 lightDirection = normalize(vec3(-0.62, 0.74, 1.15));
        float diffuse = 0.44 + 0.56 * max(dot(frontNormal, lightDirection), 0.0);
        vec3 frontColor = mix(
            GC_GEOMETRY_BLUE,
            GC_GEOMETRY_PINK,
            0.50 + 0.34 * frontGridNormal.y
        )
            * diffuse;
        vec3 backColor = mix(GC_GEOMETRY_PINK, GC_GEOMETRY_BLUE, 0.48);
        sampleValue.radiance += frontColor * (
            frontCore * GC_ORBITAL_GRID_CORE_STRENGTH
            + frontGlow * GC_ORBITAL_GRID_GLOW_STRENGTH
        );
        sampleValue.radiance += backColor * GC_ORBITAL_GRID_BACK_STRENGTH * (
            backCore * GC_ORBITAL_GRID_CORE_STRENGTH
            + backGlow * GC_ORBITAL_GRID_GLOW_STRENGTH
        );
        float silhouetteDistance = abs(radial - sphereRadius) / sphereRadius;
        float silhouetteCore = exp(
            -silhouetteDistance / GC_ORBITAL_SILHOUETTE_CORE_WIDTH
        );
        float silhouetteGlow = exp(
            -silhouetteDistance / GC_ORBITAL_SILHOUETTE_GLOW_WIDTH
        );
        sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.40) * (
            silhouetteCore * GC_ORBITAL_SILHOUETTE_CORE_STRENGTH
            + silhouetteGlow * GC_ORBITAL_SILHOUETTE_GLOW_STRENGTH
        );
        sampleValue.opacity = max(
            sampleValue.opacity,
            max(frontCore, max(backCore * GC_ORBITAL_GRID_BACK_STRENGTH, silhouetteCore))
        );
        sampleValue.opacity = max(
            sampleValue.opacity,
            max(frontGlow, silhouetteGlow) * 0.20
        );
    }
    float atmosphere = exp(-abs(radial - sphereRadius * 1.05) / 0.16)
        * smoothstep(sphereRadius * 0.72, sphereRadius * 0.96, radial);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.46)
        * atmosphere * 0.040;
    sampleValue.opacity = max(sampleValue.opacity, atmosphere * 0.035);

    float roll = -0.34 + iTime * 0.08 + identity * 0.27;
    vec2 ringPoint = rotate2d(local, -roll);
    vec2 ellipsePoint = vec2(ringPoint.x, ringPoint.y / 0.32);
    float ellipseRadius = length(ellipsePoint);
    for (int ringIndex = 0; ringIndex < 2; ringIndex++) {
        float target = 1.08 + float(ringIndex) * 0.22;
        float ringDistance = abs(ellipseRadius - target);
        float core = exp(-ringDistance / 0.025);
        float glow = exp(-ringDistance / 0.085);
        float front = step(0.0, ringPoint.y);
        float insideVisibility = mix(
            GC_ORBITAL_BACK_RING_VISIBILITY,
            1.0,
            front
        );
        float occlusion = mix(1.0, insideVisibility, sphereCoverage);
        vec3 ringColor = mix(
            GC_GEOMETRY_PINK,
            GC_GEOMETRY_BLUE,
            float(ringIndex)
        );
        sampleValue.radiance += ringColor * occlusion * (
            core * 0.38 + glow * 0.075
        );
        sampleValue.opacity = max(
            sampleValue.opacity,
            occlusion * max(core, glow * 0.25)
        );
    }
    for (int moonIndex = 0; moonIndex < 2; moonIndex++) {
        float index = float(moonIndex);
        float moonAngle = iTime * (0.42 + index * 0.09) + identity + index * GC_PI;
        float orbitDepth = sin(moonAngle);
        vec2 moonPlane = vec2(
            cos(moonAngle) * (1.45 + index * 0.24),
            orbitDepth * (1.45 + index * 0.24) * 0.32
        );
        vec2 moonCenter = center + rotate2d(moonPlane, roll) * sizeValue;
        float moon = gaussianPoint(point - moonCenter, sizeValue * (0.095 - index * 0.012));
        float behind = 1.0 - step(0.0, orbitDepth);
        float moonVisibility = 1.0 - behind * sphereCoverage
            * (1.0 - GC_ORBITAL_BACK_MOON_VISIBILITY);
        sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, index)
            * moon * moonVisibility * 0.62;
        sampleValue.opacity = max(sampleValue.opacity, moon * moonVisibility * 0.48);
    }
    return sampleValue;
}

GeometrySample renderCrystal(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec3 localVertex[14];
    vec2 projected[14];
    float depth[14];
    float side = 0.43;
    float tip = 3.05;
    localVertex[0] = vec3(-side,  side, -side);
    localVertex[1] = vec3( side,  side, -side);
    localVertex[2] = vec3( side, -side, -side);
    localVertex[3] = vec3(-side, -side, -side);
    localVertex[4] = vec3(-side,  side,  side);
    localVertex[5] = vec3( side,  side,  side);
    localVertex[6] = vec3( side, -side,  side);
    localVertex[7] = vec3(-side, -side,  side);
    localVertex[8] = vec3(0.0,  side * tip, 0.0);
    localVertex[9] = vec3(0.0, -side * tip, 0.0);
    localVertex[10] = vec3( side * tip, 0.0, 0.0);
    localVertex[11] = vec3(-side * tip, 0.0, 0.0);
    localVertex[12] = vec3(0.0, 0.0, -side * tip);
    localVertex[13] = vec3(0.0, 0.0,  side * tip);
    vec3 angle = geometryAngle(identity, 3);
    for (int vertexIndex = 0; vertexIndex < 14; vertexIndex++) {
        vec3 vertex = rotateXYZ(localVertex[vertexIndex], angle);
        projected[vertexIndex] = projectPoint(
            vertex, center, sizeValue, GC_CAMERA_DISTANCE, depth[vertexIndex]
        );
    }
    const int edgeA[36] = int[36](
        0,1,2,3, 4,5,6,7, 0,1,2,3,
        0,1,4,5, 3,2,7,6, 1,2,5,6,
        0,3,4,7, 0,1,2,3, 4,5,6,7
    );
    const int edgeB[36] = int[36](
        1,2,3,0, 5,6,7,4, 4,5,6,7,
        8,8,8,8, 9,9,9,9, 10,10,10,10,
        11,11,11,11, 12,12,12,12, 13,13,13,13
    );
    for (int edgeIndex = 0; edgeIndex < 36; edgeIndex++) {
        int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
        addProjectedEdge(
            sampleValue, point,
            projected[first], projected[second],
            depth[first], depth[second], sizeValue,
            GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK,
            edgeIndex < 12 ? 0.86 : 1.0
        );
    }
    float core = gaussianPoint(point - center, sizeValue * 0.72);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.58)
        * core * 0.072;
    sampleValue.opacity = max(sampleValue.opacity, core * 0.18);
    return sampleValue;
}

// =============================================================================
// GEOMETRY FAMILIES 4..8 — KNOT, MOBIUS, FRACTAL, ICOSAHEDRON, LORENZ
// =============================================================================

vec3 torusKnotPoint(float parameter) {
    float radial = 1.0 + 0.43 * cos(3.0 * parameter);
    return vec3(
        radial * cos(2.0 * parameter),
        radial * sin(2.0 * parameter),
        0.43 * sin(3.0 * parameter)
    );
}

GeometrySample renderTorusKnot(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec3 angle = geometryAngle(identity, 4);
    for (int segmentIndex = 0; segmentIndex < GC_CURVE_SEGMENTS; segmentIndex++) {
        float phase0 = float(segmentIndex) / float(GC_CURVE_SEGMENTS);
        float phase1 = float(segmentIndex + 1) / float(GC_CURVE_SEGMENTS);
        vec3 vertex0 = rotateXYZ(torusKnotPoint(phase0 * GC_TAU), angle);
        vec3 vertex1 = rotateXYZ(torusKnotPoint(phase1 * GC_TAU), angle);
        float depth0, depth1;
        vec2 projected0 = projectPoint(vertex0, center, sizeValue, GC_CAMERA_DISTANCE, depth0);
        vec2 projected1 = projectPoint(vertex1, center, sizeValue, GC_CAMERA_DISTANCE, depth1);
        float phaseColor = 0.5 + 0.5 * sin(phase0 * GC_TAU + identity);
        addProjectedEdge(
            sampleValue, point, projected0, projected1,
            depth0, depth1, sizeValue,
            mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, phaseColor),
            GC_GEOMETRY_PINK,
            1.0
        );
        if ((segmentIndex % 8) == 0) {
            addProjectedNode(
                sampleValue, point, projected0, sizeValue,
                mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, phaseColor), 0.72
            );
        }
    }
    float aura = gaussianPoint(point - center, sizeValue * 1.12);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.50)
        * aura * 0.045;
    sampleValue.opacity = max(sampleValue.opacity, aura * 0.12);
    return sampleValue;
}

vec3 mobiusPoint(float parameter, float transverse) {
    float twist = 0.5 * parameter;
    float radial = 1.0 + transverse * cos(twist);
    return vec3(
        radial * cos(parameter),
        radial * sin(parameter),
        transverse * sin(twist)
    );
}

GeometrySample renderMobius(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec3 angle = geometryAngle(identity, 5);
    const int railCount = 3;
    const int ribCount = 8;
    for (int railIndex = 0; railIndex < railCount; railIndex++) {
        float railPhase = float(railIndex) / float(railCount - 1);
        float transverse = mix(-0.46, 0.46, railPhase);
        for (int segmentIndex = 0; segmentIndex < GC_MOBIUS_SEGMENTS; segmentIndex++) {
            float phase0 = float(segmentIndex) / float(GC_MOBIUS_SEGMENTS);
            float phase1 = float(segmentIndex + 1) / float(GC_MOBIUS_SEGMENTS);
            vec3 vertex0 = rotateXYZ(mobiusPoint(phase0 * GC_TAU, transverse), angle);
            vec3 vertex1 = rotateXYZ(mobiusPoint(phase1 * GC_TAU, transverse), angle);
            float depth0, depth1;
            vec2 projected0 = projectPoint(vertex0, center, sizeValue, GC_CAMERA_DISTANCE, depth0);
            vec2 projected1 = projectPoint(vertex1, center, sizeValue, GC_CAMERA_DISTANCE, depth1);
            addProjectedEdge(
                sampleValue, point, projected0, projected1,
                depth0, depth1, sizeValue,
                mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, railPhase),
                GC_GEOMETRY_PINK,
                0.88
            );
        }
    }
    for (int ribIndex = 0; ribIndex < ribCount; ribIndex++) {
        float parameter = float(ribIndex) / float(ribCount) * GC_TAU;
        vec3 vertex0 = rotateXYZ(mobiusPoint(parameter, -0.46), angle);
        vec3 vertex1 = rotateXYZ(mobiusPoint(parameter,  0.46), angle);
        float depth0, depth1;
        vec2 projected0 = projectPoint(vertex0, center, sizeValue, GC_CAMERA_DISTANCE, depth0);
        vec2 projected1 = projectPoint(vertex1, center, sizeValue, GC_CAMERA_DISTANCE, depth1);
        addProjectedEdge(
            sampleValue, point, projected0, projected1,
            depth0, depth1, sizeValue,
            GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.72
        );
    }
    float core = gaussianPoint(point - center, sizeValue * 0.72);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.68)
        * core * 0.070;
    sampleValue.darken = max(sampleValue.darken, core * 0.08);
    sampleValue.opacity = max(sampleValue.opacity, core * 0.18);
    return sampleValue;
}

vec3 tetraVertex(int index) {
    const float normalizer = 0.57735026919;
    if (index == 0) return vec3( 1.0,  1.0,  1.0) * normalizer;
    if (index == 1) return vec3(-1.0, -1.0,  1.0) * normalizer;
    if (index == 2) return vec3(-1.0,  1.0, -1.0) * normalizer;
    return vec3(1.0, -1.0, -1.0) * normalizer;
}

vec3 fractalChildCenter(int childIndex) {
    vec3 childCenter = vec3(0.0);
    float offsetScale = 0.5;
    int code = childIndex;
    for (int depthIndex = 0; depthIndex < GC_FRACTAL_DEPTH; depthIndex++) {
        childCenter += tetraVertex(code % 4) * offsetScale;
        code /= 4;
        offsetScale *= 0.5;
    }
    return childCenter;
}

GeometrySample renderFractalTetra(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec3 angle = geometryAngle(identity, 6);
    float childScale = pow(0.5, float(GC_FRACTAL_DEPTH));
    const int edgeA[6] = int[6](0,0,0,1,1,2);
    const int edgeB[6] = int[6](1,2,3,2,3,3);
    for (int childIndex = 0; childIndex < GC_FRACTAL_CHILD_COUNT; childIndex++) {
        vec3 childCenter = fractalChildCenter(childIndex);
        vec2 projected[4];
        float depth[4];
        for (int vertexIndex = 0; vertexIndex < 4; vertexIndex++) {
            vec3 vertex = rotateXYZ(
                childCenter + tetraVertex(vertexIndex) * childScale,
                angle
            );
            projected[vertexIndex] = projectPoint(
                vertex, center, sizeValue, GC_CAMERA_DISTANCE, depth[vertexIndex]
            );
        }
        float childPhase = float(childIndex) / max(float(GC_FRACTAL_CHILD_COUNT - 1), 1.0);
        for (int edgeIndex = 0; edgeIndex < 6; edgeIndex++) {
            int first = edgeA[edgeIndex], second = edgeB[edgeIndex];
            addProjectedEdge(
                sampleValue, point,
                projected[first], projected[second],
                depth[first], depth[second], sizeValue,
                mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, childPhase),
                GC_GEOMETRY_PINK,
                0.88
            );
        }
    }
    float core = gaussianPoint(point - center, sizeValue * 0.68);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.42)
        * core * 0.050;
    sampleValue.opacity = max(sampleValue.opacity, core * 0.14);
    return sampleValue;
}

vec3 icosaVertex(int index) {
    const float phi = 1.61803398875;
    const float normalizer = 0.52573111212;
    if (index == 0)  return vec3(0.0,  1.0,  phi) * normalizer;
    if (index == 1)  return vec3(0.0, -1.0,  phi) * normalizer;
    if (index == 2)  return vec3(0.0,  1.0, -phi) * normalizer;
    if (index == 3)  return vec3(0.0, -1.0, -phi) * normalizer;
    if (index == 4)  return vec3( 1.0,  phi, 0.0) * normalizer;
    if (index == 5)  return vec3(-1.0,  phi, 0.0) * normalizer;
    if (index == 6)  return vec3( 1.0, -phi, 0.0) * normalizer;
    if (index == 7)  return vec3(-1.0, -phi, 0.0) * normalizer;
    if (index == 8)  return vec3( phi, 0.0,  1.0) * normalizer;
    if (index == 9)  return vec3(-phi, 0.0,  1.0) * normalizer;
    if (index == 10) return vec3( phi, 0.0, -1.0) * normalizer;
    return vec3(-phi, 0.0, -1.0) * normalizer;
}

GeometrySample renderIcosahedralCage(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec3 angle = geometryAngle(identity, 7);
    vec2 projected[12];
    float depth[12];
    for (int vertexIndex = 0; vertexIndex < 12; vertexIndex++) {
        vec3 vertex = rotateXYZ(icosaVertex(vertexIndex), angle);
        projected[vertexIndex] = projectPoint(
            vertex, center, sizeValue, GC_CAMERA_DISTANCE, depth[vertexIndex]
        );
    }
    for (int first = 0; first < 12; first++) {
        for (int second = first + 1; second < 12; second++) {
            if (length(icosaVertex(first) - icosaVertex(second)) >= 1.10) continue;
            addProjectedEdge(
                sampleValue, point,
                projected[first], projected[second],
                depth[first], depth[second], sizeValue,
                GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 1.0
            );
        }
    }
    float cageRadius = length((point - center) / max(sizeValue, 0.0001));
    float cageAura = exp(
        -abs(cageRadius - GC_ICOSA_CAGE_AURA_RADIUS)
            / max(GC_ICOSA_CAGE_AURA_WIDTH, 0.001)
    ) * smoothstep(0.48, 0.86, cageRadius);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.52)
        * cageAura * GC_ICOSA_CAGE_AURA_STRENGTH;
    sampleValue.opacity = max(
        sampleValue.opacity,
        cageAura * GC_ICOSA_CAGE_AURA_OPACITY
    );
    return sampleValue;
}

vec3 lorenzDerivative(vec3 state) {
    return vec3(
        10.0 * (state.y - state.x),
        state.x * (28.0 - state.z) - state.y,
        state.x * state.y - 2.66666666667 * state.z
    );
}

vec3 lorenzStep(vec3 state, float stepSize) {
    vec3 midpoint = state + 0.5 * stepSize * lorenzDerivative(state);
    return state + stepSize * lorenzDerivative(midpoint);
}

vec3 lorenzDisplay(vec3 state) {
    return vec3(state.x * 0.050, (state.z - 25.0) * 0.040, state.y * 0.050);
}

GeometrySample renderLorenz(
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    GeometrySample sampleValue = emptyGeometrySample();
    vec3 angle = geometryAngle(identity, 8) * vec3(0.42, 0.42, 0.65);
    vec3 state = vec3(1.0, 1.0, 20.0)
        + vec3(identity * 0.001, -identity * 0.0007, 0.0);
    for (int segmentIndex = 0; segmentIndex < GC_LORENZ_SEGMENTS; segmentIndex++) {
        vec3 previousState = state;
        for (int stepIndex = 0; stepIndex < 4; stepIndex++) {
            state = lorenzStep(state, 0.018);
        }
        vec3 vertex0 = rotateXYZ(lorenzDisplay(previousState), angle);
        vec3 vertex1 = rotateXYZ(lorenzDisplay(state), angle);
        float depth0, depth1;
        vec2 projected0 = projectPoint(vertex0, center, sizeValue, GC_CAMERA_DISTANCE, depth0);
        vec2 projected1 = projectPoint(vertex1, center, sizeValue, GC_CAMERA_DISTANCE, depth1);
        float lobe = smoothstep(-14.0, 14.0, 0.5 * (previousState.x + state.x));
        addProjectedEdge(
            sampleValue, point, projected0, projected1,
            depth0, depth1, sizeValue,
            mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, lobe),
            mix(GC_GEOMETRY_PINK, GC_GEOMETRY_BLUE, lobe),
            1.0
        );
    }
    float core = gaussianPoint(point - center, sizeValue * 0.60);
    sampleValue.radiance += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.50)
        * core * 0.050;
    sampleValue.opacity = max(sampleValue.opacity, core * 0.14);
    return sampleValue;
}

GeometrySample renderGeometryType(
    int typeIndex,
    vec2 point,
    vec2 center,
    float sizeValue,
    float identity
) {
    if (typeIndex == 0) return renderTesseract(point, center, sizeValue, identity);
    if (typeIndex == 1) return renderGem(point, center, sizeValue, identity);
    if (typeIndex == 2) return renderOrbital(point, center, sizeValue, identity);
    if (typeIndex == 3) return renderCrystal(point, center, sizeValue, identity);
    if (typeIndex == 4) return renderTorusKnot(point, center, sizeValue, identity);
    if (typeIndex == 5) return renderMobius(point, center, sizeValue, identity);
    if (typeIndex == 6) return renderFractalTetra(point, center, sizeValue, identity);
    if (typeIndex == 7) return renderIcosahedralCage(point, center, sizeValue, identity);
    if (typeIndex == 8) return renderLorenz(point, center, sizeValue, identity);
    return emptyGeometrySample();
}

// =============================================================================
// BACKGROUND SCENE — CONFIGURED FAMILY INSTANCES
// =============================================================================

void renderGeometricCosmosBackground(out vec4 fragColor, vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    float aspect = resolution.x / resolution.y;
    vec2 point = scenePoint(fragCoord);
    float narrowScale = clamp(
        aspect / GC_NARROW_REFERENCE_ASPECT,
        GC_NARROW_MIN_SCALE,
        1.0
    );
#if GC_WALLPAPER_MODE
    float backgroundMask = 1.0;
    vec3 composite = vec3(0.0);
#else
    float backgroundMask = backgroundCellMask(terminalColor);
    vec3 composite = terminalColor.rgb;
#endif
    float sceneAlpha = 0.0;

    for (int objectIndex = 0; objectIndex < GC_CONFIGURED_OBJECT_COUNT; objectIndex++) {
        int typeIndex = geometryObjectType(objectIndex);
        if (typeIndex < 0) continue;
        float identity = float(objectIndex);
        vec2 centerUv = geometryUv(iTime, identity);
        vec2 center = (centerUv - 0.5) * vec2(aspect, 1.0);
        float randomScale = mix(
            1.0 - GC_SIZE_VARIATION,
            1.0 + GC_SIZE_VARIATION,
            hash12(vec2(identity, 19.37))
        );
        float sizeValue = GC_BASE_SIZE * narrowScale * typeScale(typeIndex)
            * randomScale * (1.0 + GC_BREATHE_AMOUNT * sin(
                iTime * GC_BREATHE_SPEED + identity * 1.73
            ));
        float cullDistance = length(point - center) / max(sizeValue, 0.0001);
        if (cullDistance >= GC_CULL_RADIUS) continue;
        float cullFeather = 1.0 - smoothstep(
            GC_CULL_RADIUS - GC_CULL_FEATHER,
            GC_CULL_RADIUS,
            cullDistance
        );
        GeometrySample sampleValue = renderGeometryType(
            typeIndex,
            point,
            center,
            sizeValue,
            identity
        );
        sampleValue.radiance *= cullFeather;
        sampleValue.opacity *= cullFeather;
        sampleValue.darken *= cullFeather;
        vec3 light = vec3(1.0) - exp(
            -max(sampleValue.radiance, vec3(0.0))
                * GC_EXPOSURE * GC_MASTER_BRIGHTNESS
        );
        composite = mix(
            composite,
            GC_VOID,
            sampleValue.darken * backgroundMask
        );
        composite += light * backgroundMask;
        sceneAlpha = max(
            sceneAlpha,
            backgroundMask * GC_ALPHA_MAX * saturate(
                sampleValue.opacity + luminance(light) * GC_LIGHT_ALPHA_GAIN
            )
        );
    }
#if GC_WALLPAPER_MODE
    fragColor = vec4(clamp(composite, 0.0, 1.0), sceneAlpha);
#else
    fragColor = vec4(
        clamp(composite, 0.0, 1.0),
        max(terminalColor.a, sceneAlpha)
    );
#endif
}

vec4 compositeGeometricCosmosBehindTerminal(
    vec4 wallpaperColor,
    vec4 terminalColor
) {
    float terminalCoverage = saturate(terminalColor.a);
    return vec4(
        mix(wallpaperColor.rgb, terminalColor.rgb, terminalCoverage),
        terminalColor.a
    );
}

// =============================================================================
// TIME-VARYING CURSOR TYPE SELECTION
// =============================================================================

int greatestCommonDivisor(int firstValue, int secondValue) {
    int first = max(firstValue, 1);
    int second = max(secondValue, 0);
    for (int iteration = 0; iteration < GC_OBJECT_LIMIT; iteration++) {
        if (second == 0) break;
        int remainder = first % second;
        first = second;
        second = remainder;
    }
    return first;
}

int randomCursorPermutationStep(float blockIndex, int enabledCount) {
#if GC_DEFAULT_FAMILY_LAYOUT
    int selector = int(floor(hash11(
        blockIndex + GCC_RANDOM_SEED + 17.31
    ) * 6.0));
    if (selector == 0) return 1;
    if (selector == 1) return 2;
    if (selector == 2) return 4;
    if (selector == 3) return 5;
    if (selector == 4) return 7;
    return 8;
#else
    if (enabledCount <= 1) return 1;
    int firstCandidate = 1 + int(floor(hash11(
        blockIndex + GCC_RANDOM_SEED + 17.31
    ) * float(enabledCount)));
    for (int offset = 0; offset < GC_OBJECT_LIMIT; offset++) {
        int candidate = 1 + (firstCandidate - 1 + offset) % enabledCount;
        if (greatestCommonDivisor(candidate, enabledCount) == 1) return candidate;
    }
    return 1;
#endif
}

int cursorScheduleCount() {
#if GCC_CURSOR_WEIGHT_BY_INSTANCES
    return configuredGeometryObjectCount();
#else
    return enabledTypeCount();
#endif
}

int cursorTypeForScheduleOrdinal(int ordinal) {
#if GCC_CURSOR_WEIGHT_BY_INSTANCES
    int scheduleCount = configuredGeometryObjectCount();
    if (scheduleCount <= 0) return -1;
    int wrappedOrdinal = ordinal % scheduleCount;
    if (wrappedOrdinal < 0) wrappedOrdinal += scheduleCount;
    return geometryObjectType(wrappedOrdinal);
#else
    return enabledTypeForOrdinal(ordinal);
#endif
}

int randomCursorType(float epoch) {
#if GC_DEFAULT_FAMILY_LAYOUT && GCC_CURSOR_WEIGHT_BY_INSTANCES == 0
    // Fast affine permutation for the default nine-family configuration.
    int epochIndex = max(int(epoch), 0);
    int position = epochIndex % GC_GEOMETRY_TYPE_COUNT;
    float blockIndex = floor(epoch / float(GC_GEOMETRY_TYPE_COUNT));
    int offset = int(floor(hash11(
        blockIndex + GCC_RANDOM_SEED
    ) * float(GC_GEOMETRY_TYPE_COUNT)));
    int stepValue = randomCursorPermutationStep(
        blockIndex,
        GC_GEOMETRY_TYPE_COUNT
    );
    return (offset + stepValue * position) % GC_GEOMETRY_TYPE_COUNT;
#else
    int scheduleCount = cursorScheduleCount();
    if (scheduleCount <= 0) return -1;
    // Each block is an affine permutation of the configured cursor slots.
    int epochIndex = max(int(epoch), 0);
    int position = epochIndex % scheduleCount;
    float blockIndex = floor(epoch / float(scheduleCount));
    int offset = int(floor(hash11(
        blockIndex + GCC_RANDOM_SEED
    ) * float(scheduleCount)));
    int stepValue = randomCursorPermutationStep(blockIndex, scheduleCount);
    int scheduleOrdinal = (offset + stepValue * position) % scheduleCount;
    return cursorTypeForScheduleOrdinal(scheduleOrdinal);
#endif
}

int cursorTypeForEpoch(float epoch) {
    int enabledCount = enabledTypeCount();
    if (enabledCount <= 0) return -1;
#if GCC_CURSOR_MODE == 0
    int requestedType = GCC_FIXED_TYPE % GC_GEOMETRY_TYPE_COUNT;
    if (requestedType < 0) requestedType += GC_GEOMETRY_TYPE_COUNT;
    return typeEnabled(requestedType) ? requestedType : enabledTypeForOrdinal(0);
#elif GCC_CURSOR_MODE == 2
    int scheduleCount = cursorScheduleCount();
    int sequenceIndex = int(epoch) % scheduleCount;
    if (sequenceIndex < 0) sequenceIndex += scheduleCount;
    return cursorTypeForScheduleOrdinal(sequenceIndex);
#else
    return randomCursorType(epoch);
#endif
}

void cursorTypePair(
    out int currentType,
    out int nextType,
    out float transition,
    out float epoch
) {
    float holdSeconds = max(GCC_SHAPE_HOLD_SECONDS, 0.10);
    epoch = floor(iTime / holdSeconds);
    float phaseSeconds = iTime - epoch * holdSeconds;
    currentType = cursorTypeForEpoch(epoch);
    nextType = cursorTypeForEpoch(epoch + 1.0);
    float transitionStart = max(
        holdSeconds - min(GCC_SHAPE_TRANSITION_SECONDS, holdSeconds),
        0.0
    );
    transition = smoothstep(transitionStart, holdSeconds, phaseSeconds);
}

bool geometryObjectMatchesCursor(int objectIndex, int cursorType) {
    if (cursorType < 0) return true;
    return geometryObjectType(objectIndex) == cursorType;
}

bool shouldLinkGeometryObject(int objectIndex, int cursorType) {
    if (
        objectIndex < 0
        || objectIndex >= configuredGeometryObjectCount()
        || objectIndex >= GCC_LINK_LIMIT
        || geometryObjectType(objectIndex) < 0
    ) return false;
#if GCC_LINK_TARGET_MODE == 1
    if (!geometryObjectMatchesCursor(objectIndex, cursorType)) return false;
#endif
#if GCC_LINK_ALL_OBJECTS == 0
    int firstLinkedIndex = 0;
#if GCC_LINK_TARGET_MODE == 1
    if (cursorType >= 0) {
        firstLinkedIndex = firstGeometryObjectIndexForType(cursorType);
    }
#endif
    if (firstLinkedIndex < 0 || objectIndex != firstLinkedIndex) return false;
#endif
    return true;
}

// =============================================================================
// ALL-FAMILY CURSOR STYLE — ENABLED MINIATURES IN A ROTATING CONSTELLATION
// =============================================================================

void renderAllFamilyCursor(
    inout vec3 effectLight,
    inout float effectOpacity,
    vec2 point,
    vec2 head,
    float cursorScale
) {
    int instanceCount = configuredGeometryObjectCount();
    if (instanceCount <= 0) return;
    vec2 instanceCenter[GC_OBJECT_LIMIT];
    int instanceType[GC_OBJECT_LIMIT];
    float countScale = clamp(
        sqrt(9.0 / float(instanceCount)),
        GCC_CONSTELLATION_COUNT_SCALE_MIN,
        GCC_CONSTELLATION_COUNT_SCALE_MAX
    );
    float orbitRotation = iTime * GCC_CONSTELLATION_ROTATION_SPEED;
    for (int instanceOrdinal = 0; instanceOrdinal < GC_CONFIGURED_OBJECT_COUNT; instanceOrdinal++) {
        int typeIndex = geometryObjectType(instanceOrdinal);
        instanceType[instanceOrdinal] = typeIndex;
        float instancePhase = float(instanceOrdinal) / float(instanceCount);
        float angle = orbitRotation + instancePhase * GC_TAU;
        instanceCenter[instanceOrdinal] = head + vec2(cos(angle), sin(angle))
            * cursorScale * GCC_CONSTELLATION_ORBIT_RADIUS;
        GeometrySample instanceShape = renderGeometryType(
            typeIndex,
            point,
            instanceCenter[instanceOrdinal],
            cursorScale * GCC_CONSTELLATION_MINI_SCALE * countScale
                * typeScale(typeIndex),
            91.0 + float(instanceOrdinal)
        );
        effectLight += instanceShape.radiance * GCC_CONSTELLATION_FAMILY_STRENGTH;
        effectOpacity = max(
            effectOpacity,
            instanceShape.opacity * GCC_CONSTELLATION_FAMILY_STRENGTH
        );
    }
    if (instanceCount > 1) {
        for (int instanceOrdinal = 0; instanceOrdinal < GC_CONFIGURED_OBJECT_COUNT; instanceOrdinal++) {
            int nextOrdinal = (instanceOrdinal + 1) % instanceCount;
            float ringDistance = segmentDistance(
                point,
                instanceCenter[instanceOrdinal],
                instanceCenter[nextOrdinal]
            );
            float ringCore = exp(-ringDistance / max(
                cursorScale * GCC_CONSTELLATION_RING_WIDTH,
                0.00012
            ));
            float ringGlow = exp(-ringDistance / max(
                cursorScale * GCC_CONSTELLATION_RING_GLOW_WIDTH,
                0.00032
            ));
            vec3 ringColor = mix(
                typeColorA(instanceType[instanceOrdinal]),
                typeColorB(instanceType[nextOrdinal]),
                0.55
            );
            effectLight += ringColor * GCC_CONSTELLATION_RING_STRENGTH * (
                ringCore + ringGlow * 0.20
            );
            effectOpacity = max(
                effectOpacity,
                ringCore * 0.28 + ringGlow * 0.06
            );
        }
    }
    float centralCore = gaussianPoint(point - head, cursorScale * 0.24);
    effectLight += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, 0.52)
        * centralCore * GCC_CONSTELLATION_CORE_STRENGTH;
    effectOpacity = max(effectOpacity, centralCore * 0.22);
}

// =============================================================================
// MOVEMENT-REACTIVE GEOMETRIC CURSOR
// =============================================================================

void applyGeometricCosmosCursor(inout vec4 scene, vec2 fragCoord) {
    if (iCursorVisible == 0 || enabledTypeCount() <= 0) return;
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 uv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, uv);
    vec2 headPixels = cursorCenterPixels(iCurrentCursor);
    vec2 tailPixels = cursorCenterPixels(iPreviousCursor);
    float cursorPixels = max(iCurrentCursor.z, iCurrentCursor.w);
    float movedPixels = length(headPixels - tailPixels);
    float age = saturate((iTime - iTimeCursorChange) / GCC_EFFECT_DURATION);
    if (
        cursorPixels <= 0.0
        || movedPixels <= cursorPixels * GCC_MIN_MOVEMENT_CELLS
        || age >= 1.0
    ) return;

    float movementFactor = smoothstep(
        cursorPixels * GCC_GROWTH_START_CELLS,
        cursorPixels * GCC_GROWTH_FULL_CELLS,
        movedPixels
    );
#if GCC_CURSOR_STYLE == 1
    // Style 1 depicts every family, so type matching deliberately becomes a no-op.
    int linkCursorType = -1;
    float linkTypeTransitionGain = 1.0;
#else
    int currentType, nextType;
    float shapeTransition, shapeEpoch;
    cursorTypePair(currentType, nextType, shapeTransition, shapeEpoch);
    // During a crossfade, follow the visually dominant geometry. Briefly dim the
    // ray around the midpoint so it does not appear to teleport between objects.
    int linkCursorType = shapeTransition < 0.5 ? currentType : nextType;
    float transitionMidpoint = 1.0 - abs(2.0 * shapeTransition - 1.0);
    float linkTypeTransitionGain = mix(
        1.0,
        GCC_LINK_TYPE_SWITCH_MIN_GAIN,
        transitionMidpoint
    );
#endif
    float linkMovementFactor = pow(movementFactor, GCC_LINK_MOVEMENT_POWER);
    float linkWidthScale = mix(
        GCC_LINK_WIDTH_MIN_SCALE,
        GCC_LINK_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkGlowWidthScale = mix(
        GCC_LINK_GLOW_WIDTH_MIN_SCALE,
        GCC_LINK_GLOW_WIDTH_MAX_SCALE,
        linkMovementFactor
    );
    float linkIntensityScale = mix(
        GCC_LINK_INTENSITY_MIN_SCALE,
        GCC_LINK_INTENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkOpacityScale = mix(
        GCC_LINK_OPACITY_MIN_SCALE,
        GCC_LINK_OPACITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashDensityScale = mix(
        GCC_LINK_DASH_DENSITY_MIN_SCALE,
        GCC_LINK_DASH_DENSITY_MAX_SCALE,
        linkMovementFactor
    );
    float linkDashSpeedScale = mix(
        GCC_LINK_DASH_SPEED_MIN_SCALE,
        GCC_LINK_DASH_SPEED_MAX_SCALE,
        linkMovementFactor
    );
    float linkCullScale = mix(
        GCC_LINK_CULL_MIN_SCALE,
        GCC_LINK_CULL_MAX_SCALE,
        linkMovementFactor
    );
    float cullRadius = cursorPixels * mix(
        GCC_CULL_RADIUS_MIN,
        GCC_CULL_RADIUS_MAX,
        movementFactor
    );
    bool nearCursor = segmentDistance(fragCoord, tailPixels, headPixels) <= cullRadius;
    float linkCull = max(
        cursorPixels * linkCullScale,
        GCC_LINK_CULL_MIN_PIXELS
    );
    bool nearAnyLink = false;
    vec2 linkObjectPixels[GC_OBJECT_LIMIT];
#if GCC_ENABLE_OBJECT_LINKS
    for (int linkIndex = 0; linkIndex < GC_CONFIGURED_OBJECT_COUNT; linkIndex++) {
        linkObjectPixels[linkIndex] = geometryUv(
            iTime,
            float(linkIndex)
        ) * resolution;
        if (!shouldLinkGeometryObject(linkIndex, linkCursorType)) continue;
        nearAnyLink = nearAnyLink || segmentDistance(
            fragCoord,
            headPixels,
            linkObjectPixels[linkIndex]
        ) <= linkCull;
    }
#endif
    if (!nearCursor && !nearAnyLink) return;

    vec2 point = scenePoint(fragCoord);
    vec2 head = scenePoint(headPixels);
    vec2 tail = scenePoint(tailPixels);
    vec2 movement = head - tail;
    vec2 direction = movement / max(length(movement), 0.000001);
    vec2 normal2d = vec2(-direction.y, direction.x);
    float cursorSize = cursorPixels / resolution.y;
    float life = pow(1.0 - age, GCC_FADE_POWER);
    float easedAge = 1.0 - pow(1.0 - age, 3.0);
#if GC_WALLPAPER_MODE
    float contentMask = 1.0;
#else
    float contentMask = mix(
        GCC_CONTENT_PROTECTION,
        1.0,
        backgroundCellMask(terminalColor)
    );
#endif
    vec3 effectLight = vec3(0.0);
    float effectOpacity = 0.0;

#if GCC_ENABLE_OBJECT_LINKS
    for (int linkIndex = 0; linkIndex < GC_CONFIGURED_OBJECT_COUNT; linkIndex++) {
        if (!shouldLinkGeometryObject(linkIndex, linkCursorType)) continue;
        float identity = float(linkIndex);
        int objectType = geometryObjectType(linkIndex);
        bool matchesCursorType = geometryObjectMatchesCursor(
            linkIndex,
            linkCursorType
        );
        vec2 objectPixels = linkObjectPixels[linkIndex];
        if (segmentDistance(fragCoord, headPixels, objectPixels) > linkCull) continue;
        vec2 objectPoint = scenePoint(objectPixels);
        float distanceToLink = segmentDistance(point, head, objectPoint);
        float alongLink = segmentParameter(point, head, objectPoint);
#if GCC_LINK_TARGET_MODE == 1
        float linkOrder = float(geometryObjectInstanceIndex(linkIndex));
#elif GCC_LINK_TARGET_MODE == 2
        float matchingOrder = float(geometryObjectInstanceIndex(linkIndex));
        float linkOrder = matchesCursorType ? matchingOrder : identity;
#else
        float linkOrder = identity;
#endif
        float linkStrength = pow(GCC_LINK_SECONDARY_FALLOFF, linkOrder);
        float contextWidthScale = 1.0;
        float contextGlowWidthScale = 1.0;
        float contextIntensityScale = 1.0;
        float contextOpacityScale = 1.0;
        float contextDashDensityScale = 1.0;
        float contextDashSpeedScale = 1.0;
#if GCC_LINK_TARGET_MODE == 2
        if (!matchesCursorType) {
            contextWidthScale = GCC_LINK_CONTEXT_WIDTH_SCALE;
            contextGlowWidthScale = GCC_LINK_CONTEXT_GLOW_WIDTH_SCALE;
            contextIntensityScale = GCC_LINK_CONTEXT_INTENSITY_SCALE;
            contextOpacityScale = GCC_LINK_CONTEXT_OPACITY_SCALE;
            contextDashDensityScale = GCC_LINK_CONTEXT_DASH_DENSITY_SCALE;
            contextDashSpeedScale = GCC_LINK_CONTEXT_DASH_SPEED_SCALE;
        }
#endif
        float typeSwitchGain = 1.0;
#if GCC_LINK_TARGET_MODE == 1 || GCC_LINK_TARGET_MODE == 2
        if (matchesCursorType) typeSwitchGain = linkTypeTransitionGain;
#endif
        vec3 linkColor = mix(
            typeColorA(objectType),
            typeColorB(objectType),
            saturate(alongLink * 0.78 + identity * GCC_LINK_COLOR_PHASE_STEP)
        );
        float dash = 0.64 + 0.36 * sin(
            alongLink * GCC_LINK_DASH_COUNT * linkDashDensityScale
                * contextDashDensityScale
            - iTime * GCC_LINK_DASH_SPEED * linkDashSpeedScale
                * contextDashSpeedScale
            + identity * 1.73
        );
        float core = exp(-distanceToLink / max(cursorSize * GCC_LINK_WIDTH * linkWidthScale * contextWidthScale, 0.0002));
        float glow = exp(-distanceToLink / max(cursorSize * GCC_LINK_GLOW_WIDTH * linkGlowWidthScale
            * contextGlowWidthScale, 0.0005));
        effectLight += linkColor * dash * linkStrength * linkIntensityScale
            * contextIntensityScale * typeSwitchGain * (
            core * GCC_LINK_CORE_STRENGTH + glow * GCC_LINK_GLOW_STRENGTH
        );
        effectOpacity = max(
            effectOpacity,
            linkStrength * linkOpacityScale * contextOpacityScale
                * typeSwitchGain * (core * 0.14 + glow * 0.035)
        );
    }
#endif

    if (nearCursor) {
#if GCC_ENABLE_TRAIL
        float trailDistance = segmentDistance(point, tail, head);
        float along = segmentParameter(point, tail, head);
        float trailWidth = cursorSize * mix(
            GCC_TRAIL_WIDTH_MIN,
            GCC_TRAIL_WIDTH_MAX,
            movementFactor
        );
        float trailCore = exp(-trailDistance / max(trailWidth, 0.0002))
            * smoothstep(0.0, 0.20, along);
        float trailGlow = exp(-trailDistance / max(
            trailWidth * GCC_TRAIL_GLOW_MULTIPLIER,
            0.0004
        )) * smoothstep(0.0, 0.16, along);
        vec3 trailColor = mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, along);
        effectLight += trailColor * (
            trailCore * GCC_TRAIL_CORE_STRENGTH
            + trailGlow * GCC_TRAIL_GLOW_STRENGTH
        );
        effectOpacity = max(effectOpacity, trailCore * 0.28 + trailGlow * 0.07);
#endif

        float cursorScale = cursorSize * mix(
            GCC_SIZE_MIN,
            GCC_SIZE_MAX,
            movementFactor
        ) * (1.0 + GCC_SIZE_PULSE * sin(age * GC_PI));
#if GCC_CURSOR_STYLE == 1
        renderAllFamilyCursor(
            effectLight,
            effectOpacity,
            point,
            head,
            cursorScale
        );
#else
        float currentIdentity = 31.0 + float(currentType) * 1.73;
        float nextIdentity = 31.0 + float(nextType) * 1.73;
        GeometrySample currentShape = renderGeometryType(
            currentType,
            point,
            head,
            cursorScale * typeScale(currentType),
            currentIdentity
        );
        GeometrySample nextShape = emptyGeometrySample();
        if (shapeTransition > 0.001) {
            nextShape = renderGeometryType(
                nextType,
                point,
                head,
                cursorScale * typeScale(nextType),
                nextIdentity
            );
        }
        vec3 shapeLight = mix(
            currentShape.radiance,
            nextShape.radiance,
            shapeTransition
        );
        float shapeOpacity = mix(
            currentShape.opacity,
            nextShape.opacity,
            shapeTransition
        );
        effectLight += shapeLight;
        effectOpacity = max(effectOpacity, shapeOpacity);

#if GCC_ECHO_COUNT > 0
        for (int echoIndex = 0; echoIndex < GCC_ECHO_COUNT; echoIndex++) {
            float echoProgress = saturate(
                easedAge - float(echoIndex) * 0.14
            );
            float echoScale = mix(
                GCC_ECHO_START_SCALE,
                GCC_ECHO_END_SCALE,
                echoProgress
            );
            GeometrySample echoShape = renderGeometryType(
                currentType,
                point,
                head,
                cursorScale * typeScale(currentType) * echoScale,
                currentIdentity + 32.0 + float(echoIndex)
            );
            float echoLife = (1.0 - echoProgress) * GCC_ECHO_STRENGTH;
            effectLight += echoShape.radiance * echoLife;
            effectOpacity = max(effectOpacity, echoShape.opacity * echoLife * 0.5);
        }
#endif
#endif

#if GCC_ENABLE_SPARKS && GCC_SPARK_COUNT > 0
        vec2 eventSeed = headPixels * 0.037 + tailPixels * 0.091;
        for (int sparkIndex = 0; sparkIndex < GCC_SPARK_COUNT; sparkIndex++) {
            float index = float(sparkIndex);
            float positionRandom = hash12(eventSeed + vec2(index * 11.7, index * 31.9));
            float sideRandom = hash12(eventSeed + vec2(index * 43.1, index * 7.3));
            vec2 sparkCenter = mix(tail, head, positionRandom)
                + normal2d * (sideRandom - 0.5) * cursorSize * GCC_SPARK_SPREAD;
            float spark = gaussianPoint(
                point - sparkCenter,
                cursorSize * GCC_SPARK_RADIUS
            );
            effectLight += mix(GC_GEOMETRY_BLUE, GC_GEOMETRY_PINK, sideRandom)
                * spark * GCC_SPARK_STRENGTH;
            effectOpacity = max(effectOpacity, spark * 0.18);
        }
#endif
    }

    effectLight *= life * contentMask * GCC_MASTER_BRIGHTNESS;
    scene.rgb += effectLight;
    scene.a = max(
        scene.a,
        life * contentMask * GCC_ALPHA_MAX * saturate(
            effectOpacity + luminance(effectLight) * GCC_ALPHA_GAIN
        )
    );
    float cursorCoverage = insideCursor(fragCoord, iCurrentCursor);
    scene = mix(scene, terminalColor, cursorCoverage);
    scene.rgb = clamp(scene.rgb, 0.0, 1.0);
}

// =============================================================================
// MAIN — NORMAL OR WALLPAPER COMPOSITION, OPTIONAL CURSOR STAGE
// =============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = max(iResolution.xy, vec2(1.0));
    vec2 terminalUv = clamp(fragCoord / resolution, vec2(0.0), vec2(1.0));
    vec4 terminalColor = texture(iChannel0, terminalUv);
#if GC_ENABLE_BACKGROUND_STAGE
    if (configuredGeometryObjectCount() <= 0) {
        fragColor = terminalColor;
    } else {
        vec4 geometryColor;
        renderGeometricCosmosBackground(geometryColor, fragCoord);
#if GC_WALLPAPER_MODE
        fragColor = compositeGeometricCosmosBehindTerminal(
            geometryColor,
            terminalColor
        );
#else
        fragColor = geometryColor;
#endif
    }
#else
    fragColor = terminalColor;
#endif
#if GC_ENABLE_CURSOR_STAGE
    applyGeometricCosmosCursor(fragColor, fragCoord);
#endif
#if GC_WALLPAPER_MODE
    fragColor.a = terminalColor.a;
#endif
}
