#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DOTFILES_MACHINE=mac-work
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
for entry in imgcat ramdisk mestergruppen; do
    case "$entry" in
        mestergruppen) relative=dev/mestergruppen/gitconfig; source=per-host-config/mac-work/mestergruppen_gitconfig ;;
        *) relative="bin/$entry"; source="per-host-config/mac-work/bin/$entry" ;;
    esac
    target="$HOME/$relative"; source_file="$ROOT/$source"
    desired="$ROOT/chezmoi/../$source"; backup="$target.pre-chezmoi"
    if [ -n "$(git -C "$ROOT" ls-files -u -- "$source")" ]; then
        printf 'Source has a Git conflict: %s\n' "$source" >&2; exit 1
    fi
    mkdir -p "$(dirname "$target")"
    if ! command -v chezmoi >/dev/null 2>&1 || ! chezmoi --version >/dev/null 2>&1; then
        if [ ! -e "$target" ] && [ ! -L "$target" ]; then ln -s "$source_file" "$target"; fi
        continue
    fi
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$desired" ]; then continue; fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ ! -f "$target" ] || ! cmp -s "$target" "$source_file"; then
            printf 'Leaving %s unchanged: existing content differs.\n' "$target" >&2; exit 1
        fi
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            printf 'Leaving %s unchanged: backup already exists.\n' "$target" >&2; exit 1
        fi
        cp -pP "$target" "$backup"
    fi
    mkdir -p "$state_dir"
    chezmoi --config /dev/null --config-format toml --persistent-state "$state_dir/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" apply "$target"
done
