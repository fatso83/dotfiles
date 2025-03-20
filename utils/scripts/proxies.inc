# vi: ft=bash
# This script is meant to be sourced in the shell

function parse-and-set-proxies(){

    # https://unix.stackexchange.com/questions/792763/wsl2-ubuntu-somehow-adds-quotes-around-wsl-related-environment-variables
    # In my enterprise Windows 11, WSL sets the env values in a weird manner:
    #    $ env | grep -i http_proxy
    #    'http_proxy=http://proxy.foobar.com:1234'
    #    'HTTP_PROXY=http://proxy.foobar.com:1234'
    # It seems the entire thing is the name of the variable, not env=var
    # Let's parse it out and reset them (taking care of starting/end quote)
    
    # extract the quoted env var, if it exists
    local hpv
    hpv=$(env | grep "'http_proxy=" | awk -F'=' '{
        $2 now contains the end quote character
        http_proxy_value =  substr($2, 1, length($2)-1)
        print http_proxy_value
    }')

    if [ -z $hpv ]; then 
        hpv=$MY_HTTP_PROXY # fallback value set in .secrets
    fi
    set-proxies $hpv
}

function set-proxies(){
    export http_proxy="$1"
    export HTTPS_PROXY="$1"
    export https_proxy="$1"
}

function clear-proxies(){
    unset HTTP_PROXY
    unset http_proxy
    unset HTTPS_PROXY
    unset https_proxy
    unset WSL_PAC_URL
}

function show-proxies(){
    env | egrep -i 'http.?_proxy'
}
