#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FONTS_DIR="$SCRIPT_DIR/fonts"

if [[ ! -e "$FONTS_DIR" ]]; then
    mkdir "$FONTS_DIR"
fi

cd "$FONTS_DIR" > /dev/null
#set -x

main(){
    printf "Installing fonts ...\n"
    install_from_url "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/SourceCodePro.zip"
    install_from_url "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/SpaceMono.zip"
    install_from_url "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/UbuntuMono.zip"
}

install_from_url(){
    local url="$1"
    file="$(download $url)" 
    if [[ $? != 0 ]]; then 
        return; 
    fi;

    install "$file"
}

download(){
    local url="$1"
    local file="$(basename $url)"
    if [[ -e $file.installed ]]; then 
        printf "Already installed %s" "$file\n"
        return 1
    fi

    curl -L -s -o "$file" "$url"
    unzip -o -q "$file" 
    echo "$file"
}

install(){
    local file="$1"
    printf "Installing %s fonts!\n" $(basename $file .zip)
    mv -f *.ttf ~/Library/Fonts/
    mv -f "$file" "$file.installed"
}

main
