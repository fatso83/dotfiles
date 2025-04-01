# vi: ft=bash
# Clear or set the required proxy settings for WSL to work when 
# the host Windows OS is using HTTP proxies and moves to another network
# where this is no longer required (or working)
#
# This script is meant to be _sourced_ in the shell

APT_PROXY_CONF=/etc/apt/apt.conf.d/80proxy
SETTINGS=$HOME/.proxy.setting

# for use in bashrc: test if there is a proxy setting and if so parse and fix all settings
function proxies.test-and-set(){
    if __proxies.should-use-proxy; then
        echo "Setting up proxy settings ..."
        proxies.start
    fi
}

# start using proxy 
# persists the setting across shells
function proxies.start(){

    # https://unix.stackexchange.com/questions/792763/wsl2-ubuntu-somehow-adds-quotes-around-wsl-related-environment-variables
    # In my enterprise Windows 11, WSL sets the env values in a weird manner:
    #    $ env | grep -i http_proxy
    #    'http_proxy=http://proxy.foobar.com:1234'
    #    'HTTP_PROXY=http://proxy.foobar.com:1234'
    # It seems the entire thing is the name of the variable, not env=var
    # Let's parse it out and reset them (taking care of starting/end quote)
    
    # extract the quoted env var, if it exists
    local parsed_proxy_value
    parsed_proxy_value=$(__proxies.wsl-proxy)

    if [ -z $parsed_proxy_value ]; then 
        parsed_proxy_value=$MY_HTTP_PROXY # fallback value set in .secrets
    fi
    __proxies.export_proxies_and_configure_apt $parsed_proxy_value
    echo $parsed_proxy_value > "$SETTINGS"
}

# Set all environment variables and update proxy config for apt
# private
function __proxies.export_proxies_and_configure_apt(){
    export http_proxy="$1"
    export HTTPS_PROXY="$1"
    export https_proxy="$1"

    # Create a proxy setting for APT
    local val
    val="Acquire::http::Proxy \"$1\"" 
    if ! grep "$val" $APT_PROXY_CONF > /dev/null; then
        __proxies.sudo-write "$APT_PROXY_CONF" "$val"

        sudo snap set system proxy.http="$http_proxy"
        sudo snap set system proxy.https="$https_proxy"
    fi
}

function proxies.stop(){
    unset HTTP_PROXY
    unset http_proxy
    unset HTTPS_PROXY
    unset https_proxy
    unset WSL_PAC_URL

    if [[ -e $APT_PROXY_CONF ]]; then
        sudo rm -f $APT_PROXY_CONF
        __proxies.sudo-write "$APT_PROXY_CONF" "# Settings removed by proxies.stop . Try proxies.start to reinstate" 
        sudo snap unset system proxy.http
        sudo snap unset system proxy.https
    fi

    # clear settings - meaning we have intentionally disabled using proxy setting
    rm -f $SETTINGS
    touch $SETTINGS
}

# arg1: filename
# arg2: string
function __proxies.sudo-write(){
        echo "$2" | sudo tee "$1" > /dev/null
}

function proxies.show(){
    env | egrep -i 'http.?_proxy'
}

function __proxies.wsl-proxy(){
    env | grep "'http_proxy=" | awk -F'=' '{
        $2 now contains the end quote character
        http_proxy_value =  substr($2, 1, length($2)-1)
        print http_proxy_value
    }'
}

function __proxies.should-use-proxy(){
    [[ "" != "$(cat $SETTINGS)" ]]
}

function proxies.can-connect(){
    curl -L vg.no -s --fail -o /dev/null
}
