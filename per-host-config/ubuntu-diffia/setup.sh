#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

# make /usr/local owned by me
sudo chown -R $(whoami) /usr/local

echo -e $(blue Installing PPA)
sudo apt install software-properties-common
if ! $(grep -r neovim-ppa  /etc/apt/ >> /dev/null); then
    sudo add-apt-repository -u ppa:neovim-ppa/stable # will now ASK if you want to add it
fi

echo -e $(blue Installing local apps ...)
sudo apt install -y --no-install-recommends $(cat apps.local)

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


if ! $(which n >> /dev/null); then
    # upgrade Node
    npm install -g n
    n stable
fi
echo -e $(blue Installing Node packages ...)
npm -g install $(cat node.local)

# setup i3
rm -r ~/.config/i3
ln -s $SCRIPT_DIR/i3-config ~/.config/i3

# fix Alsa for Nforce
ln -sf $SCRIPT_DIR/asoundrc ~/.asoundrc

# for i3 - use custom Chrome to have argument added always
cp google-chrome ~/bin/

sudo apt autoremove

# install Github 'hub'
if ! $(which hub >> /dev/null); then
    echo -e $(blue "Installing Github's Hub...")
    VERSION="2.2.9"
    BASENAME="hub-linux-amd64-$VERSION"
    wget "https://github.com/github/hub/releases/download/v${VERSION}/${BASENAME}.tgz"
    tar xvzf "$BASENAME.tgz"
    cd "$BASENAME"
    sudo ./install
    cd ..
    rimraf "${BASENAME}"*
fi

# restore current directory
popd > /dev/null
