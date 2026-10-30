#!/bin/bash
# Keep an existing identity; create a private local one only if absent.
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$HOME/.gitconfig-personal"
if [ -e "$target" ] || [ -L "$target" ]; then exit 0; fi
name="${DOTFILES_GIT_NAME:-$(git config --global user.name || :)}"
email="${DOTFILES_GIT_EMAIL:-$(git config --global user.email || :)}"
if [ -z "$name" ]; then read -r -p 'Git commit name: ' name; fi
if [ -z "$email" ]; then read -r -p 'Git commit email: ' email; fi
if [ -z "$name" ] || [ -z "$email" ]; then echo 'Git name and email are required.' >&2; exit 1; fi
if command -v chezmoi >/dev/null 2>&1 && chezmoi --version >/dev/null 2>&1; then
    state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
    mkdir -p "$state_dir"
    DOTFILES_GIT_NAME="$name" DOTFILES_GIT_EMAIL="$email" DOTFILES_CREATE_GIT_IDENTITY=1 \
        chezmoi --config /dev/null --config-format toml --persistent-state "$state_dir/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" apply "$target"
else
    (umask 077; git config --file "$target" user.name "$name"; git config --file "$target" user.email "$email")
fi
