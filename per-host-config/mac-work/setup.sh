#!/bin/sh

# Homebrew
if ! which brew > /dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew update
fi

# Node / NPM
if ! which npm > /dev/null; then
    brew install node
fi

# Node Version Manager
if ! which n > /dev/null; then
    npm install -g n
    n latest
fi

# Latest vim
if ! which macvim > /dev/null; then
    brew install macvim
fi

# Latest NeoVim
if ! which nvim> /dev/null; then
    brew install neovim/neovim/neovim
fi

# CMake
if ! which cmake > /dev/null; then
    brew install cmake
    echo "CMake was not installed earlier. Try rerunning the main setup to make sure everything is working"
fi
