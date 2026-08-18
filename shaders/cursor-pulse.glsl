// Amber Strata cursor-only profile: no character glow.
const float BACKGROUND_ALPHA = 0.70;
const float CURSOR_PULSE_SECONDS = 1.45;
const float CURSOR_MIN_OPACITY = 0.0;
const float CURSOR_MAX_OPACITY = 1.0;
// Core is application-neutral; profile.sh enables an optional agent adapter.
const float AGENT_SURFACE_ADAPTER = 0.0;
const float ADAPTER_CHROMA_START = 0.035;
const float ADAPTER_CHROMA_END = 0.140;
const float ADAPTER_LUMA_START = 0.008;
const float ADAPTER_LUMA_FULL = 0.018;
const float ADAPTER_LUMA_FADE = 0.120;
const float ADAPTER_LUMA_END = 0.220;
const vec3 ADAPTER_PANEL_COLOR = vec3(0.105, 0.034, 0.000);

float cursorMask(vec2 fragCoord, vec4 cursor) {
    vec2 halfSize = max(cursor.zw * 0.5, vec2(1.0));
    vec2 center = cursor.xy + vec2(halfSize.x, -halfSize.y);
    vec2 edgeDistance = abs(fragCoord - center) - halfSize;
    float distance = length(max(edgeDistance, 0.0))
        + min(max(edgeDistance.x, edgeDistance.y), 0.0);
    return 1.0 - smoothstep(-1.0, 3.0, distance);
}

vec2 cursorCenter(vec4 cursor) {
    return cursor.xy + vec2(cursor.z * 0.5, -cursor.w * 0.5);
}

float matrixCursorTrail(vec2 fragCoord) {
    vec2 from = cursorCenter(iPreviousCursor);
    vec2 to = cursorCenter(iCurrentCursor);
    float moved = smoothstep(2.0, 8.0, length(to - from));
    float trail = 0.0;
    for (int index = 1; index <= 6; ++index) {
        float position = float(index) / 7.0;
        vec2 node = mix(from, to, position);
        float nodeMask = 1.0 - smoothstep(1.1, 2.5, length(fragCoord - node));
        trail += nodeMask * (1.0 - position * 0.58);
    }
    return min(trail, 1.0) * moved;
}

float tuiSurfaceMask(vec3 sampleColor) {
    float high = max(sampleColor.r, max(sampleColor.g, sampleColor.b));
    float low = min(sampleColor.r, min(sampleColor.g, sampleColor.b));
    float chroma = high - low;
    float luminance = dot(sampleColor, vec3(0.2126, 0.7152, 0.0722));
    float lowChroma = 1.0 - smoothstep(
        ADAPTER_CHROMA_START, ADAPTER_CHROMA_END, chroma
    );
    float midDark = smoothstep(ADAPTER_LUMA_START, ADAPTER_LUMA_FULL, luminance)
        * (1.0 - smoothstep(ADAPTER_LUMA_FADE, ADAPTER_LUMA_END, luminance));
    return lowChroma * midDark * AGENT_SURFACE_ADAPTER;
}

vec3 themedTuiSurface(vec3 sampleColor) {
    return mix(sampleColor, ADAPTER_PANEL_COLOR, tuiSurfaceMask(sampleColor));
}

float roundedTuiSurfaceMask(vec2 uv, vec2 px) {
    vec2 radius = px * 9.0;
    float coverage = tuiSurfaceMask(texture(iChannel0, uv).rgb) * 4.0;
    coverage += tuiSurfaceMask(texture(iChannel0, uv + vec2( radius.x, 0.0)).rgb);
    coverage += tuiSurfaceMask(texture(iChannel0, uv + vec2(-radius.x, 0.0)).rgb);
    coverage += tuiSurfaceMask(texture(iChannel0, uv + vec2(0.0,  radius.y)).rgb);
    coverage += tuiSurfaceMask(texture(iChannel0, uv + vec2(0.0, -radius.y)).rgb);
    coverage += tuiSurfaceMask(texture(iChannel0, uv + vec2( radius.x,  radius.y)).rgb);
    coverage += tuiSurfaceMask(texture(iChannel0, uv + vec2(-radius.x,  radius.y)).rgb);
    coverage += tuiSurfaceMask(texture(iChannel0, uv + vec2( radius.x, -radius.y)).rgb);
    coverage += tuiSurfaceMask(texture(iChannel0, uv + vec2(-radius.x, -radius.y)).rgb);
    return smoothstep(0.56, 0.82, coverage / 12.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 px = 1.0 / iResolution.xy;
    vec4 source = texture(iChannel0, uv);
    float rawPanel = tuiSurfaceMask(source.rgb);
    float roundedPanel = roundedTuiSurfaceMask(uv, px) * rawPanel;
    vec3 themedSource = mix(source.rgb, iBackgroundColor, rawPanel);
    themedSource = mix(
        themedSource,
        ADAPTER_PANEL_COLOR,
        roundedPanel
    );
    vec3 delta = max(themedSource - iBackgroundColor, vec3(0.0));
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
    vec3 cursorSurface = mix(iCursorColor, iBackgroundColor, cursorGlyph);
    float cursorCoverage = cursorMask(fragCoord, iCurrentCursor)
        * cursorOpacity * float(iCursorVisible.x);
    vec3 color = mix(themedSource, cursorSurface, cursorCoverage);
    float age = max(iTime - iTimeCursorChange, 0.0);
    float matrixTrail = matrixCursorTrail(fragCoord)
        * exp(-age * 11.0) * float(iFocus);
    color += vec3(1.0, 0.54, 0.12) * matrixTrail * 0.62;
    fragColor = vec4(color, BACKGROUND_ALPHA);
}
