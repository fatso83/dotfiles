#!/bin/bash

set -e

downloads=""

download(){
    curl --fail --progress-bar -L -o "$1" "$2"
}

cleanup(){
    echo "Running cleanup"
    rm $downloads
}

trap  "cleanup" "EXIT"

echo "Downloading Pycharm"
downloads="pycharm.tgz"
download pycharm.tgz 'https://download.jetbrains.com/python/pycharm-2025.1.1.tar.gz'
mkdir -p ~/apps/pycharm
echo "Extracting ..."
tar xf pycharm.tgz -C ~/apps/pycharm
echo "Pycharm extracted"
