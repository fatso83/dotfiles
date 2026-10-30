#!/bin/bash
# Generate only when a token is provided. Never expose it in logs or a diff.
set +x
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$HOME/.ngrok2/ngrok.yml"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
if [ -z "${DOTFILES_NGROK_OP_REF:-}" ] && [ -z "${NGROK_AUTHTOKEN:-}" ]; then
    printf '%s\n' 'No ngrok token configured; leaving existing ngrok configuration unchanged.'
    exit 0
fi
if ! command -v chezmoi >/dev/null 2>&1 || ! chezmoi --version >/dev/null 2>&1; then
    printf '%s\n' 'chezmoi unavailable; leaving existing ngrok configuration unchanged.' >&2
    exit 1
fi
mkdir -p "$state_dir" "$HOME/.ngrok2"
chmod 700 "$state_dir"
export DOTFILES_NGROK_APPLY=1 DOTFILES_NGROK_TOKEN="${NGROK_AUTHTOKEN:-}"
rendered=$(mktemp "$state_dir/ngrok.XXXXXX")
trap 'rm -f "$rendered"' EXIT
chmod 600 "$rendered"
c() { chezmoi --config /dev/null --config-format toml --persistent-state "$state_dir/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" "$@"; }
if ! c cat "$target" > "$rendered" 2>/dev/null; then
    echo 'Unable to render ngrok configuration; check the token source and 1Password access.' >&2
    exit 1
fi
hash() { shasum -a 256 "$1" | cut -d ' ' -f 1; }
if [ -e "$target" ] || [ -L "$target" ]; then
    if [ ! -f "$target" ] || [ -L "$target" ]; then echo 'Existing ngrok path is not a regular file; leaving it unchanged.' >&2; exit 1; fi
    if ! cmp -s "$target" "$rendered" && { [ ! -f "$state_dir/ngrok.sha256" ] || [ "$(hash "$target")" != "$(cat "$state_dir/ngrok.sha256")" ]; }; then
        echo 'Existing ngrok configuration differs; leaving it unchanged for review.' >&2; exit 1
    fi
fi
if ! c apply "$target" >/dev/null 2>&1; then
    echo 'Unable to apply ngrok configuration; check the token source and destination.' >&2
    exit 1
fi
hash "$target" > "$state_dir/ngrok.sha256"
chmod 600 "$state_dir/ngrok.sha256"
