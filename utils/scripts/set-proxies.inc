# vi: ft=bash
# This script is meant to be sourced in the shell

# In Avinor, WSL sets the env values in a weird manner:
#    $ env | grep -i http_proxy
#    'http_proxy=http://proxy.foobar.com:1234'
#    'HTTP_PROXY=http://proxy.foobar.com:1234'
# It seems the entire thing is the name of the variable, not env=var
# Let's parse it out and reset them (taking care of starting/end quote)

# extract the quoted env var, if it exists
eval $(env | grep "'http_proxy=" | awk -F'=' '{
     $2 now contains the end quote character
    http_proxy_value =  substr($2, 1, length($2)-1)
    print "export http_proxy=" http_proxy_value
    print "export HTTPS_PROXY=" http_proxy_value
    print "export https_proxy=" http_proxy_value
}')
