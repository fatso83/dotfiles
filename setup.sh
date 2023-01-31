#!/bin/bash

# Just delegate down
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Init submodules
git submodule init
git submodule update

ROOT="$SCRIPT_DIR"
source "$ROOT/shared.lib"

h1 "Installing common setup"
common-setup/setup.sh || fail "Failed common setup"

h1 "Install config specific to this machine"
per-host-config/setup.sh || fail "Failed machine specific setup"

# Add the little `millis` util for cross-platform millisecond support
h1 "Adding scripts and binary utilities"
utils/setup.sh || fail "Failed utils setup"

# Restore current directory of user
popd > /dev/null

# Re-read BASH settings
banner "Remember to 'source ~/.bashrc'!"
