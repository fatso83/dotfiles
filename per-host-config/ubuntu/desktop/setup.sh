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
gnome-key-bindings --set=switch-applications '<Alt>Tab'
gnome-key-bindings --set=switch-applications-backward '<Alt><Shift>Tab'

# https://askubuntu.com/questions/1396900/why-does-not-the-gnome-keyboard-settings-override-clear-the-xkb-settings
blue "Removing XKB input source setting messing all Alt-Shift shortcuts up"
gsettings reset org.gnome.desktop.input-sources xkb-options

blue "Pointing Flameshot config to dotfiles folder\n"
# hack to get around the fact that a new file is created on Save, preventing hard links
rm -rf ~/.config/Dharkael 2>/dev/null
ln -sf "$SCRIPT_DIR" ~/.config/Dharkael

popd  > /dev/null

