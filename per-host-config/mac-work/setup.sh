#!/bin/sh

# exit on errors
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

# Homebrew
if ! which brew > /dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    brew update
fi

# CMake
if ! which cmake > /dev/null; then
    brew install cmake
    echo "CMake was not installed earlier. Try rerunning the main setup to make sure everything is working"
fi

blue "Installing local apps using Homebrew"

brew cask install java

while read line; do 
    brew install $line
done < apps.local 

# Node Version Manager
if ! which n > /dev/null; then
    npm install -g n
    n latest
fi
