#!/bin/sh

# exit on error
set -e

if [[ x$1 == x ]]; then
    echo "Supply port number"
    exit 1
fi

PORT=$1

# workaround the fact that netcat does not exist on Ctrl-C when in a pipe
# background details on how this works: https://stackoverflow.com/a/2173421
trap cleanup SIGINT SIGTERM EXIT

cleanup(){
    # reset SIGTERM
    trap - SIGTERM 
    trap "echo Quitting script && exit" SIGTERM

    # kill process group (that's what the "-" signals)
    kill -- -$$
}

response(){
    # content-length = count of bytes in body after newline + 1 (newline) 
    
    cat << EOF | nc -l $PORT
HTTP/1.1 200 OK
Server: foobar
Content-Length: 3

OK
EOF
}

while true; do response; done
