# Development setup for a Windows box

```
# Install Choco
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

# Remove some prompting: how? choco ... ?

# Cygwin setup
choco install cygwin    # Unix environment in Windows
choco install cyg-get   # apt-get for Cygwin
cyg-get git             # Use Cygwin's own git

# Some build tools used when getting stuff from scratch
cyg-get make
cyg-get gcc
cyg-get g++
cyg-get vim

choco install conemu    # Better console emulator
choco install cmder     # ConEmu with better defaults
choco install vim       # global vim install
choco install git       # global Git install

choco install nodejs    # Basis for all front-end tooling
```

## Custom stuff not setup

### Own ConEmu setup
The Cmder setup is nice, but it needs some work for it to work for me.
It has a lot of niceties, like clink, but I do not really need the
bundled git and msys.

I should base a setup file on the standard setup, remove some tasks,
and export that setup to  a file. I could then just have some task
that added a registry setting that made ConEmu/Cmder use that config
instead of the admin-writable setting it uses as the default.


