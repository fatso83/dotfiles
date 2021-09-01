#!/bin/bash

# exit on errors
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

sudo chown $USER /opt

# Homebrew
if ! which -s brew; then
    printf "Installing Homebrew\n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"

    brew update
fi

# CMake
if ! which -s cmake; then
    brew install cmake
    dark_red "CMake was not installed earlier. Re-start the top level setup"
    exit 1
fi

blue "Installing local apps using Homebrew ..."
function formula_installed() {
    brew ls --versions $1 > /dev/null
}

while read FORMULA; do 
    if ! formula_installed $FORMULA; then
        brew install $FORMULA
    fi
done < apps.local 
blue "finished \n"

if ! which -s java; then
    blue "Installing Java\n"
    # TODO: replace with SDKMAN, sdk install java open-jdk-16
fi

# Node Version Manager
if ! which -s n; then
    blue "Installing n (Node version manager) ..."
    npm install -g n
    n latest
    blue " finished.\n"
fi

cp ./imgcat.sh ~/bin/imgcat

if [[ ! -d /opt/google-cloud-sdk ]]; then
    blue "Installing Google Cloud SDK ...\n"

    if [[ "$(uname -m)" == arm64 ]]; then
        GSDK=google-cloud-sdk-355.0.0-darwin-arm.tar.gz
    fi

    if [[ -n $GSD ]]; then
        pushd /tmp
        curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/"$GSDK" 
        tar xzf $GSDK -C /opt
        /opt/google-cloud-sdk/install.sh
        blue "Cloud SDK setup finished.\n"
    else
        dark_red "No Cloud SDK configured for architecture $(uname -m)"
    fi
fi
