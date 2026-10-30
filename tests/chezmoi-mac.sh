#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
[ -x "$CHEZMOI_BIN" ] || exit 1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/bin" "$tmp/home/dev/mestergruppen"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin" HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" XDG_CACHE_HOME="$tmp/cache" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
ln "$ROOT/per-host-config/mac-work/bin/imgcat" "$HOME/bin/imgcat"
ln "$ROOT/per-host-config/mac-work/bin/ramdisk" "$HOME/bin/ramdisk"
ln -s "$ROOT/per-host-config/mac-work/mestergruppen_gitconfig" "$HOME/dev/mestergruppen/gitconfig"
"$ROOT/per-host-config/mac-work/chezmoi-mac.sh"
"$ROOT/per-host-config/mac-work/chezmoi-mac.sh"
for name in imgcat ramdisk; do
    [ -L "$HOME/bin/$name" ] && [ -f "$HOME/bin/$name.pre-chezmoi" ]
    cmp "$HOME/bin/$name" "$ROOT/per-host-config/mac-work/bin/$name"
done
[ -L "$HOME/dev/mestergruppen/gitconfig" ] && [ -L "$HOME/dev/mestergruppen/gitconfig.pre-chezmoi" ]
echo 'chezmoi mac tests passed'
