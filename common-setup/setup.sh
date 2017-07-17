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

# Installs all Vundle and quits all windows
echo  -n -e $(blue "Installing all VIM plugins")
echo -e $(dark_grey "(might take some time the first time ... )")
vim +PluginInstall +qall

if [[ -e ~/.vim/bundle/YouCompleteMe ]]; then
    if [[ $(uname) == "Linux" ]]; then
        sudo apt-get install -y python-dev python3-dev
    fi

    # Check if YCM has been compiled already - if so, drop compiling again
    # The ".*" matches both *.dll and *.so 
    ycm_lib=$(echo ~/.vim/bundle/YouCompleteMe/third_party/ycmd/ycm_core.* )
    if [[ ! -e "$ycm_lib" ]]; then
        # Compiles YouCompleteMe with semenatic support for C-family languages
        # This needs to happen each time the YCM repo has been deleted
        echo -e $(blue "Compiling YouCompleteMe") "(takes a minute or two)"

        pushd ~/.vim/bundle/YouCompleteMe

        # Enable auto-completion support for all available languages
        # (TypeScript, Javascript, Rust, C#, ...)
         ./install.py --all

         # six smooths out differences between python 2 and 3
         pip install six
        popd
    fi
fi

# Semantic Typescript support for YCM
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

popd > /dev/null
