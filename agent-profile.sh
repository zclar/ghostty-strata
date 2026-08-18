#!/usr/bin/env bash
set -euo pipefail

agent_mode="${1:-}"
if [[ -z "$agent_mode" ]]; then
    printf 'Usage: %s ADAPTER_ID\n' "${0##*/}" >&2
    exit 2
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-${HOME:?}/.config}/ghostty"
glow_mode="glow-soft"
if [[ -f "$config_dir/glow-mode" ]]; then
    glow_mode="$(<"$config_dir/glow-mode")"
fi
exec "$repo_dir/profile.sh" "$glow_mode" "$agent_mode"
