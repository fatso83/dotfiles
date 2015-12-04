#!/bin/bash
# I might have some actual content here at some time, 
# looking up per-machine stuff, but not right now

# Just delegate down
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "$SCRIPT_DIR/common-setup" > /dev/null
echo Installing common setup
./setup.sh
popd > /dev/null


# Add the little `millis` util for cross-platform millisecond support
echo Adding scripts and binary utilities
pushd "$SCRIPT_DIR/utils" > /dev/null
make install 
popd > /dev/null

#echo TODO: Install per-machine config
# perhaps look up some token?
