#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null
source ../../../common-setup/bash.d/colors

# hacking around a bug
blue "Customizing systray icons for Electron apps on Ubuntu ...\n"
for f in *.desktop; do
    sudo cp $f /usr/share/applications/
done


blue "Removing (almost) all Gnome key bindings ...\n" # crashes with IntelliJ products
../../../utils/scripts/gnome-key-bindings --unset-all --except 'close|switch-applications|switch-input-source|show-desktop|maximize'

ln -f flameshot.ini ~/.config/Dharkael/flameshot.ini

popd  > /dev/null

