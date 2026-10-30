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
unset NGROK_AUTHTOKEN DOTFILES_NGROK_OP_REF DOTFILES_NGROK_TOKEN DOTFILES_NGROK_APPLY
"$ROOT/common-setup/chezmoi-ngrok.sh"
[ ! -e "$HOME/.ngrok2/ngrok.yml" ]
NGROK_AUTHTOKEN='fixture-token' "$ROOT/common-setup/chezmoi-ngrok.sh"
[ "$(stat -f '%Lp' "$HOME/.ngrok2/ngrok.yml" 2>/dev/null || stat -c '%a' "$HOME/.ngrok2/ngrok.yml")" = 600 ]
NGROK_AUTHTOKEN='rotated-fixture' "$ROOT/common-setup/chezmoi-ngrok.sh"
grep -q 'rotated-fixture' "$HOME/.ngrok2/ngrok.yml"
printf 'local user data\n' >> "$HOME/.ngrok2/ngrok.yml"
if NGROK_AUTHTOKEN='other-fixture' "$ROOT/common-setup/chezmoi-ngrok.sh"; then echo 'Expected local change to be protected' >&2; exit 1; fi
[ "$(tail -1 "$HOME/.ngrok2/ngrok.yml")" = 'local user data' ]
# Test the optional 1Password integration with a fake CLI and dummy values.
cat > "$tmp/bin/op" <<'STUB'
#!/bin/sh
case " $* " in
    *" signin "*) printf fixture-session ;;
    *" read "*) printf fixture-from-password-manager ;;
    *) exit 1 ;;
esac
STUB
chmod +x "$tmp/bin/op"
export HOME="$tmp/op-home" XDG_STATE_HOME="$tmp/op-state"
mkdir -p "$HOME"
DOTFILES_NGROK_OP_REF='op://test/item/token' "$ROOT/common-setup/chezmoi-ngrok.sh"
grep -q 'fixture-from-password-manager' "$HOME/.ngrok2/ngrok.yml"
cat > "$tmp/bin/op" <<'STUB'
#!/bin/sh
exit 1
STUB
chmod +x "$tmp/bin/op"
if DOTFILES_NGROK_OP_REF='op://test/item/token' "$ROOT/common-setup/chezmoi-ngrok.sh" >/dev/null 2>&1; then echo 'Expected unavailable password manager to fail' >&2; exit 1; fi
grep -q 'fixture-from-password-manager' "$HOME/.ngrok2/ngrok.yml"
echo 'chezmoi ngrok tests passed'
