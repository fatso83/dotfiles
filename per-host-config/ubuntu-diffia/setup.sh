#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

set -e                      # exit on errors
shopt -s expand_aliases     # to use alias definitions

# Get common aliases (if new shell)
source ../../common-setup/bash.d/bash_aliases_functions

# Get some color codes
source ../../common-setup/bash.d/colors

# make /usr/local owned by me
sudo chown -R $(whoami) /usr/local

echo -e $(blue Installing PPA software)
sudo apt-get install software-properties-common # Installs 'add-apt-repository'

# Add keys
blue "Adding keys for PPAs ...\n"
curl -s https://davesteele.github.io/key-366150CE.pub.txt | sudo apt-key add -
curl -s https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
curl -s https://repo.jotta.us/public.gpg | sudo apt-key add -
curl -s https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

blue "Adding external package repositories ...\n"
while read line; do 

    # strip first four chars: 'ppa:' or 'deb '
    ppa=$(echo $line | sed 's/^....//')

    if $(grep -r -F "$ppa"  /etc/apt/ >> /dev/null); then
        continue
    fi

    sudo add-apt-repository --yes "$line"
    APT_SHOULD_UPDATE=yes
done < repos.local 


echo -e $(blue Updating package lists ...)
if [[ -n $APT_SHOULD_UPDATE ]]; then
    sudo apt-get update
fi


blue "Installing local apps ..."
sudo apt-get install -y --no-install-recommends $(strip-comments apps.local)

# https://github.com/pypa/pip/issues/5240
blue "Upgrading pip\n"
alias pip="python3 -m pip"  # to avoid warning about script wrapper and old python
pip install --upgrade --user pip

blue "Installing python packages ...\n"
pip install -r python.local 

blue "Installing ruby packages ...\n"
while read line; do 
    if gem list -i $line > /dev/null; then
        continue
    fi

    sudo gem install $line; 
done < ruby.local 


if ! which n >> /dev/null; then
    blue "Upgrade Node using n"
    npm install -g n
    n stable
fi

# Install Yarn - used for instance by coc.vim
if ! which yarn >> /dev/null; then
    curl --compressed -o- -L https://yarnpkg.com/install.sh | bash
fi

blue "Installing Node packages ...\n"
if which pick_json > /dev/null; then
    installed=$(mktemp)
    npm list -g --depth 1 --json | pick_json -k -e dependencies > $installed

    #filters out patterns that are present in the other file, see https://stackoverflow.com/questions/4780203/deleting-lines-from-one-file-which-are-in-another-file
    node_apps=$(grep -v -f $installed node.local || true) 
else
    node_apps="$(cat node.local|| true)" 
fi
# if non-zero, https://unix.stackexchange.com/a/146945/18594
if [[ -n "${node_apps// }" ]]; then
    npm -g install $node_apps 
fi


# setup i3
#rm -r ~/.config/i3
#ln -s $SCRIPT_DIR/i3-config ~/.config/i3

blue "fix Alsa for Nforce\n"
ln -sf $SCRIPT_DIR/asoundrc ~/.asoundrc

# for i3 - use custom Chrome to have argument added always
cp google-chrome ~/bin/

blue "Autoremove unused\n"
sudo apt-get autoremove --yes

blue "Installing Github's 'hub' - if required\n"
if ! which hub > /dev/null; then
    echo -e $(blue "Installing Github's Hub...")
    VERSION="2.11.2"
    BASENAME="hub-linux-amd64-$VERSION"
    wget --quiet "https://github.com/github/hub/releases/download/v${VERSION}/${BASENAME}.tgz"
    tar xvzf "$BASENAME.tgz"
    cd "$BASENAME"
    sudo ./install
    cd ..
    rimraf "${BASENAME}"*
fi

# install GitHub LFS support
if ! which git-lfs > /dev/null; then
    echo -e $(blue "Installing Git LFS client...")
    VERSION="2.4.2"
    NAME="git-lfs"
    OS="linux-amd64"
    BASENAME="${NAME}-${OS}-$VERSION"
    wget --quiet "https://github.com/git-lfs/git-lfs/releases/download/v${VERSION}/${BASENAME}.tar.gz"
    tar xvzf "$BASENAME.tar.gz"
    cd "${NAME}-${VERSION}"
    sudo ./install.sh
    cd ..
    rimraf "${BASENAME}"*
fi

export SDKMAN_DIR="/home/carlerik/.sdkman"
[[ -s "/home/carlerik/.sdkman/bin/sdkman-init.sh" ]] && source "/home/carlerik/.sdkman/bin/sdkman-init.sh"
if ! type sdk > /dev/null 2> /dev/null; then # if the `sdk` function doesn't exist
    blue "Installing SDKMAN\n"
    curl -s "https://get.sdkman.io" | bash # installs SDKMAN

    # make sdk available in the current shell
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

JAVA_VERSION=14.0.2
if ! sh -c "java --version  | grep 'openjdk $JAVA_VERSION' > /dev/null"; then
    blue "Installing Java\n"
    sdk install java $JAVA_VERSION-open
    sdk use java $JAVA_VERSION-open
fi

blue "Install QR copier\n"
go get github.com/claudiodangelis/qr-filetransfer

blue "Use PowerTOP suggestions for saving power\n"
sudo cp powertop.service /etc/systemd/system/
# Enable the service, if first time
if ! service powertop status > /dev/null 2>&1; then
    sudo systemctl daemon-reload
    sudo systemctl enable powertop.service
fi

if ! is_wsl; then
    blue "Installing snaps ...\n" # universal linux packages
    installed=$(mktemp)
    snap list 2>/dev/null |  awk '{if (NR>1){print $1}}' > $installed

    #filters out patterns that are present in the other file, see https://stackoverflow.com/questions/4780203/deleting-lines-from-one-file-which-are-in-another-file
    snaps=$(grep -v -f $installed snaps.local || true) 
    for pkg in $snaps; do
        sudo snap install $pkg --classic
    done

    blue "Customizing desktop applications\n"
    ./desktop/setup.sh
else
    blue "Setting up win32yank as pbpaste\n"
    if ! which win32yank.exe > /dev/null; then
        echo "Downloading win32yank"
        wget --quiet https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
        unzip win32yank-x64.zip -d tmp
        mv tmp/win32yank.exe ~/bin/
        chmod +x ~/bin/win32yank.exe
        rm -r tmp
    fi
fi

if ! which pspg > /dev/null; then
    blue "Compiling pspg: Postgres Pager\n"
    apt install lib32ncursesw5-dev
    PSPGTMP=$(mktemp -d)
    pushd $PSPGTMP
    git clone https://github.com/okbob/pspg
    cd pspg
    ./configure --with-ncursesw
    make -j 12
    make install
    popd
fi

# Installing zplug
#curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

# Use rc.local for small tweaks
sudo cp rc.local /etc/
sudo systemctl start rc-local.service

# restore current directory
popd > /dev/null
