#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes for printing
source ../common-setup/bash.d/colors

if [[ ! -e ~/bin ]]; then
    mkdir ~/bin
fi

function has-command(){
    command -v $1 > /dev/null;
}

has-command millis || (printf "Installing millis utility \n"; cd millis; make install > /dev/null)

if ! has-command signal-reset; then
    printf "Installing signal-reset\n"
    _f(){
        cd signal-reset 
        make
        cp signal-reset $HOME/bin/
    }
    _f > /dev/null
fi

# inotify-info
# The better native version of my own script :D 
if ! has-command inotify-info; then
    printf "Installing inotify-info\n"
    _f(){
        cd inotify-info/
        make
        cp _release/inotify-info $HOME/bin/
    }
    _f > /dev/null
fi


# scripts
ln -sf "$SCRIPT_DIR/scripts/"* $HOME/bin/

# Dependencies for scripts
python3 -m pip install --user --upgrade pip
python3 -m pip install --user smsutil
python3 -m pip install --user requests 

npm install

# Restore current directory of user
popd > /dev/null
