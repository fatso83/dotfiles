# Machine specific config
This is where you can put per-machine configs. 

- You set the machine name by adding it to `.dotfiles-machine` in your home dir. The following would set the machine name to 'mac-work': `echo 'mac-work' > ~/.dotfiles-machine`
- You can have per-machine settings in the directory `./per-host-config/${machine_name}`.
- Chezmoi manages links for the host files that exist (such as `bashrc.local`, `profile.local`, `gitlocal`, `vimrc.local` and `tmux.local`). The links point back to this checkout, so edits still affect the repo directly. Existing files with different contents are left alone; matching existing links are backed up as `.pre-chezmoi`. If chezmoi is unavailable, existing files are kept and missing links are created as before.
- It will also try to run `setup.sh` in the same machine dir. Put special setup there

A machine dir may also contain a `mise.toml`: this host's [Mise module](https://mise.jdx.dev/bootstrap/modules.html)
(packages, login shell, files, macOS defaults, launchd agents, host-only tools). `setup.sh` in this dir
symlinks it to `~/.config/mise/config.<machine>.toml` and selects it by writing
`~/.config/mise/miserc.local.toml` (`env = ["<machine>"]`); that file is generated, do not hand-edit it.
The module is applied with `mise bootstrap` from that machine's own `setup.sh`. Edit the repo file,
never `mise use -g` / `mise bootstrap packages use`.

mac-work: Alacritty is not declared (no formula, and Homebrew disabled the cask); install it by hand
from https://github.com/alacritty/alacritty/releases when needed.

The host links are enabled for the selected machine by `per-host-config/chezmoi-host.sh`; a plain chezmoi invocation without `DOTFILES_MACHINE` ignores those host-specific targets. Existing host setup scripts and mise bootstrap still run separately.
