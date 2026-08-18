// Amber Strata Clean: modern phosphor glow without CRT aging artifacts.
const float SHARPNESS = 0.20;
const float BACKGROUND_ALPHA = 0.70;
const float GLOW_STRENGTH = 1.28;
const float GLOW_RADIUS = 1.80;
const float TYPE_PULSE_STRENGTH = 0.48;
// Core is application-neutral; profile.sh enables an optional agent adapter.
const float AGENT_SURFACE_ADAPTER = 0.0;
const float TYPE_PULSE_RADIUS = 34.0;
const float TYPING_GLOW_PEAK = 1.28;
const float TYPING_GLOW_DECAY = 2.40;
const float TRAIL_STRENGTH = 0.14;
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

vec3 luminousPart(vec3 sampleColor) {
    // Remove the stable terminal background so only characters and UI glow.
    vec3 delta = max(sampleColor - iBackgroundColor, vec3(0.0));
    float energy = max(delta.r, max(delta.g, delta.b));
    // Ignore restrained dark UI surfaces (for example a TUI composer using
    // ANSI bright-black) so panels stay crisp while amber glyphs still bloom.
    return delta * smoothstep(0.10, 0.30, energy);
}

float tuiSurfaceMask(vec3 sampleColor) {
    float high = max(sampleColor.r, max(sampleColor.g, sampleColor.b));
    float low = min(sampleColor.r, min(sampleColor.g, sampleColor.b));
    float chroma = high - low;
    float luminance = dot(sampleColor, vec3(0.2126, 0.7152, 0.0722));
    // Ghostty supplies shader colors in linear-corrected space. These bounds
    // correspond to the composer's ~66/60/75 sRGB panel after conversion.
    float lowChroma = 1.0 - smoothstep(0.035, 0.14, chroma);
    float midDark = smoothstep(0.008, 0.018, luminance)
        * (1.0 - smoothstep(0.12, 0.22, luminance));
    return lowChroma * midDark * AGENT_SURFACE_ADAPTER;
}

vec3 themedTuiSurface(vec3 sampleColor) {
    // Codex emits a fixed purple-gray composer. Convert it to the translucent
    // burnt-amber panel used by the Konsole reference while preserving text.
    // Pre-compensated so translucent wallpaper blending lands near the
    // Konsole reference's ~108/71/26 sRGB surface.
    vec3 composerAmber = vec3(0.105, 0.034, 0.000);
    return mix(sampleColor, composerAmber, tuiSurfaceMask(sampleColor));
}

float roundedTuiSurfaceMask(vec2 uv, vec2 px) {
    // Average a compact neighborhood around the detected TUI background.
    // Straight edges survive while low-coverage corners recede, producing a
    // visible 9 px radius from otherwise rectangular terminal cell backgrounds.
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
        vec3(0.105, 0.034, 0.000),
        roundedPanel
    );
    float age = max(iTime - iTimeCursorChange, 0.0);

    // Restore a defined glyph core before adding light around it. This is a
    // restrained four-neighbor unsharp mask, gated to avoid ringing in the UI.
    vec3 adjacent = vec3(0.0);
    adjacent += themedTuiSurface(texture(iChannel0, uv + vec2( 1.0,  0.0) * px).rgb);
    adjacent += themedTuiSurface(texture(iChannel0, uv + vec2(-1.0,  0.0) * px).rgb);
    adjacent += themedTuiSurface(texture(iChannel0, uv + vec2( 0.0,  1.0) * px).rgb);
    adjacent += themedTuiSurface(texture(iChannel0, uv + vec2( 0.0, -1.0) * px).rgb);
    adjacent *= 0.25;
    vec3 detail = themedSource - adjacent;
    vec3 sourceLight = luminousPart(themedSource);
    float glyphEnergy = max(sourceLight.r, max(sourceLight.g, sourceLight.b));
    vec3 crispSource = max(themedSource + detail * SHARPNESS
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
    // Every typed character moves the cursor and resets iTimeCursorChange.
    // Restore full phosphor energy immediately, then settle to the selected
    // profile's quieter idle strength until the next character arrives.
    float typingGlowEnvelope = exp(-age * TYPING_GLOW_DECAY);
    float liveGlowStrength = mix(
        GLOW_STRENGTH,
        TYPING_GLOW_PEAK,
        typingGlowEnvelope
    );
    color += softGlow * amberGlow * liveGlowStrength * haloSpace;

    float previous = cursorMask(fragCoord, iPreviousCursor);
    float current = cursorMask(fragCoord, iCurrentCursor);

    // Ghostty's native cursor is transparent; draw the complete block here so
    // its actual opacity can breathe rather than merely changing brightness.
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
    float cursorCoverage = current * cursorOpacity * float(iCursorVisible.x);
    color = mix(color, cursorSurface, cursorCoverage);

    // A short six-node matrix trail makes cursor movement feel intentional
    // without smearing the terminal grid or introducing CRT artifacts.
    float matrixTrail = matrixCursorTrail(fragCoord)
        * exp(-age * 11.0) * float(iFocus);
    color += amberGlow * matrixTrail * 0.62;

    // Cursor movement accompanies normal typing. Briefly energize the newly
    // written area, then let it fall away like phosphor afterglow.
    vec2 pulseCenter = cursorCenter(iCurrentCursor);
    float pulseDistance = length((fragCoord - pulseCenter)
        / vec2(TYPE_PULSE_RADIUS, TYPE_PULSE_RADIUS * 0.72));
    float pulseShape = exp(-pulseDistance * pulseDistance * 2.4);
    float pulseDecay = exp(-age * 5.2);
    float typingPulse = pulseShape * pulseDecay
        * TYPE_PULSE_STRENGTH * float(iFocus);
    color += (softGlow * 0.72 + amberGlow * previous * 0.18)
        * amberGlow * typingPulse;

    color += amberGlow * previous * (1.0 - current) * exp(-age * 9.0)
        * TRAIL_STRENGTH * float(iFocus);

    // Ghostty's shader input is an opaque texture even when window background
    // opacity is configured. Restore translucency only for background pixels;
    // glyphs and the animated cursor remain solid and sharply readable.
    fragColor = vec4(max(color, vec3(0.0)), BACKGROUND_ALPHA);
}
