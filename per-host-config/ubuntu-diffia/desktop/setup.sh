#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# hacking around a bug
echo Customizing systray icons for Electron apps on Ubuntu 
for f in *.desktop; do
    sudo cp $f /usr/share/applications/
done

popd  > /dev/null

