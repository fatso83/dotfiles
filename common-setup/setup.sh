#!/bin/bash
# Run to setup with ./setup.sh
BASH_DIR="${HOME}/.bash.d"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

rm -rf "$HOME"/.bash_completion.d 2>/dev/null
ln -sf "$SCRIPT_DIR"/bash_completion.d "$HOME"/.bash_completion.d 

if [ -e "$HOME/.bash_profile" ]; then
    info "We don't use .bash_profile to avoid trouble. Renaming to .bash_profile.bak"
    mv ~/.bash_profile{,.bak}
fi

h2 "Setup base tool versions using ASDF"
ln -sf "$SCRIPT_DIR/tool-versions" $HOME/.tool-versions

carefully_replace_gitconfig(){
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

h2 "Installing all VIM plugins"
info "(might take some time the first time ... )"
vim +PlugInstall +qall

h2 "Vim Fugitive setup"
vim -X -u NONE -c "helptags ~/.vim/plugged/vim-fugitive/doc" -c q

# Needed for Typescript support in CoC using tsserver
ts_cmd='npm install -g typescript'
if which npm > /dev/null 2>&1 ; then
    which tsc > /dev/null 2>&1 || bash -c "$ts_cmd"
else
    banner "Install NodeJS and run '$ts_cmd' to get TypeScript support in Vim"
fi

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

if ! command_exists starship; then
    h2 "Installing Starship from source"
    curl -sS https://starship.rs/install.sh | sh
fi

if ! command_exists bun; then
    h2 "Installing Bun from online installer"
    curl -fsSL https://bun.sh/install | bash
fi

[[ ! -e ~/.ssh ]] && mkdir ~/.ssh
rm -f ~/.ssh/allowed_signers 2>/dev/null
ln ./allowed_signers ~/.ssh/

[[ ! -e ~/.config ]] && mkdir ~/.config
[[ ! -e ~/.config/alacritty ]] && mkdir ~/.config/alacritty
ln -sf ~/dev/dotfiles/common-setup/alacritty.toml ~/.config/alacritty/alacritty.toml 

./fonts.sh
"$SCRIPT_DIR/update-completion-scripts.sh"

h2 "Finished common setup"
popd > /dev/null
