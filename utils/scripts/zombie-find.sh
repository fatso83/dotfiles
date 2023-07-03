#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/cross-platform-utils.bashlib

if is_mac; then
    echo "Only works on Linux"
    exit 1
fi
ps -elf --forest | grep -B5 '<[d]efunct>'
