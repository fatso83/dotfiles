#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# make /usr/local owned by me
sudo chown -R $(whoami) /usr/local

# install local apps
sudo apt install -y $(cat apps.local)

# upgrade PIP
pip install --upgrade pip

# install python packages
while read line; do pip install $line; done < python.local 

# install ruby packages
while read line; do 
    if gem list -i $line > /dev/null; then
        continue
    fi

    sudo gem install $line; 
done < ruby.local 

# restore current directory
popd > /dev/null
