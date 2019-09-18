#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null
source ../../../common-setup/bash.d/colors

# hacking around a bug
blue "Customizing systray icons for Electron apps due to the Ubuntu XDG_... bug\n"
for f in *.desktop; do
    sudo cp $f /usr/share/applications/
done


blue "Removing (almost) all Gnome key bindings ...\n" # crashes with IntelliJ products
../../../utils/scripts/gnome-key-bindings --unset-all --except 'close|switch-applications|switch-input-source|show-desktop|maximize'

blue "Pointing Flameshot config to dotfiles folder"
# hack to get around the fact that a new file is created on Save, preventing hard links
rm ~/.config/Dharkael
ln -sf "$SCRIPT_DIR" ~/.config/Dharkael

popd  > /dev/null

