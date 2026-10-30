#!/bin/bash
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$(command -v chezmoi || true)}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"
ln -s "$CHEZMOI_BIN" "$tmp/bin/chezmoi"
export PATH="$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin" HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" XDG_CACHE_HOME="$tmp/cache"
unset DOTFILES_SECRET_OP_REF DOTFILES_SECRET_APPLY
"$ROOT/common-setup/chezmoi-secret.sh"
[ ! -e "$HOME/.secret" ]
cat > "$tmp/bin/op" <<'STUB'
#!/bin/sh
case " $* " in
 *" signin "*) printf fixture-session ;;
 *" read "*) printf 'export FIXTURE_TOKEN=fake\n' ;;
 *) exit 1 ;;
esac
STUB
chmod +x "$tmp/bin/op"
export DOTFILES_SECRET_OP_REF='op://test/item/shell'
"$ROOT/common-setup/chezmoi-secret.sh"
[ "$(stat -f '%Lp' "$HOME/.secret" 2>/dev/null || stat -c '%a' "$HOME/.secret")" = 600 ]
grep -q FIXTURE_TOKEN "$HOME/.secret"
printf 'local fixture\n' > "$HOME/.secret"
"$ROOT/common-setup/chezmoi-secret.sh"
[ "$(cat "$HOME/.secret")" = 'local fixture' ]
rm "$HOME/.secret"
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/op"
if "$ROOT/common-setup/chezmoi-secret.sh"; then exit 1; fi
[ ! -e "$HOME/.secret" ]
echo 'chezmoi secret tests passed'
