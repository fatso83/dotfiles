#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

set -e                      # exit on errors

if [[ -n $DEBUG ]]; then
    set -x
fi

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
        jammy)
            line=$(echo "$org_line" | envsubst | \
                sed -e 's/bionic/jammy/g' -e 's/focal/jammy/g' -e 's/hirsute/jammy/g' \
                -e 's/18.04/22.04/g' -e 's/20.04/22.04/g' -e 's/21.04/22.04/g' -e 's/21.10/22.04/g')
            ;;
        noble)
            line=$(echo "$org_line" | envsubst | \
                sed -e 's/jammy/noble/g' \
                -e 's/22.04/24.04/g')
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
    # -E required to include proxy settings, could also be done manually by doing myvar=$myvar or something, which would be a bit safer
    sudo -E add-apt-repository --no-update --yes "$line" || :
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

source ../_shared/install-utils.inc

# Python, Ruby, Node handled via ASDF
install_asdf_tooling
install_sdkman_packages
install_ada_packages
source "$SDKMAN_DIR/bin/sdkman-init.sh"

# This cannot be a shared app, as the install fails on macOS due to some node-gyp thingie
npm i -g @fatso83/luxafor-cli

# Install Yarn - used for instance by coc.vim
if ! which yarn >> /dev/null; then
    curl --compressed -o- -L https://yarnpkg.com/install.sh | bash
fi

# This is legacy - until I start using this again
#h2 "fix Alsa for Nforce USB soundcard"
#ln -sf $SCRIPT_DIR/asoundrc ~/.asoundrc

h2 "Autoremove unused"
sudo apt-get autoremove --yes

# install GitHub LFS support
if ! which git-lfs > /dev/null; then
    h2 "Installing Git LFS client..."
    VERSION="3.7.0"
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

if ! command_exists fzf; then
    h2 "Installing FZF"
    curl -L -o tmp-fzf.tar.gz https://github.com/junegunn/fzf/releases/download/v0.60.2/fzf-0.60.2-linux_amd64.tar.gz
    tar xvzf tmp-fzf.tar.gz
    rm tmp-fzf.tar.gz
    mv fzf ~/bin/
fi

h2 "Install QR copier"
go install github.com/claudiodangelis/qrcp@latest

# These bits do not make sense on WSL2 (Windows Subsystem for Linux)
if is_wsl; then
    wsl/setup.sh
else
    h1 "Installing non-WSL2 adjustments\n"

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

    # Note 2025-02-25: I do not understand why it says "Windows Keystore" in the non-wsl section?!
    h2 "Setup Git Credential Manager to use the Windows Keystore"
    ln -sf $PWD/gitlocal-non-wsl ~/.gitlocal-non-wsl

    add_1password_identity_agent_ssh_config

    h2 "Customizing desktop applications"
    ./desktop/setup.sh

    # Use rc.local for small tweaks
    sudo cp rc.local /etc/
    sudo systemctl start rc-local.service
fi

if ! command_exists pspg; then
    h2 "Compiling pspg: Postgres Pager"
    apt install -y libncurses-dev
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

if ! command_exists cargo; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o tmp-rust-install
    sh tmp-rust-install  --no-modify-path
    rm tmp-rust-install
fi

# Cargo/Rust
# tms / https://github.com/jrmoulton/tmux-sessionizer
cargo install tmux-sessionizer

if groups | grep docker > /dev/null; then
    h2 "Adding myself to the docker group"
    sudo usermod -aG docker ${USER}
fi

if ! command_exists bat; then
     curl -o bat.deb https://github.com/sharkdp/bat/releases/download/v0.25.0/bat_0.25.0_amd64.deb -L -s
     sudo dpkg -i bat.deb
     rm bat.deb
fi

info "Consider installing the cron jobs"
echo ">  crontab $SCRIPT_DIR/example-crontab"
echo ""
command cat "$SCRIPT_DIR/example-crontab"
echo
echo

# restore current directory
popd > /dev/null
