// Amber Strata: restrained CRT post-processing for Ghostty.
// Tune these strengths in the 0.0–1.0 range; use 0.0 to disable an effect.
const float BLOOM_STRENGTH   = 0.26;
const float SCAN_STRENGTH    = 0.075;
const float FLICKER_STRENGTH = 0.012;
const float GRAIN_STRENGTH   = 0.010;
const float VIGNETTE_STRENGTH = 0.16;
const float TRAIL_STRENGTH   = 0.24;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float cursorMask(vec2 fragCoord, vec4 cursor) {
    vec2 halfSize = max(cursor.zw * 0.5, vec2(1.0));
    vec2 center = cursor.xy + halfSize;
    vec2 distanceToEdge = abs(fragCoord - center) - halfSize;
    float signedDistance = length(max(distanceToEdge, 0.0))
        + min(max(distanceToEdge.x, distanceToEdge.y), 0.0);
    return 1.0 - smoothstep(-1.0, 2.0, signedDistance);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 resolution = iResolution.xy;
    vec2 uv = fragCoord / resolution;
    vec2 texel = 1.0 / resolution;
    vec4 source = texture(iChannel0, uv);

    // Small cross-shaped convolution: a warm phosphor halo without blur-heavy text.
    vec3 bloom = vec3(0.0);
    bloom += texture(iChannel0, uv + vec2( 2.0,  0.0) * texel).rgb;
    bloom += texture(iChannel0, uv + vec2(-2.0,  0.0) * texel).rgb;
    bloom += texture(iChannel0, uv + vec2( 0.0,  2.0) * texel).rgb;
    bloom += texture(iChannel0, uv + vec2( 0.0, -2.0) * texel).rgb;
    bloom += texture(iChannel0, uv + vec2( 4.0,  0.0) * texel).rgb * 0.5;
    bloom += texture(iChannel0, uv + vec2(-4.0,  0.0) * texel).rgb * 0.5;
    bloom += texture(iChannel0, uv + vec2( 0.0,  4.0) * texel).rgb * 0.5;
    bloom += texture(iChannel0, uv + vec2( 0.0, -4.0) * texel).rgb * 0.5;
    bloom /= 6.0;

    // Only luminous pixels contribute strongly, preserving the brown-black field.
    float bloomGate = smoothstep(0.055, 0.42, max(bloom.r, max(bloom.g, bloom.b)));
    vec3 color = source.rgb + bloom * bloomGate * BLOOM_STRENGTH;

    // Two-pixel scanline rhythm with a very slow vertical phase drift.
    float scan = 0.5 + 0.5 * sin((fragCoord.y + iTime * 3.0) * 3.14159265);
    color *= 1.0 - scan * SCAN_STRENGTH;

    // Independent low-frequency phosphor breathing and fine film grain.
    float flicker = sin(iTime * 7.1) * 0.55 + sin(iTime * 13.7) * 0.25;
    color *= 1.0 + flicker * FLICKER_STRENGTH;
    float grain = hash21(fragCoord + vec2(float(iFrame), iTime * 31.0)) - 0.5;
    color += grain * GRAIN_STRENGTH * vec3(1.0, 0.58, 0.16);

    // Fade the previous cursor briefly as it moves to make jumps easy to follow.
    float cursorAge = max(iTime - iTimeCursorChange, 0.0);
    float trailLife = exp(-cursorAge * 8.0) * TRAIL_STRENGTH;
    float previousCursor = cursorMask(fragCoord, iPreviousCursor);
    float currentCursor = cursorMask(fragCoord, iCurrentCursor);
    color += vec3(1.0, 0.38, 0.035) * previousCursor * (1.0 - currentCursor)
        * trailLife * float(iFocus);

    // Soft edge falloff evokes glass while keeping the rectangular modern UI.
    vec2 centered = uv * 2.0 - 1.0;
    float edge = clamp(1.0 - dot(centered * vec2(0.86, 0.72), centered), 0.0, 1.0);
    color *= mix(1.0 - VIGNETTE_STRENGTH, 1.0, smoothstep(0.0, 0.9, edge));

    fragColor = vec4(max(color, vec3(0.0)), source.a);
}
