#!/bin/bash
# https://askubuntu.com/a/1251175/165026

if [[ ! -e ubuntu-wsl2-systemd-script ]]; then
    git clone https://github.com/DamionGans/ubuntu-wsl2-systemd-script.git
    cd ubuntu-wsl2-systemd-script/
    sudo bash ubuntu-wsl2-systemd-script.sh --force
    # Enter your password and wait until the script has finished
    cmd.exe /C setx WSLENV BASH_ENV/u
    cmd.exe /C setx BASH_ENV /etc/bash.bashrc
fi
