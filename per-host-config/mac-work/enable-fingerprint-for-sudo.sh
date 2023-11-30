#!/bin/bash
# Probably works in most other shells as well
# Based on (buggy) script in https://gist.github.com/fraune/0831edc01fa89f46ce43b8bbc3761ac7, which
# again comes from https://azimi.io/how-to-enable-touch-id-for-sudo-on-macbook-pro-46272ac3e2df

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

  grep -q "$PAM_REATTACH_MODULE" /etc/pam.d/sudo || sudo sed -i '' '2i\
auth       optional       /opt/homebrew/lib/pam/pam_reattach.so ignore_ssh
' /etc/pam.d/sudo
}

enable_touch_id(){
  if egrep -q 'auth[[:space:]]+sufficient[[:space:]]+pam_tid.so' /etc/pam.d/sudo; then
    echo "Touch ID is enabled for sudo"
  else
    read -p "Touch ID is not enabled for sudo. Would you like to enable it now? [y/n]: " RESPONSE
    shopt -s extglob # enables extended globbing
  
    if [[ $RESPONSE == [yY] ]]; then
      sudo grep -q -F 'pam_tid.so' /etc/pam.d/sudo || sudo sed -i '' '2i\
auth       sufficient     pam_tid.so
' /etc/pam.d/sudo
      if grep -q 'auth sufficient pam_tid.so' /etc/pam.d/sudo; then
        echo "'auth sufficient pam_tid.so' added to /etc/pam.d/sudo"
      fi
    else
      echo "No modifications were made to /etc/pam.d/sudo"
    fi
  fi
}

enable_touch_id

# the reattach module MUST be loaded before touch id module
# it will inject itself at the top of the list when installed last
tmux_fix
