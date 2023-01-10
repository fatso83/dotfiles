#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes for printing
source ../common-setup/bash.d/colors
source ../common-setup/bash.d/bash_aliases_functions 

shopt -s expand_aliases

if [[ ! -e ~/bin ]]; then
    mkdir ~/bin
fi

# millis
if ! command -v millis > /dev/null; then
    cd millis
    make install 
fi

# signal-reset
if ! which signal-reset > /dev/null; then
    echo signal-reset not found ... building.
    pushd signal-reset > /dev/null
    make
    cp signal-reset $HOME/bin/
    popd > /dev/null
fi

# inotify-info
# The better native version of my own script :D 
if (! is_mac)  && (! command -v inotify-info > /dev/null); then
    pushd inotify-info/
    make
    cp _release/inotify-info ~/bin/
    popd
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
