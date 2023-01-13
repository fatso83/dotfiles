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

# Make sure curl exists
if ! which curl > /dev/null; then
    apt install -y curl
fi

# Add keys
blue "Adding keys for PPAs ...\n"
TRUSTED_DIR=/etc/apt/trusted.gpg.d/
function __install-key(){
    curl -s $1 | sudo gpg --batch --yes --dearmor -o $TRUSTED_DIR/$2.gpg
}
__install-key https://davesteele.github.io/key-366150CE.pub.txt  davesteele.github.io
__install-key https://dl-ssl.google.com/linux/linux_signing_key.pub  dl-ssl.google.com
__install-key https://repo.jotta.us/public.gpg  jotta.us
__install-key https://packages.microsoft.com/keys/microsoft.asc  microsoft.com
__install-key https://www.postgresql.org/media/keys/ACCC4CF8.asc  postgresql.org
__install-key https://packages.cloud.google.com/apt/doc/apt-key.gpg  cloud.google.com
__install-key https://download.docker.com/linux/ubuntu/gpg  download.docker.com

blue "Adding external package repositories ...\n"
while read org_line; do 
    export RELEASE=$(lsb_release -cs)

    # replace bionic -> focal and vice versa
    # this handles having both 18.04, 20.04, 21.04 and 21.10 repos
    case $RELEASE in 
        bionic)
            line=$(echo $org_line | envsubst | sed -e 's/focal/bionic/g' -e 's/20.04/18.04/g')
            ;;
        focal)
            line=$(echo $org_line | envsubst | sed -e 's/bionic/focal/g' -e 's/18.04/20.04/g')
            ;;
        hirsute)
            line=$(echo $org_line | envsubst | \
                sed -e 's/bionic/hirsute/g' -e 's/focal/hirsute/g' \
                    -e 's/18.04/20.04/g' -e 's/20.04/21.04/g')
            ;;
        impish)
            line=$(echo $org_line | envsubst | \
                sed -e 's/bionic/impish/g' -e 's/focal/impish/g' -e 's/hirsute/impish/g' \
                -e 's/18.04/21.10/g' -e 's/20.04/21.10/g' -e 's/21.04/21.10/g')
            ;;
        jammy)
            line=$(echo $org_line | envsubst | \
                sed -e 's/bionic/impish/g' -e 's/focal/impish/g' -e 's/hirsute/impish/g' \
                -e 's/18.04/22.04/g' -e 's/20.04/22.04/g' -e 's/21.04/22.04/g' -e 's/21.10/22.04/g')
            ;;
        *)
            printf "Unhandled Ubuntu release $RELEASE! Exiting "; exit 1
    esac


    # strip first four chars: 'ppa:' or 'deb '
    ppa=$(echo $line | sed 's/^....//')

    if $(find /etc/apt/ -name '*.list' | xargs cat | grep -v '^#' | grep -F "$ppa" >> /dev/null); then
        printf "Found existing entry for $ppa. Skipping.\n"
        continue
    fi

    # handle possible error
    sudo add-apt-repository --no-update --yes "$line" || :
    APT_SHOULD_UPDATE=yes
done < repos.local 
APT_SHOULD_UPDATE=yes

# TODO: 22.04 upgrade, check this file and remove old comment
# Patch: peek does not exist for the 21.04 release of Ubuntu ... so use the old for Focal
_PEEK=/etc/apt/sources.list.d/peek-developers-ubuntu-stable-hirsute.list
[ -e $_PEEK ] && sed 's/hirsute/focal/g' $_PEEK

echo -e $(blue Updating package lists ...)
if [[ -n $APT_SHOULD_UPDATE ]]; then
    sudo apt-get update
fi


blue "Installing local apps ..."
sudo apt-get install -y --no-install-recommends $(strip-comments apps.local)

source ../_shared/install-utils
install_python_packages
install_ruby_packages
install_node_packages

# Install Yarn - used for instance by coc.vim
if ! which yarn >> /dev/null; then
    curl --compressed -o- -L https://yarnpkg.com/install.sh | bash
fi

blue "fix Alsa for Nforce\n"
ln -sf $SCRIPT_DIR/asoundrc ~/.asoundrc

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

JAVA_VERSION=16
if ! sh -c "java --version  | grep 'openjdk $JAVA_VERSION' > /dev/null"; then
    blue "Installing Java\n"
    sdk install java $JAVA_VERSION-open
    sdk default java $JAVA_VERSION-open
fi
MAVEN_VERSION=3.6.3
if ! sh -c "mvn --version  | grep '$MAVEN_VERSION' > /dev/null"; then
    blue "Installing Maven"
    sdk install maven $MAVEN_VERSION
    sdk default maven $MAVEN_VERSION
fi

blue "Install QR copier\n"
go install github.com/claudiodangelis/qrcp@latest

# These bits do not make sense on WSL2 (Windows Subsyste for Linux)
if ! is_wsl; then

    sudo cp services/*.service /etc/systemd/system/

    blue "Use PowerTOP suggestions for saving power\n"
    if ! service powertop status > /dev/null 2>&1; then
        sudo systemctl daemon-reload
        sudo systemctl enable powertop.service
    fi

    blue "Use Reverse SSH service to allow connecting to the box\n"
    if ! service reverse-tunnel status > /dev/null 2>&1; then
        sudo systemctl daemon-reload
        sudo systemctl enable reverse-tunnel.service
    fi


    blue "Installing snaps ...\n" # universal linux packages
    installed=$(mktemp)
    snap list 2>/dev/null |  awk '{if (NR>1){print $1}}' > $installed

    #filters out patterns that are present in the other file, see https://stackoverflow.com/questions/4780203/deleting-lines-from-one-file-which-are-in-another-file
    snaps=$(grep -v -f $installed snaps.local || true) 
    for pkg in $snaps; do
        sudo snap install $pkg --classic
    done

    # Git Credential Manager for Linux
    curl -L -o gcm-linux.deb https://github.com/GitCredentialManager/git-credential-manager/releases/download/v2.0.886/gcm-linux_amd64.2.0.886.deb
    sudo dpkg -i gcm-linux.deb
    rm gcm-linux.deb

    blue "Customizing desktop applications\n"
    ./desktop/setup.sh

    # Use rc.local for small tweaks
    sudo cp rc.local /etc/
    sudo systemctl start rc-local.service
else 
    green "Installing WSL2 adjustments\n"

    blue "Setting up win32yank as pbpaste\n"
    if ! which win32yank.exe > /dev/null; then
        echo "Downloading win32yank"
        wget --quiet https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
        unzip win32yank-x64.zip -d tmp
        mv tmp/win32yank.exe ~/bin/
        chmod +x ~/bin/win32yank.exe
        rm -r tmp
    fi

    blue "Setup Git Credential Manager to use the Windows Keystore\n"
    ln -sf $PWD/wsl/wsl-gitlocal ~/.wsl-gitlocal

    if  ! locale -a | grep nb_NO > /dev/null; then
        blue "Generate locale for Norwegian\n"
        sudo locale-gen nb_NO
        sudo locale-gen nb_NO.UTF-8
        sudo update-locale
    fi

    green "Finished WSL2 adjustments\n"
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

if groups | grep docker > /dev/null; then
    blue "Adding myself to the docker group\n"
    sudo usermod -aG docker ${USER}
fi
# restore current directory
popd > /dev/null
