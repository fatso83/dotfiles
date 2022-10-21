# Development setup for a Windows box
> Not updated since 2016. Do most development in a VMWare image these days TBH

# Install Scoop
See [scoop.sh](http://scoop.sh).

```
iex (new-object net.webclient).downloadstring('https://get.scoop.sh')
```
Needs Powershell 3


# Cygwin setup
scoop install cygwin    # Unix environment in Windows
scoop install cyg-get   # apt-get for Cygwin
cyg-get git             # Use Cygwin's own git

# Some build tools used when getting stuff from scratch
cyg-get make
cyg-get gcc
cyg-get g++
cyg-get vim

scoop install conemu    # Better console emulator
scoop install cmder     # ConEmu with better defaults
scoop install vim       # global vim install
scoop install git       # global Git install

scoop install nodejs    # Basis for all front-end tooling
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

Registry export/import: 
- http://superuser.com/a/450157/69121
- http://conemu.github.io/en/Settings.html#Where_settings_are_stored

LoadCfgFile file   | Use specified xml file as configuration storage.
- http://conemu.github.io/en/ConEmuArgs.html
