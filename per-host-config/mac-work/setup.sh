#!/bin/bash

# exit on errors
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

# Get common aliases (if new shell)
shopt -s expand_aliases     # to use alias definitions
source ../../common-setup/bash.d/bash_aliases_functions

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
    error "CMake was not installed earlier. Re-start the top level setup"
fi

function _f(){ # create throw-away function to not pollute global namespace with local variables
    h2 "Installing local apps using Homebrew ..."
    brew tap shivammathur/php

    local app_to_formula_map=$( awk -F/ '{  print ( ($3 != "") ? $3 : $1) "\t" $0 } ' < apps.local | sort )
    local to_install=$(awk -F'\t' '{  print $1 }' <(printf "%s\n" "$app_to_formula_map"))
    local formulae=$(brew list --formulae -1)
    local casks=$(brew list --casks -1)
    local installed=$(printf '%s\n%s\n' "$casks" "$formulae" | sort)
    local not_installed=$(comm -23 <(printf '%s\n' "$to_install") <(printf '%s\n' "$installed" ) )
    while read APP; do 
        if [ "$APP" == "" ]; then continue; fi
        local formula=$(awk -v APP=$APP -F'\t' '$1==APP{print $2}' <(printf "%s\n" "$app_to_formula_map" ) )
        brew install "$formula" < /dev/null
    done <<< "$not_installed"
    h3 "finished installing Homebrew apps"
}; _f

if ! which -s java; then
    warn "TODO: Install Java using SDKMAN on macOS: sdk install java open-jdk-16"
fi

# Setup RVM before installing packages
if ! command_exists rvm; then
    curl -sSL https://get.rvm.io | bash -s stable
    rvm install "ruby-2.7.2"
fi
source "$HOME/.rvm/scripts/rvm"
rvm use ruby-2.7.2
PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"

source ../_shared/install-utils
install_python_packages
install_ruby_packages
install_node_packages

cp ./imgcat.sh ~/bin/imgcat

if [[ ! -d /opt/google-cloud-sdk ]]; then
    h2 "Installing Google Cloud SDK ..."
    ARCH=$(uname -m)

    case $ARCH in
        arm64)
            GSDK=google-cloud-sdk-358.0.0-darwin-arm.tar.gz
            ;;
        x86_64)
            GSDK=google-cloud-sdk-358.0.0-darwin-x86_64.tar.gz
            ;;
    esac

    if [[ -n $GSDK ]]; then
        pushd /tmp
        curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/"$GSDK" 
        tar xzf $GSDK -C /opt
        /opt/google-cloud-sdk/install.sh
        h3 "Cloud SDK setup finished"
    else
        warn "No Cloud SDK configured for architecture $ARCH"
    fi
fi
