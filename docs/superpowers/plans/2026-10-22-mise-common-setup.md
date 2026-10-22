# Mise Common Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete #29 by moving common machine setup and runtime selection to Mise, leaving host provisioning for #28 and subsequent platform work.

**Architecture:** Keep the existing source layout. A root `mise.toml` declares deployment and invokes a short sequence of remaining setup tasks. A tools-only fragment is loaded in the checkout and linked into global Mise configuration so project overrides still work. Shell files explicitly activate Mise; bootstrap does not rewrite those same files a second time.

**Tech Stack:** Mise, TOML, Bash compatible with macOS's bootstrap Bash, existing Git/Make/npm/Python utilities; no new configuration framework.

**Spec:** `docs/superpowers/specs/2026-10-22-mise-migration-design.md`.

**State:** Research-backed implementation proposal, not implemented. Source inspected at `538b21e` on 2026-10-22. Existing modification to `common-setup/gitconfig` belongs to the user and must remain untouched. Mise was not installed on PATH during planning. The first task verifies the precise configuration against a pinned release before any home migration.

---

## 1. Decisions and phase boundary

1. **Use a bootstrap project, not `--adopt`.** Keep this checkout at its stable location. `mise -C /path/to/dotfiles bootstrap` is the canonical command once Mise exists. `--from` can be documented after the local path works, but does not make `[tools]` global by itself.
2. **#29 is common-only.** Change `./setup.sh` to common bootstrap, accept `--common` as an explicit spelling and `--dry-run` for preview, and print that host provisioning is deferred. Remove the automatic call into `per-host-config/setup.sh`. Never silently run the old host installers after Mise: they install ASDF and Volta again. This temporary change to the old entry point is intentional and must be advertised prominently. Existing host `.local` files remain in use on already configured machines.
3. **No edits under `per-host-config` in #29.** Preserve the old tool-versions file for its readers. Keep old package manifests as legacy inputs; make no continuing runtime dependency on them in the new path. SDKMAN, host Python/Ruby package installation and Ada remain host work. Common utility Python dependencies are in scope.
4. **Preserve runtime versions, do not combine migration with upgrades.** Start with Node 24.8.0, Python 3.14.0, Ruby 3.2.2 and Just 1.40.0. Capture installed Bun/Starship and npm CLI versions through read-only inventory when implementation starts; for tools absent locally, resolve one version during the implementation spike and pin it. Record compatibility exceptions rather than silently moving to `latest`.
5. **Separate CLI packages from runtime installations.** Use `npm:` tools for actual CLI packages. No generic `npm install -g`, no default-npm-packages file and no ASDF reshim loop. Libraries/plugins stay with their consumer in a local package. npm tools may still use the selected Node runtime, so test an older project Node explicitly.
6. **Keep environment tools with separate responsibilities.** Retain direnv, SDKMAN and Alire integration where currently present. Do not move Java/Maven/Kotlin or every Homebrew executable to Mise as part of #29.
7. **Own activation in the versioned shell files.** Do not also enable `[bootstrap.mise_shell_activate]` for those targets. Mise's bootstrap shell support skips whole-file-owned targets, and relying on it would hide an absent activation line.

## 2. What the current setup actually does

| Current location | Behavior / risk | #29 disposition |
| --- | --- | --- |
| `setup.sh` | Submodules → common → host → common-post → utilities | Thin common-only entry point; explicit prerequisite and phase messaging |
| `common-setup/setup.sh` | Many forced links; deletes Vim/Neovim/completion directories; Git identity; plugin install; downloads; fonts | Declarative plain links/repositories, guarded preparation and finish tasks |
| `common-setup/tool-versions` | Four runtime/tool pins; consumed by host ASDF loop | Copy pins to Mise; retain file as legacy compatibility data |
| `common-post/setup.sh` | Node version comparison and ASDF reshim | Replace with explicit Mise verification, or compatibility wrapper for that task |
| `profile`, `bashrc`, `zsh/zshrc`, `config.fish` | Volta PATH in four places; ASDF initialization in Bash; Bun PATH in two places | One Mise activation per shell; login/shim path; remove obsolete manager injections |
| `bash.d/aliases_functions` | `n` tells user to run `asdf global` | Point to an explicit personal Mise config path; leave npm/npx overrides alone |
| `default-npm-packages` | Comment-only deprecated file, no longer deployed | Delete after reference check; do not recreate it in Mise |
| `gitignore_global` | Globally ignores `.tool-versions` | Retain for compatibility; describe generically. Ignore local Mise overrides, not shared `mise.toml` |
| `per-host-config/_shared/node.local` | Volta CLI/library inventory | Account for every entry in new common tooling, keeping legacy file intact |
| `per-host-config/_shared/{python,ruby}.local` | Python CLI/providers/libraries mixed together; Ruby gems and old Bundler | Deferred host package migration; do not claim these are replaced in #29 |
| `utils/setup.sh` | Native builds; npm dependencies; global pip dependencies; calendar wrapper; formatter download; vimdecrypt | Run after tools through Mise; isolate Python runtime/dependencies and make failure/retry behavior explicit |
| `utils/millis` | Tracked source but broad ignore rule; shell startup depends on it | Preserve build and verify it exists before evaluating full shell smoke tests |
| `utils/fetch-todays-calendar/package.json` | Declares Node <19/npm <9 despite current default Node 24 | Test compatibility and resolve truthful engines metadata before claiming success; no OAuth/network calls in tests |
| `fonts.sh`, `update-completion-scripts.sh` | OS-specific user-font handling; generated completions; Bun may edit rc files | Retain as tasks; stop rc/repository rewriting and create destination dirs first |
| `wireguard-vpn`, other utility source | Independent functionality, not runtime bootstrap | No conversion needed except scripts that actually consume migrated dependencies |

