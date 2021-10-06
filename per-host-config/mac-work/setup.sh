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
    dark_red "CMake was not installed earlier. Re-start the top level setup"
    exit 1
fi

function _f(){ # create throw-away function to not pollute global namespace with local variables
    blue "Installing local apps using Homebrew ...\n"

    local app_to_formula_map=$( awk -F/ '{  print ( ($3 != "") ? $3 : $1) "\t" $0 } ' < apps.local | sort )
    local to_install=$(awk -F'\t' '{  print $1 }' <(printf "%s\n" "$app_to_formula_map"))
    local formulae=$(brew list --formulae -1)
    local casks=$(brew list --casks -1)
    local installed=$(printf '%s\n%s\n' "$casks" "$formulae" | sort)
    local not_installed=$(comm -23 <(printf '%s\n' "$to_install") <(printf '%s\n' "$installed" ) )
    while read APP; do 
        if [ "$APP" == "" ]; then continue; fi
        local formula=$(awk -v APP=$APP -F'\t' '$1==APP{print $2}' <(printf "%s\n" "$app_to_formula_map" ) )
        brew install "$formula"
    done <<< "$not_installed"
    green "finished \n"
}; _f

if ! which -s java; then
    blue "Installing Java\n"
    # TODO: replace with SDKMAN, sdk install java open-jdk-16
fi

source ../_shared/install-utils
install_python_packages
install_ruby_packages
install_node_packages

cp ./imgcat.sh ~/bin/imgcat

if [[ ! -d /opt/google-cloud-sdk ]]; then
    blue "Installing Google Cloud SDK ...\n"
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
        green "Cloud SDK setup finished.\n"
    else
        dark_red "No Cloud SDK configured for architecture $ARCH"
    fi
fi
