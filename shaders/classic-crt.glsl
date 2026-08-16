// Amber Strata Classic: optional aged-CRT artifacts layered over clean glow.
// Select this instead of amber-strata.glsl if you want the deliberately retro pass.
const float SCAN_STRENGTH = 0.075;
const float FLICKER_STRENGTH = 0.012;
const float GRAIN_STRENGTH = 0.010;
const float VIGNETTE_STRENGTH = 0.16;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 source = texture(iChannel0, uv);
    vec3 color = source.rgb;

    float scan = 0.5 + 0.5 * sin((fragCoord.y + iTime * 3.0) * 3.14159265);
    color *= 1.0 - scan * SCAN_STRENGTH;

    float flicker = sin(iTime * 7.1) * 0.55 + sin(iTime * 13.7) * 0.25;
    color *= 1.0 + flicker * FLICKER_STRENGTH;
    float grain = hash21(fragCoord + vec2(float(iFrame), iTime * 31.0)) - 0.5;
    color += grain * GRAIN_STRENGTH * vec3(1.0, 0.58, 0.16);

    vec2 centered = uv * 2.0 - 1.0;
    float edge = clamp(1.0 - dot(centered * vec2(0.86, 0.72), centered), 0.0, 1.0);
    color *= mix(1.0 - VIGNETTE_STRENGTH, 1.0, smoothstep(0.0, 0.9, edge));
    fragColor = vec4(max(color, vec3(0.0)), source.a);
}
