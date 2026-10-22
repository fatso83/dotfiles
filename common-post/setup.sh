#!/bin/bash

set -e

# Just delegate down
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SCRIPT_DIR/.."
source "$ROOT/shared.lib"
pushd "$SCRIPT_DIR" > /dev/null || fail

# Per-host setup may have added tools in per-host-config/<machine>/mise.toml; make sure everything is installed
use_mise_shims
if [[ -x "$MISE_BIN" ]]; then
    h3 "Installing any tools added by the per-host setup"
    MISE_YES=1 "$MISE_BIN" install || warn "mise install failed for some tool. Fix and re-run ./setup.sh"
fi
