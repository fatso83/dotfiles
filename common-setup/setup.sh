#!/bin/bash
# Run to setup with ./setup.sh
MAIN_DIR="$HOME" 
DEST="${MAIN_DIR}"
BASH_DIR="${MAIN_DIR}/.bash.d"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "$SCRIPT_DIR" > /dev/null

source "$SCRIPT_DIR/bash.d/colors"

if [ ! -e "$MAIN_DIR" ]; then
  echo Destination ${MAIN_DIR} does not exist
  exit 1
fi

if [ ! -e "$BASH_DIR" ]; then
  mkdir "${BASH_DIR}"
fi

rm -r "$DEST"/.bash_completion.d
ln -s "$SCRIPT_DIR"/bash_completion.d "$DEST"/.bash_completion.d 

ln -sf "$SCRIPT_DIR"/profile "$DEST"/.profile
ln -sf "$SCRIPT_DIR"/bashrc "$DEST"/.bashrc
ln -sf "$SCRIPT_DIR"/gitconfig "$DEST"/.gitconfig
ln -sf "$SCRIPT_DIR"/gitignore_global "$DEST"/.gitignore_global
ln -sf "$SCRIPT_DIR"/pystartup "$DEST"/.pystartup
ln -sf "$SCRIPT_DIR"/tmux.conf "$DEST"/.tmux.conf

# Zsh
ln -sf "$SCRIPT_DIR"/zsh/zshrc "$DEST"/.zshrc

# create needed dirs
[[ ! -e "$DEST/.tmux" ]] && mkdir "$DEST/.tmux";
[[ ! -e "$DEST/.tmux/plugins" ]] && mkdir "$DEST/.tmux/plugins";
[[ ! -e "$DEST/.tmux/plugins/tpm" ]] && git clone https://github.com/tmux-plugins/tpm "$DEST"/.tmux/plugins/tpm 

for file in "$SCRIPT_DIR"/bash.d/*; do
  ln -sf "$file" "${BASH_DIR}"/
done

# Remove any existing symlink (or dir on mingw) - will fail if it is a dir
rm -rf "$DEST"/.vim 2>/dev/null
if [ ! -e "$DEST"/.vim ]; then  
    ln -sf "$SCRIPT_DIR"/vim/dotvim "$DEST"/.vim
fi

ln -sf "$SCRIPT_DIR"/vim/vimrc "$DEST"/.vimrc

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

touch "$DEST"/.vimrc.local

# Install NeoVim config (we don't have to worry about XDG_CONFIG_HOME stuff
[[ ! -e "$DEST"/.config ]] && mkdir "$DEST/.config"
rm -rf ~/.config/nvim 
ln -sf ~/.vim ~/.config/nvim
ln -sf ~/.vimrc ~/.config/nvim/init.vim

# Install a better matcher for Ctrl-P
cd matcher
make 
make install PREFIX=$HOME
cd ..

# Make a config file for ngrok
[[ ! -e "$DEST"/.ngrok2 ]] && mkdir "$DEST/.ngrok2"
ln -sf $SCRIPT_DIR/ngrok.yml $DEST/.ngrok2/ngrok.yml

popd > /dev/null
