#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin" HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" XDG_CACHE_HOME="$tmp/cache" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export DOTFILES_GIT_NAME='Migration Test' DOTFILES_GIT_EMAIL='migration@example.invalid'
unset DOTFILES_SECRET_OP_REF DOTFILES_NGROK_OP_REF DOTFILES_NGROK_TOKEN NGROK_AUTHTOKEN DEBUG || true
printf 'mac-work\n' > "$HOME/.dotfiles-machine"
"$ROOT/scripts/apply-chezmoi.sh"
"$ROOT/scripts/apply-chezmoi.sh"
[ -f "$HOME/.psqlrc" ]
[ -L "$HOME/.config/mise/config.mac-work.toml" ]
[ -L "$HOME/bin/imgcat" ]
[ -f "$HOME/.ssh/dotfiles-1password.conf" ]
[ ! -e "$HOME/.secret" ]
[ "$(git config --file "$HOME/.gitconfig-personal" user.email)" = migration@example.invalid ]
echo 'Config-only integrated apply passed'
