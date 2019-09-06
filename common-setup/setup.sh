#!/bin/bash
# Run to setup with ./setup.sh
BASH_DIR="${HOME}/.bash.d"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# read local environment variables, like auth tokens
source ~/.secret

pushd "$SCRIPT_DIR" > /dev/null

source "$SCRIPT_DIR/bash.d/colors"

if [ ! -e "$BASH_DIR" ]; then
  mkdir "${BASH_DIR}"
fi

rm -r "$HOME"/.bash_completion.d
ln -s "$SCRIPT_DIR"/bash_completion.d "$HOME"/.bash_completion.d 

ln -sf "$SCRIPT_DIR"/profile "$HOME"/.profile
ln -sf "$SCRIPT_DIR"/bashrc "$HOME"/.bashrc
ln -sf "$SCRIPT_DIR"/gitconfig "$HOME"/.gitconfig
ln -sf "$SCRIPT_DIR"/gitignore_global "$HOME"/.gitignore_global
ln -sf "$SCRIPT_DIR"/pystartup "$HOME"/.pystartup
ln -sf "$SCRIPT_DIR"/tmux.conf "$HOME"/.tmux.conf

# Zsh
ln -sf "$SCRIPT_DIR"/zsh/zshrc "$HOME"/.zshrc

# create needed dirs
[[ ! -e "$HOME/.tmux" ]] && mkdir "$HOME/.tmux";
[[ ! -e "$HOME/.tmux/plugins" ]] && mkdir "$HOME/.tmux/plugins";
[[ ! -e "$HOME/.tmux/plugins/tpm" ]] && git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm 

# copy tmux project settings
for file in "$SCRIPT_DIR"/tmux/*.proj; do
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

echo  -n -e $(blue "Installing all VIM plugins")
echo -e $(dark_grey "(might take some time the first time ... )")
vim +PlugInstall +qall

# Vim Fugitive setup
vim -u NONE -c "helptags vim-fugitive/doc" -c q

# Needed for Typescript support in CoC and YCM using tsserver
ts_cmd='npm install -g typescript'
if which npm > /dev/null 2>&1 ; then
    which tsc > /dev/null 2>&1 || bash -c "$ts_cmd"
else
    echo "Install NodeJS and run '$ts_cmd' to get TypeScript support in Vim"
fi

touch "$HOME"/.vimrc.local

# Install NeoVim config (we don't have to worry about XDG_CONFIG_HOME stuff
[[ ! -e "$HOME"/.config ]] && mkdir "$HOME/.config"
rm -rf ~/.config/nvim 
ln -sf ~/.vim ~/.config/nvim
ln -sf ~/.vimrc ~/.config/nvim/init.vim

# Install a better matcher for Ctrl-P
cd matcher
make 
make install PREFIX=$HOME
cd ..

# Make a config file for ngrok, passing in the secret auth token
[[ ! -e "$HOME"/.ngrok2 ]] && mkdir "$HOME/.ngrok2"
NGROK_YML="$HOME/.ngrok2/ngrok.yml"
cat > "$NGROK_YML" << EOF
###############################################################
## WARNING: this file is auto-generated. See dotfiles repo   ##
###############################################################
authtoken: ${NGROK_AUTHTOKEN} 

EOF
cat $SCRIPT_DIR/ngrok.yml >> "$NGROK_YML"

# Postgres config
ln -sf "$SCRIPT_DIR"/psqlrc $HOME/.psqlrc

popd > /dev/null
