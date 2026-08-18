#!/usr/bin/env bash
set -euo pipefail

profile="${1:-}"
case "$profile" in
    glow-on|glow-soft|glow-off) ;;
    *)
        printf 'Usage: %s {glow-on|glow-soft|glow-off}\n' "${0##*/}" >&2
        exit 2
        ;;
esac

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-${HOME:?}/.config}/ghostty"
active_path="$config_dir/shaders/active.glsl"

case "$profile" in
    glow-on) source_path="$repo_dir/shaders/amber-strata.glsl" ;;
    glow-soft) source_path="$repo_dir/shaders/amber-strata.glsl" ;;
    glow-off) source_path="$repo_dir/shaders/cursor-pulse.glsl" ;;
esac

mkdir -p "$config_dir/shaders"
# Update the installed shader, then ask Ghostty to recompile it.
profile_contents="$(<"$source_path")"
if [[ "$profile" == "glow-soft" ]]; then
    # Preserve the animated phosphor character while keeping neighboring
    # matrix nodes distinct at terminal sizes.
    profile_contents="${profile_contents/const float GLOW_STRENGTH = 1.28;/const float GLOW_STRENGTH = 0.72;}"
    profile_contents="${profile_contents/const float GLOW_RADIUS = 1.80;/const float GLOW_RADIUS = 1.15;}"
    profile_contents="${profile_contents/const float TYPE_PULSE_STRENGTH = 0.48;/const float TYPE_PULSE_STRENGTH = 0.30;}"
fi
[[ -n "$profile_contents" ]] || { printf 'Shader profile is empty; refusing to apply.\n' >&2; exit 1; }
printf '%s\n' "$profile_contents" > "$active_path"
printf 'Amber Strata profile: %s\n' "$profile"
if command -v pgrep >/dev/null 2>&1 && command -v pkill >/dev/null 2>&1 \
    && pgrep -x ghostty >/dev/null 2>&1; then
    pkill -USR2 -x ghostty
    printf 'Ghostty reload signal sent.\n'
else
    printf 'Reload Ghostty with Ctrl+Shift+,.\n'
fi
