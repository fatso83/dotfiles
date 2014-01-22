#!/bin/bash
# Run to setup with ./setup.sh
MAIN_DIR="$HOME" DEST="${MAIN_DIR}"
BASH_DIR="${MAIN_DIR}/.bash.d"
PWD="`pwd`"

if [ ! -e "$MAIN_DIR" ]; then
  echo Destination ${MAIN_DIR} does not exist
  exit 1
fi

if [ ! -e "$BASH_DIR" ]; then
  mkdir ${BASH_DIR}
fi

ln -sf "$PWD"/bashrc ${DEST}/.bashrc
ln -sf "$PWD"/gitconfig ${DEST}/.gitconfig
ln -sf "$PWD"/gitignore_global ${DEST}/.gitignore_global
ln -sf "$PWD"/pystartup ${DEST}/.pystartup

for file in "$PWD"/bash.d/*; do
  ln -sf $file ${BASH_DIR}/
done
