My dot files
========================

These are my config files for Bash, VIM, Python, and more.

You may use them as they are, fork the repo, copy-paste what you like or suggest changes. It's under a do as you please license :)

## Intentionally simple
I really hate code or configuration that I don't understand. It might do magical things, but when things ago awry, and they do, I need to be able to fix it. In this setup, I have handwritten (or at least hand copied :smiley:) every line, and I have tried to document why the line exists if it is scary or weird in some way.

## Installation

```
git clone https://github.com/fatso83/dotfiles
./dotfiles/setup.sh # and wait until completion ...
```
![install vid](https://www.dropbox.com/s/8p59bhwirvwozyi/dotfiles-install.gif?dl=1)
The first time you run the install it will take some time, mostly due [YouCompleteMe](https://github.com/Valloric/YouCompleteMe), which needs to be downloaded and compiled. It might seem as if the install hangs on this step, but this only takes a lot of time the first time you run setup. On subsequent `./setup.sh` runs, it should not take more than a second or two.

## Per machine settings

See `per-host-config/README.md`
