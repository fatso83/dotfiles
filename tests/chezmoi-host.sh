#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
[ -x "$CHEZMOI_BIN" ] || { echo 'chezmoi required' >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin"
for machine in mac-work ubuntu jumphost win-dev-machine retropie; do
    export HOME="$tmp/$machine" XDG_CONFIG_HOME="$tmp/$machine/config" XDG_CACHE_HOME="$tmp/$machine/cache" XDG_DATA_HOME="$tmp/$machine/data" XDG_STATE_HOME="$tmp/$machine/state"
    mkdir -p "$HOME/.tmux"
    for name in bashrc.local profile.local gitlocal vimrc.local tmux.local; do
        src="$ROOT/per-host-config/$machine/$name"; [ -f "$src" ] || continue
        case "$name" in tmux.local) dest="$HOME/.tmux/local" ;; *) dest="$HOME/.$name" ;; esac
        ln -s "$src" "$dest"
    done
    "$ROOT/per-host-config/chezmoi-host.sh" "$machine"
    "$ROOT/per-host-config/chezmoi-host.sh" "$machine"
    for name in bashrc.local profile.local gitlocal vimrc.local tmux.local; do
        src="$ROOT/per-host-config/$machine/$name"; [ -f "$src" ] || continue
        case "$name" in tmux.local) dest="$HOME/.tmux/local" ;; *) dest="$HOME/.$name" ;; esac
        [ -L "$dest" ] && [ -L "$dest.pre-chezmoi" ] && cmp "$dest" "$src"
    done
done
export HOME="$tmp/conflict" XDG_STATE_HOME="$tmp/conflict/state" XDG_CACHE_HOME="$tmp/conflict/cache" XDG_CONFIG_HOME="$tmp/conflict/config" XDG_DATA_HOME="$tmp/conflict/data"
mkdir -p "$HOME"
printf 'local change\n' > "$HOME/.bashrc.local"
if "$ROOT/per-host-config/chezmoi-host.sh" mac-work; then echo 'Expected conflict' >&2; exit 1; fi
[ "$(cat "$HOME/.bashrc.local")" = 'local change' ]
if "$ROOT/per-host-config/chezmoi-host.sh" unknown; then echo 'Expected unknown machine error' >&2; exit 1; fi
export HOME="$tmp/wsl" XDG_STATE_HOME="$tmp/wsl/state" XDG_CACHE_HOME="$tmp/wsl/cache" XDG_CONFIG_HOME="$tmp/wsl/config" XDG_DATA_HOME="$tmp/wsl/data"
mkdir -p "$HOME"
for name in profile.wsl bashrc.wsl gitlocal-wsl ssh-agent-bridge.sh; do
    case "$name" in ssh-agent-bridge.sh) dest="$HOME/.agent-bridge.sh" ;; *) dest="$HOME/.$name" ;; esac
    ln -s "$ROOT/per-host-config/ubuntu/wsl/$name" "$dest"
done
"$ROOT/per-host-config/chezmoi-host.sh" ubuntu wsl
"$ROOT/per-host-config/chezmoi-host.sh" ubuntu wsl
for name in profile.wsl bashrc.wsl gitlocal-wsl ssh-agent-bridge.sh; do
    case "$name" in ssh-agent-bridge.sh) dest="$HOME/.agent-bridge.sh" ;; *) dest="$HOME/.$name" ;; esac
    [ -L "$dest" ] && [ -L "$dest.pre-chezmoi" ] && cmp "$dest" "$ROOT/per-host-config/ubuntu/wsl/$name"
done
echo 'chezmoi host tests passed'
