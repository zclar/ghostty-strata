// Amber Strata cursor-only profile: no character glow.
const float CURSOR_PULSE_SECONDS = 1.45;
const float CURSOR_MIN_OPACITY = 0.0;
const float CURSOR_MAX_OPACITY = 1.0;

float cursorMask(vec2 fragCoord, vec4 cursor) {
    vec2 halfSize = max(cursor.zw * 0.5, vec2(1.0));
    vec2 center = cursor.xy + vec2(halfSize.x, -halfSize.y);
    vec2 edgeDistance = abs(fragCoord - center) - halfSize;
    float distance = length(max(edgeDistance, 0.0))
        + min(max(edgeDistance.x, edgeDistance.y), 0.0);
    return 1.0 - smoothstep(-1.0, 3.0, distance);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 source = texture(iChannel0, uv);
    vec3 delta = max(source.rgb - iBackgroundColor, vec3(0.0));
    float glyphEnergy = max(delta.r, max(delta.g, delta.b));

    float cursorWave = 0.5 + 0.5 * sin(
        iTime * 6.28318530718 / CURSOR_PULSE_SECONDS - 1.57079632679
    );
    cursorWave = cursorWave * cursorWave * (3.0 - 2.0 * cursorWave);
    float cursorOpacity = mix(
        CURSOR_MIN_OPACITY,
        CURSOR_MAX_OPACITY,
        cursorWave
    );

    float cursorGlyph = smoothstep(0.035, 0.22, glyphEnergy);
    vec3 cursorSurface = mix(iCursorColor, iCursorText, cursorGlyph);
    float cursorCoverage = cursorMask(fragCoord, iCurrentCursor)
        * cursorOpacity * float(iCursorVisible.x);
    vec3 color = mix(source.rgb, cursorSurface, cursorCoverage);
    fragColor = vec4(color, source.a);
}
