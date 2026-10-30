#!/bin/bash
# Run to setup with ./setup.sh
BASH_DIR="${HOME}/.bash.d"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ensures referencing local files is simpler
cd $SCRIPT_DIR

set -e #exit on error
[[ -n $DEBUG ]] && set -x

# read local environment variables, like auth tokens
if [ -e "${HOME}/.secret" ]; then
  [[ -n $DEBUG ]] && set +x
  source "${HOME}/.secret"
  [[ -n $DEBUG ]] && set -x
fi

pushd "$SCRIPT_DIR" > /dev/null

ROOT="$SCRIPT_DIR/.."
source "$ROOT/shared.lib"

mkdir -p "${BASH_DIR}"
mkdir -p "${HOME}/bin"
mkdir -p "$HOME/.config"

mkdir -p "$HOME/.config/fish"
"$SCRIPT_DIR/chezmoi-link.sh" fish
if command_exists fisher; then
    # Bass makes it easy to use utilities written for Bash in fish shell.
    # Bass is simple to use. Just prefix your bash utility command with bass.
    # See https://github.com/edc/bass?tab=readme-ov-file#example
    #
    # alternative: exec bash -c "source some-bash-setup.sh; exec fish".
    fisher install edc/bass
fi

if [ -e "$HOME/.bash_profile" ]; then
    info "We don't use .bash_profile to avoid trouble. Renaming to .bash_profile.bak"
    if [ -e "$HOME/.bash_profile.bak" ] || [ -L "$HOME/.bash_profile.bak" ]; then
        echo 'Existing .bash_profile.bak: refusing to overwrite backup' >&2; exit 1
    fi
    mv "$HOME/.bash_profile" "$HOME/.bash_profile.bak"
fi



# Zsh

# create needed dirs
mkdir -p "$HOME/.tmux";
mkdir -p "$HOME/.tmux/plugins";

[[ ! -e "$HOME/.tmux/plugins/tpm" ]] && git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm

# Checks out the Vundle submodule
git submodule update --init --recursive

# Before the vim plugins: gh (a mise tool) is the git credential helper in gitconfig
h2 "Mise: tool version manager (replaces asdf and Volta)"
if [[ ! -x "$MISE_BIN" ]]; then
    h3 "Installing mise to $MISE_BIN"
    # Official installer, verifies checksums. MISE_INSTALL_HELP=0 silences the "add this to your rc" hint.
    curl -fsSL https://mise.run | MISE_INSTALL_HELP=0 sh
fi

MISE_CONF="$HOME/.config/mise/config.toml"
mkdir -p "$(dirname "$MISE_CONF")"
if [[ -e "$MISE_CONF" && ! -L "$MISE_CONF" ]] && ! cmp -s "$MISE_CONF" "$SCRIPT_DIR/mise/config.toml"; then
    echo "Preserving local mise configuration: $MISE_CONF" >&2
    exit 1
fi
if [[ ! -e "$MISE_CONF" && ! -L "$MISE_CONF" ]]; then
    ln -s "$SCRIPT_DIR/mise/config.toml" "$MISE_CONF"
fi

# mise also reads ~/.tool-versions; remove the old asdf symlink so it cannot shadow the config
if [[ -L "$HOME/.tool-versions" ]]; then
    h3 "Removing legacy asdf ~/.tool-versions symlink"
    rm "$HOME/.tool-versions"
fi

for legacy in "$HOME/.asdf" "$HOME/.volta" "$HOME/bin/asdf" "$HOME/.bun"; do
    [[ -e "$legacy" ]] && warn "Legacy tool install found: $legacy — safe to remove now that mise manages it"
done

use_mise_shims
h3 "Installing tools from ~/.config/mise/config.toml (first run takes a while)"
MISE_YES=1 "$MISE_BIN" install || warn "mise install failed for some tool. Fix and re-run ./setup.sh (the rest of the setup continues)"

"$SCRIPT_DIR/chezmoi-link.sh" mise
"$SCRIPT_DIR/chezmoi-link.sh" fish

h2 "Setting up Git identity"
"$SCRIPT_DIR/git-identity-setup.sh"

h2 "Setting up chezmoi-managed config"
"$SCRIPT_DIR/chezmoi-setup.sh" gitconfig
"$SCRIPT_DIR/chezmoi-setup.sh" gitignore_global
"$SCRIPT_DIR/chezmoi-setup.sh" psqlrc
"$SCRIPT_DIR/chezmoi-setup.sh" pystartup
"$SCRIPT_DIR/chezmoi-setup.sh" pdbrc
"$SCRIPT_DIR/chezmoi-setup.sh" tmux.conf
"$SCRIPT_DIR/chezmoi-setup.sh" profile
"$SCRIPT_DIR/chezmoi-setup.sh" bashrc
"$SCRIPT_DIR/chezmoi-setup.sh" zshrc
"$SCRIPT_DIR/chezmoi-setup.sh" vimrc

"$SCRIPT_DIR/chezmoi-runtime.sh"

h2 "Installing all VIM plugins"
info "(might take some time the first time ... )"
vim +PlugInstall +qall

h2 "Vim Fugitive setup"
vim -X -u NONE -c "helptags ~/.vim/plugged/vim-fugitive/doc" -c q


# Resolve an explicitly configured 1Password reference without logging values.
if [[ -n $DEBUG ]]; then set +x; fi
"$SCRIPT_DIR/chezmoi-secret.sh"
if [ -f "$HOME/.secret" ]; then source "$HOME/.secret"; fi
if [[ -n $DEBUG ]]; then set -x; fi

# A token from ~/.secret or an optional 1Password reference is rendered privately.
# Disable xtrace around credentials, including shell variable assignments.
if [[ -n $DEBUG ]]; then set +x; fi
NGROK_AUTHTOKEN="${NGROK_AUTHTOKEN:-}" "$SCRIPT_DIR/chezmoi-ngrok.sh"
if [[ -n $DEBUG ]]; then set -x; fi

# Download to latest to home dir
h2 "Fetching rupa/z (Jump Around)"
curl -s https://raw.githubusercontent.com/rupa/z/master/z.sh -o ~/bin/z.sh

[[ ! -e ~/.config ]] && mkdir ~/.config
[[ ! -e ~/.config/alacritty ]] && mkdir ~/.config/alacritty
"$SCRIPT_DIR/chezmoi-link.sh" alacritty

mkdir -p "$HOME/.gemini/policies"
"$SCRIPT_DIR/chezmoi-link.sh" gemini-settings
"$SCRIPT_DIR/chezmoi-link.sh" gemini-rules

./fonts.sh
"$SCRIPT_DIR/update-completion-scripts.sh"

h2 "Finished common setup"
popd > /dev/null
