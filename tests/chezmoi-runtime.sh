#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin" HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" XDG_CACHE_HOME="$tmp/cache" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME/.config" "$HOME/.ssh"
ln -s "$ROOT/common-setup/vim/dotvim" "$HOME/.vim"
ln -s "$HOME/.vim" "$HOME/.config/nvim"
cp "$ROOT/common-setup/allowed_signers" "$HOME/.ssh/allowed_signers"
"$ROOT/common-setup/chezmoi-runtime.sh"
[ -L "$HOME/.vim.pre-chezmoi" ]
[ -L "$HOME/.config/nvim.pre-chezmoi" ]
[ -f "$HOME/.ssh/allowed_signers.pre-chezmoi" ]
case "$(uname -s)" in Darwin) tms="$HOME/Library/Application Support/tms/config.toml";; *) tms="$HOME/.config/tms/config.toml";; esac
printf 'local tms config\n' > "$tms"
"$ROOT/common-setup/chezmoi-runtime.sh"
[ "$(cat "$tms")" = 'local tms config' ]
[ -L "$HOME/.vim" ]
[ ! -L "$HOME/.config/nvim" ]
cmp "$HOME/.config/nvim/init.vim" "$ROOT/chezmoi/dot_config/nvim/init.vim"
rm "$HOME/.ssh/allowed_signers"
printf 'local\n' > "$HOME/.ssh/allowed_signers"
if "$ROOT/common-setup/chezmoi-runtime.sh"; then echo 'Expected local-file refusal'; exit 1; fi
[ "$(cat "$HOME/.ssh/allowed_signers")" = local ]
rm "$HOME/.ssh/allowed_signers"
rm "$HOME/.vim"
mkdir "$HOME/.vim"
printf 'local\n' > "$HOME/.vim/precious"
if "$ROOT/common-setup/chezmoi-runtime.sh"; then echo 'Expected directory refusal'; exit 1; fi
[ "$(cat "$HOME/.vim/precious")" = local ]
echo 'chezmoi runtime tests passed'
