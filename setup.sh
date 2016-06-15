#!/bin/bash
# I might have some actual content here at some time, 
# looking up per-machine stuff, but not right now

# Just delegate down
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes for printing
source common-setup/bash.d/colors

echo -e $(blue "Installing common setup")
common-setup/setup.sh

# Add the little `millis` util for cross-platform millisecond support
echo -e $(blue "Adding scripts and binary utilities")
pushd "$SCRIPT_DIR/utils" > /dev/null
make install 
popd > /dev/null

"$SCRIPT_DIR"/per-host-config/setup.sh

# Restore current directory of user
popd > /dev/null
