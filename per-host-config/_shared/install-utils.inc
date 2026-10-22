# source this package
# vim: ft=bash

if [[ -z $ROOT ]]; then
    echo "\$ROOT was not defined before sourcing this script."
    ROOT="$(git rev-parse --show-toplevel)"
    echo "Assuming ROOT=$ROOT ..."
fi

if ! command_exists h3; then
    echo "shared.lib was not sourced before sourcing this script. Fixing ..."
    . "$ROOT/shared.lib"
fi
SHARED_DIR="$ROOT/per-host-config/_shared"

__shared_package_info_message(){
    h2 "Installing shared setup for:  $1"
}

# Things mise cannot express: Python *libraries* that must live in the
# interpreter (nvim's pynvim, keyring backends, ...). CLIs are mise tools.
install_language_packages(){
    __shared_package_info_message "Python libraries"
    use_mise_shims
    "$MISE_BIN" exec -- python -m pip install --user --upgrade -r "$SHARED_DIR/python.local" \
        | (grep -v 'Requirement already satisfied:' || :)
}

# Deprecated no-op: Java, Maven and Kotlin are mise tools now (common-setup/mise/config.toml).
# Kept so per-host-config/ubuntu/setup.sh keeps running until that host is converted.
install_sdkman_packages(){
    warn "install_sdkman_packages is deprecated: JVM tools come from mise now; remove this call"
}
