#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/.ssh"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin" HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" XDG_CACHE_HOME="$tmp/cache"
printf 'Host special\n  IdentityAgent none\n' > "$HOME/.ssh/config"
"$ROOT/common-setup/chezmoi-ssh.sh"
cp "$HOME/.ssh/config" "$tmp/expected"
"$ROOT/common-setup/chezmoi-ssh.sh"
cmp "$HOME/.ssh/config" "$tmp/expected"
ssh -G -F "$HOME/.ssh/config" special 2>/dev/null | grep -q '^identityagent none$'
printf '# local change\n' >> "$HOME/.ssh/dotfiles-1password.conf"
if "$ROOT/common-setup/chezmoi-ssh.sh"; then exit 1; fi
grep -q '# local change' "$HOME/.ssh/dotfiles-1password.conf"
echo 'chezmoi SSH tests passed'
