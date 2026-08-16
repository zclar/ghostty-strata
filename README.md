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

The default shader is deliberately clean: no noise, scanlines, flicker,
vignette, distortion, or artificial contrast. Clearly labeled constants at
the top control only character glow and cursor afterglow.

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
rm ~/.config/ghostty/themes/'Amber Strata'
rm ~/.config/ghostty/shaders/amber-strata.glsl
rm ~/.config/ghostty/shaders/classic-crt.glsl
rm ~/.config/ghostty/styles/amber-strata.css
```

## License

[MIT](LICENSE)
