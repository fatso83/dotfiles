# Development setup for a Windows box
> For WSL2 setups

I basically do not have much to setup for pure Windows development anymore.
There used to be a lot of Cygwin and Scoop stuff here, but since 2016 I do
most of my development in a Linux VM or WSL2.

Therefore, Windows stuff is mostly about linking the Windows
world to the Linux world:
- [re-using Git Credential Manager for Windows in WSL2](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-git)
- [re-using the 1Password SSH Agent in WSL2](https://dev.to/d4vsanchez/use-1password-ssh-agent-in-wsl-2j6m)

The actual changes are in the `ubuntu` folder and they 
are added using a `is_wsl` check during running `./setup.sh`.
