#!/usr/bin/env bash
set -euo pipefail

profile="${1:-}"
case "$profile" in
    terminus|dot|square|matrix) ;;
    *)
        printf 'Usage: %s {terminus|dot|square|matrix}\n' "${0##*/}" >&2
        exit 2
        ;;
esac

config_dir="${XDG_CONFIG_HOME:-${HOME:?}/.config}/ghostty"
active_path="$config_dir/font.ghostty"
mkdir -p "$config_dir"

case "$profile" in
    terminus)
        family='Terminus (TTF)'; style='Medium'; thicken='true'; strength='165'; cell_width='-6%'
        ;;
    dot)
        family='Strata Dot'; style='Regular'; thicken='false'; strength='0'; cell_width='0%'
        ;;
    square)
        family='Strata Square'; style='Regular'; thicken='false'; strength='0'; cell_width='0%'
        ;;
    matrix)
        family='Strata Matrix'; style='Regular'; thicken='false'; strength='0'; cell_width='3%'
        ;;
esac

printf 'font-family = %s\nfont-style = %s\nfont-thicken = %s\nfont-thicken-strength = %s\nadjust-cell-width = %s\n' \
    "$family" "$style" "$thicken" "$strength" "$cell_width" > "$active_path"

printf 'Amber Strata font: %s\n' "$family"
printf 'Reload Ghostty with Ctrl+Shift+,.\n'
