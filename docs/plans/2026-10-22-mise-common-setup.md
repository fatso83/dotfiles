# Convert common setup from asdf + Volta to Mise (#29)

**Issue:** https://github.com/fatso83/dotfiles/issues/29 (sub-issue of #27)
**Status:** plan v3 — written 2026-10-22, reviewed by two independent reviewers
(repo-grounded and Mise-docs-grounded); all blockers/should-fixes folded in; open
questions resolved with the owner (see "Decisions taken"). Ready to implement.
**Mise version the plan was written against:** v2026.10.17 (https://mise.jdx.dev)

## Goal

Replace asdf (project/global runtimes) and Volta (global Node CLIs) with a single
Mise setup for everything that is *not* host-specific. After this issue:

- `common-setup/setup.sh` installs Mise, links the global config and installs every
  tool in it — on any OS, before the per-host step runs and before build tools exist.
- Bash, zsh and fish all activate Mise; no asdf/Volta/Bun-installer lines remain in any rc file.
- Global Node CLIs, Python CLIs and Ruby gems that used to come from
  `per-host-config/_shared/{node,python,ruby}.local` are installed by Mise.
- `install_asdf_tooling` in `per-host-config/_shared/install-utils.inc` is replaced by
  `install_language_packages` (Python libraries only); the old name stays as a
  deprecated alias so `mac-work`/`ubuntu` setup scripts keep working until #28.
- Bun and Starship move from `curl | sh` installers to Mise `[tools]`.

Out of scope (#28 or follow-ups): Homebrew/apt package lists, SDKMAN/Java,
Alire/Ada, replacing direnv, per-host `config.local.toml`, lockfiles.

## Why Mise fits this repo

- One binary, no plugins for node/python/ruby/bun (core tools) or just/starship/uv/pnpm
  (registry). Node, Python and Ruby 3.2.2 are **precompiled** for macOS and Linux
  (x86_64 and arm64), so `mise install` works on a fresh machine before any compiler
  is installed — the thing asdf could not do (hence the "re-run the global setup"
  warning in `per-host-config/setup.sh`).
- `mise activate` prepends the real `bin` dirs to `PATH` and re-evaluates on `cd`, so a
  project `.tool-versions`/`mise.toml` wins over the global config without shim
  juggling. Shims are still generated for GUI apps/editors.
- Mise still reads `.tool-versions` in projects (including the `nodejs` spelling), so
  nothing changes for existing repos that use asdf.

## Design decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Global config is a repo file `common-setup/mise/config.toml`, symlinked to `~/.config/mise/config.toml` | Same pattern as every other dotfile here. Mise trusts global config automatically. Per-host additions later go in `~/.config/mise/config.local.toml` (#28). Consequence: never run `mise use -g` — it would rewrite the repo file; edit the file instead. |
| D2 | Activation lines are handwritten in `bashrc`/`profile`/`zshrc`/`config.fish`, **not** `[bootstrap.mise_shell_activate]` | `~/.bashrc` etc. are symlinks into this repo; letting Mise edit them with marker blocks fights the "I hand-wrote every line" philosophy. |
| D3 | `mise activate bash` is the **last PATH manipulation** in `bashrc` (after SDKMAN and direnv); `mise activate bash --shims` goes in `profile`. Prompt init (`starship init`) moves *after* activation. | Docs: anything prepended to `PATH` after activation wins unless `activate_aggressive=true`. Starship now comes from Mise, so it must be on `PATH` before `starship init` runs. Shims in the login profile cover login shells and Linux display-manager sessions; macOS Dock-launched GUI apps never read `~/.profile` (known limitation, same as with asdf today). |
| D4 | Install with the official installer to the default `~/.local/bin/mise`; setup scripts always call it by absolute path | `~/.local/bin` is already put on `PATH` by `profile`, but `profile` is only read at login, so first-run scripts cannot rely on it. Not Homebrew: must work on Linux/WSL too. |
| D5 | Pin exact versions for runtimes (as `tool-versions` does today), `latest` for CLIs; no `mise.lock` yet | Keeps behaviour identical to today. Lockfile + symlinked global config has a documented gotcha (`mise lock --global` must run inside the repo and `~/.config/mise/mise.lock` symlinked too). Note `latest` respects Mise's 24h `minimum_release_age`, and is resolved at install time, not per shell. |
| D6 | Node CLIs via the `npm:` backend, one entry per CLI; `pnpm` from the registry; `ngrok` via `npm:` with `allow_builds = true` | `npm:` installs each CLI in its own dir, so it survives Node upgrades (what Volta did well). `pnpm` has a registry binary. `ngrok` is **not** in the Mise registry (verified against mise-versions.jdx.dev); its npm package downloads the binary in a postinstall script, which Mise blocks unless `allow_builds` is set. |
| D7 | The `import-sort-*` plugin packages are installed with a `postinstall` on `node`, not as `npm:` tools | They are not CLIs; `import-sort-cli` resolves them from the global `node_modules`, which `npm:` isolation would break. Caveat: they live only in the pinned Node version; a project that pins another Node loses them. |
| D8 | Python CLIs (`poetry`, `pgcli`) via `pypi:`; Python *libraries* (`pynvim`, `neovim`, `keyring`, `bitwarden-keyring`, `setuptools`, `pygobject`) via `pip install --user` in `install_language_packages` | Libraries must live in the interpreter's site-packages (nvim imports `pynvim`); `pypi:` gives isolated venvs. `~/.default-python-packages` is deprecated by Mise (warnings from 2026.11.0). Mise installs `uv`/`python` before `pypi:` tools, `node` before `npm:`, `ruby` before `gem:` — no `depends` needed. |
| D9 | Ruby gems `gist`, `mdless` via `gem:`; **no Bundler postinstall** | Bundler 1.17.3 cannot run on Ruby 3.2 (`untaint` removed), and the jdx/ruby 3.2.2 build already ships Bundler 2.4.10. The old Ruby 2.7.8 + Bundler 1.17.3 pair belongs in the Jekyll project's own `.tool-versions`/`mise.toml`, not in the global config (see Open question 1). |
| D10 | Drop Ruby 2.7.8 and Python 3.11.0 from the global setup | Both are hardcoded in `install-utils.inc` with a "should come from tool-versions" TODO; 2.7.8 has no precompiled build and needs a full compile toolchain. |
| D11 | `direnv` stays **for now**, hooked before Mise, with the caveat documented | Mise docs: "Running direnv and mise together is unsupported… their shell hooks can disagree about which PATH entries to add, restore or remove." Both hook `PROMPT_COMMAND`. Ordering `direnv hook` → `mise activate` means Mise's PATH wins at the prompt, and `.envrc` PATH edits still apply on top. Replacing direnv with Mise `[env]` is pulled forward as the first follow-up. `mise direnv activate` is deprecated — do not use it. |

## Target file layout

```
common-setup/
  mise/
    config.toml          # NEW: global Mise config (tools + settings), symlinked to ~/.config/mise/config.toml
  tool-versions          # DELETED
  default-npm-packages   # DELETED
  setup.sh               # installs mise, links config, runs `mise install` (late in the script)
  bashrc / profile / zsh/zshrc / config.fish   # activation lines; asdf/volta/bun lines removed
  bash.d/aliases_functions                      # `n` alias text
  update-completion-scripts.sh                  # mise completion
common-post/setup.sh     # `mise install` re-run instead of asdf reshim
utils/setup.sh           # use_mise_shims so npm/pip/node resolve on first run
per-host-config/_shared/
  install-utils.inc      # asdf/volta functions removed; install_language_packages added
  node.local             # DELETED (now in mise config)
  python.local           # kept, libraries only
  ruby.local             # DELETED (now in mise config)
per-host-config/jumphost/setup.sh   # text only
shared.lib               # use_mise_shims helper
README.md                # mention Mise
```

## Proposed `common-setup/mise/config.toml`

```toml
# Global Mise configuration (https://mise.jdx.dev/configuration.html)
# Symlinked to ~/.config/mise/config.toml by common-setup/setup.sh.
# Replaces the old asdf ~/.tool-versions and Volta's global toolchain.
#
# Edit THIS file, never `mise use -g` (that would rewrite the symlink target).
# Machine specific additions belong in ~/.config/mise/config.local.toml (see #28).
# Project specific versions still come from the project's .tool-versions / mise.toml.

[settings]
# Mise ignores .nvmrc/.python-version/.ruby-version unless listed here.
idiomatic_version_file_enable_tools = ["node", "python", "ruby"]
# A `ruby "x.y.z"` line in a Gemfile would otherwise auto-install (compile) that Ruby
idiomatic_version_file_disable_files = ["ruby:Gemfile"]

[settings.status]
show_tools = true   # say which tool versions changed when cd-ing
show_env = false

[tools]
# ---- Runtimes (previously common-setup/tool-versions) ----
# import-sort plugins are not CLIs; import-sort-cli loads them from the global node_modules
node   = { version = "24.8.0", postinstall = "npm install -g import-sort-cli import-sort-parser-babylon import-sort-parser-typescript import-sort-style-module" }
python = "3.14.0"
ruby   = "3.2.2"
just   = "1.40.0"
bun    = "latest"

# ---- Previously installed via curl|sh ----
starship = "latest"

# ---- Previously installed per host (brew/apt). Needed already in common-setup:
# gitconfig uses `gh auth git-credential` and utils/setup.sh uses `gclone` (gh repo clone)
gh = "latest"

# ---- Needed by the pypi: backend ----
uv = "latest"

# ---- Global Node CLIs (previously per-host-config/_shared/node.local, via Volta) ----
"npm:bash-language-server" = "latest"
"npm:eslint"               = "latest"
"npm:gifify" = { version = "latest", allow_low_downloads = true }   # needs ffmpeg + imagemagick at runtime
"npm:neovim"               = "latest"     # provides neovim-node-host
"npm:prettier"             = "latest"
"npm:slug"                 = "latest"
"npm:tldr"                 = "latest"
"npm:tsx"                  = "latest"
"npm:typescript"           = "latest"
"npm:ngrok" = { version = "latest", allow_builds = true }   # postinstall script downloads the binary
pnpm = "latest"                           # registry binary (aqua:pnpm/pnpm), not npm:pnpm

# ---- Python CLIs (previously pip --user from python.local) ----
"pypi:poetry" = "latest"
"pypi:pgcli"  = "latest"

# ---- Ruby CLIs (previously gem install from ruby.local) ----
"gem:gist"   = "latest"
"gem:mdless" = "latest"
```

Registry resolution (verified 2026-10-22): `just` → aqua:casey/just, `starship` →
aqua:starship/starship, `uv` → aqua:astral-sh/uv, `pnpm` → aqua:pnpm/pnpm, `bun` →
core. No GitHub token needed for these. `gist`/`mdless` are not registry short
names, hence the explicit `gem:` prefix.

Notes:
- `nodejs` is accepted as an alias but the docs say to use `node` in `mise.toml`.
- `postinstall` runs once per installed version with the tool's `bin` on `PATH`;
  Mise's `npm` wrapper reshims after `npm install -g`. It re-runs only on
  `mise install --force node`.
- After a Python *minor* upgrade run `mise install --force pypi:poetry pypi:pgcli`;
  same for `gem:` tools after a Ruby minor upgrade.

## Implementation tasks

Each task ends in a commit. Run the verification steps before committing.

### Task 1 — Add the Mise config and installer to `common-setup`

Files: `common-setup/mise/config.toml` (new), `common-setup/setup.sh`, `shared.lib`,
`common-setup/tool-versions` (delete), `common-setup/default-npm-packages` (delete).

1. Create `common-setup/mise/config.toml` as above.
2. Add to `shared.lib`:

   ```bash
   # Makes mise and its shims available to non-interactive setup scripts.
   # ~/.local/bin is only added to PATH by ~/.profile, which a first run has not read yet.
   # Safe to call before mise is installed (no-op).
   MISE_BIN="$HOME/.local/bin/mise"
   use_mise_shims(){
       if [[ -x "$MISE_BIN" ]]; then
           case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac
           eval "$("$MISE_BIN" activate bash --shims)"
       fi
   }
   ```
3. In `common-setup/setup.sh` **delete** lines 45–46
   (`h2 "Setup base tool versions using ASDF"` / `ln -sf "$SCRIPT_DIR/tool-versions" …`).
   Do **not** put the Mise block there: the script has `set -e` and that spot is before
   any rc file is linked; a failed download would leave a fresh machine without a
   `~/.bashrc`.
4. Insert the Mise block **after all `ln -sf` steps and the ngrok/psql/z steps, right
   before `./fonts.sh` and `"$SCRIPT_DIR/update-completion-scripts.sh"`** (the latter
   needs `npm` and `bun`; `vim +PlugInstall` does not need Node — coc.nvim uses the
   prebuilt `release` branch):

   ```bash
   h2 "Mise: tool version manager (replaces asdf and Volta)"
   if [[ ! -x "$MISE_BIN" ]]; then
       h3 "Installing mise to $MISE_BIN"
       # Official installer, verifies checksums. MISE_INSTALL_HELP=0 silences the "add this to your rc" hint.
       curl -fsSL https://mise.run | MISE_INSTALL_HELP=0 sh
   fi

   MISE_CONF="$HOME/.config/mise/config.toml"
   mkdir -p "$(dirname "$MISE_CONF")"
   if [[ -e "$MISE_CONF" && ! -L "$MISE_CONF" ]]; then
       info "Found a hand-made $MISE_CONF. Renaming to config.toml.bak"
       mv "$MISE_CONF" "$MISE_CONF.bak"
   fi
   ln -sf "$SCRIPT_DIR/mise/config.toml" "$MISE_CONF"

   # mise also reads ~/.tool-versions; remove the old asdf symlink so it cannot shadow the config
   if [[ -L "$HOME/.tool-versions" ]]; then
       h3 "Removing legacy asdf ~/.tool-versions symlink"
       rm "$HOME/.tool-versions"
   fi

   for legacy in "$HOME/.asdf" "$HOME/.volta" "$HOME/bin/asdf" "$HOME/.bun"; do
       [[ -e "$legacy" ]] && warn "Legacy tool install found: $legacy — safe to remove now that mise manages it"
   done

   use_mise_shims
   h3 "Installing tools from ~/.config/mise/config.toml (first run takes a while)"
   MISE_YES=1 "$MISE_BIN" install || warn "mise install failed for some tool. Fix and re-run ./setup.sh (the rest of the setup continues)"
   ```
5. Remove the Bun and Starship `curl | sh` blocks (and the `git checkout ./bashrc`
   hack that undid the Bun installer's edit) — both now come from `[tools]`.
6. In `update-completion-scripts.sh`, replace `which npm`/`which bun` with
   `command -v` (they resolve to shims after `use_mise_shims`) and add:

   ```bash
   if [[ -x "$HOME/.local/bin/mise" ]]; then
       echo "Updating BASH completion script for mise ..."
       "$HOME/.local/bin/mise" completion bash > "$COMPLETIONS/mise"
   fi
   ```

   (`bash_completion.d/` is git-ignored like `bun.completion.bash`; that is fine.)
7. `git rm common-setup/tool-versions common-setup/default-npm-packages`.

Verification:

```bash
./common-setup/setup.sh
test -L ~/.config/mise/config.toml && ! test -e ~/.tool-versions
~/.local/bin/mise doctor          # no "problems" section
~/.local/bin/mise ls              # every tool listed, none marked missing
~/.local/bin/mise exec -- node -v # v24.8.0
~/.local/bin/mise exec -- prettier --version
~/.local/bin/mise exec -- just --version
~/.local/bin/mise exec -- starship --version
~/.local/bin/mise exec -- bun --version
~/.local/bin/mise exec -- ngrok version
~/.local/bin/mise exec -- npm ls -g --depth=0 import-sort-style-module   # postinstall worked
./common-setup/setup.sh           # second run: idempotent, mise install is a no-op
```

### Task 2 — Shell activation (bash, zsh, fish)

Files: `common-setup/bashrc`, `common-setup/profile`, `common-setup/zsh/zshrc`,
`common-setup/config.fish`.

`bashrc`:
- Delete the `ASDF tool setup` block and the `Volta tool setup` block (the
  "Dynamic configuration/init" section near the end).
- Move the `starship init bash` block (currently right after the color codes, with
  the `__set_prompt` fallback) to the very end, after Mise activation.
- Fix the SDKMAN comment ("must be at the end" is no longer true) and append, as the
  final block:

  ```bash
  t_debug Mise activation  # last PATH manipulation on purpose: anything prepended later would win. See docs/plans/2026-10-22-mise-common-setup.md
  if [[ -x "$HOME/.local/bin/mise" ]]; then
      eval "$("$HOME/.local/bin/mise" activate bash)"
  fi

  # Prompt. Starship is a mise tool, so this must come after activation
  if command_exists starship; then
      eval "$(starship init bash)"
  else
      __set_prompt   # (keep the existing fallback function definition above)
  fi

  t_debug Finished bash setup
  ```
- Starship replaces `PROMPT_COMMAND` with just `starship_precmd` and moves the previous
  chain (`_mise_hook; _direnv_hook; history -a …`) into `STARSHIP_PROMPT_COMMAND`, which
  `starship_precmd` evals every prompt. So `declare -p PROMPT_COMMAND` showing only
  `starship_precmd` is expected; check `echo "$STARSHIP_PROMPT_COMMAND"` instead.
  direnv's `.envrc` PATH edits still win inside a directory.
- Known quirk to document in README: `restore_path` resets to `ORIGINAL_PATH`
  (snapshotted after `profile`, so it contains the shims dir in login shells); the
  real Mise bin dirs come back at the next prompt.

`profile`:
- Delete the two Volta lines at the bottom **and** the `# Bun` block
  (`BUN_INSTALL`/`PATH` lines) — Bun is a Mise tool now.
- Add, right before the `if [ -n "$BASH_VERSION" ]` block that sources `.bashrc`:

  ```bash
  # Mise shims for login shells and (Linux) GUI sessions. Interactive bash upgrades to full activation in .bashrc
  if [ -x "$HOME/.local/bin/mise" ]; then
      eval "$("$HOME/.local/bin/mise" activate bash --shims)"
  fi
  ```

`zsh/zshrc`:
- Delete the Volta block, the `# bun` export block and the hardcoded
  `/Users/carlerik/.bun/_bun` completion line.
- Guard the unconditional last line: `[ -e "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"`
  (it is uv's installer script; uv now comes from Mise so the file may not exist).
- Append **after** that line (it prepends `~/.local/bin`, which must not shadow Mise):

  ```zsh
  # Mise activation: must be the last PATH manipulation
  [[ -x "$HOME/.local/bin/mise" ]] && eval "$("$HOME/.local/bin/mise" activate zsh)"
  ```
- Completions: `mise completion zsh > ~/.zfunc/_mise` is a one-off; document in
  README rather than automate (zplug already runs `compinit`).

`config.fish`:
- Replace the two `VOLTA_HOME` lines and move the block **above** the
  `starship init fish | source` line:

  ```fish
  if test -x $HOME/.local/bin/mise
      if status is-interactive
          $HOME/.local/bin/mise activate fish | source
      else
          $HOME/.local/bin/mise activate fish --shims | source
      end
  end
  ```

Verification (open a *new* terminal for each):

```bash
bash -lic 'mise doctor | grep -E "activated|shims"'   # activated: yes
bash -lic 'command -v node'    # ~/.local/share/mise/installs/node/24.8.0/bin/node (not a shim)
bash -lc  'command -v node'    # login, non-interactive: ~/.local/share/mise/shims/node
env -i HOME=$HOME TERM=$TERM bash -ic 'command -v starship; echo $PROMPT_COMMAND'   # starship found, prompt set
zsh  -ic  'mise doctor | grep activated'
fish -ic  'mise doctor | grep activated'
DEBUG=1 bash -ic true 2>&1 | tail -3   # init time still sane
# Project override — type this in an interactive terminal (the cd hook does not run in `bash -c`):
mise install node@22.12.0 && mkdir -p /tmp/p && printf 'nodejs 22.12.0\n' > /tmp/p/.tool-versions
cd /tmp/p && mise which node && node -v    # .../installs/node/22.12.0/bin/node, v22.12.0
cd ~ && node -v                            # v24.8.0
```

### Task 3 — Replace `install_asdf_tooling` in `_shared/install-utils.inc`

Files: `per-host-config/_shared/install-utils.inc`, `node.local` (delete),
`ruby.local` (delete), `python.local` (trim).

1. Delete `__asdf_has_plugin`, `__install_volta`, `__use_volta`,
   `__install_node_packages`, `__install_asdf_exe`, `__install_ruby_packages`, and the
   uv `curl | sh` lines (uv is a Mise tool).
2. Trim `python.local` to libraries only: `bitwarden-keyring`, `keyring`, `setuptools`,
   `neovim`, `pynvim`, `pygobject` (poetry and pgcli moved to `pypi:`).
3. Replace `__install_python_packages` + `install_asdf_tooling` with:

   ```bash
   # Things mise cannot express: Python *libraries* that must live in the
   # interpreter (nvim's pynvim, keyring backends, ...). CLIs are mise tools.
   install_language_packages(){
       __shared_package_info_message "Python libraries"
       use_mise_shims
       "$MISE_BIN" exec -- python -m pip install --user --upgrade -r "$SHARED_DIR/python.local" \
           | (grep -v 'Requirement already satisfied:' || :)
   }

   # Deprecated name, kept until #28 updates the per-host setup scripts
   install_asdf_tooling(){
       warn "install_asdf_tooling is deprecated; call install_language_packages (tools come from mise now)"
       install_language_packages
   }
   ```

   (`install-utils.inc` self-sources `shared.lib` when `h3` is missing, so `warn`,
   `MISE_BIN` and `use_mise_shims` are always defined.)
4. Leave `install_sdkman_packages` and `install_ada_packages` untouched (#28).
5. Fix the stale comments: `# todo: replace with asdf` (install-utils.inc) and
   `# Python, Ruby, Node handled via ASDF` (ubuntu/setup.sh) — text only.

Verification:

```bash
bash -c 'ROOT=$PWD; source shared.lib; source per-host-config/_shared/install-utils.inc; install_language_packages'
~/.local/bin/mise exec -- python -c 'import pynvim, keyring'
~/.local/bin/mise exec -- poetry --version && ~/.local/bin/mise exec -- pgcli --version
~/.local/bin/mise exec -- gist --version && ~/.local/bin/mise exec -- mdless --version
bash -n per-host-config/mac-work/setup.sh per-host-config/ubuntu/setup.sh   # still parse; they call the deprecated alias
```

### Task 4 — `common-post/setup.sh`, `utils/setup.sh`, aliases, README

Files: `common-post/setup.sh`, `utils/setup.sh`, `common-setup/bash.d/aliases_functions`,
`README.md`, `per-host-config/jumphost/setup.sh` (text only).

1. `common-post/setup.sh`: replace the asdf/nodejs reshim block with

   ```bash
   # Per-host setup may have added ~/.config/mise/config.local.toml; make sure everything is installed
   use_mise_shims
   if [[ -x "$MISE_BIN" ]]; then
       h3 "Installing any tools added by the per-host setup"
       MISE_YES=1 "$MISE_BIN" install
   fi
   ```
2. `utils/setup.sh`: add `use_mise_shims` right after `source "$ROOT/shared.lib"` so
   `npm i`, `pip install` and `node` resolve on a first run (the script has no
   `set -e`, so today these fail silently on a fresh machine).
3. `aliases_functions` line 335: change the `n` alias text to
   `"Node version is managed by mise: edit common-setup/mise/config.toml (global) or the project's .tool-versions"`.
   Do not suggest `mise use -g` (D1).
4. README: a short "Tool versions (mise)" section: tools come from
   `common-setup/mise/config.toml`, project overrides from `.tool-versions`/`mise.toml`,
   never `mise use -g`; `mise doctor` and `DEBUG=1 bash -i` for debugging; the
   `restore_path` quirk; zsh completion one-liner; direnv caveat (D11).
5. `jumphost/setup.sh`: update the "install_asdf_tooling" echo line.

Verification: `./setup.sh` end to end on the current machine, then

```bash
git grep -niE 'asdf|volta|BUN_INSTALL|\.bun\b|tool-versions|default-npm-packages|node\.local|ruby\.local'
```

returns only: the deprecated alias + its warning text, `gitignore_global`
(`.tool-versions` ignore rule is still right for projects), `mac-work/bashrc.local`
(`BUN_INSTALL`, left for #28), and this plan.

### Task 5 — Fresh-machine smoke test (Linux)

Mise's main selling point here is that a clean machine can run
`common-setup/setup.sh` *before* build tools exist. Prove it in a container
(no `gcc`/`make` on purpose):

```bash
docker run --rm -it -v "$PWD":/src ubuntu:24.04 bash -c '
  export DEBIAN_FRONTEND=noninteractive &&   # otherwise tzdata (pulled in by fontconfig) waits for a hidden prompt
  apt-get update -qq && apt-get install -y -qq curl git ca-certificates gettext-base vim fontconfig unzip >/dev/null &&
  useradd -m dev && su - dev -c "git clone /src dotfiles && cd dotfiles && git switch mise-common-setup && ./common-setup/setup.sh && ~/.local/bin/mise doctor && ~/.local/bin/mise ls"'
```

Expected: no compile steps for node/python/ruby (all precompiled; works on x86_64 and
arm64 hosts), `mise ls` shows every tool, `mise doctor` reports no problems.

Result of the first run (2026-10-22, Podman, ubuntu:24.04 arm64): 19 of 21 tools
installed in one go, including node, python, ruby, bun, starship, uv, pnpm, ngrok,
poetry and pgcli — no compiler needed. Three findings, all fixed on the branch:

- `npm:gifify` stopped on an interactive "128 downloads last week, continue?" prompt
  from mise's npm backend → `allow_low_downloads = true` on that entry.
- `gem:mdless` fails without `make` (its `redcarpet` dependency builds a native
  extension). Accepted: the per-host step installs build tools (`build-essential` on
  Ubuntu, Xcode CLT via Homebrew on macOS) and `common-post/setup.sh` re-runs
  `mise install`, which then succeeds. Documented in the config.
- `warn` in `shared.lib` wrote to `>> /dev/stderr`, which is `Permission denied` under
  `su - dev` in a container (the tty belongs to root) and, with `set -e`, aborted the
  whole setup right after `mise install` reported the two failures. Changed to `>&2`.
  Pre-existing bug, only surfaced now that the warn path is exercised.

## Migration on an existing machine (one-off, manual)

1. `git pull` and run `./setup.sh`.
2. Open a new terminal, run `mise doctor` and the Task 2 checks.
3. Remove stale `pip --user` CLIs that would shadow the Mise ones:
   `python3 -m pip uninstall -y poetry pgcli` (or `rm ~/.local/bin/{poetry,pgcli}`).
4. When satisfied: `rm -rf ~/.asdf ~/.volta ~/bin/asdf ~/.tool-versions ~/.bun ~/.default-npm-packages`
   and remove any asdf/volta/bun leftovers from `~/.bashrc.local`.
5. macOS: `brew uninstall starship` to avoid two copies (or drop it from
   `mac-work/apps.local` in #28).

## Decisions taken (2026-10-22, with the repo owner)

1. **Ruby 2.7.8 / Bundler 1.17.3** — dropped from the global setup. A Jekyll repo that
   still needs them pins `ruby 2.7.8` in its own `.tool-versions` and installs
   Bundler 1.17.3 locally (Mise compiles 2.7.8 from source; needs build deps).
2. **Python 3.11.0** — dropped; projects pin it themselves.
3. **direnv** — kept, hooked before Mise, caveat documented (D11). Replacement is a
   separate follow-up issue.
4. **`gifify` / `ngrok`** — stay global via `npm:` as in the config above; a failure
   only warns.
5. **Lockfile** — not now; follow-up.
6. **macOS GUI apps not seeing Mise tools** (Dock-launched apps never read
   `~/.profile`) — accepted for #29; #28 adds a macOS-specific fix.
7. **Starship/direnv duplicated by Homebrew on the Mac** — left for #28; the migration
   notes say `brew uninstall starship`.
8. **Execution** — branch `mise-common-setup` off master, one commit per task,
   pausing for review after each. Claude implements Tasks 1, 3 and 4 and writes the
   Task 2 changes as a patch (`docs/plans/task2-rc-files.patch`); the owner applies
   Task 2 (the rc files are off-limits to Claude's tooling) and runs the shell checks
   that need a real terminal (Task 2 verification, Task 5 Docker run). The
   uncommitted `common-setup/gitconfig` change and untracked files on master are
   left untouched.

## Follow-ups (new issues)

- Replace `direnv` with Mise `[env]` / `mise.local.toml` (first, because of D11).
- **Done** by [2026-10-22-mise-mac-work.md](2026-10-22-mise-mac-work.md) (as a Mise module
  `per-host-config/mac-work/mise.toml` rather than `config.local.toml`; Java is `temurin-25`).
  #28: `per-host-config/mac-work` — Homebrew list via `[bootstrap.packages]`
  `brew:`/`brew-cask:` entries in `config.local.toml`, drop `starship`/`direnv` from
  `apps.local` (and `gh`, which the Docker smoke test showed common-setup needs before
  the per-host step: it is now a Mise tool), Java via Mise (`java = "temurin-21.0.2"`, `maven`, `kotlin`) replacing
  SDKMAN, rename `install_asdf_tooling` calls, clean `BUN_INSTALL` from `bashrc.local`,
  and make Mise tools visible to Dock-launched GUI apps (e.g. a LaunchAgent running
  `launchctl setenv PATH "$HOME/.local/share/mise/shims:..."`, or
  `[bootstrap.macos.launchd.agents]` once #28 adopts `mise bootstrap`).
- Lockfile (`mise lock --global` + symlinked `~/.config/mise/mise.lock`).
- `mise self-update` cadence (`self_update.auto`).
- Ruby 3.2 is EOL (March 2026): bump to a supported Ruby in a separate change.

## Reference (docs read for this plan)

- Bootstrap overview: https://mise.jdx.dev/bootstrap.html
- Shell activation & shims: https://mise.jdx.dev/bootstrap/shell.html, https://mise.jdx.dev/dev-tools/shims.html, https://mise.jdx.dev/shell-setup.html
- Config hierarchy: https://mise.jdx.dev/configuration.html
- Installing: https://mise.jdx.dev/installing-mise.html
- Backends: https://mise.jdx.dev/dev-tools/backends/npm.html, .../pypi.html, .../gem.html
- Languages: https://mise.jdx.dev/lang/node.html, .../python.html, .../ruby.html
- Migrating from asdf: https://mise.jdx.dev/dev-tools/comparison-to-asdf.html
- direnv caveat: https://mise.jdx.dev/direnv.html
- Registry lookups: https://mise-versions.jdx.dev/tools/<name>
