#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-${HOME:?}/.config}/ghostty"
font_dir="${XDG_DATA_HOME:-${HOME:?}/.local/share}/fonts/amber-strata"
timestamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$config_dir/themes" "$config_dir/shaders" "$config_dir/styles" "$config_dir/profiles" "$font_dir"

link_file() {
    local source_path="$1"
    local target_path="$2"

    if [[ -L "$target_path" && "$(readlink -f -- "$target_path")" == "$(readlink -f -- "$source_path")" ]]; then
        printf 'Already linked: %s\n' "$target_path"
        return
    fi

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        local backup_path="${target_path}.backup-${timestamp}"
        mv -- "$target_path" "$backup_path"
        printf 'Backed up: %s\n' "$backup_path"
    fi

    ln -s -- "$source_path" "$target_path"
    printf 'Linked: %s -> %s\n' "$target_path" "$source_path"
}

link_file "$repo_dir/config.ghostty" "$config_dir/config.ghostty"
link_file "$repo_dir/profile.sh" "$config_dir/profile.sh"
link_file "$repo_dir/font-profile.sh" "$config_dir/font-profile.sh"
link_file "$repo_dir/themes/Amber Strata" "$config_dir/themes/Amber Strata"
link_file "$repo_dir/shaders/amber-strata.glsl" "$config_dir/shaders/amber-strata.glsl"
link_file "$repo_dir/shaders/cursor-pulse.glsl" "$config_dir/shaders/cursor-pulse.glsl"
link_file "$repo_dir/shaders/classic-crt.glsl" "$config_dir/shaders/classic-crt.glsl"
link_file "$repo_dir/styles/amber-strata.css" "$config_dir/styles/amber-strata.css"
link_file "$repo_dir/profiles/glow-on.ghostty" "$config_dir/profiles/glow-on.ghostty"
link_file "$repo_dir/profiles/glow-off.ghostty" "$config_dir/profiles/glow-off.ghostty"
link_file "$repo_dir/fonts/dist/StrataDot-Regular.ttf" "$font_dir/StrataDot-Regular.ttf"
link_file "$repo_dir/fonts/dist/StrataSquare-Regular.ttf" "$font_dir/StrataSquare-Regular.ttf"
link_file "$repo_dir/fonts/dist/StrataMatrix-Regular.ttf" "$font_dir/StrataMatrix-Regular.ttf"

if [[ ! -e "$config_dir/font.ghostty" ]]; then
    printf 'font-family = Terminus (TTF)\nfont-style = Medium\nfont-thicken = true\nfont-thicken-strength = 165\nadjust-cell-width = -6%%\n' > "$config_dir/font.ghostty"
fi
fc-cache -f "$font_dir"

if [[ ! -e "$config_dir/shaders/active.glsl" ]]; then
    profile_contents="$(<"$repo_dir/shaders/amber-strata.glsl")"
    printf '%s\n' "$profile_contents" > "$config_dir/shaders/active.glsl"
    printf 'Selected profile: glow-on\n'
fi

printf '\nAmber Strata installed. Restart Ghostty, or reload with Ctrl+Shift+,.\n'
