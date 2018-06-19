#!/bin/bash
## Utility to build a set of command line to download 
## a script of mine
##
## @script.name [-h ] [--commit <commit>] <SCRIPT>
##
## Options
##      --commit=SHA1       The commit id you are interested in (usually HEAD)
##
## Example usage:
## $ build-cmdline-external.sh gnome-key-bindings | pbcopy | indent4

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/easyoptions.sh"

SCRIPT="${arguments[0]}"
COMMIT="$(git rev-parse --short HEAD)"
 
if [[ -n $commit ]]; then
    COMMIT=$commit
fi

if [[ ${#arguments[*]} == 0 ]]; then
    /bin/echo -e "\nSupply a script name - none given\n"
    $0 --help
    exit 1
fi

echo-download(){
    local BASE=https://raw.githubusercontent.com/fatso83/dotfiles/$COMMIT/utils/scripts
    echo curl -s "$BASE/$1" -o "$1"
}

echo-download "$SCRIPT" 
echo-download easyoptions.sh 
echo-download easyoptions.rb 

echo chmod +x "./$SCRIPT"
echo sudo mv ./$SCRIPT easyoptions.* /usr/local/bin/
