#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SCRIPT_DIR/../../../"
BIN="$ROOT/utils/scripts"
PATH="$BIN:$PATH"

pushd "$SCRIPT_DIR" > /dev/null
source "$ROOT/shared.lib"

set -e 

# hacking around a bug
h2 "Customizing systray icons for Electron apps due to the Ubuntu XDG_... bug"
for f in *.desktop; do
    sudo cp $f /usr/share/applications/
done


h2 "Removing (almost) all Gnome key bindings ..." # crashes with IntelliJ products
gnome-key-bindings --unset-all --except 'close|switch-applications|switch-input-source|show-desktop|maximize'
gnome-key-bindings --set=switch-applications '<Alt>Tab'
gnome-key-bindings --set=switch-applications-backward '<Alt><Shift>Tab'

# https://askubuntu.com/questions/1396900/why-does-not-the-gnome-keyboard-settings-override-clear-the-xkb-settings
h2 "Removing XKB input source setting messing all Alt-Shift shortcuts up"
gsettings reset org.gnome.desktop.input-sources xkb-options
TMP=$(mktemp)
grep -v XKBOPTIONS= /etc/default/keyboard > $TMP; sudo mv $TMP /etc/default/keyboard

h2 "Pointing Flameshot config to dotfiles folder"
# hack to get around the fact that a new file is created on Save, preventing hard links
rm -rf ~/.config/Dharkael 2>/dev/null
ln -sf "$SCRIPT_DIR" ~/.config/Dharkael

popd  > /dev/null

