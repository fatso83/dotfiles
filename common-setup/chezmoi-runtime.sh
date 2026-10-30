#!/bin/bash
# Keep runtime/plugin directories in the checkout; chezmoi owns their links.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
command -v chezmoi >/dev/null || { echo 'chezmoi is required for runtime migration' >&2; exit 1; }
if [ -n "$(git -C "$ROOT" ls-files -u)" ]; then
 echo 'Unresolved Git conflicts: runtime deployment stopped' >&2; exit 1
fi
state="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
mkdir -p "$state"
cm() { chezmoi --config /dev/null --config-format toml --persistent-state "$state/chezmoi.boltdb" --source "$ROOT" --destination "$HOME" "$@"; }
while read -r relative source; do
 target="$HOME/$relative"; expected="$ROOT/$source"
 if [ -e "$target" ] || [ -L "$target" ]; then
  if [ -d "$expected" ]; then
   [ -L "$target" ] && [ -d "$target" ] && [ "$(cd "$target" && pwd -P)" = "$(cd "$expected" && pwd -P)" ] || { echo "Preserving local directory: $target" >&2; exit 1; }
  else
   cmp -s "$target" "$expected" || { echo "Preserving local file: $target" >&2; exit 1; }
  fi
  if [ ! -L "$target" ] || [ "$(readlink "$target")" != "$ROOT/chezmoi/../$source" ]; then
   [ ! -e "$target.pre-chezmoi" ] && [ ! -L "$target.pre-chezmoi" ] || exit 1
   cp -pP "$target" "$target.pre-chezmoi"
  fi
 fi
 mkdir -p "$(dirname "$target")"
 cm apply "$target"
done < "$ROOT/common-setup/chezmoi-runtime.manifest"
# Replace the historical nvim -> ~/.vim link without writing init.vim into Git.
nvim="$HOME/.config/nvim"
if [ -L "$nvim" ]; then
 [ -d "$nvim" ] && [ "$(cd "$nvim" && pwd -P)" = "$(cd "$HOME/.vim" && pwd -P)" ] || exit 1
 [ ! -e "$nvim.pre-chezmoi" ] && [ ! -L "$nvim.pre-chezmoi" ] || exit 1
 mv "$nvim" "$nvim.pre-chezmoi"
fi
mkdir -p "$nvim"
if [ -e "$nvim/init.vim" ] || [ -L "$nvim/init.vim" ]; then
 cmp -s "$nvim/init.vim" "$ROOT/chezmoi/dot_config/nvim/init.vim" || { echo 'Preserving local nvim/init.vim' >&2; exit 1; }
fi
cm apply "$nvim/init.vim"
case "$(uname -s)" in Darwin) tms="$HOME/Library/Application Support/tms/config.toml";; *) tms="$HOME/.config/tms/config.toml";; esac
mkdir -p "$(dirname "$tms")"
cm apply "$tms"
