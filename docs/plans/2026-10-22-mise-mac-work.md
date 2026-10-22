# Convert the macOS host setup to Mise (#28)

**Issue:** https://github.com/fatso83/dotfiles/issues/28 (sub-issue of #27, follows #29)
**Status:** plan v2 — written 2026-10-22 after #29 shipped (`a0c8075` on master); reviewed
by two independent reviewers (repo-grounded and Mise/Homebrew-docs-grounded), all
blockers and should-fixes folded in; alacritty decided. Ready to implement.
**Mise version the plan was written against:** v2026.10.17 (https://mise.jdx.dev)

## Goal

`per-host-config/mac-work/setup.sh` is a 150-line imperative script. After this issue
the macOS host is described declaratively in one Mise config file that `mise bootstrap`
applies (Homebrew packages, login shell, Touch ID for sudo, macOS defaults, a launchd
agent for GUI-app `PATH`, mac-only tools), and the script shrinks to the handful of
things Mise has no section for (Homebrew's own `brew` CLI, 1Password agent socket,
GPG key import, iTerm/gitconfig symlinks). SDKMAN, the hand-rolled Terraform and Google
Cloud SDK downloads, and the dead Ada code go away.

The same mechanism (`per-host-config/<machine>/mise.toml` → Mise config environment
`<machine>`) is set up generically so the Ubuntu host can follow in its own issue.

Decisions taken with the owner before writing (2026-10-22):

| # | Decision |
|---|----------|
| D1 | Homebrew formulae/casks move to `[bootstrap.packages]` using Mise's built-in `brew`/`brew-cask` managers (bottles installed straight into `/opt/homebrew`, Homebrew-compatible receipts; formulae Homebrew already installed count as installed). The official Homebrew installer stays so the `brew` CLI exists (`brew --prefix`, `brew services`, `brew postinstall`). Apple Silicon only — on an Intel Mac Mise skips `brew:` entries. |
| D2 | SDKMAN is replaced by Mise tools at current recommended versions: `java = "temurin-25"` (LTS), `maven = "latest"`, `kotlin = "latest"`. Declared in the *common* config since Ubuntu used SDKMAN too. |
| D3 | Terraform: global `terraform = "latest"`; the Posten repos pin `terraform 1.6.2` in their own `.tool-versions`. The `~/bin/terraform-1.6.2` download and the `hashicorp/tap/terraform` brew entry go. |
| D4 | Google Cloud SDK moves to the `gcloud` Mise tool with `gke-gcloud-auth-plugin` installed by `postinstall`; the `/opt/google-cloud-sdk` download and the two `profile.local` lines go. |
| D5 | GUI-app `PATH`: a launchd agent (`[bootstrap.macos.launchd.agents]`) runs `launchctl setenv PATH …` at login so Dock-launched apps see Mise shims; plus the Mise JDK is registered under `/Library/Java/JavaVirtualMachines` for IDEs. Not documented by Mise, well-known macOS technique; flagged as the one experimental piece. |
| D6 | Ada is removed: `install_ada_packages`, its calls, the Alire `PATH` line in `bashrc`, the `GPR_PROJECT_PATH`/`ADA_PROJECT_PATH` exports. The untracked `ada_lsp.tar.gz`/`alire.zip` are left for the owner to delete. |
| D7 | `profile.local`/`bashrc.local` lose what Mise now covers and what is dead: openjdk `PATH`, `BUN_INSTALL`, the `Gem.user_dir` prepend, `~/Library/Python/3.7|3.9/bin`, `postgresql@10`, `php@7.2`. `php@7.4`, `PNPM_HOME`, Kafka/IntelliJ paths, `/usr/local/bin` stay. |
| D8 | Host selection stays in `~/.dotfiles-machine`; `per-host-config/setup.sh` turns it into Mise's module mechanism (below). No `mise bootstrap --adopt`, no `[dotfiles]` — the repo keeps its symlink style. |
| D9 | `direnv` stays in `apps.local` until #30. |

## How per-host config maps onto Mise

Mise "machine modules" (https://mise.jdx.dev/bootstrap/modules.html): shared setup
lives in `~/.config/mise/config.toml`; each optional piece is a *config environment*
file `config.<name>.toml` beside it, and the machine picks its modules in
`~/.config/mise/miserc.local.toml` (`env = ["mac-work"]`). That is exactly the
`per-host-config/<machine>` idea, so:

```
per-host-config/
  setup.sh                      # generic: links <machine>/mise.toml and writes miserc.local.toml
  mac-work/
    mise.toml                   # NEW: this host's module → ~/.config/mise/config.mac-work.toml
    setup.sh                    # shrinks to: Homebrew CLI, mise bootstrap, leftovers
    apps.local                  # DELETED (now [bootstrap.packages])
    enable-fingerprint-for-sudo.sh   # DELETED (now [bootstrap.files])
    profile.local / bashrc.local     # trimmed (D7)
common-setup/mise/config.toml   # + java/maven/kotlin/go/rust/cargo:tmux-sessionizer
common-setup/bashrc, profile, zsh/zshrc   # SDKMAN + Alire lines removed (patch, files are blocked for Claude's tooling)
per-host-config/_shared/install-utils.inc # SDKMAN + Ada functions removed
```

Precedence: `config.mac-work.toml` loads after `config.toml`, so it can add tools and
packages and override a version. `[bootstrap.packages]` entries merge as a union
across files (a module can add, not remove). Global-dir config is trusted without
`mise trust`, symlinked or not.

Never run `mise use -g`, `mise bootstrap packages use -g` or `… brew tap` on this
setup: they write to the symlinked global file (how they treat the symlink is
undocumented). Edit the repo files instead; the README already says so.

## Proposed `per-host-config/mac-work/mise.toml`

```toml
# Mise module for the mac-work host (https://mise.jdx.dev/bootstrap/modules.html)
# Symlinked to ~/.config/mise/config.mac-work.toml by per-host-config/setup.sh, which also
# selects it in ~/.config/mise/miserc.local.toml. Applied with `mise bootstrap` from
# per-host-config/mac-work/setup.sh. Edit this file, never `mise bootstrap packages use`.

# ---------------------------------------------------------------------------
# Tools that only this host needs (the common ones live in common-setup/mise/config.toml)
# ---------------------------------------------------------------------------
[tools]
terraform = "latest"   # Posten repos pin 1.6.2 in their own .tool-versions
# vfox:jdx/vfox-gcloud. `components` is the plugin's own option: added on the next `mise install`
# without re-downloading the SDK. Needs a Python matching gcloud's required minor (see Risks).
gcloud = { version = "latest", components = ["gke-gcloud-auth-plugin"] }

# ---------------------------------------------------------------------------
# Homebrew formulae and casks (previously apps.local + a brew install loop).
# Mise installs bottles itself; the `brew` CLI is still installed by setup.sh for brew services etc.
# https://mise.jdx.dev/bootstrap/packages/brew.html
# ---------------------------------------------------------------------------
[bootstrap.packages]
# alacritty: NOT here. There is no formula, and Homebrew disabled the cask on 2026-09-01
# ("fails_gatekeeper_check"). Install by hand from https://github.com/alacritty/alacritty/releases
"brew:ansifilter" = "latest"          # strip color codes and junk
"brew:bash" = "latest"                # tj/git-extras needs Bash 4+; also the login shell (see [bootstrap.user])
"brew:bash-completion" = "latest"
"brew:bat" = "latest"                 # syntax highlighting for fzf.vim
"brew:ccat" = "latest"
"brew:cmake" = "latest"
"brew:cloc" = "latest"
"brew:cowsay" = "latest"
"brew:csshx" = "latest"               # distribute ssh commands (posten/bring)
"brew:direnv" = "latest"              # until #30
"brew:erlang" = "latest"
"brew:fisher" = "latest"
"brew:fortune" = "latest"
"brew:fswatch" = "latest"
"brew:fzf" = "latest"                 # bashrc runs `fzf --bash` before mise activation, so not a mise tool
"brew:git-extras" = "latest"
"brew:git-lfs" = "latest"
"brew:glow" = "latest"
"brew:gnupg" = "latest"
"brew:gum" = "latest"
"brew:gtk4" = "latest"
"brew:htop" = "latest"
"brew:imagemagick" = "latest"
"brew:jq" = "latest"
"brew:kcat" = "latest"
"brew:llvm" = "latest"
"brew:neovim" = "latest"
"brew:pam-reattach" = "latest"        # Touch ID for sudo inside tmux (see [bootstrap.files])
"brew:perl" = "latest"                # fzf.vim
"brew:pinentry-mac" = "latest"        # integrate openpgp with the keychain
"brew:postgresql@15" = "latest"
"brew:pygobject3" = "latest"
"brew:pspg" = "latest"
"brew:qrencode" = "latest"
"brew:reattach-to-user-namespace" = "latest"
"brew:ripgrep" = "latest"             # fzf.vim
"brew:shellcheck" = "latest"
"brew:shfmt" = "latest"
"brew:sox" = "latest"
"brew:the_silver_searcher" = "latest"
"brew:tmux" = "latest"
"brew:universal-ctags" = "latest"     # fzf.vim
"brew:xmlstarlet" = "latest"
"brew-cask:macvim-app" = { os = "macos" }       # the cask `macvim` was renamed to macvim-app (old apps.local: homebrew/cask/macvim). Not the `macvim` formula: that would link a second vim into /opt/homebrew/bin
"brew-cask:vagrant" = { os = "macos" }          # pkg cask (no formula exists); already installed → no-op
"brew-cask:git-credential-manager" = { os = "macos" }   # was `brew install --cask git-credential-manager-core`; pkg cask, see Task 6 pre-checks
# Removed vs apps.local: gh, starship, node, golang, rust, maven, hashicorp/tap/terraform — all mise tools now.
# shivammathur/php/php@7.4 stays a real `brew install` in setup.sh: mise would build the tap's
# Ruby formula from source (gcc, patches, pear post_install) instead of pouring the tap's bottle.

# ---------------------------------------------------------------------------
# Login shell: Homebrew bash (previously /etc/shells + chsh in setup.sh)
# https://mise.jdx.dev/bootstrap/shell.html#set-your-login-shell
# ---------------------------------------------------------------------------
[bootstrap.user]
login_shell = "/opt/homebrew/bin/bash"

# ---------------------------------------------------------------------------
# Touch ID for sudo, also inside tmux (previously enable-fingerprint-for-sudo.sh).
# pam_reattach must come before pam_tid. Written with sudo (owner/group declared).
# https://mise.jdx.dev/bootstrap/files.html
# ---------------------------------------------------------------------------
[bootstrap.files."/etc/pam.d/sudo_local"]
os = "macos"
owner = "root"
group = "wheel"
mode = "0444"
content = """
# sudo_local: local config file which survives system update and is included for sudo
# Managed by mise, see per-host-config/mac-work/mise.toml in the dotfiles repo
auth       optional       /opt/homebrew/lib/pam/pam_reattach.so ignore_ssh
auth       sufficient     pam_tid.so
"""

# ---------------------------------------------------------------------------
# macOS defaults (previously `defaults write org.alacritty AppleFontSmoothing -int 0`)
# ---------------------------------------------------------------------------
[bootstrap.macos.defaults]
"org.alacritty" = { AppleFontSmoothing = 0 }

# ---------------------------------------------------------------------------
# PATH for GUI apps. Dock-launched apps never read ~/.profile, so this agent sets the
# login session's PATH at login (applies to apps started afterwards). Not a documented
# mise feature, a standard launchd technique. Remove with `mise bootstrap services remove gui-path`.
# ---------------------------------------------------------------------------
[bootstrap.macos.launchd.agents.gui-path]
program = "/bin/launchctl"
args = ["setenv", "PATH", "{{ env.HOME }}/.local/share/mise/shims:{{ env.HOME }}/.local/bin:{{ env.HOME }}/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
run_at_load = true
```

## Additions to `common-setup/mise/config.toml`

```toml
# ---- JVM (previously SDKMAN via per-host-config/_shared/install-utils.inc) ----
java   = "temurin-25"   # current LTS; projects pin their own in .tool-versions / .sdkmanrc
maven  = "latest"
kotlin = "latest"

# ---- Toolchains previously from Homebrew (mac) / apt (ubuntu) ----
go   = "latest"
rust = "stable"
"cargo:tmux-sessionizer" = "latest"   # tms; was `cargo install` in both per-host scripts
```

Mise sets `JAVA_HOME` in activated shells and `mise exec`; `.sdkmanrc` files are read
if `java` is added to `idiomatic_version_file_enable_tools` (optional, not planned).

## Proposed `per-host-config/mac-work/setup.sh` (after)

```bash
#!/bin/bash
set -e
[[ -n $DEBUG ]] && set -x
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SCRIPT_DIR/../.."
pushd "$SCRIPT_DIR" > /dev/null
source "$ROOT/shared.lib"
shopt -s expand_aliases
source ../../common-setup/bash.d/aliases_functions

# Homebrew CLI. mise installs the formulae itself (see mise.toml), but `brew` is still
# wanted for brew services, brew --prefix, brew postinstall and formulae mise cannot build.
if [[ ! -x /opt/homebrew/bin/brew ]]; then
    h2 "Installing Homebrew\n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"   # the installer does not change the running shell's PATH

# Everything declarative: packages, login shell, Touch ID, defaults, launchd agent, tools.
# Idempotent; re-run after editing mise.toml. sudo prompts once for /etc/pam.d/sudo_local
# (MISE_YES only answers mise's own confirmations). One failing package must not stop the rest.
h2 "Applying the mac-work mise module (mise bootstrap)"
use_mise_shims
MISE_YES=1 "$MISE_BIN" bootstrap || warn "mise bootstrap reported failures. Fix and re-run ./setup.sh (continuing)"

# Third-party tap that mise would have to build from source; real brew pours the tap's bottle
brew install shivammathur/php/php@7.4 < /dev/null || true

# ---- Things mise has no section for ----
source ../_shared/install-utils.inc
install_language_packages          # Python libraries (pynvim, keyring ...)

h2 "Registering the mise JDK for GUI apps (IntelliJ, /usr/libexec/java_home)"
# Re-linked on every run: `mise where java` is version-specific and the link does not follow upgrades
mise_java_home="$("$MISE_BIN" where java 2>/dev/null || true)"
if [[ -n "$mise_java_home" && -d "$mise_java_home/Contents" ]]; then
    sudo mkdir -p /Library/Java/JavaVirtualMachines/mise-java.jdk
    sudo ln -sfn "$mise_java_home/Contents" /Library/Java/JavaVirtualMachines/mise-java.jdk/Contents
fi

ln -f ./bin/* ~/bin/

if [[ ! -e "$HOME/.1password" ]]; then
    h2 "Use 1Password for SSH"
    add_1password_identity_agent_ssh_config
    mkdir -p ~/.1password && ln -s ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock
fi

./pgp-keychain.sh
mkdir -p ~/dev/mestergruppen
ln -fs "$PWD/mestergruppen_gitconfig" ~/dev/mestergruppen/gitconfig
popd > /dev/null
```

Gone from the script: `sudo chown "$USER" /opt` (nothing writes to `/opt` any more),
the `brew update` throttle (`.latest_brew_update`), the `apps.local` loop and taps
(the per-formula `|| true` tolerance is now the `|| warn` around `mise bootstrap`),
`_f2` (`/etc/shells` + `chsh`), `install_asdf_tooling`, `install_sdkman_packages`,
`install_ada_packages`, `cargo install tmux-sessionizer`, the CMake re-run trick, the
Google Cloud SDK block, the Terraform 1.6.2 block, `enable-fingerprint-for-sudo.sh`
(note: `[bootstrap.files]` writes the whole file and no longer asks y/n — check the
current file first, Task 6), `defaults write org.alacritty`. `HOMEBREW_PREFIX` is no
longer exported by the script itself; `brew shellenv` does that.

## Implementation tasks

Branch `mise-mac-work` off master, one commit per task, pause for review after each.
Tasks 1–4 are Claude's; Task 5 is a patch for the blocked rc files; Task 6 is the
owner's real-machine run.

### Task 1 — Generic per-host Mise module wiring

File: `per-host-config/setup.sh`, `per-host-config/README.md`.

In the `if [[ -e "$MACHINE" ]]` block, after the existing `ln -sf` lines and **before**
`[[ -e ./setup.sh ]] && ./setup.sh`:

```bash
    # Mise module for this host: per-host-config/<machine>/mise.toml becomes the config
    # environment "<machine>" (https://mise.jdx.dev/bootstrap/modules.html)
    if [[ -e ./mise.toml ]]; then
        mkdir -p "$HOME/.config/mise"
        ln -sf "$PWD/mise.toml" "$HOME/.config/mise/config.$MACHINE.toml"
        printf '# Generated by per-host-config/setup.sh from ~/.dotfiles-machine\nenv = ["%s"]\n' "$MACHINE" \
            > "$HOME/.config/mise/miserc.local.toml"
    fi
```

README: one paragraph — a machine dir may contain `mise.toml`; it is applied with
`mise bootstrap` from that machine's `setup.sh`; `miserc.local.toml` is generated, do
not hand-edit.

Verification: `bash -n`; `MACHINE=mac-work` dry run of just that block in a temp
`HOME`; `mise config ls` from `$HOME` lists `config.mac-work.toml` after
`config.toml`.

### Task 2 — The mac-work module and the slimmed setup script

Files: `per-host-config/mac-work/mise.toml` (new, as above), `mac-work/setup.sh`
(rewrite as above), `mac-work/apps.local` (delete), `mac-work/enable-fingerprint-for-sudo.sh`
(delete), root `.gitignore` (remove the `per-host-config/mac-work/.latest_brew_update`
and `per-host-config/mac-work/integration/` lines — neither is written any more).

Checks before committing:
- TOML parses. Formula/cask kinds were verified against the Homebrew API on
  2026-10-22 (`macvim-app` = app cask, old token `macvim`; `vagrant` and
  `git-credential-manager` = pkg casks; `alacritty` = disabled cask). The Task 6 dry run
  caught that the reviewer-suggested `brew:macvim` *formula* would have installed a
  second MacVim next to the already-installed `macvim-app` cask.
- `{{ env.HOME }}` in the launchd `args` is rendered (every string value in an agent is a
  Tera template; `env` is available everywhere). `~` is expanded only in `program`,
  `working_directory`, `stdout_path`, `stderr_path`, not in `args`, so the template is required.

### Task 3 — Common config and `_shared`: replace SDKMAN, drop Ada

Files: `common-setup/mise/config.toml` (additions above),
`per-host-config/_shared/install-utils.inc`, `per-host-config/ubuntu/setup.sh`,
`per-host-config/jumphost/setup.sh` (text), `docs/plans/2026-10-22-mise-common-setup.md`
(follow-ups section: tick off).

- `install-utils.inc`: delete `install_ada_packages` entirely; replace
  `install_sdkman_packages` with a deprecated no-op that warns
  ("JVM tools come from mise now; remove this call") so `ubuntu/setup.sh` keeps running
  until its own conversion; delete the `# todo … install_jvm_stuff` comment; delete the
  `install_asdf_tooling` alias (its "until #28" promise) now that both callers are updated.
- `ubuntu/setup.sh`: rename the `install_asdf_tooling` call to `install_language_packages`,
  remove the `install_ada_packages` call and the unguarded
  `source "$SDKMAN_DIR/bin/sdkman-init.sh"` line (would fail with `set -e` once SDKMAN
  is gone); leave the rest (apt `golang-go`/`maven`, the rustup + `cargo install
  tmux-sessionizer` block, now duplicates of the common config) for the Ubuntu issue.
- `ubuntu/apps.local`: remove `libgmp-dev # used by ada language server install`.
- `common-setup/mise/config.toml` line 6 and `common-post/setup.sh` line 11 still talk
  about `~/.config/mise/config.local.toml`; point them at
  `per-host-config/<machine>/mise.toml` (D8). On the Mac, common-post's `mise install`
  becomes a no-op after `mise bootstrap`, which is fine.

Verification: `bash -n` on all three; `mise install` on the Mac installs
`temurin-25`, maven, kotlin, go, rust, tmux-sessionizer; `mise exec -- java -version`,
`mvn -v`, `kotlin -version`, `tms --help`, `echo $JAVA_HOME` in a new shell.

### Task 4 — Trim `mac-work/profile.local` and `bashrc.local`

`profile.local`: remove the `# OpenJDK macOS Homebrew` comment and the two
`~/Library/Python/3.x/bin` lines under it, the `opt/openjdk/bin`, `postgresql@10` and
`php@7.2` lines, the Ada GNAT line `export PATH="/opt/gcc-14.2.0-3-aarch64/bin:$PATH"`
(D6), and the two Google Cloud SDK `.inc` lines (gcloud completion: add
`source "$(mise where gcloud)/completion.bash.inc"` to `bashrc.local` only if the
vfox layout provides it — check in Task 6, otherwise skip).
`bashrc.local`: remove the `# bun` block, the `Gem.user_dir` block, the two
`GPR_PROJECT_PATH`/`ADA_PROJECT_PATH` exports, the `CLOUDSDK_PYTHON` comment block and
the `/usr/local/etc/autojump` comment.

Verification: `bash -n`; `git grep -n 'openjdk\|BUN_INSTALL\|Gem.user_dir\|ADA_PROJECT\|gcc-14\|google-cloud-sdk\|CLOUDSDK' per-host-config/mac-work` is empty.

### Task 5 — Patch for the blocked common rc files (owner applies)

`docs/plans/task5-rc-files.patch` touching `common-setup/bashrc` (remove the Alire
`PATH` export and the SDKMAN init line + comment), `common-setup/profile` (remove
`export SDKMAN_DIR`), `common-setup/zsh/zshrc` (remove the SDKMAN line + comment).
Validated with `git apply --cached --check`. Applied and committed by the owner as
"Remove SDKMAN and Alire from the shell startup files (#28)".

### Task 6 — Real-machine migration (owner, on the Mac)

Everything is already installed on this machine, so Mise should mostly report
"installed" and change little. Order matters:

```bash
cd ~/dev/dotfiles && git switch mise-mac-work
./per-host-config/setup.sh                      # links config.mac-work.toml, writes miserc.local.toml, runs mac-work/setup.sh
```

Before letting `mac-work/setup.sh` run `mise bootstrap` for real, preview from a shell
(run Task 1's block by hand first, or run `per-host-config/setup.sh` with the
`./setup.sh` call temporarily commented out):

```bash
cat /etc/pam.d/sudo_local                       # anything hand-added here? mise will replace the whole file
ls /opt/homebrew/Caskroom                       # is git-credential-manager there under that token? else mise runs its pkg installer (sudo)
mise config ls                                  # config.toml then config.mac-work.toml
mise bootstrap packages status                  # every brew: entry "installed"; look for "missing", "needs repair", "unknown"
mise bootstrap --dry-run                        # files: sudo_local "update"; user: unchanged; launchd gui-path: missing → launchctl commands; tools: java/maven/... install
mise bootstrap                                  # sudo asks for your password once (the pam file); MISE_YES is irrelevant to sudo
mise bootstrap status --missing && echo IN SYNC
```

Then:

```bash
# Touch ID still works, also in tmux
sudo -k; sudo true
# login shell unchanged
dscl . -read ~ UserShell
# GUI PATH: log out and in, then from a Dock-launched terminal-less app, e.g. IntelliJ's terminal, or:
launchctl getenv PATH
/usr/libexec/java_home -V                        # lists mise-java.jdk
mise exec -- gcloud components list | grep gke-gcloud-auth-plugin
# cleanup of what mise replaced
rm -rf ~/.sdkman ~/bin/terraform-1.6.2 ~/bin/terraform /opt/google-cloud-sdk /opt/gcc-14.2.0-3-aarch64
rm -f per-host-config/mac-work/{ada_lsp.tar.gz,alire.zip,.latest_brew_update}
brew uninstall starship gh node go rust maven terraform 2>/dev/null || true   # mise versions now
```

Expected `follow-up` list from `mise bootstrap`: a new login session for the launchd
agent (the login shell is already Homebrew bash).

## Decision: alacritty (owner, 2026-10-22)

No formula exists and Homebrew disabled the cask on 2026-09-01 (Gatekeeper check
fails). Decided: nothing declared; install by hand from
https://github.com/alacritty/alacritty/releases when needed (comment in `mise.toml`,
one line in `per-host-config/README.md`). The installed app keeps working and the
`org.alacritty` defaults entry stays.

## Risks and fallbacks

- **`shivammathur/php/php@7.4`** stays with real `brew` (the formula is deprecated,
  keg-only, `fails_with :clang`, patches and a `pear` post-install — Mise would build it
  from source with gcc or fail with `formula uses …`). It is EOL; dropping it is a valid
  follow-up. Being keg-only, the `php@7.4` `PATH` line in `profile.local` is still needed.
- **`gcloud` via vfox plugin** needs a Python matching gcloud's required minor (it looks
  in `CLOUDSDK_PYTHON`, `/Library/Frameworks/Python.framework`, Homebrew, `PATH`; otherwise
  installs with `--install-python false` and warns). Mise's `python = "3.14.0"` is on
  `PATH` in activated shells; if the plugin complains, set `CLOUDSDK_PYTHON` or revert D4
  to the `/opt` block.
