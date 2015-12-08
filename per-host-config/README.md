# Machine specific config
This is where you can put per-machine configs. 

- You set the machine name by adding it to `.dotfiles-machine` in your home dir. The following would set the machine name to 'mac-work': `echo 'mac-work' > ~/.dotfiles-machine`
- You can have per-machine settings in the directory `./per-host-config/${machine_name}`.
- It will make a symlink from `./per-host-config/${machine_name}/bashrc.local` to `$HOME/.bashrc.local`
- It will also try to run `setup.sh` in the same machine dir. Put special setup there