The ASDF helper also installs Python 3.11.0 and Ruby 2.7.8 independently of the common pins. These are host legacy requirements, not reasons to add extra defaults in #29. `install_ada_packages` immediately returns today; the migration does not remove a working Ada installer.

## 3. File structure and ownership

| File | Responsibility |
| --- | --- |
| `mise.toml` (new) | Minimum supported Mise version, `[dotfiles]`, `[bootstrap.repos]`, hooks and `bootstrap` task |
| `.mise/conf.d/10-tools.toml` (new) | Common runtime and actual CLI versions only; no tasks or home mutations |
| `setup.sh` (replace driver) | Locate/install compatible Mise, validate flags, run common bootstrap from repo root |
| `common-setup/setup.sh` (reduce) | Backward-compatible common entry path delegating to root `--common` |
| `common-setup/mise-prepare.sh` (new) | Preflight, Git identity capture, safe known-link migration; no tools required from Mise |
| `common-setup/mise-finish.sh` (new) | Remaining common initialization after tools; calls fonts/completions/utilities in order |
| `common-post/setup.sh` (replace body) | Verification task entry; no ASDF calls |
| Common shell files and aliases | Mise activation and runtime selection |
| `utils/setup.sh` and relevant Python entry points | Deterministic utility dependency installation and execution |
| `utils/import-sort/package.json` and lockfile (new if inventory confirms plugins are needed) | One dependency environment for import-sort and its parsers/style |
| `tests/bootstrap.sh` (new) | Small offline integration harness for the changed shell logic, temporary HOME and command stubs |
| `tests/mise-smoke.sh` (new) | Explicit opt-in real Mise tests in an isolated disposable home; not a workstation setup command |
| `README.md`, `.gitignore` | Entry points, prerequisites, migration/rollback and generated artifacts |

Use `shared.lib` where useful but avoid invoking startup helpers requiring `millis` in the initial installer. Retain it for host consumers; do not delete or broadly refactor it.

## 4. Proposed configuration shape

These snippets explain the implementation design; Task 1 must validate them against the chosen binary. Complete the file with the deployment inventory below, not by symlinking all of `common-setup` into HOME.

`.mise/conf.d/10-tools.toml` begins:

```toml
[tools]
node = "24.8.0"
python = "3.14.0"
ruby = "3.2.2"
just = "1.40.0"
```

Add pinned Bun/Starship and CLI entries from Task 2. This fragment is deployed to `~/.config/mise/conf.d/10-dotfiles-tools.toml`; it does not replace a user's existing `config.toml`. For #29, fail before mutation if the effective Mise/XDG config location differs from this supported default; explain the mismatch without changing it. Also reject `MISE_GLOBAL_CONFIG_FILE`/`global_config_file`, which disables fragment discovery, and global override entries for the managed runtimes, which defeat project precedence. Test these cases explicitly. Do not pretend an unexpanded TOML key containing `$XDG_CONFIG_HOME` is portable; nondefault-layout support can be a small later extension.

The root configuration includes declarations of this form:

```toml
[dotfiles]
"~/.config/mise/conf.d/10-dotfiles-tools.toml" = { source = ".mise/conf.d/10-tools.toml", mode = "symlink" }
"~/.profile" = { source = "common-setup/profile", mode = "symlink" }
"~/.bashrc" = { source = "common-setup/bashrc", mode = "symlink" }
"~/.zshrc" = { source = "common-setup/zsh/zshrc", mode = "symlink" }
"~/.bash.d" = { source = "common-setup/bash.d", mode = "symlink-each" }

[bootstrap.hooks]
pre-repos = 'bash "{{ config_root }}/common-setup/mise-prepare.sh" --check'
pre-dotfiles = 'bash "{{ config_root }}/common-setup/mise-prepare.sh"'

[tasks.bootstrap]
run = 'bash "{{ config_root }}/common-setup/mise-finish.sh"'
```

