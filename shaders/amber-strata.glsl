// Amber Strata Clean: modern phosphor glow without CRT aging artifacts.
const float SHARPNESS = 0.20;
const float INNER_GLOW = 0.27;
const float OUTER_GLOW = 0.13;
const float TRAIL_STRENGTH = 0.20;

float cursorMask(vec2 fragCoord, vec4 cursor) {
    vec2 halfSize = max(cursor.zw * 0.5, vec2(1.0));
    vec2 center = cursor.xy + halfSize;
    vec2 edgeDistance = abs(fragCoord - center) - halfSize;
    float distance = length(max(edgeDistance, 0.0))
        + min(max(edgeDistance.x, edgeDistance.y), 0.0);
    return 1.0 - smoothstep(-1.0, 3.0, distance);
}

vec3 luminousPart(vec3 sampleColor) {
    // Remove the stable terminal background so only characters and UI glow.
    vec3 delta = max(sampleColor - iBackgroundColor, vec3(0.0));
    float energy = max(delta.r, max(delta.g, delta.b));
    return delta * smoothstep(0.025, 0.24, energy);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 px = 1.0 / iResolution.xy;
    vec4 source = texture(iChannel0, uv);

    // Restore a defined glyph core before adding light around it. This is a
    // restrained four-neighbor unsharp mask, gated to avoid ringing in the UI.
    vec3 adjacent = vec3(0.0);
    adjacent += texture(iChannel0, uv + vec2( 1.0,  0.0) * px).rgb;
    adjacent += texture(iChannel0, uv + vec2(-1.0,  0.0) * px).rgb;
    adjacent += texture(iChannel0, uv + vec2( 0.0,  1.0) * px).rgb;
    adjacent += texture(iChannel0, uv + vec2( 0.0, -1.0) * px).rgb;
    adjacent *= 0.25;
    vec3 detail = source.rgb - adjacent;
    vec3 sourceLight = luminousPart(source.rgb);
    float glyphEnergy = max(sourceLight.r, max(sourceLight.g, sourceLight.b));
    vec3 crispSource = max(source.rgb + detail * SHARPNESS
        * smoothstep(0.02, 0.16, glyphEnergy), vec3(0.0));

    // A close, restrained halo keeps phosphor character without softening type.
    vec3 inner = vec3(0.0);
    inner += luminousPart(texture(iChannel0, uv + vec2( 1.5,  0.0) * px).rgb);
    inner += luminousPart(texture(iChannel0, uv + vec2(-1.5,  0.0) * px).rgb);
    inner += luminousPart(texture(iChannel0, uv + vec2( 0.0,  1.5) * px).rgb);
    inner += luminousPart(texture(iChannel0, uv + vec2( 0.0, -1.5) * px).rgb);
    inner += luminousPart(texture(iChannel0, uv + vec2( 1.2,  1.2) * px).rgb);
    inner += luminousPart(texture(iChannel0, uv + vec2(-1.2,  1.2) * px).rgb);
    inner += luminousPart(texture(iChannel0, uv + vec2( 1.2, -1.2) * px).rgb);
    inner += luminousPart(texture(iChannel0, uv + vec2(-1.2, -1.2) * px).rgb);
    inner *= 0.125;

    vec3 outer = vec3(0.0);
    outer += luminousPart(texture(iChannel0, uv + vec2( 4.5,  0.0) * px).rgb);
    outer += luminousPart(texture(iChannel0, uv + vec2(-4.5,  0.0) * px).rgb);
    outer += luminousPart(texture(iChannel0, uv + vec2( 0.0,  4.5) * px).rgb);
    outer += luminousPart(texture(iChannel0, uv + vec2( 0.0, -4.5) * px).rgb);
    outer += luminousPart(texture(iChannel0, uv + vec2( 3.2,  3.2) * px).rgb);
    outer += luminousPart(texture(iChannel0, uv + vec2(-3.2,  3.2) * px).rgb);
    outer += luminousPart(texture(iChannel0, uv + vec2( 3.2, -3.2) * px).rgb);
    outer += luminousPart(texture(iChannel0, uv + vec2(-3.2, -3.2) * px).rgb);
    outer *= 0.125;

    vec3 amberGlow = vec3(1.0, 0.48, 0.09);
    vec3 color = crispSource;
    color += inner * amberGlow * INNER_GLOW;
    color += outer * amberGlow * OUTER_GLOW;

    float age = max(iTime - iTimeCursorChange, 0.0);
    float previous = cursorMask(fragCoord, iPreviousCursor);
    float current = cursorMask(fragCoord, iCurrentCursor);
    color += amberGlow * previous * (1.0 - current) * exp(-age * 9.0)
        * TRAIL_STRENGTH * float(iFocus);

    fragColor = vec4(max(color, vec3(0.0)), source.a);
}