- **Two package managers on one prefix.** `brew upgrade` and `mise bootstrap packages
  upgrade --manager brew` both work; pick one habit (brew is fine). Never
  `mise bootstrap packages prune` without `--dry-run` — it removes formulae Homebrew
  installed that the config does not list.
- **launchd `setenv PATH`** affects only apps started after the agent ran; apps in
  "reopen windows at login" may start first. Harmless if it does not work; remove with
  `mise bootstrap services remove gui-path`.
- **Intel Macs**: the `brew` manager is unavailable; `brew:` entries are skipped. This
  repo's Mac is Apple Silicon; noted for completeness.
- **`maven`/`kotlin`/`go` `latest`** respect Mise's 24 h minimum release age and are
  pinned at install time; `mise upgrade` moves them.

## Follow-ups

- Ubuntu host (`per-host-config/ubuntu`) → `mise.toml` with `apt:` packages, same
  wiring as Task 1; retire the `install_sdkman_packages` stub, the rustup +
  `cargo install tmux-sessionizer` block, the apt `golang-go`/`maven` duplicates, and
  the `ADA_BIN_PATHS` line in `wsl/bashrc.wsl`.
- Drop PHP 7.4 (EOL) from the Mac entirely.
- #30 direnv → Mise `[env]`; then drop `"brew:direnv"`.
- Lockfile (`mise lock --global`).
- Consider `[bootstrap.macos.dock]`/`finder`/`keyboard` sections for the rest of the
  Mac's manual preferences, and `mas:` for App Store apps.

## Reference

- Packages overview and brew/brew-cask: https://mise.jdx.dev/bootstrap/packages/ , https://mise.jdx.dev/bootstrap/packages/brew.html , https://mise.jdx.dev/bootstrap/packages/brew-cask.html
- Machine modules / config environments: https://mise.jdx.dev/bootstrap/modules.html , https://mise.jdx.dev/configuration/environments.html
- Login shell: https://mise.jdx.dev/bootstrap/shell.html#set-your-login-shell
- Files: https://mise.jdx.dev/bootstrap/files.html ; defaults: https://mise.jdx.dev/bootstrap/macos-defaults.html ; launchd: https://mise.jdx.dev/bootstrap/launchd.html
- Java: https://mise.jdx.dev/lang/java.html ; cargo backend: https://mise.jdx.dev/dev-tools/backends/cargo.html
- Run order, hooks, `--only/--skip`: https://mise.jdx.dev/bootstrap.html