The read-only pre-repos check runs before the common configuration's first mutating phase. The prepare hook rechecks before replacing Git configuration and before tools exist, also covering direct `mise dot apply`. The bootstrap task runs after tool installation and uses that tool environment. Do not depend on a newly deployed global fragment being reloaded midway through bootstrap: the project already loads the same tools fragment. Test discovery and relative paths, especially when invoking from outside the repository and through `--from`.

Do not deploy root `mise.toml` globally: doing so would also load its bootstrap tasks/hooks outside this repository. Do not use global override configuration, which would defeat project version selection.

The shared tools fragment is a symlink into Git. `mise use -g` can update an existing declaration there, modifying the repository. Document `mise use --path ~/.config/mise/config.toml node@VERSION` for a personal default instead, and editing `.mise/conf.d/10-tools.toml` for an intentional shared change. Test the personal-default command leaves the checkout unchanged.

## 5. Deployment and retained-operation inventory

Every row is an implementation requirement or an explicit retained exception.

| Source / operation | Destination / treatment |
| --- | --- |
| `profile`, `bashrc`, `zsh/zshrc`, `config.fish` | Existing `.profile`, `.bashrc`, `.zshrc`, `.config/fish/config.fish` locations |
| `gitconfig`, `gitignore_global` | `.gitconfig`, `.gitignore_global`; capture identity first, preserve personal includes |
| `pystartup`, `pdbrc`, `tmux.conf`, `psqlrc` | Existing corresponding dotfiles; `pdbrc.py` is not currently deployed, do not invent a new action |
| `bash.d/*` | `symlink-each` into `.bash.d`, retain unrelated local files |
| `tmux/*` | `symlink-each` into `.tmux`, exclude no existing project configs, retain `.tmux/plugins` and host `.tmux/local` |
| Vim config | `.vim` → `common-setup/vim/dotvim`, `.vimrc` → `common-setup/vim/vimrc`; stop deleting existing directories |
| Neovim config | A real `.config/nvim` directory with `init.vim` linked to new `common-setup/nvim/init.vim`; reuse Vim runtime paths and source `.vimrc`, avoiding generated files inside the checkout |
| `allowed_signers` | `.ssh/allowed_signers` as a symlink instead of remove/re-hardlink; preserve existing SSH directory permissions |
| `alacritty.toml`, Gemini settings/policy | Existing config targets |
| `tms-config.toml` | Seed only if absent: macOS `~/Library/Application Support/tms/config.toml`, Linux `~/.config/tms/config.toml`; retain task because ordinary copy mode would overwrite user changes |
| Tmux plugin manager | Declarative repo clone to `.tmux/plugins/tpm`; dirty checkout is not reset |
| rupa/z | Declarative repo under user data; link its `z.sh` to `~/bin/z.sh` after clone; do not replace it with zoxide |
| Submodules | `git submodule update --init --recursive` in apply-only preparation; avoid `--force` |
| Vim plugins/helptags | Retain guarded task after dependencies exist, support headless/noninteractive invocation; failure is visible |
| Git personal identity | Retain existing `.gitconfig-personal`; otherwise use Git's config writer with captured values, avoiding envsubst dependency and escaping mistakes |
| `.bash_profile` handling | Inspect first. Back up an existing conflicting profile without overwriting `.bak`, and establish the repository's `.profile` login route; never silently discard a custom file |
| ngrok configuration | Retain generated config under `.ngrok2`; source `.secret` only in apply task if required; write with mode 0600 and no token logging; preserve existing customized file unless explicitly migrated |
| Fonts | Retain existing font versions and macOS/WSL behavior, including WSL's manual install instruction; report unsupported native Linux font setup accurately |
| Completions | Generate into a user cache/data directory; link/load from there. Move the already-tracked static tmux/Azure completions out of the broadly ignored directory; do not lose them when switching paths. No `git checkout ./bashrc`, no installer appending activation to linked rc files |
| Local binaries, scripts, formatter, calendar, vimdecrypt | Retain through corrected `utils/setup.sh`; see Task 6 |
| Fisher/Bass | Keep optional installation only where Fisher is actually available in Fish, not a Bash `command -v` check for a Fish function |

## 6. Implementation tasks

