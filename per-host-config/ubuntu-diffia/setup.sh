#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

# make /usr/local owned by me
sudo chown -R $(whoami) /usr/local

# 
echo -e $(blue Installing local apps ...)
sudo apt install -y $(cat apps.local)

# upgrade PIP
pip install --upgrade pip

echo -e $(blue Installing python packages ...)
pip install -r python.local 

echo -e $(blue Installing ruby packages ...)
while read line; do 
    if gem list -i $line > /dev/null; then
        continue
    fi

    sudo gem install $line; 
done < ruby.local 

# restore current directory
popd > /dev/null
