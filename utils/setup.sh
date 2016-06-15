#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes for printing
source ../common-setup/bash.d/colors

# millis
make install 

# scripts
cp scripts/* $HOME/bin/

# Restore current directory of user
popd > /dev/null
