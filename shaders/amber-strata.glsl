// Amber Strata Clean: modern phosphor glow without CRT aging artifacts.
const float SHARPNESS = 0.20;
const float GLOW_STRENGTH = 1.02;
const float GLOW_RADIUS = 1.65;
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

    // A fractional-pixel 5x5 Gaussian produces a continuous halo. Bilinear
    // texture sampling blends between physical pixels so no sample ring or
    // staircase pattern is visible around diagonal and curved glyph edges.
    vec3 softGlow = vec3(0.0);
    float totalWeight = 0.0;
    for (int y = -2; y <= 2; ++y) {
        for (int x = -2; x <= 2; ++x) {
            vec2 samplePoint = vec2(float(x), float(y));
            float weight = exp(-dot(samplePoint, samplePoint) * 0.42);
            vec2 offset = samplePoint * GLOW_RADIUS * px;
            softGlow += luminousPart(texture(iChannel0, uv + offset).rgb) * weight;
            totalWeight += weight;
        }
    }
    softGlow /= totalWeight;

    // Put the glow primarily into dark pixels around the glyph. The bright
    // core stays sharpened instead of being blurred or overexposed.
    float core = smoothstep(0.025, 0.22, glyphEnergy);
    float haloSpace = 1.0 - core * 0.82;
    vec3 amberGlow = vec3(1.0, 0.54, 0.12);
    vec3 color = crispSource;
    color += softGlow * amberGlow * GLOW_STRENGTH * haloSpace;

    float age = max(iTime - iTimeCursorChange, 0.0);
    float previous = cursorMask(fragCoord, iPreviousCursor);
    float current = cursorMask(fragCoord, iCurrentCursor);
    color += amberGlow * previous * (1.0 - current) * exp(-age * 9.0)
        * TRAIL_STRENGTH * float(iFocus);

    fragColor = vec4(max(color, vec3(0.0)), source.a);
}
