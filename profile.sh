#!/usr/bin/env bash
set -euo pipefail

profile="${1:-}"
case "$profile" in
    glow-on|glow-off) ;;
    *)
        printf 'Usage: %s {glow-on|glow-off}\n' "${0##*/}" >&2
        exit 2
        ;;
esac

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-${HOME:?}/.config}/ghostty"
active_path="$config_dir/shaders/active.glsl"

case "$profile" in
    glow-on) source_path="$repo_dir/shaders/amber-strata.glsl" ;;
    glow-off) source_path="$repo_dir/shaders/cursor-pulse.glsl" ;;
esac

mkdir -p "$config_dir/shaders"
# Update the watched shader itself; Ghostty hot-reloads shaders without a
# configuration reload. active.glsl is installer-owned and never a repo file.
profile_contents="$(<"$source_path")"
printf '%s\n' "$profile_contents" > "$active_path"
printf 'Amber Strata profile: %s\n' "$profile"
printf 'Ghostty is hot-reloading the effect now.\n'
