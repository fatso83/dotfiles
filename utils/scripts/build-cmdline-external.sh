#!/bin/bash
## Make a recipe on how to use one of my scripts
## @script.name [-h ] [--commit <commit>] <SCRIPT>
##
## Options
##      --commit=SHA1       The commit id you are interested in (usually HEAD)
##
## Example usage:
## $ build-cmdline-external.sh gnome-key-bindings 
## curl -s https://raw.githubusercontent.com/fatso83/dotfiles/master/utils/scripts/gnome-key-bindings -o gnome-key-bindings
## curl -s https://raw.githubusercontent.com/fatso83/dotfiles/master/utils/scripts/easyoptions.sh -o easyoptions.sh
## curl -s https://raw.githubusercontent.com/fatso83/dotfiles/master/utils/scripts/easyoptions.rb -o easyoptions.rb
## chmod +x ./gnome-key-bindings
## sudo mv ./gnome-key-bindings easyoptions.* /usr/local/bin/


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/easyoptions.sh"

SCRIPT="${arguments[0]}"
COMMIT="master"
 
if [[ -n $commit ]]; then
    COMMIT=$commit
fi

if [[ ${#arguments[*]} == 0 ]]; then
    printf "\nERROR: Supply a script name \n\n"
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
