#!/bin/bash

set -e

# Just delegate down
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SCRIPT_DIR/.."
source "$ROOT/shared.lib"
pushd "$SCRIPT_DIR" > /dev/null || fail

if command_exists asdf; then
    V_WANTED=$(sed -n -e '/nodejs/s/nodejs //p' "$ROOT/common-setup/tool-versions")
    V_IN_USE=$(asdf current nodejs 2> /dev/null | awk '{print $2}')

    if [[ "$V_IN_USE" != "$V_WANTED" ]]; then
        h3 'Current wanted NodeJS version not matching target. Re-shimming ...'
        asdf install nodejs "$V_WANTED"
        asdf reshim nodejs
    fi
fi
