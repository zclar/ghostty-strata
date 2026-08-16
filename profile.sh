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
active_path="$config_dir/profiles/active.ghostty"
source_path="$repo_dir/profiles/$profile.ghostty"

mkdir -p "$config_dir/profiles"
if [[ -e "$active_path" && ! -L "$active_path" ]]; then
    printf 'Refusing to replace non-link profile: %s\n' "$active_path" >&2
    exit 1
fi

ln -sfn -- "$source_path" "$active_path"
printf 'Amber Strata profile: %s\n' "$profile"
printf 'Reload Ghostty with Ctrl+Shift+,.\n'
