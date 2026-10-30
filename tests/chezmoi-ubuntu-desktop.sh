#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/.config"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin" HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
ln -s "$ROOT/per-host-config/ubuntu/desktop" "$HOME/.config/Dharkael"
"$ROOT/per-host-config/chezmoi-host.sh" ubuntu desktop
"$ROOT/per-host-config/chezmoi-host.sh" ubuntu desktop
[ -L "$HOME/.config/Dharkael.pre-chezmoi" ]
[ -L "$HOME/.gitlocal-non-wsl" ]
rm "$HOME/.config/Dharkael"
mkdir "$HOME/.config/Dharkael"
printf 'local\n' > "$HOME/.config/Dharkael/local"
if "$ROOT/per-host-config/chezmoi-host.sh" ubuntu desktop; then exit 1; fi
[ "$(cat "$HOME/.config/Dharkael/local")" = local ]
echo 'Ubuntu desktop migration tests passed'
