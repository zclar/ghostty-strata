#!/usr/bin/env bash
set -euo pipefail

profile="${1:-}"
agent_mode="${2:-}"
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
agent_mode_path="$config_dir/agent-mode"
glow_mode_path="$config_dir/glow-mode"

if [[ -z "$agent_mode" && -f "$agent_mode_path" ]]; then
    agent_mode="$(<"$agent_mode_path")"
fi
agent_mode="${agent_mode:-core}"
[[ "$agent_mode" =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
    printf 'Invalid adapter id: %s\n' "$agent_mode" >&2
    exit 2
}
adapter_path="$repo_dir/adapters/$agent_mode.json"
[[ -f "$adapter_path" ]] || {
    printf 'Unknown adapter: %s\nAvailable adapters:\n' "$agent_mode" >&2
    find "$repo_dir/adapters" -maxdepth 1 -type f -name '*.json' -printf '  %f\n' \
        | sed 's/\.json$//' >&2
    exit 2
}

case "$profile" in
    glow-on) source_path="$repo_dir/shaders/amber-strata.glsl" ;;
    glow-soft) source_path="$repo_dir/shaders/amber-strata.glsl" ;;
    glow-off) source_path="$repo_dir/shaders/cursor-pulse.glsl" ;;
esac

mkdir -p "$config_dir/shaders"
# Validate the adapter and render a complete shader before asking Ghostty to
# recompile it. The renderer refuses malformed or out-of-range SDK values.
python3 "$repo_dir/adapter-sdk/render_adapter.py" \
    --source "$source_path" \
    --adapter "$adapter_path" \
    --glow-mode "$profile" \
    --output "$active_path"
[[ -s "$active_path" ]] || { printf 'Rendered shader is empty; refusing to apply.\n' >&2; exit 1; }
printf '%s\n' "$agent_mode" > "$agent_mode_path"
printf '%s\n' "$profile" > "$glow_mode_path"
printf 'Amber Strata profile: %s / %s\n' "$profile" "$agent_mode"
if command -v pgrep >/dev/null 2>&1 && command -v pkill >/dev/null 2>&1 \
    && pgrep -x ghostty >/dev/null 2>&1; then
    pkill -USR2 -x ghostty
    printf 'Ghostty reload signal sent.\n'
else
    printf 'Reload Ghostty with Ctrl+Shift+,.\n'
fi
