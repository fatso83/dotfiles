#!/bin/bash
# Probably works in most other shells as well
# Based on (buggy) script in https://gist.github.com/fraune/0831edc01fa89f46ce43b8bbc3761ac7, which
# again comes from https://azimi.io/how-to-enable-touch-id-for-sudo-on-macbook-pro-46272ac3e2df
if grep -q 'auth sufficient pam_tid.so' /etc/pam.d/sudo; then
  echo "Touch ID is enabled for sudo"
else
  read -p "Touch ID is not enabled for sudo. Would you like to enable it now? [y/n]: " RESPONSE
  shopt -s extglob # enables extended globbing

  if [[ $RESPONSE == [yY] ]]; then
    sudo grep -q -F 'auth sufficient pam_tid.so' /etc/pam.d/sudo || sudo sed -i '' '2i\
auth sufficient pam_tid.so
    ' /etc/pam.d/sudo
    if grep -q 'auth sufficient pam_tid.so' /etc/pam.d/sudo; then
      echo "'auth sufficient pam_tid.so' added to /etc/pam.d/sudo"
    fi
  else
    echo "No modifications were made to /etc/pam.d/sudo"
  fi
fi
