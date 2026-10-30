#!/bin/bash
# Deploy user configuration only; no package installation, downloads or OS changes.
set +x
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
command -v chezmoi >/dev/null || { echo 'Install chezmoi before applying configuration.' >&2; exit 1; }
machine="${1:-}"
if [ -z "$machine" ] && [ -f "$HOME/.dotfiles-machine" ]; then machine=$(cat "$HOME/.dotfiles-machine"); fi
if [ -n "$machine" ]; then
 case "$machine" in *[!a-zA-Z0-9_-]*|_shared) echo 'Invalid machine profile' >&2; exit 1;; esac
 [ -d "$ROOT/per-host-config/$machine" ] || { echo 'Unknown machine profile' >&2; exit 1; }
fi
[ -z "$(git -C "$ROOT" ls-files -u)" ] || { echo 'Resolve Git conflicts before applying configuration.' >&2; exit 1; }
# Establish identity before .gitconfig starts including its private identity file.
"$ROOT/common-setup/git-identity-setup.sh"
for file in gitconfig gitignore_global psqlrc pystartup pdbrc tmux.conf profile bashrc zshrc vimrc; do
 "$ROOT/common-setup/chezmoi-setup.sh" "$file"
done
for link in mise fish alacritty gemini-settings gemini-rules; do "$ROOT/common-setup/chezmoi-link.sh" "$link"; done
"$ROOT/common-setup/chezmoi-runtime.sh"
if [ -n "$machine" ]; then
 "$ROOT/per-host-config/chezmoi-host.sh" "$machine"
 "$ROOT/per-host-config/chezmoi-mise.sh" "$machine"
 case "$machine" in
  mac-work) "$ROOT/per-host-config/mac-work/chezmoi-mac.sh"
    "$ROOT/common-setup/chezmoi-ssh.sh" ;;
  ubuntu)
   if [ "${DOTFILES_WSL:-}" = 1 ] || [ -n "${WSL_DISTRO_NAME:-}" ]; then
    "$ROOT/per-host-config/chezmoi-host.sh" ubuntu wsl
   else
    "$ROOT/per-host-config/chezmoi-host.sh" ubuntu desktop
    "$ROOT/common-setup/chezmoi-ssh.sh"
   fi ;;
 esac
fi
# Never execute ~/.secret here. Explicit environment references/tokens opt in.
"$ROOT/common-setup/chezmoi-secret.sh"
"$ROOT/common-setup/chezmoi-ngrok.sh"
printf 'Configuration applied. Package installation and OS provisioning are separate.\n'
