# Machine specific config
This is where you can put per-machine configs. 

- You set the machine name by adding it to `.dotfiles-machine` in your home dir. The following would set the machine name to 'mac-work': `echo 'mac-work' > ~/.dotfiles-machine`
- You can have per-machine settings in the directory `./per-host-config/${machine_name}`.
- It will make a symlink from `./per-host-config/${machine_name}/bashrc.local` to `$HOME/.bashrc.local`
- It will also try to run `setup.sh` in the same machine dir. Put special setup there

A machine dir may also contain a `mise.toml`: this host's [Mise module](https://mise.jdx.dev/bootstrap/modules.html)
(packages, login shell, files, macOS defaults, launchd agents, host-only tools). `setup.sh` in this dir
symlinks it to `~/.config/mise/config.<machine>.toml` and selects it by writing
`~/.config/mise/miserc.local.toml` (`env = ["<machine>"]`); that file is generated, do not hand-edit it.
The module is applied with `mise bootstrap` from that machine's own `setup.sh`. Edit the repo file,
never `mise use -g` / `mise bootstrap packages use`.
