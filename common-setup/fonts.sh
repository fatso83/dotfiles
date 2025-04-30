#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

customize_per_os(){
    source "$SCRIPT_DIR"/../utils/scripts/cross-platform-utils.bashlib

    FONTS_DIR="$SCRIPT_DIR/fonts"

    # default implementation: noop
    install_font(){ echo "TODO: implement font installation"; }
    is_installed(){ echo "TODO: implement font installation"; }

    if is_mac; then
        install_font() { install_font_mac $@; }
        is_installed() { is_installed_mac $@; }
    elif is_wsl; then
        WINHOME_WIN=$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null | sed 's/\\/\//g' )
        WINHOME_NIX="$(wslpath $WINHOME_WIN)"
        SUBDIR="terminal-fonts"
        FONTS_DIR="$WINHOME_NIX/$SUBDIR"
        install_font() {
            echo "Open $WINHOME_WIN/$SUBDIR in Explorer and manually install fonts"
        }
        is_installed() { is_installed_wsl; }
    fi
}

main(){
    customize_per_os

    if [[ -z "$FONTS_DIR" ]]; then
        echo FONTS_DIR undefined. Exiting
        exit 1
    fi

    if [[ ! -e "$FONTS_DIR" ]]; then
        mkdir "$FONTS_DIR"
    fi

    cd "$FONTS_DIR" > /dev/null
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

    install_font "$file"
}

download(){
    local url="$1"
    local file="$(basename $url)"
    if is_installed "$file" ; then 
        printf "Already installed %s\n" "$file" > /dev/stderr
        return 1
    fi

    curl -L -s -o "$file" "$url"
    unzip -o -q "$file" 
    echo "$file"
}

install_font_mac(){
    local file="$1"
    printf "Installing %s fonts!\n" $(basename $file .zip)

    mv -f *.ttf ~/Library/Fonts/
    mv -f "$file" "$file.installed"
}

is_installed_mac(){
    local file="$1"
    [[ -e $file.installed ]]
}

is_installed_wsl(){
    # might be too simple, but interim solution ...
    [[ -e $file ]]
}

main
