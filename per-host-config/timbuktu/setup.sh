#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# exit on errors
set -e 
shopt -s expand_aliases     # to use the alias

# setup general Ubuntu dev machine
source ../ubuntu-diffia/setup.sh

# install /etc files
sudo cp ./postfix-main.cf /etc/postfix/main.cf

# activate certain scripts
# we cannot activate this without knowing we have a working mail system installed in advance, see postfix
#sudo chmod +x /etc/fail2ban/action.d/complain.conf

# restore current directory
popd > /dev/null
