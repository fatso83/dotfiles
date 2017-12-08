#!/bin/bash

# Just delegate down
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Init submodules
git submodule init
git submodule update

# Get some color codes for printing
source common-setup/bash.d/colors

echo -e $(blue "Installing common setup")
common-setup/setup.sh

# Add the little `millis` util for cross-platform millisecond support
echo -e $(blue "Adding scripts and binary utilities")
utils/setup.sh

echo "Install config specific to this machine"
per-host-config/setup.sh

# Restore current directory of user
popd > /dev/null

# Re-read BASH settings
source ~/.bashrc
