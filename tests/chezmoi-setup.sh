#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
if [ -z "$CHEZMOI_BIN" ] || [ ! -x "$CHEZMOI_BIN" ]; then
    echo 'Install chezmoi or set CHEZMOI_BIN to run this test.' >&2
    exit 1
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin"
new_home() {
    export HOME="$tmp/$1" XDG_CONFIG_HOME="$tmp/$1/config" XDG_CACHE_HOME="$tmp/$1/cache" XDG_DATA_HOME="$tmp/$1/data" XDG_STATE_HOME="$tmp/$1/state"
    mkdir -p "$HOME"
}
setup() { "$ROOT/common-setup/chezmoi-setup.sh"; }
new_home fresh
setup
[ -f "$HOME/.psqlrc" ] && [ ! -L "$HOME/.psqlrc" ]
cmp "$HOME/.psqlrc" "$ROOT/chezmoi/dot_psqlrc"
setup
new_home legacy
ln -s "$ROOT/common-setup/psqlrc" "$HOME/.psqlrc"
setup
[ ! -L "$HOME/.psqlrc" ] && [ -L "$HOME/.psqlrc.pre-chezmoi" ]
[ "$(readlink "$HOME/.psqlrc.pre-chezmoi")" = "$ROOT/common-setup/psqlrc" ]
cmp "$HOME/.psqlrc" "$ROOT/chezmoi/dot_psqlrc"
new_home backup_exists
ln -s "$ROOT/common-setup/psqlrc" "$HOME/.psqlrc"
printf 'keep backup\n' > "$HOME/.psqlrc.pre-chezmoi"
if setup; then echo 'Expected existing backup to stop migration' >&2; exit 1; fi
[ -L "$HOME/.psqlrc" ] && [ "$(cat "$HOME/.psqlrc.pre-chezmoi")" = 'keep backup' ]
new_home modified
printf 'local change\n' > "$HOME/.psqlrc"
if setup; then echo 'Expected migration to reject modified file' >&2; exit 1; fi
[ "$(cat "$HOME/.psqlrc")" = 'local change' ]
new_home broken
ln -s "$HOME/missing" "$HOME/.psqlrc"
if setup; then echo 'Expected migration to reject broken link' >&2; exit 1; fi
[ -L "$HOME/.psqlrc" ]
new_home fallback
PATH=/usr/bin:/bin:/usr/sbin:/sbin setup
[ -L "$HOME/.psqlrc" ] && cmp "$HOME/.psqlrc" "$ROOT/chezmoi/dot_psqlrc"
setup
[ ! -L "$HOME/.psqlrc" ] && [ -L "$HOME/.psqlrc.pre-chezmoi" ]
# Exercise a subsequent repository change without editing the real checkout.
mkdir -p "$tmp/repo/common-setup" "$tmp/repo/chezmoi"
cp "$ROOT/.chezmoiroot" "$tmp/repo/.chezmoiroot"
cp "$ROOT/common-setup/chezmoi-setup.sh" "$tmp/repo/common-setup/chezmoi-setup.sh"
cp "$ROOT/chezmoi/dot_psqlrc" "$tmp/repo/chezmoi/dot_psqlrc"
new_home update
"$tmp/repo/common-setup/chezmoi-setup.sh"
printf '\n-- updated fixture\n' >> "$tmp/repo/chezmoi/dot_psqlrc"
"$tmp/repo/common-setup/chezmoi-setup.sh"
cmp "$HOME/.psqlrc" "$tmp/repo/chezmoi/dot_psqlrc"
printf 'local modification\n' >> "$HOME/.psqlrc"
printf 'another upstream modification\n' >> "$tmp/repo/chezmoi/dot_psqlrc"
if "$tmp/repo/common-setup/chezmoi-setup.sh"; then echo 'Expected local edit to stop update' >&2; exit 1; fi
[ "$(tail -1 "$HOME/.psqlrc")" = 'local modification' ]
# Refuse unmerged Git source even if a user tries to run setup during a conflict.
git -C "$tmp/repo" init -q
git -C "$tmp/repo" add .
git -C "$tmp/repo" -c user.name=Test -c user.email=test@example.invalid commit -qm base
git -C "$tmp/repo" checkout -qb other
printf 'other branch\n' > "$tmp/repo/chezmoi/dot_psqlrc"
git -C "$tmp/repo" add chezmoi/dot_psqlrc
git -C "$tmp/repo" -c user.name=Test -c user.email=test@example.invalid commit -qm other
git -C "$tmp/repo" checkout -q -
printf 'original branch\n' > "$tmp/repo/chezmoi/dot_psqlrc"
git -C "$tmp/repo" add chezmoi/dot_psqlrc
git -C "$tmp/repo" -c user.name=Test -c user.email=test@example.invalid commit -qm original
if git -C "$tmp/repo" -c user.name=Test -c user.email=test@example.invalid merge other >/dev/null 2>&1; then
    echo 'Expected fixture merge conflict' >&2; exit 1
fi
new_home conflict
printf 'untouched\n' > "$HOME/.psqlrc"
if "$tmp/repo/common-setup/chezmoi-setup.sh"; then echo 'Expected conflict to stop update' >&2; exit 1; fi
[ "$(cat "$HOME/.psqlrc")" = untouched ]
new_home gitignore
ln -s "$ROOT/common-setup/gitignore_global" "$HOME/.gitignore_global"
"$ROOT/common-setup/chezmoi-setup.sh" gitignore_global
[ ! -L "$HOME/.gitignore_global" ] && [ -L "$HOME/.gitignore_global.pre-chezmoi" ]
cmp "$HOME/.gitignore_global" "$ROOT/chezmoi/dot_gitignore_global"
printf 'local ignore rule\n' >> "$HOME/.gitignore_global"
if "$ROOT/common-setup/chezmoi-setup.sh" gitignore_global; then echo 'Expected local ignore edit to stop update' >&2; exit 1; fi
[ "$(tail -1 "$HOME/.gitignore_global")" = 'local ignore rule' ]
for name in pystartup pdbrc tmux.conf profile bashrc; do
    new_home "test-$name"
    ln -s "$ROOT/common-setup/$name" "$HOME/.$name"
    "$ROOT/common-setup/chezmoi-setup.sh" "$name"
    [ ! -L "$HOME/.$name" ] && [ -L "$HOME/.$name.pre-chezmoi" ]
    cmp "$HOME/.$name" "$ROOT/chezmoi/dot_$name"
done
for name in zshrc vimrc; do
    new_home "test-$name"
    case "$name" in zshrc) old="$ROOT/common-setup/zsh/zshrc" ;; vimrc) old="$ROOT/common-setup/vim/vimrc" ;; esac
    ln -s "$old" "$HOME/.$name"
    "$ROOT/common-setup/chezmoi-setup.sh" "$name"
    [ ! -L "$HOME/.$name" ] && [ -L "$HOME/.$name.pre-chezmoi" ]
    cmp "$HOME/.$name" "$ROOT/chezmoi/dot_$name"
done
echo 'chezmoi setup tests passed'
