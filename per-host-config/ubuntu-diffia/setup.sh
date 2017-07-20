#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

# make /usr/local owned by me
sudo chown -R $(whoami) /usr/local

# Cannot use this yet, must find way to check if PPA 
# already has been added
#echo -e $(blue Installing PPA)
#sudo apt install software-properties-common
#sudo add-apt-repository ppa:neovim-ppa/stable
#sudo apt-get update

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

# setup i3
rm -r ~/.config/i3
ln -s $SCRIPT_DIR/i3-config ~/.config/i3

# fix Alsa for Nforce
ln -sf $SCRIPT_DIR/asoundrc ~/.asoundrc

# for i3 - use custom Chrome to have argument added always
cp google-chrome ~/bin/

sudo apt autoremove

# restore current directory
popd > /dev/null