### Task 1: Prove the Mise interfaces and define a repeatable baseline

**Files:** create initial `tests/mise-smoke.sh` and `tests/bootstrap.sh`; record verified version and prerequisite notes in `README.md` and `mise.toml` when introduced.

- [ ] Create an isolated implementation worktree using Superpowers' worktree workflow. Preserve the dirty `common-setup/gitconfig` in the current checkout; do not stash or include it.
- [ ] Inventory installed runtime/CLI versions read-only (`volta list`, `asdf current`, version commands as available). Save only package/version data, never environment dumps or tokens.
- [ ] Use an official pinned Mise release in scratch. The documentation displayed `2026.10.17` during research; treat that as the candidate, not an already-tested minimum. Check `mise --version`, `mise bootstrap --help`, `mise dot apply --help`, `mise config ls` and `mise tasks ls`.
- [ ] In a disposable home, verify: `.mise/conf.d/*.toml` loads with root `mise.toml`; source paths resolve as expected; linking a tools-only global fragment applies outside the repo; a nearer project `.tool-versions` overrides global Node.
- [ ] Check `pre-dotfiles` and the bootstrap task ordering with harmless logging commands; assert `--dry-run` does not run them. Assert whole-file dotfile activation is provided by source files, not automatically added.
- [ ] Confirm the chosen release's npm backend behavior with a trivial CLI and two Node versions; check any dependency install script needed by `tsx`/ngrok. Pin and document the supported Mise release. If required documented interfaces are absent, stop this implementation task and resolve the release mismatch rather than substituting guessed syntax.
- [ ] Define prerequisites for macOS and Ubuntu/WSL: Git, curl, CA trust, archive utilities, compiler/Make and Ruby build dependencies, plus Vim and tools used by retained tasks. Exercise installation with that image baseline. #29 does not install apt/Homebrew prerequisites itself; missing prerequisites must fail before deploying dotfiles.
- [ ] Commit the smoke harness and verified baseline notes: `test: establish mise bootstrap compatibility baseline`.

**Test shape:** The harness creates a temporary directory with `mktemp -d`, launches a child through `env HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" XDG_DATA_HOME="$test_home/.local/share" XDG_CACHE_HOME="$test_home/.cache" XDG_STATE_HOME="$test_home/.local/state" ...`, and points every Mise state/config path into that directory. Do not repurpose the current shell's HOME. Also isolate system/global config discovery, cwd/parent configs and inherited activation variables. Use a copied fixture repo and fake home; never execute the live setup against the real HOME. A trap may remove only the directory the harness created.

### Task 2: Declare global tools and account for the Node package inventory

**Files:** create `.mise/conf.d/10-tools.toml`; create `utils/import-sort/package.json`/lockfile if needed; retain `per-host-config/_shared/node.local`; annotate compatibility status in `common-setup/tool-versions` without changing its values.

- [ ] Add failing tests for exact base versions, global fragment discovery outside the checkout and project override selection.
- [ ] Add the four preserved pins and pinned Bun/Starship versions. Prefer known registry identifiers; verify each with `mise registry`/`mise tool` before committing.
- [ ] Account for every existing `node.local` entry using this mapping:

