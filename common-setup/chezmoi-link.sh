#!/bin/bash
# Manage selected links while preserving locally modified targets.
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "${1:-}" in
    mise) relative=.config/mise/config.toml; source=common-setup/mise/config.toml ;;
    fish) relative=.config/fish/config.fish; source=common-setup/config.fish ;;
    alacritty) relative=.config/alacritty/alacritty.toml; source=common-setup/alacritty.toml ;;
    gemini-settings) relative=.gemini/settings.json; source=common-setup/gemini/settings.json ;;
    gemini-rules) relative=.gemini/policies/my-rules.toml; source=common-setup/gemini/my-rules.toml ;;
    *) echo 'Unknown link target' >&2; exit 2 ;;
esac
if [ -n "$(git -C "$ROOT" ls-files -u)" ]; then
    echo 'Unresolved Git conflicts: link deployment stopped' >&2; exit 1
fi
target="$HOME/$relative"
source_file="$ROOT/$source"
desired="$ROOT/chezmoi/../$source"
backup="$target.pre-chezmoi"
if ! command -v chezmoi >/dev/null 2>&1 || ! chezmoi --version >/dev/null 2>&1; then
    mkdir -p "$(dirname "$target")"
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then ln -s "$source_file" "$target"; fi
    exit 0
fi
if [ -L "$target" ] && [ "$(readlink "$target")" = "$desired" ]; then exit 0; fi
if [ -e "$target" ] || [ -L "$target" ]; then
    if [ ! -f "$target" ] || ! cmp -s "$target" "$source_file"; then
        printf 'Leaving %s unchanged: existing content differs.\n' "$target" >&2; exit 1
    fi
    if [ -e "$backup" ] || [ -L "$backup" ]; then
        printf 'Leaving %s unchanged: backup already exists.\n' "$target" >&2; exit 1
    fi
    cp -pP "$target" "$backup"
fi
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
mkdir -p "$state_dir" "$(dirname "$target")"
chezmoi --config /dev/null --config-format toml --persistent-state "$state_dir/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" apply "$target"
