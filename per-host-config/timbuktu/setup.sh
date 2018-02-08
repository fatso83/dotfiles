#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

function strip-comments(){
    grep -v '^#' $@
}

# make /usr/local owned by me
sudo chown -R $(whoami) /usr/local

echo -e $(blue Installing local apps ...)
sudo apt-get install -y --no-install-recommends $(strip-comments apps.local)

# upgrade PIP
pip install --upgrade pip

#echo -e $(blue Installing python packages ...)
#pip install -r python.local 

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
if which pick_json > /dev/null; then
    installed=$(mktemp)
    npm list -g --depth 1 --json | pick_json -k -e dependencies > $installed

    #filters out patterns that are present in the other file, see https://stackoverflow.com/questions/4780203/deleting-lines-from-one-file-which-are-in-another-file
    node_apps=$(grep -v -f $installed node.local)
else
    node_apps="$(cat node.local)"
fi
# if non-zero, https://unix.stackexchange.com/a/146945/18594
if [[ -n "${node_apps// }" ]]; then
    npm -g install $node_apps 
fi

sudo apt-get autoremove --yes

# install Github 'hub'
if ! $(which hub >> /dev/null); then
    echo -e $(blue "Installing Github's Hub...")
    VERSION="2.3.0-pre10"
    BASENAME="hub-linux-amd64-$VERSION"
    wget "https://github.com/github/hub/releases/download/v${VERSION}/${BASENAME}.tgz"
    tar xvzf "$BASENAME.tgz"
    cd "$BASENAME"
    sudo ./install
    cd ..
    rimraf "${BASENAME}"*
fi

# install /etc files
cp ./postfix-main.cf /etc/postfix/main.cf

# activate certain scripts
# we cannot activate this without knowing we have a working mail system installed in advance, see postfix
#sudo chmod +x /etc/fail2ban/action.d/complain.conf

# restore current directory
popd > /dev/null
