#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

ROOT="$SCRIPT_DIR/../../.."
source "$ROOT/shared.lib"

set -e                      # exit on errors

if [[ -n $DEBUG ]]; then
    set -x
fi

h1 "Installing WSL2 adjustments\n"

"$ROOT/per-host-config/chezmoi-host.sh" ubuntu wsl

h2 "Setup 1Password to use as SSH Agent"
if [[ ! -e $HOME/.1password ]]; then
    mkdir $HOME/.1password
fi

h2 "Setting up win32yank as pbpaste"
if ! which win32yank.exe > /dev/null; then
    echo "Downloading win32yank"
    wget --quiet https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
    unzip win32yank-x64.zip -d tmp
    chmod +x tmp/win32yank.exe
    mv tmp/win32yank.exe /usr/local/bin/
    rm -r tmp
fi

if  ! locale -a | grep nb_NO > /dev/null; then
    h2 "Generate locale for Norwegian"
    sudo locale-gen nb_NO
    sudo locale-gen nb_NO.UTF-8
    sudo update-locale
fi

info "Finished WSL2 adjustments\n"
