#!/bin/bash

# Just delegate down
BASH_DIR="${HOME}/.bash.d"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Init submodules
git submodule init
git submodule update

if [ ! -e "$HOME/bin" ]; then
  mkdir "${HOME}/bin"
fi
ln -sf "$SCRIPT_DIR/utils/scripts/"* $HOME/bin/

ROOT="$SCRIPT_DIR"

if [ ! -e "$BASH_DIR" ]; then
  mkdir "${BASH_DIR}"
fi

for file in "$ROOT"/common-setup/bash.d/*; do
  ln -sf "$file" "${BASH_DIR}"/
done
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