| Existing entry | Planned ownership / validation |
| --- | --- |
| bash-language-server, eslint, gifify, prettier, tldr, tsx, typescript | Individual `npm:` declarations; assert actual exported command and check required external tools (e.g. gifify's media tools) |
| pnpm | One Mise pnpm tool (verify selected backend); no competing npm/Corepack installation |
| ngrok | Verify whether the npm package's exported CLI or a native registry tool preserves the existing config/command contract; select one, test `ngrok version`, do not silently upgrade config schema |
| neovim | npm provider package, not the Neovim editor; preserve its `neovim-node-host` binary and editor provider discovery |
| import-sort-cli | Local package with the parsers/style below; expose a wrapper to its actual CLI using explicit managed Node |
| import-sort-parser-babylon, import-sort-parser-typescript, import-sort-style-module | Dependencies of that local package, not independently isolated CLI tools; test a JS and TS fixture with the configured style |
| slug | Inspect the package's `bin` metadata. If library-only, keep it solely in existing `utils/package.json` (already present); record that no global executable existed |

- [ ] Use captured versions where available. Pin resolved versions for previously unpinned tools; avoid introducing a large lockfile workflow unless needed for an actual failure. If adopting `mise.lock`, verify global-fragment installation and sidecar resolution as well as checkout installation; do not claim reproducible transitive npm dependencies from top-level pins alone.
- [ ] Run two-Node tests: global CLI remains discoverable; a project reports its selected Node; returning home restores the default. An incompatible CLI/Node combination must receive a narrowly scoped explicit-runtime wrapper or a documented supported range, not a globally forced Node version.
- [ ] Run `bash tests/bootstrap.sh` once the applicable cases exist, and the real tool subset of `tests/mise-smoke.sh`. Commit: `feat: declare common runtimes and node tools with mise`.

### Task 3: Add a small common bootstrap entry point

**Files:** modify `setup.sh`, `common-setup/setup.sh`; create `common-setup/mise-prepare.sh`; extend `tests/bootstrap.sh`.

- [ ] Write failure tests for absent/incompatible Mise, unknown flags, a failed download, invocation outside repo root, and a repo path containing spaces.
- [ ] Implement root flag handling: no args and `--common` mean common bootstrap; `--dry-run` previews it. Unknown options fail before mutation. Print the phase boundary. No automatic host dispatch, no interactive host selection, no `.dotfiles-machine` requirement in this path.
- [ ] Reuse a compatible installed Mise. Otherwise install the verified release with official installer options to the user executable directory, after a successfully downloaded installer file; do not pipe an unchecked partial download into a shell. Do not use shell-specific installer endpoints, since the repository owns activation. On dry-run with no compatible Mise, report the requirement and exit without installation.
- [ ] Resolve an absolute Mise executable path and use `mise -C "$repo_root" ...`; no dependency on shell activation. Inspect/trust the checkout explicitly, with clear instructions for noninteractive use. Trust is separate from preview; do not silently trust arbitrary external paths. A direct `mise bootstrap --from` run has Mise's own trust behavior and is documented separately.
- [ ] Inspect effective configuration in the root wrapper **before invoking bootstrap**: Mise also merges pre-existing global bootstrap declarations/hooks. If unrelated global setup is present, report it and require an explicitly reviewed configuration before applying; do not silently claim the run is common-only or suppress the user's settings. Test that ordinary existing global tool preferences remain intact. The canonical direct Mise command is documented only for this already-reviewed configuration; repository hooks cannot intercept global phases that run earlier.
- [ ] Run prerequisite/conflict checks before apply-only setup. Root, `pre-repos --check` and pre-dotfiles share the preparation script's check mode. This checks direct common bootstrap before its repository clones, and direct `mise dot apply` before dotfile changes. Keep identity capture/known-link migration in the mutation phase. Do not claim a repository hook can prevent unrelated earlier phases or hooks from an existing global config; the effective-config review above must exclude those from this common-only invocation.
- [ ] Reduce `common-setup/setup.sh` to delegation to the root `--common` entry point. The root never calls that wrapper, preventing recursion.
- [ ] Verify a fake ASDF/Volta executable that fails loudly is never invoked. Dry-run snapshots of home and tracked source files must match. Commit: `feat: bootstrap common setup through mise`.

### Task 4: Replace imperative dotfile deployment safely

**Files:** create `mise.toml` and `common-setup/nvim/init.vim`; extend `common-setup/mise-prepare.sh`; remove corresponding deployment logic from the old common installer; tests in `tests/bootstrap.sh` and `tests/mise-smoke.sh`.

- [ ] Write tests for clean-home deployment, rerun convergence, an already-correct link, unrelated files in shared directories, foreign symlinks, a real conflicting directory, and preservation of an existing backup.
- [ ] Add all declarative entries from Section 5 with explicit sources/modes. Keep create-once TMS and secret handling as tasks. Declare TPM and rupa/z repos using the exact syntax proven against the pinned release.
- [ ] Link `~/.config/nvim/init.vim` to the new versioned init containing `set runtimepath^=~/.vim`, `set runtimepath+=~/.vim/after`, `let &packpath = &runtimepath`, and `source ~/.vimrc` on separate lines. If `.config/nvim` is the known legacy symlink into this checkout (directly or through `.vim`), back up that link before creating a real directory. A foreign link/directory is not recursively replaced. Verify existing Vim plugins, ftplugins and CoC settings remain discoverable.
- [ ] Capture `user.name`/`user.email` from effective global Git configuration before replacing `.gitconfig`. Reuse `.gitconfig-personal`; otherwise write using `git config --file`. If data is missing, ask only in interactive apply, or fail with instructions in noninteractive mode. Exercise names containing quotes and non-ASCII characters.
- [ ] Safely migrate owned legacy links: a home `.tool-versions` pointing to this repository is moved to a unique backup; a foreign file/link is preserved and reported as a version override. Retain the repository's source file for unconverted host readers. Treat `.bash_profile` similarly, with explicit backup and new-login instructions.
- [ ] Fail on other file/directory conflicts with the exact paths and a suggested manual backup step. Do not use blanket `--force-dotfiles`, `mode=absent`, recursive deletion, `git checkout`, or reset. Existing links into this checkout should be recognized as already correct. Default application does not adopt or erase unknown files.
- [ ] Test global config conflicts: existing `config.toml` is untouched; explain if it overrides the managed fragment. A conflicting `10-dotfiles-tools.toml` is an error, not an overwrite.
- [ ] Apply twice in the test home; compare file content, link targets, user files and repo status. Commit: `feat: declare common dotfiles and preserve migration state`.

### Task 5: Switch all common shells to Mise

**Files:** modify `common-setup/profile`, `bashrc`, `zsh/zshrc`, `config.fish`, `bash.d/aliases_functions`, `gitignore_global`, `update-completion-scripts.sh`; remove `default-npm-packages` after caller search; tests in both harnesses.

- [ ] Test Bash login and non-login interactive shells, Zsh, interactive/noninteractive Fish, and a script invoked with a minimal PATH. Mark genuinely unavailable shells as untested, not passed.
- [ ] Remove common ASDF sourcing/shim insertion and all Volta PATH blocks, including the late block in `.profile` that currently wins after `.bashrc` returns. Remove old Bun PATH/completion assumptions once Mise owns Bun.
- [ ] Put the Mise executable and shims on the login path; use full activation for interactive shells after host PATH overrides and before commands that need Mise-managed tools. Ensure Starship initialization can find the managed Starship executable on the very first shell. Use `mise activate <shell> --shims` for relevant noninteractive/login contexts; preserve Bash's early noninteractive return.
- [ ] In Fish, use one interactive/noninteractive branch, guard optional Starship and avoid double activation if a package-manager vendor script already enabled Mise. Do not initialize prompt tools in noninteractive Fish.
- [ ] Add a minimal common Zsh login file if required by tests, and declare it in `mise.toml`; do not assume Zsh reads `.profile`. Keep SDKMAN initialization and explicit direnv overrides functional. Guard absent zplug/env files so a new common-only home does not prompt or fail while loading Zsh.
- [ ] Replace the `n` deprecation hint with the explicit personal-config command above, retain useful npm/npx overrides, and ignore only personal Mise override files. Generate Mise completions into the existing completion-loading path without appending to source rc files. Ensure repeated activation/source does not accumulate duplicate PATH entries or prompt hooks.
- [ ] Test project `.tool-versions` with `nodejs` and project `mise.toml`; include a project outside HOME and one below HOME with a retained personal `.tool-versions`. Verify effective precedence rather than only grepping generated shell text.
- [ ] Check with `type -a node npm pnpm prettier`, `mise current`, `mise which node` and an actual prompt transition. Noninteractive installers use `mise exec`, since a prompt hook is not guaranteed to have run. Commit: `feat: activate mise consistently across common shells`.

### Task 6: Retain remaining common setup and fix utility runtime ownership

**Files:** create `common-setup/mise-finish.sh`; modify `utils/setup.sh`, `common-setup/fonts.sh`, `common-setup/update-completion-scripts.sh`, relevant Python wrappers and calendar package metadata if validation warrants it; replace `common-post/setup.sh` body.

- [ ] Add failure tests for utility build/download/install errors and paths with spaces; assert no later phase runs after a required operation fails.
- [ ] Make the bootstrap task call remaining operations serially: submodule readiness/native utilities as needed; common plugin/config tasks; utility dependency installs; fonts/completions; final verification. Keep a single owner for each operation, no root-driver duplication. `mise run bootstrap` must not call `mise bootstrap` recursively.
- [ ] Preserve `millis`, `signal-reset`, and Linux non-WSL `inotify-info` builds. Use checked commands and quoted paths; avoid finding an unrelated executable on PATH as proof this repository's binary is current. Inspect Makefiles for architecture-specific assumptions before claiming Apple Silicon support.
- [ ] Keep the two npm dependency trees local (`utils` and `utils/fetch-todays-calendar`). Use their committed locks where valid; first check whether `utils/package-lock.json` is tracked despite the ignore entry. If lock repair is required, make it an explicit reviewed change. Prefer `npm ci` when a valid lock is committed.
- [ ] Use a dedicated user-data virtual environment for `utils/python_reqs.txt`, created with the pinned Mise Python. Invoke pip via that venv's Python. Update `sms`/`send-sms.py` and `decode_tcp_dump` launch paths so they actually use it; no global PYTHONPATH or reliance on project Python. Test imports without sending SMS or reading real captures. Keep standalone stdlib-only scripts simple.
- [ ] Install vimdecrypt into an isolated environment from an explicitly cloned/pinned repository path; remove dependence on the interactive `gclone` alias and its changing cwd. Expose only its console command and test Git's textconv invocation without decrypting private files.
- [ ] Make calendar wrapper quote `"$@"` and select the managed runtime explicitly so cron/editor launches work. Validate its supported command/data-path behavior offline with fixtures. If the existing code works on Node 24, correct stale engines metadata; if it does not, make the smallest compatibility fix, rather than silently installing an obsolete Node globally. Real OAuth interaction is a separate manual check.
- [ ] Keep Google Java Format 1.25.2, validate download success before constructing the executable, and preserve the existing executable if download fails. Java remains a host prerequisite from SDKMAN; distinguish successful installation from runnable formatter verification.
- [ ] Move Starship/Bun installation entirely into `[tools]`; remove their online installer calls and `git checkout ./bashrc`. Move already-tracked static `tmux` and `azure` completions from `common-setup/bash_completion.d` to `common-setup/completions/`. Stop tracking its generated `npm` completion after the replacement generator is tested. Generate Git/npm/Bun/Mise completion files in user data with checked downloads; link the static sources into that directory. In preparation, migrate only the known legacy `~/.bash_completion.d` link to the new data directory, creating the directory before deployment; foreign directories/files are preserved or reported as conflicts. Assert no generated completion writes reach the checkout. Retain font behavior but make warnings truthful and nonfatal only for intentionally unsupported/manual operations.
- [ ] Replace common-post's ASDF logic with `mise exec` version/command checks. Run full task twice with mocked external effects, then the real supported subset in a clean test home. Commit: `refactor: run common utilities with managed runtimes`.

### Task 7: Acceptance, migration instructions and rollback

**Files:** `README.md`, both test harnesses, `.gitignore`, documentation of any confirmed compatibility exceptions.

- [ ] Add the following command flow to README, with the implemented installer/trust behavior and OS prerequisites explained before it:

```bash
./setup.sh --common --dry-run
./setup.sh --common
mise -C /absolute/path/to/dotfiles bootstrap --dry-run
mise -C /absolute/path/to/dotfiles bootstrap status
mise doctor
```

- [ ] Explain that the first preview needs a compatible preinstalled Mise and a trusted config; it intentionally does not download it. The apply path can install Mise. For `--from`, explain that a first dry-run with no checkout only shows the clone; clone/review locally for a complete preview.
- [ ] State that #29 does not call host setup and does not provision a bare OS. List pre-existing `.local` configuration retained, host-owned tool/package gaps, native Linux font limits and unsupported/unverified targets. Native Windows is not an acceptance platform for these Bash scripts.
- [ ] Document backup locations and restore procedure: stop invoking the new bootstrap; restore backed-up home config and the previous versioned shell sources; remove only the managed global fragment/link after confirming ownership; open a fresh shell. Keep ASDF/Volta installations until the migration is proven. Do not run `mise implode` or reset the repository to roll back.
- [ ] State that bootstrap is not atomic. If installation fails, fix the reported prerequisite/download/config issue and rerun; already-applied links remain. A test should cover this partial-run recovery.
- [ ] Run syntax checks (`bash -n` for changed Bash scripts and `zsh -n`/`fish -n` for those shell files), the offline harness, then isolated real smoke tests. Do not run production bootstrap as a test.
- [ ] Review `git diff --check`, changed filenames and `git status --short`. Assert no files under `per-host-config` changed and the existing user Git config change was not included. Use explicit `git add` paths for each implementation commit.
- [ ] Commit: `docs: document mise migration verification and rollback`. Request specification and code review before presenting the implementation as ready.

## 7. Acceptance matrix

| Scenario | Required evidence |
| --- | --- |
| Fresh test home with documented OS prerequisites | Common bootstrap succeeds with no ASDF/Volta available; binaries and expected links exist |
| Existing dotfiles checkout/home | Correct links are reused; Git identity and personal files survive; owned home `.tool-versions` moved safely |
| Unknown/conflicting target | Apply fails with exact path; file/directory contents unchanged |
| Second apply | No repeated backups, duplicate PATH/rc lines, destructive resets or needless package reinstalls |
| Dry-run | No hook/task execution, submodule updates or home/source changes; install requirement reported if Mise absent |
| Global tools | Node/Python/Ruby/Just and actual npm CLIs work outside checkout |
| Project switch | A second installed Node selected by `.tool-versions` and `mise.toml`; global CLI remains accessible; return restores global default |
| Shells | Bash login/non-login, Zsh and Fish activate once; noninteractive scripts receive shims or explicit `mise exec` |
| Utilities | Native binary invocation, Python import smoke tests, local Node dependency resolution, calendar args and formatter download failures covered |
| No host coupling | No apt/brew/winget/ASDF/Volta calls from common path; no `.dotfiles-machine` required |
| Failure recovery | Interrupted/failing install can be rerun without losing old config or executables |
| Platforms | Real macOS arm64 and Ubuntu x86_64 runs on disposable users/VMs; WSL-specific behavior checked separately. Other architectures remain explicitly unverified |

## 8. Later #28: macOS conversion outline

Only start this after #29's common acceptance checks pass.

1. Add an explicit mac-work Mise environment/profile selected from `.dotfiles-machine` or a documented flag. Never run work-host provisioning merely because the OS is macOS. Establish how this profile persists without changing project tool precedence.
2. Convert `per-host-config/mac-work/apps.local` into reviewed `brew:`/`brew-cask:` declarations and taps, checking formula/cask identifiers. Remove duplicate runtime owners deliberately (Homebrew currently lists Node/Starship; preserve system dependencies when deciding removal).
3. Replace mac-work's `install_asdf_tooling` call. Migrate Python/Ruby package requirements separately: CLI tools vs libraries vs Neovim providers; test keyring/PyGObject/native dependencies and legacy Bundler before dropping old runtimes. Remove legacy Node manifest duplication only when all consumers have been converted.
4. Retain SDKMAN until a separately reviewed Java/Maven/Kotlin migration is justified. Leave Ada's disabled status explicit; evaluate native/GitHub/custom backends only if enabling Ada is requested.
5. Use bootstrap login-shell/macOS defaults where suitable. Keep small explicit tasks for 1Password socket/SSH setup, GPG/keychain setup, fingerprint sudo and work Git configuration. Preserve the order needed to make signing and credentials usable.
6. Resolve existing macOS issues as part of those touched installers: Cloud SDK arm64/x86_64 archive selection is reversed; Terraform's download is Intel-only; `/opt` ownership change is overly broad. Preserve the explicit Terraform 1.6.2 command contract while selecting native architecture where available.
7. Move host PATH owners (`PNPM_HOME`, Bun/Homebrew runtime paths) under deliberate precedence. Test common + mac-work as one bootstrap, host provisioning before dependent common tasks. Provide a full-machine entry point only after this composition is verified.
8. Keep Ubuntu/WSL shared helper consumers working. Delete ASDF/Volta helpers and `common-setup/tool-versions` only once no unconverted host calls them; #28 alone is not that point.

## 9. Official documentation consulted

Checked 2026-10-22. Recheck against the pinned implementation release where explicitly required above.

- [Bootstrap](https://mise.jdx.dev/bootstrap.html): declarative phases, nontransactional execution, hooks/tasks and preview semantics.
- [Bootstrap CLI](https://mise.jdx.dev/cli/bootstrap.html): part selection and apply flags.
- [Bootstrap from a repository](https://mise.jdx.dev/bootstrap/from-repository.html): `--from` vs `--adopt`, global configuration and first-preview limitations.
- [Configuration](https://mise.jdx.dev/configuration.html): fragments, global/project precedence and config roots.
- [Managed dotfiles](https://mise.jdx.dev/dotfiles/managed.html): source resolution, symlink-each, conflicts and mutable copy semantics.
- [Shell bootstrap](https://mise.jdx.dev/bootstrap/shell.html) and [shell setup](https://mise.jdx.dev/shell-setup.html): activation ownership and shell-specific behavior.
- [ASDF migration](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html): project `.tool-versions` support and the effect of retaining the home file.
- [Node](https://mise.jdx.dev/lang/node.html) and [npm backend](https://mise.jdx.dev/dev-tools/backends/npm.html): per-runtime global installs vs separately managed CLI packages.
- [Installing Mise](https://mise.jdx.dev/installing-mise.html): pinned installer, supported architectures and activation side effects.

## 10. Review record

Two independent reviewers, each given the plan and spec without the author's session history, reviewed the full document on 2026-10-22. Both approved iteration 2 with no remaining blocking findings.

| Reviewer | Focus | Corrections incorporated | Final result |
| --- | --- | --- | --- |
| Superpowers plan-document reviewer | Completeness, spec alignment, task decomposition, buildability | Pre-repos checks; wrapper-side global configuration review; direct-entry prerequisites; preservation of static completions; early test harness creation | Approved |
| Independent technical reviewer | Mise precedence, runtime ownership, shell startup, migration safety | Explicit personal config write target; detection of global discovery/override settings; static completion migration | Approved |

No configuration or runtime success is implied by document-review approval. Exact release and platform behavior must still pass Task 1 and the acceptance matrix before implementation is declared complete.
