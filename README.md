# Ghostty Strata

Amber Strata is a modern amber-CRT theme for [Ghostty](https://ghostty.org/).
It keeps the exact palette and Terminus character of the original Konsole
profile, then adds clean GPU-rendered phosphor bloom, an animated cursor
afterglow, and a matching modern application shell.

The result is deliberately restrained: retro atmosphere without bending the
terminal grid or making everyday text difficult to read.

## What is included

- `config.ghostty` — complete Ghostty setup, including typography and window UI
- `themes/Amber Strata` — the portable 16-color amber palette
- `shaders/amber-strata.glsl` — clean phosphor glow and cursor animation
- `shaders/classic-crt.glsl` — optional scanlines, grain, flicker, and vignette
- `styles/amber-strata.css` — tabs, titlebar, controls, menus, and overlays
- `install.sh` — safe installer that backs up an existing Ghostty config

The palette is a direct port of `CoolRetroTermAmber.colorscheme`. Terminus
(TTF), 15 pt, matches the latest Konsole profile.

## Requirements

- Ghostty 1.2.0 or newer (cursor shader uniforms were added in 1.2)
- Terminus (TTF), recommended for the intended look

On Ubuntu and Debian, Terminus is available from the package manager:

```bash
sudo apt install fonts-terminus
```

Ghostty still works if the font is absent, but it will substitute another
monospace face.

## Install

Clone the repository, then run the installer:

```bash
git clone https://github.com/zclar/ghostty-strata.git
cd ghostty-strata
./install.sh
```

The installer creates links under `~/.config/ghostty`, keeping the cloned
repository as the source of truth. If `config.ghostty` already exists, it is
moved to a timestamped backup first. Restart Ghostty after the first install.
Later changes can be loaded with `Ctrl+Shift+,`.

To update:

```bash
cd ghostty-strata
git pull --ff-only
```

## Preview without installing

From this directory:

```bash
ghostty --config-file="$(pwd)/config.ghostty"
```

If a shader ever renders a black window, start Ghostty with the base theme only:

```bash
ghostty --config-file="$(pwd)/themes/Amber Strata"
```

## Clean and classic effects

The default shader is deliberately clean and crisp: no noise, scanlines,
flicker, vignette, distortion, or artificial contrast. A restrained sharpen
pass preserves the glyph core before a fractional-pixel Gaussian phosphor halo
is applied, avoiding pixelated rings around curved and diagonal characters.
Cursor movement triggers a localized phosphor pulse, giving typed characters a
brief ignition and smooth afterglow instead of a simple cursor smear.
The active cursor is shader-drawn as a solid block and breathes smoothly from
fully transparent to fully opaque; Ghostty's native cursor is transparent and
hard blinking is disabled so the animation remains continuous.

## Toggle the glow

Two settings profiles are included. Both retain the Amber interface and the
animated block cursor; `glow-off` removes character glow and the typing pulse.

```bash
./profile.sh glow-on
./profile.sh glow-soft
./profile.sh glow-off
```

You can also press `Ctrl+Shift+P` inside Ghostty and choose **Amber Strata: Glow
On** or **Amber Strata: Glow Off** while at a normal shell prompt. Ghostty does
not expose an action that executes a profile switch directly, so the palette
entry enters the installed command into that prompt. The switch updates the
installed `shaders/active.glsl`, which Ghostty hot-reloads immediately. The
active selection lives under `~/.config/ghostty`, so switching does not dirty
the Git checkout.

## Matrix fonts

Amber Strata includes three original scalable monospaced faces. **Strata Dot**
uses a fine 7×11 round-node grid, **Strata Square** uses softly rounded cells,
and **Strata Matrix** uses a coarse, widely spaced 5×7 display rhythm inspired
by modern dot-matrix industrial design. They are display faces: their visible
node grids need 20–22 pt to resolve cleanly and are not recommended for dense
shell text.

For everyday terminal text, the settings panel also offers **DM Mono** (clean
modern), **IBM Plex Mono** (technical modern-retro), and **IBM 3270** (stronger
retro). These full-outline fonts preserve detail at 11–15 pt. Terminus remains
the default.

```bash
./font-profile.sh dot
./font-profile.sh square
./font-profile.sh matrix
./font-profile.sh modern
./font-profile.sh technical
./font-profile.sh retro
./font-profile.sh terminus
```

The same choices appear in `Ctrl+Shift+P`. Reload with `Ctrl+Shift+,` after a
font change. Printable ASCII and Latin-1 use the matrix face; Ghostty falls back
for other scripts and specialist symbols.

The settings preview changes immediately. Dot and Square enforce a 20 pt
display floor; the intentionally coarser Matrix face uses 22 pt. Compact
settings controls use a clean UI font so small labels stay crisp.

When glow is enabled with a Strata display face, the settings panel applies a
tighter display-safe halo automatically. This keeps neighboring dots separate;
the normal stronger glow remains unchanged for full-outline terminal fonts.

Version 1.1 uses a conventional condensed terminal advance, so full-screen
layouts retain roughly the same column count as Terminus instead of being
pushed beyond the right edge.

The generated TTF files are ready to install. Font developers can rebuild them
from the OFL-licensed Terminus scaffold with:

```bash
python3 -m pip install -r fonts/requirements.txt
python3 fonts/build_fonts.py
```

## Visual settings

Run **Amber Strata Settings** from the KDE application launcher, select **Amber
Strata: Open Settings** from Ghostty's `Ctrl+Shift+P` palette while at a shell
prompt, or run:

```bash
~/.config/ghostty/settings.py
```

The panel provides a live type preview, font selection, size and Terminus
thickness controls, and an instant glow toggle. **Apply + Open Ghostty Preview**
opens a new terminal with the saved settings. Ghostty 1.3 does not expose its
surface-level `reload_config` action to external applications, so existing
windows still require one `Ctrl+Shift+,` after a font or metric change; shader
changes hot-reload immediately.

The panel's large Amber Strata identity uses the finer Strata Dot display face
with open letter spacing. Ghostty does not provide a configuration or CSS hook for inserting a new
button into its native titlebar; doing that requires maintaining a custom build
of Ghostty itself. The settings panel remains available from the KDE launcher
and Ghostty command palette without forking the terminal.

Clearly labeled constants at the top control sharpness, character glow, and
cursor afterglow.

For an aged CRT appearance, add this directly after the default shader in
`config.ghostty`:

```ini
custom-shader = shaders/classic-crt.glsl
```

Ghostty runs repeated shaders in order, so the optional artifacts are layered
over the clean glow.

For a static, lower-power version, change this line in `config.ghostty`:

```ini
custom-shader-animation = false
```

The shader will still render bloom and scanlines, but time-based flicker and
cursor movement will not animate continuously.

## Uninstall

Remove the three links created by the installer, then restore the timestamped
backup if one was made:

```bash
rm ~/.config/ghostty/config.ghostty
rm ~/.config/ghostty/profile.sh
rm ~/.config/ghostty/font-profile.sh
rm ~/.config/ghostty/font.ghostty
rm ~/.config/ghostty/settings.py
rm ~/.config/ghostty/themes/'Amber Strata'
rm ~/.config/ghostty/shaders/amber-strata.glsl
rm ~/.config/ghostty/shaders/active.glsl
rm ~/.config/ghostty/shaders/cursor-pulse.glsl
rm ~/.config/ghostty/shaders/classic-crt.glsl
rm ~/.config/ghostty/styles/amber-strata.css
rm ~/.config/ghostty/profiles/active.ghostty
rm ~/.config/ghostty/profiles/glow-on.ghostty
rm ~/.config/ghostty/profiles/glow-off.ghostty
rm ~/.local/share/fonts/amber-strata/StrataDot-Regular.ttf
rm ~/.local/share/fonts/amber-strata/StrataSquare-Regular.ttf
rm ~/.local/share/fonts/amber-strata/StrataMatrix-Regular.ttf
rm ~/.local/share/applications/amber-strata-settings.desktop
```

## License

The terminal configuration, shaders, scripts, and styles are [MIT](LICENSE).
The Strata fonts and their source are licensed under the
[SIL Open Font License 1.1](fonts/OFL.txt).
