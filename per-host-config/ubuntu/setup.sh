#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

set -e                      # exit on errors

ROOT="$SCRIPT_DIR/../../"
source "$ROOT/shared.lib"

# make /usr/local owned by me
sudo chown -R $(whoami) /usr/local

h2 "Installing PPA software"
sudo apt-get install -y software-properties-common # Installs 'add-apt-repository'

# Make sure curl exists
if ! which curl > /dev/null; then
    apt install -y curl
fi

# Add keys
h2 "Adding keys for PPAs ..."
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
__install-key https://repo.charm.sh/apt/gpg.key  repo.charm.sh
__install-key https://downloads.1password.com/linux/keys/1password.asc 1password 
__install-key https://www.charlesproxy.com/packages/apt/PublicKey charlesproxy
__install-key https://cli.github.com/packages/githubcli-archive-keyring.gpg github-cli-keyring

h2 "Adding external package repositories ..."

# 2023-01-13 manual workaround, see https://askubuntu.com/questions/1450095/does-add-apt-repository-not-support-globs-in-source-list
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/repo.charm.sh.gpg] https://repo.charm.sh/apt/ * *' \
    | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
echo 'deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/1password.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' \
    | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null

strip-comments repos.local | while read org_line; do 
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
            line=$(echo "$org_line" | envsubst | \
                sed -e 's/bionic/impish/g' -e 's/focal/impish/g' -e 's/hirsute/impish/g' \
                -e 's/18.04/22.04/g' -e 's/20.04/22.04/g' -e 's/21.04/22.04/g' -e 's/21.10/22.04/g')
            ;;
        *)
            printf "Unhandled Ubuntu release $RELEASE! Exiting "; exit 1
    esac


    # strip first four chars: 'ppa:' or 'deb '
    ppa=$(echo "$line" | sed 's/^....//')

    if $(find /etc/apt/ -name '*.list' | xargs cat | grep -v '^#' | grep -F "$ppa" >> /dev/null); then
        printf "Found existing entry for $ppa. Skipping.\n"
        continue
    fi

    # handle possible error
    sudo add-apt-repository --no-update --yes "$line" || :
    APT_SHOULD_UPDATE=yes
done 

h2 "Updating package lists ..."
if [[ -n $APT_SHOULD_UPDATE ]]; then
    sudo apt-get update
fi

h2 "Installing local apps ..."
sudo apt-get install -y --no-install-recommends $(strip-comments apps.local)

h2 "Removing some apps ..."
sudo apt-get remove xserver-xephyr # Kolide wants me to not have remote servers running. I do not need this, me thinks
sudo apt-get purge avahi-daemon    # ZeroConf for local networks, printers, etc. Tends to get stuck in 100% cpu

# Add current user to rvm group
# https://github.com/rvm/ubuntu_rvm
sudo usermod -a -G rvm $USER


source ../_shared/install-utils
install_python_packages
install_ruby_packages
install_node_packages

# This cannot be a shared app, as the install fails on macOS due to some node-gyp thingie
npm i -g @fatso83/luxafor-cli

# Install Yarn - used for instance by coc.vim
if ! which yarn >> /dev/null; then
    curl --compressed -o- -L https://yarnpkg.com/install.sh | bash
fi

h2 "fix Alsa for Nforce"
ln -sf $SCRIPT_DIR/asoundrc ~/.asoundrc

h2 "Autoremove unused"
sudo apt-get autoremove --yes

# install GitHub LFS support
if ! which git-lfs > /dev/null; then
    h2 "Installing Git LFS client..."
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
    h2 "Installing SDKMAN"
    curl -s "https://get.sdkman.io" | bash # installs SDKMAN

    # make sdk available in the current shell
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

JAVA_VERSION=16
if ! sh -c "java --version  | grep 'openjdk $JAVA_VERSION' > /dev/null"; then
    h2 "Installing Java"
    sdk install java $JAVA_VERSION-open
    sdk default java $JAVA_VERSION-open
fi
MAVEN_VERSION=3.6.3
if ! sh -c "mvn --version  | grep '$MAVEN_VERSION' > /dev/null"; then
    h2 "Installing Maven"
    sdk install maven $MAVEN_VERSION
    sdk default maven $MAVEN_VERSION
