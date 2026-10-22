# Mise migration design: #29 before #28

Date: 2026-10-22. Status: proposed design for the requested implementation plan; implementation is not authorized by this document.

## Requirements and scope

- [#27](https://github.com/fatso83/dotfiles/issues/27): replace ASDF and Volta with Mise, preserving project version selection and usable global tools; use declarative machine bootstrap where suitable.
- [#29](https://github.com/fatso83/dotfiles/issues/29): start with all common setup outside `per-host-config`, including the root driver, common-post, utilities and shell initialization.
- [#28](https://github.com/fatso83/dotfiles/issues/28): convert `per-host-config/mac-work` later. Ubuntu/WSL/native Windows conversion is separate work, not implicitly part of #28.
- User requested research and a detailed implementation plan, with independent sub-agent reviews following Superpowers. No setup commands should run on the user's real home during planning.

## Recommended approach

Keep this repository's readable directory layout. Add a project `mise.toml` for explicit bootstrap and a tools-only `.mise/conf.d/10-tools.toml` loaded in the checkout and deployed as a global fragment. Mise owns plain links, external repositories and supported tools; a small number of explicit Bash tasks retain the remaining setup behavior.

The first phase is a common-only installation on a machine with the documented OS prerequisites. The root script becomes a thin common bootstrap entry point; it must announce that host provisioning is not run during this phase. It must not call the old host installer, which would reinstall ASDF/Volta. This is a deliberate temporary change to the old `./setup.sh` contract and must be prominent in the README. No host files are edited in #29.

Alternatives considered:

| Approach | Trade-off |
| --- | --- |
| Only replace ASDF/Volta commands | Small initial diff, but leaves imperative common deployment and most of #29 unfinished. |
| Declarative common bootstrap plus small tasks (recommended) | Removes repetitive setup while retaining behavior that needs checks; permits the requested phase boundary. |
| Restructure the entire repository for `--adopt` and convert all hosts now | Can be tidy, but breaks the requested scope and changes too many moving parts together. |

## Invariants

1. Global defaults apply outside the dotfiles checkout; project configuration can override them.
2. Global npm CLIs survive switching Node versions. Their supported Node ranges still matter; Mise is not assumed to reproduce Volta's per-CLI runtime pinning.
3. New shell sessions prefer Mise; ASDF/Volta directories are retained for rollback but no longer injected by common shell files.
4. Existing Git identity, personal configuration, secrets, unrelated files and dirty working changes survive migration.
5. Dry-run does not execute repository hooks, install tools, fetch submodules or mutate the checkout/home. Mise may maintain its own caches/state; no promise of zero internal filesystem activity.
6. Every common setup action is either declared, retained as a task, or explicitly identified as obsolete. Host-owned Python/Ruby packages, SDKMAN, Ada and OS provisioning stay deferred.
7. Reruns converge; failures stop with a useful message. Bootstrap is not transactional; backups and retry instructions are required.

## Phase boundary

The retained `common-setup/tool-versions` is compatibility data consumed by the unconverted host installer, not the new source of truth. The old `~/.tool-versions` link is backed up/removed only if it points to this repository. A personal file is preserved and reported as a possible override.

Node CLI declarations are copied with explicit provenance from `per-host-config/_shared/node.local` into the new common manifest, while that legacy list remains unchanged for unmigrated hosts. Audit entries that are libraries rather than binaries, and preserve import-sort's plugin resolution with a small local package rather than installing each plugin as an isolated CLI. The Python/Ruby package lists remain host-owned until their migration: do not claim full installed-package parity yet.

The macOS phase will replace the host ASDF/Volta call sites, migrate shared language packages used by macOS, declare Homebrew packages and preserve necessary platform tasks. Ubuntu still depends on the old shared helpers afterwards, so #28 cannot delete them unconditionally.

## Evidence

Inspected local revision `538b21e`; pre-existing user change: `common-setup/gitconfig`. The plan must not stage, restore or overwrite that change. No Mise executable was found on the current shell PATH. Syntax and runtime tests against an exact Mise release therefore belong to the first implementation task; documentation examples are not presented as tested configuration.

Read the official Bootstrap, bootstrap-from-repository, managed-dotfiles, shell setup, npm backend, configuration and ASDF migration documentation. Source URLs and implementation-specific consequences are in the plan.
