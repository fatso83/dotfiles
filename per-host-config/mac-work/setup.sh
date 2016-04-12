#!/bin/sh

# Homebrew
if ! which brew; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew update
fi

# Node / NPM
if ! which npm; then
    brew install node
fi

# Node Version Manager
if ! which n; then
    npm install -g n
    n latest
fi

# Latest vim
if ! which macvim; then
    brew install macvim
fi
