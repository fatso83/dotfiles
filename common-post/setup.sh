#!/bin/bash

set -e

# Just delegate down
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null || fail

# used by the nodejs asdf plugin when installing a new version
ln -sf "$SCRIPT_DIR/default-npm-packages" ~/.default-npm-packages

if command_exists node; then
    V_IN_USE=$(node --version 2> /dev/null| sed 's/v//')
    V_WANTED=$(sed -n -e '/nodejs/s/nodejs //p' tool-versions)

    if [[ "$V_IN_USE" != "$V_WANTED" ]]; then
        h3 'Current wanted NodeJS version not matching target. Re-shimming ...'
        asdf install nodejs "$V_WANTED"
        # the plugin auto-installs everything in ~/.default-npm-packages
        asdf reshim nodejs
    fi
fi

# Needed for Typescript support in CoC using tsserver
ts_cmd='npm install -g typescript'
if command_exists npm ; then
    bash -c "$ts_cmd"
else
    banner "Install NodeJS and run '$ts_cmd' to get TypeScript support in Vim"
fi
