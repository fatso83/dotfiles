#!/bin/bash
# Deploy migrated files without losing existing local changes.
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "${1:-psqlrc}" in
    psqlrc|gitignore_global|pystartup|pdbrc|tmux.conf|profile|bashrc|zshrc|vimrc|gitconfig) name="${1:-psqlrc}" ;;
    *) printf 'Unknown chezmoi target: %s\n' "$1" >&2; exit 2 ;;
esac
source_file="$ROOT/chezmoi/dot_$name"
target="$HOME/.$name"
backup="$target.pre-chezmoi"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
baseline="$state_dir/$name.last-applied"

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
   [ -n "$(git -C "$ROOT" ls-files -u -- "chezmoi/dot_$name")" ]; then
    printf '%s\n' "Leaving $target unchanged: chezmoi/dot_$name has a Git conflict." >&2
    exit 1
fi

if ! command -v chezmoi >/dev/null 2>&1 || ! chezmoi --version >/dev/null 2>&1; then
    # Keep the legacy setup usable until chezmoi is available.
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        ln -s "$source_file" "$target"
    fi
    printf '%s\n' "chezmoi not found; keeping existing .$name (install chezmoi and rerun setup to migrate it)."
    exit 0
fi

if [ -e "$target" ] || [ -L "$target" ]; then
    if [ ! -f "$target" ] || { ! cmp -s "$target" "$source_file" && { [ ! -f "$baseline" ] || ! cmp -s "$target" "$baseline"; }; }; then
        printf '%s\n' "Leaving $target unchanged: it differs from the repo or is not a regular file. Review it before migrating." >&2
        exit 1
    fi
    if [ -L "$target" ]; then
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            printf '%s\n' "Leaving $target unchanged: backup already exists at $backup." >&2
            exit 1
        fi
        cp -pP "$target" "$backup"
    fi
fi

# Select only this file: setup must not run unrelated chezmoi scripts.
mkdir -p "$state_dir"
chezmoi --config /dev/null --config-format toml --persistent-state "$state_dir/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" apply "$target"
cp "$target" "$baseline"
