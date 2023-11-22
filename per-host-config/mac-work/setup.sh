#!/bin/bash

# exit on errors
set -e

if [[ "$DEBUG" != "" ]]; then
    set -x
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SCRIPT_DIR/../.."
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source $ROOT/shared.lib

# Get common aliases (if new shell)
shopt -s expand_aliases     # to use alias definitions
source ../../common-setup/bash.d/aliases_functions

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
    brew tap microsoft/git
    brew tap hashicorp/tap

    local app_to_formula_map=$(cat apps.local | strip-comments | trim | awk -F/ '{  print ( ($3 != "") ? $3 : $1) "\t" $0 } '  | sort )
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

_f(){
    local homebrew_bash_path=$(echo $(brew --prefix)/bin/bash)
    
    if grep "$homebrew_bash_path" /etc/shells > /dev/null; then 
        return
    fi

    h2 "Use the Homebrew version of Bash"
    sudo bash -c "echo $homebrew_bash_path >> /etc/shells"
    chsh -s "$homebrew_bash_path/bin/bash"
}; _f

if ! command_exists git-credential-manager; then
    brew install --cask git-credential-manager-core
fi

source ../_shared/install-utils

install_asdf_tooling
install_sdkman_packages

# copy mac specific utils
cp ./bin/* ~/bin/

if [[ ! -d /opt/google-cloud-sdk ]]; then
    h2 "Installing Google Cloud SDK ..."
    ARCH=$(uname -m)

    case $ARCH in
        arm64)
            GSDK=google-cloud-cli-435.0.1-darwin-arm.tar.gz
            ;;
        x86_64)
            GSDK=google-cloud-cli-435.0.1-darwin-x86_64.tar.gz
            ;;
    esac

    if [[ -n $GSDK ]]; then
        pushd /tmp
        curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/"$GSDK" 
        tar xzf $GSDK -C /opt
        /opt/google-cloud-sdk/install.sh

        gcloud components install gke-gcloud-auth-plugin

        h3 "Cloud SDK setup finished"
    else
        warn "No Cloud SDK configured for architecture $ARCH"
    fi
fi

if [[ ! -e "$HOME/.1password" ]]; then
    h2 "Use 1Password for SSH"

    add_1password_identity_agent_ssh_config

    h3 "Creating symlink to align setups for Linux and macOS"
    #see Tip in https://developer.1password.com/docs/ssh/get-started#step-4-configure-your-ssh-or-git-client
    mkdir -p ~/.1password && ln -s ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock
fi

./enable-fingerprint-for-sudo.sh

# Fonts
./fonts.sh
