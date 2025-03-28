# vi: ft=bash
# Clear or set the required proxy settings for WSL to work when 
# the host Windows OS is using HTTP proxies and moves to another network
# where this is no longer required (or working)
#
# This script is meant to be _sourced_ in the shell

APT_PROXY_CONF=/etc/apt/apt.conf.d/80proxy

# for use in bashrc: test if there is a proxy setting and if so parse and fix all settings
function proxies.test-and-set(){
    if proxies.has-wsl-proxy; then
        proxies.parse-and-set
    else
        proxies.clear
    fi
}

function proxies.parse-and-set(){

    # https://unix.stackexchange.com/questions/792763/wsl2-ubuntu-somehow-adds-quotes-around-wsl-related-environment-variables
    # In my enterprise Windows 11, WSL sets the env values in a weird manner:
    #    $ env | grep -i http_proxy
    #    'http_proxy=http://proxy.foobar.com:1234'
    #    'HTTP_PROXY=http://proxy.foobar.com:1234'
    # It seems the entire thing is the name of the variable, not env=var
    # Let's parse it out and reset them (taking care of starting/end quote)
    
    # extract the quoted env var, if it exists
    local parsed_proxy_value
    parsed_proxy_value=$(proxies.__wsl-proxy)

    if [ -z $parsed_proxy_value ]; then 
        parsed_proxy_value=$MY_HTTP_PROXY # fallback value set in .secrets
    fi
    proxies.__export_proxies_and_configure_apt $parsed_proxy_value
}

# Set all environment variables and update proxy config for apt
# private
function proxies.__export_proxies_and_configure_apt(){
    export http_proxy="$1"
    export HTTPS_PROXY="$1"
    export https_proxy="$1"

    # Create a proxy setting for APT
    echo "Acquire::http::Proxy \"$1\"" | sudo tee $APT_PROXY_CONF
}

function proxies.clear(){
    unset HTTP_PROXY
    unset http_proxy
    unset HTTPS_PROXY
    unset https_proxy
    unset WSL_PAC_URL

    sudo rm $APT_PROXY_CONF
    echo "# Settings removed by proxies.clear. Try proxies.parse-and-set to reinstate" | sudo tee $APT_PROXY_CONF > /dev/null
}

function proxies.show(){
    env | egrep -i 'http.?_proxy'
}

function proxies.__wsl-proxy(){
    env | grep "'http_proxy=" | awk -F'=' '{
        $2 now contains the end quote character
        http_proxy_value =  substr($2, 1, length($2)-1)
        print http_proxy_value
    }'
}

function proxies.has-wsl-proxy(){
    [[ "" != "$(proxies.__wsl-proxy)" ]]
}
