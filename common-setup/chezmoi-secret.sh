#!/bin/bash
# Optional first-time bootstrap. Existing machine-local secrets always win.
set +x
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$HOME/.secret"
if [ -e "$target" ] || [ -L "$target" ]; then exit 0; fi
if [ -z "${DOTFILES_SECRET_OP_REF:-}" ]; then exit 0; fi
command -v chezmoi >/dev/null || { echo 'chezmoi is required for secret bootstrap.' >&2; exit 1; }
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
mkdir -p "$state_dir"
chmod 700 "$state_dir"
# Do not print renderer diagnostics: a provider error can contain private data.
if ! DOTFILES_SECRET_APPLY=1 chezmoi --config /dev/null --config-format toml --persistent-state "$state_dir/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" apply "$target" >/dev/null 2>&1; then
    echo 'Secret bootstrap failed; check 1Password access and the configured reference.' >&2
    exit 1
fi
