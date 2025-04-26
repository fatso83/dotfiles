#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

ROOT="$SCRIPT_DIR/.."
source "$ROOT/shared.lib"

if [[ ! -e ~/bin ]]; then
    mkdir ~/bin
fi

if ! command_exists millis ; then
    h2 "Installing 'millis'"
    pushd millis > /dev/null
    make install 
    popd > /dev/null
fi

if ! command_exists signal-reset; then
    h2 "Installing 'signal-reset'"
    pushd signal-reset > /dev/null
    make
    cp signal-reset $HOME/bin/
    popd > /dev/null
fi

# inotify-info
# The better native version of my own script :D 
if (! is_mac ) && (! is_wsl)  && (! command_exists inotify-info); then
    h2 "Installing inotify-info"
    pushd inotify-info/
    make
    cp _release/inotify-info ~/bin/
    popd
fi

if (! command_exists fetch-todays-calendar); then
    h2 "Install utility to fetch todays calendar"
    WRAPPER="$HOME/bin/fetch-todays-calendar"
    cd ./fetch-todays-calendar
    npm i
    cd ..
    command cat > $WRAPPER <<__DELIM
#!/usr/bin/env bash
# vi: ft=bash

cd "${SCRIPT_DIR}/fetch-todays-calendar"
node app.js \$@
__DELIM
    chmod +x "$WRAPPER"
fi

# symlink all scripts
ln -sf "$SCRIPT_DIR/scripts/"* $HOME/bin/

h3 'Installing dependencies for scripts'
h3 'Python dependencies'
(python3 -m pip install --user smsutil && python3 -m pip install --user requests ) | grep -v 'Requirement already satisfied'

if command_exists npm; then
    h3 'Node dependencies'
    npm install
fi

h3 'Java formatter'
curl -s -o java-formatter.jar https://github.com/google/google-java-format/releases/download/v1.25.2/google-java-format-1.25.2-all-deps.jar
cat ./jar-executable.preamble java-formatter.jar > ~/bin/google-java-format
rm ./java-formatter.jar
chmod +x ~/bin/google-java-format

# This works together with a git config for the type "vimcrypt"
h3 'Vim encrypted file diffing support'
curl -s -o ~/bin/vimdecrypt.py https://raw.githubusercontent.com/fatso83/vimdecrypt/refs/heads/publicbranch/vimdecrypt.py
chmod +x ~/bin/vimdecrypt.py

# Restore current directory of user
(popd > /dev/null || exit)
