# Amber Strata Agent Adapter SDK

The adapter SDK lets an agent-specific fixed UI surface join Amber Strata
without forking the core shader. The terminal palette, typography, glow,
cursor, transparency, and native Ghostty shell remain part of Core. An adapter
only identifies a surface color range and maps that range to the Amber Strata
glass color.

## Create an adapter

```sh
python3 adapter-sdk/create_adapter.py claude-code --name "Claude Code"
```

This creates `adapters/claude-code.json`. It never overwrites an existing
adapter. Restart the settings panel and the new adapter appears under
**Interface compatibility**, or apply it directly:

```sh
./agent-profile.sh claude-code
```

## Adapter schema

```json
{
  "schema_version": 1,
  "id": "example-agent",
  "name": "Example Agent",
  "description": "Maps the agent composer into Amber Strata glass.",
  "enabled": true,
  "detection": {
    "chroma_start": 0.035,
    "chroma_end": 0.14,
    "luminance_start": 0.008,
    "luminance_full": 0.018,
    "luminance_fade": 0.12,
    "luminance_end": 0.22
  },
  "panel_color": [0.105, 0.034, 0.0]
}
```

All color values are normalized linear RGB shader values from `0.0` through
`1.0`, not ordinary 8-bit sRGB values. The detection window selects restrained
low-chroma surfaces while preserving bright text and the terminal background.

- `chroma_start` and `chroma_end` control how neutral the source surface must be.
- The four luminance values create a soft dark-to-light selection window.
- `panel_color` is the replacement surface before desktop transparency blends in.
- Set `enabled` to `false` for an application-neutral adapter such as Core.

Thresholds must be ordered and remain between `0.0` and `1.0`. The renderer
validates the complete file and refuses invalid values before replacing the
active shader.

## Calibrate safely

1. Start from the generated adapter and open the target agent in Ghostty.
2. Change one detection range at a time in small increments.
3. Run `./agent-profile.sh YOUR_ID` after each change.
4. Check the composer, normal text, selections, code blocks, and empty terminal.
5. Narrow the ranges if unrelated pixels change color.
6. Test with glow both enabled and disabled.

An adapter cannot change an agent's layout, padding, borders, or true corner
geometry. Those belong to the agent. It can integrate fixed surface colors
without making the universal theme depend on that application.

## Validate without changing the live profile

```sh
python3 adapter-sdk/render_adapter.py \
  --source shaders/amber-strata.glsl \
  --adapter adapters/YOUR_ID.json \
  --glow-mode glow-on \
  --output /tmp/amber-strata-adapter-test.glsl
```

Then inspect the generated shader or test it in a separate Ghostty config.
Commit the JSON file with a screenshot and a short note identifying the tested
agent version so other users can reproduce the result.
