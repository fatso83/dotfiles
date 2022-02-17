#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes for printing
source ../common-setup/bash.d/colors

if [[ ! -e ~/bin ]]; then
    mkdir ~/bin
fi

# millis
make install 

# signal-reset
if ! which signal-reset > /dev/null; then
    echo signal-reset not found ... building.
    pushd signal-reset > /dev/null
    make
    cp signal-reset $HOME/bin/
    popd > /dev/null
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
