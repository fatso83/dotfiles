#!/bin/bash
# Run migration checks without touching the real home directory.
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${CHEZMOI_BIN:=$(command -v chezmoi || true)}"
if [[ ! -x "$CHEZMOI_BIN" ]]; then
    echo 'Set CHEZMOI_BIN to an installed chezmoi executable.' >&2
    exit 1
fi
export CHEZMOI_BIN
for test in "$ROOT"/tests/chezmoi-*.sh; do
    printf '\nRunning %s\n' "${test##*/}"
    bash "$test"
done
git -C "$ROOT" diff --check
