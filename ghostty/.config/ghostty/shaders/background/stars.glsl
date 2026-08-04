// transparent background
const bool transparent = true;

// terminal contents luminance threshold to be considered background
const float threshold = 0.28;

// divisions of grid
const float repeats = 42.;

// number of layers
const float layers = 11.;

// star colours
const vec3 blue   = vec3(51., 64., 195.) / 255.;
const vec3 cyan   = vec3(117., 250., 254.) / 255.;
const vec3 white  = vec3(255., 255., 255.) / 255.;
const vec3 yellow = vec3(251., 245., 44.) / 255.;
const vec3 red    = vec3(247., 2., 20.) / 255.;

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float N21(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

vec2 N22(vec2 p) {
    float n = N21(p);
    return vec2(n, N21(p + n));
}

mat2 scale(vec2 _scale) {
    return mat2(_scale.x, 0.0,
                0.0, _scale.y);
}

vec3 starTint(vec2 seed) {
    float r = N21(seed);

    if (r < 0.78) return white;
    if (r < 0.88) return mix(white, cyan, 0.6);
    if (r < 0.95) return mix(white, yellow, 0.65);
    return mix(white, red, 0.45);
}

vec3 stars(vec2 uv, float offset) {
    float timeScale = -(iTime + offset) / layers;
    float trans = fract(timeScale);
    float newRnd = floor(timeScale);
    vec3 col = vec3(0.0);

    uv -= vec2(0.5);
    uv = scale(vec2(trans)) * uv;
    uv += vec2(0.5);

    uv.x *= iResolution.x / iResolution.y;
    uv *= repeats;

    vec2 ipos = floor(uv);
    uv = fract(uv);

    vec2 rndXY = N22(newRnd + ipos * (offset + 1.0)) * 0.9 + 0.05;
    float rndSize = N21(ipos + newRnd) * 120.0 + 240.0;

    vec2 j = (rndXY - uv) * rndSize;
    float sparkle = 0.08 / dot(j, j);
    sparkle = min(sparkle, 1.25);

    vec3 tint = starTint(ipos + rndXY + newRnd);
    col += tint * sparkle;

    // occasional slightly brighter stars
    float bigStar = step(0.985, N21(ipos + newRnd * 3.17));
    float halo = 1.0 / (1.0 + dot(j * 0.35, j * 0.35));
    col += tint * halo * bigStar * 0.35;

    col *= smoothstep(1.0, 0.82, trans);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    vec3 col = vec3(0.0);

    for (float i = 0.0; i < layers; i++) {
        col += stars(uv, i);
    }

    vec4 terminalColor = texture(iChannel0, uv);

    if (transparent) {
        col += terminalColor.rgb;
    }

    float mask = 1.0 - step(threshold, luminance(terminalColor.rgb));

    // darken the background where stars are allowed
    vec3 darkBase = mix(terminalColor.rgb, terminalColor.rgb * 0.10, mask);

    vec3 blendedColor = darkBase + col * mask;

    fragColor = vec4(blendedColor, terminalColor.a);
}
