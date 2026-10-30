#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fragment="$HOME/.ssh/dotfiles-1password.conf"
config="$HOME/.ssh/config"
include='Include ~/.ssh/dotfiles-1password.conf'
mkdir -p "$HOME/.ssh"
# Preserve custom config paths and fragment contents, including dangling links.
if [ -L "$config" ] || { [ -e "$config" ] && [ ! -f "$config" ]; }; then echo 'SSH config is not a regular file; review required.' >&2; exit 1; fi
if [ -L "$fragment" ] || { [ -e "$fragment" ] && ! cmp -s "$fragment" "$ROOT/chezmoi/dot_ssh/private_dotfiles-1password.conf"; }; then echo 'SSH fragment has local changes; review required.' >&2; exit 1; fi
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
mkdir -p "$state_dir"
c() { DOTFILES_SSH_APPLY=1 chezmoi --config /dev/null --config-format toml --persistent-state "$state_dir/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" "$@"; }
if [ "$(uname -s)" = Darwin ]; then
    socket="$HOME/.1password/agent.sock"
    expected="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    if { [ -e "$socket" ] || [ -L "$socket" ]; } && { [ ! -L "$socket" ] || [ "$(readlink "$socket")" != "$expected" ]; }; then echo 'Existing SSH agent path differs; review required.' >&2; exit 1; fi
    mkdir -p "$HOME/.1password"
    c apply "$socket"
fi
c apply "$fragment"
if ! grep -Fxq "$include" "$config" 2>/dev/null; then
    # Appending keeps pre-existing host-specific choices ahead of our default.
    (umask 077; printf '\nHost *\n%s\n' "$include" >> "$config")
fi
