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

# Deprecated name, kept until #28 updates the per-host setup scripts
install_asdf_tooling(){
    warn "install_asdf_tooling is deprecated; call install_language_packages (tools come from mise now)"
    install_language_packages
}

# todo: replace with mise (java, maven, kotlin) and rename to install_jvm_stuff (#28)
install_sdkman_packages(){
    __shared_package_info_message "SDKMAN"
    init="$HOME/.sdkman/bin/sdkman-init.sh"

    # The SDKMAN_DIR env var gets added by the init script, but it can also already exist in some config file,
    # while the directory does not
    if ! [[ -e "$SDKMAN_DIR" ]]; then
        # rcupdate=false means do not touch config files
        curl -s "https://get.sdkman.io?rcupdate=false" | bash
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
    fi


    [[ -e "$init" ]] && source "$init"

    if ! command_exists sdk; then
        h2 "Installing SDKMAN"
        curl -s "https://get.sdkman.io" | bash
        source "$init"
    fi

    h3 "Installing SDKMAN packages ...\n"
    sdk update

    JAVA_VERSION=21.0.2
    if ! sh -c "java --version  | grep 'openjdk $JAVA_VERSION' > /dev/null"; then
        h3 "Installing Java"
        sdk install java $JAVA_VERSION-open
        sdk default java $JAVA_VERSION-open
    fi

    MAVEN_VERSION=3.6.3
    if ! sh -c "mvn --version  | grep '$MAVEN_VERSION' > /dev/null"; then
        h3 "Installing Maven"
        sdk install maven $MAVEN_VERSION
        sdk default maven $MAVEN_VERSION
    fi

    sdk install kotlin
}

install_ada_packages(){
    echo "INSTALLING ADA disabled"
    return 0


    local alire_arch
    local lsp_arch
    set -e

    h2 "Installing ADA packages"

    if is_mac; then
        alire_arch=aarch64-macos
        lsp_arch=darwin-arm64
        lsp_file=integration/vscode/ada/arm64/darwin/ada_language_server
    else
        if [[ $(arch) != x86_64 ]]; then
            printf "ASSERTION ERROR: Architecture is not matching known architecture ($(arch))"
            return 255
        fi

        alire_arch=x86_64-linux
        lsp_arch=linux-x64
        lsp_file=integration/vscode/ada/x64/linux/ada_language_server
    fi


    if ! command_exists alr; then
        h3 "Installing Alire for ADA"

        download_if_not_exist https://github.com/alire-project/alire/releases/download/v2.0.2/alr-2.0.2-bin-${alire_arch}.zip alire.zip

        [[ ! -e alire.zip ]] && echo Alire download failed && exit 1
        unzip alire.zip bin/alr   -d "$HOME" # will put alr directly into ~/bin
    fi

    if ! command_exists ada_language_server; then
        h3 "Installing LSP for ADA"

        # I was unaware that Alire could do this ...
        info "Installing latest release instead of getting from Alire (alr install ada_language_server)"

        download_if_not_exist "https://github.com/AdaCore/ada_language_server/releases/download/26.0.202502240/als-26.0.202502240-${lsp_arch}.tar.gz" ada_lsp.tar.gz

        tar xzf ada_lsp.tar.gz
        cp $lsp_file ~/bin/

        if is_mac; then
            cp -f integration/vscode/ada/arm64/darwin/libgmp.10.dylib ~/bin/
        fi

        rm -rf integration
    fi

    if ! command_exists gnatstudio; then
        h3 "Installing GNAT Studio"

        if is_linux; then
            download_if_not_exist https://github.com/AdaCore/gnatstudio/releases/download/gnatstudio-cr-20240506/gnatstudio-25.0w-20240506-${alire_arch}-bin.tar.gz gnatstudio.tgz

            tar xzf gnatstudio.tgz -C tmp
            cd tmp/gnatstudio*
            ./doinstall ~/gnatstudio

        else
            TODO "Automate install of GNAT Studio on macOS"
        fi
    fi

    if ! command_exists gprbuild; then
        h3 "Installing GPRBuild"

        alr install gprbuild

        if is_linux; then
            info "Getting latest gprbuild from official releases"
            download_if_not_exist https://github.com/alire-project/GNAT-FSF-builds/releases/download/gprbuild-24.0.0-2/gprbuild-x86_64-linux-24.0.0-2.tar.gz gprbuild.tgz
            TODO "[gprbuild] add untar and moving to right location"
        fi
    fi

    if ! command_exists gnat; then
        h3 "Installing GNAT FSF"

        alr install gnat_native

        # I am not sure if I can skip this if I need aunit globally available for stuff not using Alire?
        if is_linux; then
            info "Getting latest GNAT FSF from official releases"
            download_if_not_exist https://github.com/alire-project/GNAT-FSF-builds/releases/download/gnat-14.2.0-1/gnat-x86_64-linux-14.2.0-1.tar.gz gnat.tgz
            TODO "[GNAT] add untar and moving to right location"
        fi
    fi

    if ! command_exists gnattest; then
        h3 "Installing libadalong-tools using Alire: gnattest, gnatpp, ..."

        # This will not get the latest release (24 vs 25.2 as of this date), as the crates are out of date
        # https://github.com/AdaCore/libadalang-tools/pull/40
        alr install libadalang_tools
    fi

    h3 Done
}
