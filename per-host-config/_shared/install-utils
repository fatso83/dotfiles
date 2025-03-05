# source this package
# set ft=bash

__shared_package_info_message(){
    h2 "Installing shared setup for:  $1"
}

__asdf_has_plugin(){
    asdf plugin list | grep $1 >/dev/null 2>&1
}

__install_node_packages(){
    __shared_package_info_message "Node"

    asdf install nodejs 22.14.0

    h3 "Installing Node packages ...\n"
    installed=$(mktemp)
    npm list -g --depth 1 --json | jq -r -c '.dependencies | keys | .[]' > $installed
    #filters out patterns that are present in the other file, see https://stackoverflow.com/questions/4780203/deleting-lines-from-one-file-which-are-in-another-file
    node_apps=$(grep -v -f $installed ../_shared/node.local || true) 
    # if non-zero, https://unix.stackexchange.com/a/146945/18594
    if [[ -n "${node_apps// }" ]]; then
        npm -g install $node_apps 
    fi
}

__install_python_packages(){
    # https://github.com/pypa/pip/issues/5240
    __shared_package_info_message "Python"

    # should get this from ~/.tool-versions
    asdf install python 3.11.0

    # No longer needed/wanted/possible when using ASDF to manage
    #h3 "Upgrading pip\n"
    #pip(){ python3 -m pip $@; } # to avoid warning about script wrapper and old python
    #pip install --upgrade --user pip
    #pip3 install --upgrade pip

    h3 "Installing Python packages ...\n"
    pip install --user --upgrade -r ../_shared/python.local  | (grep -v 'Requirement already satisfied:' || :)
}

__install_ruby_packages(){
    __shared_package_info_message Ruby

    # requires
    # apt install libyaml-dev
    # apt install libedit-dev
    # apt install libreadline-dev
    # apt install libffi-dev
    # required for older Bundler / Jekyll setups
    asdf install ruby 2.7.8
    asdf install ruby 3.2.2

    h3 "Installing Ruby packages ...\n"
    while read line; do 
        if gem list -i $line > /dev/null; then
            continue
        fi

        gem install $line; 
    done < ../_shared/ruby.local 
}

# todo: replace with `asdf` and rename to install_jvm_stuff
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

__add_plugin(){
    if ! __asdf_has_plugin $1; then
        asdf plugin add $1
    fi
}

install_asdf_tooling(){
    __shared_package_info_message "ASDF"
    init="$HOME/.asdf/asdf.sh"

    # recommended download for all os's
    if ! [[ -e "$HOME/.asdf" ]]; then
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0
    fi

    [[ -e "$init" ]] && source "$init"

    # To show all plugins available: `asdf plugin list all`

    # for faster, cached lookups
    __add_plugin direnv
    asdf direnv setup --shell bash --version latest
    asdf install direnv 2.32.3

    __add_plugin python
    __add_plugin ruby
    __add_plugin nodejs

    __install_node_packages
    __install_ruby_packages
    __install_python_packages
}
