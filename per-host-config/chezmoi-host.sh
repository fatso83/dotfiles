#!/bin/bash
# Preserve the existing per-host source files and let chezmoi manage their links.
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
machine="${1:-}"
case "$machine" in ''|*[!a-zA-Z0-9_-]*) printf 'Invalid machine: %s\n' "$machine" >&2; exit 1 ;; esac
if [ ! -d "$ROOT/per-host-config/$machine" ] || [ "$machine" = _shared ]; then
    printf 'Unknown machine: %s\n' "$machine" >&2; exit 1
fi
export DOTFILES_MACHINE="$machine"
mode="${2:-host}"
case "$mode" in
    host) names="bashrc.local profile.local gitlocal vimrc.local tmux.local"; source_dir="per-host-config/$machine" ;;
    desktop) [ "$machine" = ubuntu ] || exit 1
         export DOTFILES_UBUNTU_DESKTOP=1
         names="gitlocal-non-wsl desktop"; source_dir="per-host-config/ubuntu" ;;
    wsl) [ "$machine" = ubuntu ] || { echo 'WSL requires ubuntu' >&2; exit 1; }
         export DOTFILES_WSL=1
         names="profile.wsl bashrc.wsl gitlocal-wsl ssh-agent-bridge.sh"; source_dir="per-host-config/ubuntu/wsl" ;;
    *) echo "Unknown mode: $mode" >&2; exit 1 ;;
esac
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
for name in $names; do
    source_file="$ROOT/$source_dir/$name"
    [ -e "$source_file" ] || continue
    case "$name" in desktop) target="$HOME/.config/Dharkael" ;; tmux.local) target="$HOME/.tmux/local" ;; ssh-agent-bridge.sh) target="$HOME/.agent-bridge.sh" ;; *) target="$HOME/.$name" ;; esac
    desired="$ROOT/chezmoi/../$source_dir/$name"
    backup="$target.pre-chezmoi"
    if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
       [ -n "$(git -C "$ROOT" ls-files -u -- "$source_dir/$name")" ]; then
        printf 'Leaving %s unchanged: source has a Git conflict.\n' "$target" >&2; exit 1
    fi
    if ! command -v chezmoi >/dev/null 2>&1 || ! chezmoi --version >/dev/null 2>&1; then
        mkdir -p "$(dirname "$target")"
        if [ ! -e "$target" ] && [ ! -L "$target" ]; then ln -s "$source_file" "$target"; fi
        continue
    fi
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$desired" ]; then
        continue
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source_file" ]; then
            :
        elif [ ! -f "$target" ] || ! cmp -s "$target" "$source_file"; then
            printf 'Leaving %s unchanged: existing content differs.\n' "$target" >&2; exit 1
        fi
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            printf 'Leaving %s unchanged: backup already exists.\n' "$target" >&2; exit 1
        fi
        cp -pP "$target" "$backup"
    fi
    mkdir -p "$(dirname "$target")"
    mkdir -p "$state_dir"
    chezmoi --config /dev/null --config-format toml --persistent-state "$state_dir/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" apply "$target"
done
