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
for pair in 'mise:.config/mise/config.toml:common-setup/mise/config.toml' 'fish:.config/fish/config.fish:common-setup/config.fish' 'alacritty:.config/alacritty/alacritty.toml:common-setup/alacritty.toml' 'gemini-settings:.gemini/settings.json:common-setup/gemini/settings.json' 'gemini-rules:.gemini/policies/my-rules.toml:common-setup/gemini/my-rules.toml'; do
    name=${pair%%:*}; rest=${pair#*:}; dest=${rest%%:*}; src=${rest#*:}
    mkdir -p "$(dirname "$HOME/$dest")"
    ln -s "$ROOT/$src" "$HOME/$dest"
    "$ROOT/common-setup/chezmoi-link.sh" "$name"
    "$ROOT/common-setup/chezmoi-link.sh" "$name"
    [ -L "$HOME/$dest" ] && [ -L "$HOME/$dest.pre-chezmoi" ]
    cmp "$HOME/$dest" "$ROOT/$src"
done
echo 'chezmoi link tests passed'
