#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
[ -x "$CHEZMOI_BIN" ] || exit 1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin" HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" XDG_CACHE_HOME="$tmp/cache" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
DOTFILES_GIT_NAME='Test "User"' DOTFILES_GIT_EMAIL='test@example.invalid' "$ROOT/common-setup/git-identity-setup.sh"
[ "$(git config --file "$HOME/.gitconfig-personal" user.name)" = 'Test "User"' ]
[ "$(git config --file "$HOME/.gitconfig-personal" user.email)" = 'test@example.invalid' ]
[ "$(stat -f '%Lp' "$HOME/.gitconfig-personal" 2>/dev/null || stat -c '%a' "$HOME/.gitconfig-personal")" = 600 ]
DOTFILES_GIT_NAME=other DOTFILES_GIT_EMAIL=other@example.invalid "$ROOT/common-setup/git-identity-setup.sh"
[ "$(git config --file "$HOME/.gitconfig-personal" user.email)" = 'test@example.invalid' ]
"$ROOT/common-setup/chezmoi-setup.sh" gitconfig
[ "$(git config --file "$HOME/.gitconfig" include.path | tail -1)" = '.gitconfig-personal' ]
echo 'chezmoi identity tests passed'
