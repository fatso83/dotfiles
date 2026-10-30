# Common configuration inventory

## Managed by chezmoi

- Root regular files: `.psqlrc`, `.gitconfig`, `.gitignore_global`, `.pystartup`, `.pdbrc`, `.tmux.conf`, `.profile`, `.bashrc`, `.zshrc`, `.vimrc`. Compatibility links remain at former repository paths.
- Private Git identity: create-only `.gitconfig-personal`; existing identity stays local.
- Configuration links: global mise, fish, Alacritty, Gemini settings and policies.
- Runtime manifest (`common-setup/chezmoi-runtime.manifest`): each bash fragment and tmux project, completion directory, Vim runtime directory, SSH allowed signers, and every previously linked `utils/scripts` entry. Plugin trees and Git submodules stay in the checkout. Existing directories containing unknown local data stop deployment.
- NeoVim: a real configuration directory with `init.vim` sourcing `.vimrc` and using `.vim` runtime paths. Historical directory symlink is backed up, avoiding writes through that link into the repository.
- TMS: create-only platform-specific configuration; home paths rendered for the destination home. Existing custom config remains untouched.
- Secrets: private ngrok template and optional private create-only `.secret` through an explicit 1Password reference; see dedicated secret documentation.

## Provisioning/runtime retained outside chezmoi

- Installing mise and tool versions, package dependencies, font installation and completion generation.
- Checking out Git submodules, cloning tmux TPM, installing Vim plugins and generating help tags. These populate runtime state; they are not declarative user configuration.
- Downloading `z.sh`, building native utility binaries, downloading Java formatter, installing utility package dependencies, and generating the fetch-todays-calendar application launcher.
- Existing `.bash_profile` is backed up before enabling the shared shell profile; an existing backup blocks replacement. Legacy asdf `.tool-versions` symlink cleanup remains part of tool-manager migration.

## Validation and boundaries

`tests/chezmoi-runtime.sh` uses a temporary home and tests legacy link backups, repeated deployment, TMS local configuration preservation, and refusal to overwrite a local SSH file or a real Vim directory. It does not run provisioning installers or modify the real home. Runtime deployment rejects unresolved Git conflicts. Deployment is sequential: a later refusal may leave earlier safe targets migrated, and rerunning is supported. This is not an atomic filesystem transaction.
