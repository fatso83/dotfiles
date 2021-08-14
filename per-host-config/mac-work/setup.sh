#!/bin/bash

# exit on errors
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

# Homebrew
if ! which brew > /dev/null; then
    printf "Installing Homebrew\n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"

    brew update
fi

# CMake
if ! which -s cmake; then
    brew install cmake
    echo "CMake was not installed earlier. Re-start the top level setup"
    exit 1
fi

blue "Installing local apps using Homebrew"
function formula_installed() {
    brew ls --versions $1 > /dev/null
}

while read FORMULA; do 
    if ! formula_installed $FORMULA; then
        brew install $FORMULA
    fi
done < apps.local 

if ! which -s java; then
    brew cask install java
fi

# Node Version Manager
if ! which -s n; then
    npm install -g n
    n latest
fi

cp ./imgcat.sh ~/bin/imgcat