fi

h2 "Install QR copier"
go install github.com/claudiodangelis/qrcp@latest

# These bits do not make sense on WSL2 (Windows Subsyste for Linux)
if ! is_wsl; then

    sudo cp services/*.service /etc/systemd/system/

    h2 "Use PowerTOP suggestions for saving power"
    if ! service powertop status > /dev/null 2>&1; then
        sudo systemctl daemon-reload
        sudo systemctl enable powertop.service
    fi

    h2 "Use Reverse SSH service to allow connecting to the box"
    if ! service reverse-tunnel status > /dev/null 2>&1; then
        sudo systemctl daemon-reload
        sudo systemctl enable reverse-tunnel.service
    fi


    h2 "Installing snaps ..." # universal linux packages
    installed=$(mktemp)
    snap list 2>/dev/null |  awk '{if (NR>1){print $1}}' > $installed

    #filters out patterns that are present in the other file, see https://stackoverflow.com/questions/4780203/deleting-lines-from-one-file-which-are-in-another-file
    snaps=$(grep -v -f $installed snaps.local || true) 
    for pkg in $snaps; do
        sudo snap install $pkg --classic
    done

    if ! command_exists git-credential-manager; then
        h2 "Git Credential Manager for Linux\n"
        curl -L -o gcm-linux.deb https://github.com/GitCredentialManager/git-credential-manager/releases/download/v2.0.886/gcm-linux_amd64.2.0.886.deb
        sudo dpkg -i gcm-linux.deb
        rm gcm-linux.deb
    fi

    h2 "Setup Git Credential Manager to use the Windows Keystore"
    ln -sf $PWD/gitlocal-non-wsl ~/.gitlocal-non-wsl

    add_1password_identity_agent_ssh_config

    h2 "Customizing desktop applications"
    ./desktop/setup.sh

    # Use rc.local for small tweaks
    sudo cp rc.local /etc/
    sudo systemctl start rc-local.service
else 
    h1 "Installing WSL2 adjustments\n"


    h2 "Setup 1Password to use as SSH Agent"
    if [[ ! -e $HOME/.1password ]]; then
        mkdir $HOME/.1password
    fi
    ln -sf $SCRIPT_DIR/wsl/ssh-agent-bridge.sh ~/.agent-bridge.sh

    ln -sf $SCRIPT_DIR/wsl/wsl-profile.local ~/.wsl-profile.local

    h2 "Setting up win32yank as pbpaste"
    if ! which win32yank.exe > /dev/null; then
        echo "Downloading win32yank"
        wget --quiet https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
        unzip win32yank-x64.zip -d tmp
        chmod +x tmp/win32yank.exe
        mv tmp/win32yank.exe /usr/local/bin/
        rm -r tmp
    fi

    h2 "Setup Git Credential Manager to use the Windows Keystore"
    ln -sf $PWD/wsl/gitlocal-wsl ~/.gitlocal-wsl

    if  ! locale -a | grep nb_NO > /dev/null; then
        h2 "Generate locale for Norwegian"
        sudo locale-gen nb_NO
        sudo locale-gen nb_NO.UTF-8
        sudo update-locale
    fi

    info "Finished WSL2 adjustments\n"
fi

if ! command_exists pspg; then
    h2 "Compiling pspg: Postgres Pager"
    apt install -y lib32ncursesw5-dev
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

if ! command_exists ccat; then
     curl -o - -L https://github.com/jingweno/ccat/releases/download/v1.1.0/linux-amd64-1.1.0.tar.gz | tar xvz linux-amd64-1.1.0/ccat
     mv  linux-amd64-1.1.0/ccat /usr/local/bin/ccat
fi

if groups | grep docker > /dev/null; then
    h2 "Adding myself to the docker group"
    sudo usermod -aG docker ${USER}
fi

info "Consider installing the cron jobs"
echo ">  crontab $SCRIPT_DIR/example-crontab"
echo ""
command cat "$SCRIPT_DIR/example-crontab"
echo
echo

# restore current directory
popd > /dev/null
