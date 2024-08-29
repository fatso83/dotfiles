#!/bin/bash
# Probably works in most other shells as well
# Based on (buggy) script in https://gist.github.com/fraune/0831edc01fa89f46ce43b8bbc3761ac7, which
# again comes from https://azimi.io/how-to-enable-touch-id-for-sudo-on-macbook-pro-46272ac3e2df

# exit on error
set -e

# https://gist.github.com/fraune/0831edc01fa89f46ce43b8bbc3761ac7?permalink_comment_id=5171048#gistcomment-5171048
SUDO_FILE=/etc/pam.d/sudo_local

tmux_fix(){
  PAM_REATTACH_MODULE=/opt/homebrew/lib/pam/pam_reattach.so
  if ! command -v tmux > /dev/null; then
      # tmux is not installed, quitting early
      return 0
  fi

  if ! [[ -e "$PAM_REATTACH_MODULE" ]]; then
      printf "The pam_reattach module is not found (%s). \
Install it using Homebrew to have Touch ID work in tmux." "$PAM_REATTACH_MODULE"
      return 1
  fi

  grep -q "$PAM_REATTACH_MODULE" $SUDO_FILE || sudo sed -i '' '1i\
auth       optional       /opt/homebrew/lib/pam/pam_reattach.so ignore_ssh
' $SUDO_FILE
}


enable_touch_id(){
  RE_PAM_TID='^auth[[:space:]]+sufficient[[:space:]]+pam_tid.so'
  if egrep -q "$RE_PAM_TID"  "$SUDO_FILE"; then
    echo "Touch ID is enabled for sudo"
  else
    set -x
    read -p "Touch ID is not enabled for sudo. Would you like to enable it now? [y/n]: " RESPONSE
    shopt -s extglob # enables extended globbing
  
    if [[ $RESPONSE == [yY] ]]; then
      sudo egrep -q "$RE_PAM_TID" $SUDO_FILE || sudo sed -i '' '1i\
auth       sufficient     pam_tid.so
' $SUDO_FILE
      if egrep -q "$RE_PAM_TID" $SUDO_FILE; then
        echo "'auth sufficient pam_tid.so' added to $SUDO_FILE"
      fi
    else
      echo "No modifications were made to $SUDO_FILE"
    fi
  fi
}

if [[ ! -e "$SUDO_FILE" ]]; then
    # Create file with one line to not make sed bork
    echo | sudo tee $SUDO_FILE > /dev/null
fi
enable_touch_id

# the reattach module MUST be loaded before touch id module
# it will inject itself at the top of the list when installed last
tmux_fix
