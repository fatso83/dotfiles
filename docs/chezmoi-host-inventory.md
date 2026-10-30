# Host migration inventory

Home configuration is deployed through targeted chezmoi helpers, with existing differing files preserved and reported as conflicts. Host selection remains the local `.dotfiles-machine` file; it is input, not a generated file that could silently switch machine identity.

| Scope | Owner and behavior |
| --- | --- |
| mac-work, ubuntu, jumphost, win-dev-machine, retropie | `chezmoi-host.sh` manages available bashrc.local, profile.local, gitlocal, vimrc.local and tmux.local links. Missing optional source files are skipped. |
| Ubuntu WSL | Same helper in `wsl` mode manages profile.wsl, bashrc.wsl, gitlocal-wsl and agent bridge script. |
| Ubuntu desktop | Same helper in `desktop` mode manages gitlocal-non-wsl and `.config/Dharkael`. Existing directories are never recursively removed. Matching legacy symlinks are backed up. |
| Mise | mac-work is the only profile with a mise.toml. `chezmoi-mise.sh` manages its module link and selector; other profiles have no module to migrate. Existing selector differences stop deployment. |
| mac-work home scripts | `chezmoi-mac.sh` manages imgcat, ramdisk and the work-directory Git include. |

## Explicit provisioning boundary

The following remain in existing setup scripts because they install software, operate system services or change runtime/OS state rather than deploy user dotfiles:

- macOS Homebrew installation, mise bootstrap package/defaults/login shell/launchd declarations, language packages and JDK registration under `/Library`.
- macOS PGP keychain setup (requires local keychain and GPG interaction).
- Ubuntu apt repositories/packages, systemd service installation under `/etc`, rc.local, desktop launchers under `/usr/share`, GNOME settings and system keyboard settings.
- WSL/Windows binary installation and agent runtime; external GUI/authentication prerequisites remain real-machine checks.
- Downloaded executables and generated plugin caches are runtime installations, not copied into chezmoi source state.

1Password SSH integration and secret-file migration are tracked with the common secret workflow, separately from the host profile inventory.

## Verification

Executed on macOS with chezmoi 2.73.0 in temporary homes: `tests/chezmoi-host.sh`, `tests/chezmoi-mise.sh`, `tests/chezmoi-mac.sh`, and `tests/chezmoi-ubuntu-desktop.sh`. All passed. Desktop test covers legacy link migration, repeat execution, and preservation of a locally edited directory. Host fixtures exercise profile selection; they do not claim actual Linux/WSL system provisioning was run.

## Live links and update safety

These targets are symbolic links into the working repository. Pulling or editing their source changes what applications read immediately, before any subsequent chezmoi apply. Targeted apply guards prevent replacing unrelated local files; they do not make a Git update transactional. Review and validate updates in an isolated checkout before changing the live source checkout. See `chezmoi-update.md` for the update procedure.
