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
  source "${HOME}/.secret"
fi

pushd "$SCRIPT_DIR" > /dev/null

ROOT="$SCRIPT_DIR/.."
source "$ROOT/shared.lib"

mkdir -p "${BASH_DIR}"
mkdir -p "${HOME}/bin"
mkdir -p "$HOME/.config"

mkdir -p "$HOME/.config/fish"
ln -sf "$SCRIPT_DIR"/config.fish "$HOME"/.config/fish/
if command_exists fisher; then
    # Bass makes it easy to use utilities written for Bash in fish shell.
    # Bass is simple to use. Just prefix your bash utility command with bass.
    # See https://github.com/edc/bass?tab=readme-ov-file#example
    #
    # alternative: exec bash -c "source some-bash-setup.sh; exec fish".
    fisher install edc/bass
fi

rm -rf "$HOME"/.bash_completion.d 2>/dev/null
ln -sf "$SCRIPT_DIR"/bash_completion.d "$HOME"/.bash_completion.d

if [ -e "$HOME/.bash_profile" ]; then
    info "We don't use .bash_profile to avoid trouble. Renaming to .bash_profile.bak"
    mv ~/.bash_profile{,.bak}
fi

carefully_replace_gitconfig(){
    if ! command_exists envsubst; then
        warn "Unable to configure Git: missing 'envsubst'. Finish the per-computer setup and re-run ./setup.sh"
        return
    fi

    h2 "Configuring Git ..."

    local personal_details_file="$HOME/.gitconfig-personal"
    local git_name
    local git_email
    git_name=$(git config --global user.name || :)
    git_email=$(git config --global user.email || :)

    debug "Git user.name: $git_name"
    debug "Git user.email: $git_email"

    if [[ -e "$personal_details_file" ]]; then
        debug "Found personal details file for Git. Re-using."
    else
        h3 "Creating personal details file for Git ($personal_details_file)"

        if [[ "" == "$git_name" ]]; then
            debug "No committer name set in the global gitconfig."
            read -r -p "Input the name to be used by Git in your commits (e.g. \"John Doe\"): " git_name
        fi
        if [[ "" == "$git_email" ]]; then
            debug "No committer email set in the global gitconfig."
            read -r -p "Input the email to be used by Git in your commits (e.g. \"john.doe@google.com\"): " git_email
        fi

        if [[ -z "$git_email" || -z "$git_name" ]]; then
            error "Both email and name must be specified"
            exit 1
        fi

        GIT_NAME=$git_name GIT_EMAIL=$git_email envsubst < ./git-personal.template > "$personal_details_file"
    fi

    ln -sf "$SCRIPT_DIR"/gitconfig "$HOME"/.gitconfig
}

ln -sf "$SCRIPT_DIR"/profile "$HOME"/.profile
ln -sf "$SCRIPT_DIR"/bashrc "$HOME"/.bashrc
ln -sf "$SCRIPT_DIR"/gitignore_global "$HOME"/.gitignore_global
ln -sf "$SCRIPT_DIR"/pystartup "$HOME"/.pystartup
ln -sf "$SCRIPT_DIR"/pdbrc "$HOME"/.pdbrc
ln -sf "$SCRIPT_DIR"/tmux.conf "$HOME"/.tmux.conf

TMS_CONF_DIR="$HOME/.config/tms"
if is_mac; then
    TMS_CONF_DIR="$HOME/Library/Application Support/tms"
fi
mkdir -p "$TMS_CONF_DIR"
TMS_CONF="$TMS_CONF_DIR/config.toml"
if [[ ! -e "$TMS_CONF" ]]; then
    cp "$SCRIPT_DIR"/tms-config.toml "${TMS_CONF_DIR}/config.toml"
fi

carefully_replace_gitconfig

# Zsh
ln -sf "$SCRIPT_DIR"/zsh/zshrc "$HOME"/.zshrc

# create needed dirs
mkdir -p "$HOME/.tmux";
mkdir -p "$HOME/.tmux/plugins";

[[ ! -e "$HOME/.tmux/plugins/tpm" ]] && git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm

# copy tmux project settings
for file in "$SCRIPT_DIR"/tmux/*; do
  ln -sf "$file" "${HOME}/.tmux/"
done

for file in "$SCRIPT_DIR"/bash.d/*; do
  ln -sf "$file" "${BASH_DIR}"/
done

# Remove any existing symlink (or dir on mingw) - will fail if it is a dir
rm -rf "$HOME"/.vim 2>/dev/null
if [ ! -e "$HOME"/.vim ]; then
    ln -sf "$SCRIPT_DIR"/vim/dotvim "$HOME"/.vim
fi

ln -sf "$SCRIPT_DIR"/vim/vimrc "$HOME"/.vimrc

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
if [[ -e "$MISE_CONF" && ! -L "$MISE_CONF" ]]; then
    info "Found a hand-made $MISE_CONF. Renaming to config.toml.bak"
    mv "$MISE_CONF" "$MISE_CONF.bak"
fi
ln -sf "$SCRIPT_DIR/mise/config.toml" "$MISE_CONF"

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

h2 "Installing all VIM plugins"
info "(might take some time the first time ... )"
vim +PlugInstall +qall

h2 "Vim Fugitive setup"
vim -X -u NONE -c "helptags ~/.vim/plugged/vim-fugitive/doc" -c q


# Install NeoVim config (we don't have to worry about XDG_CONFIG_HOME stuff
rm -rf ~/.config/nvim
ln -sf ~/.vim ~/.config/nvim
ln -sf ~/.vimrc ~/.config/nvim/init.vim

# Make a config file for ngrok, passing in the secret auth token
[[ ! -e "$HOME"/.ngrok2 ]] && mkdir "$HOME/.ngrok2"
NGROK_YML="$HOME/.ngrok2/ngrok.yml"
rm "$NGROK_YML" 2> /dev/null || :;
cat > "$NGROK_YML" << EOF
###############################################################
## WARNING: this file is auto-generated. See dotfiles repo   ##
###############################################################
authtoken: ${NGROK_AUTHTOKEN:-'fill-NGROK_AUTHTOKEN-in-in-~/.secret'}

EOF
cat "$SCRIPT_DIR/ngrok.yml" >> "$NGROK_YML"

h2 "Copying psql config"
ln -sf "$SCRIPT_DIR"/psqlrc "$HOME/.psqlrc"

# Download to latest to home dir
h2 "Fetching rupa/z (Jump Around)"
curl -s https://raw.githubusercontent.com/rupa/z/master/z.sh -o ~/bin/z.sh

[[ ! -e ~/.ssh ]] && mkdir ~/.ssh
rm -f ~/.ssh/allowed_signers 2>/dev/null
ln ./allowed_signers ~/.ssh/

[[ ! -e ~/.config ]] && mkdir ~/.config
[[ ! -e ~/.config/alacritty ]] && mkdir ~/.config/alacritty
ln -sf "$PWD"/alacritty.toml ~/.config/alacritty/alacritty.toml

mkdir -p "$HOME/.gemini/policies"
ln -sf "$PWD"/gemini/settings.json ~/.gemini/
ln -sf "$PWD"/gemini/my-rules.toml ~/.gemini/policies/

./fonts.sh
"$SCRIPT_DIR/update-completion-scripts.sh"

h2 "Finished common setup"
popd > /dev/null
