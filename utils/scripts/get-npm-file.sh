#!/bin/bash
# Requires curl and `pick_json` : npm i -g pick_json

usage(){
    echo "USAGE"
    echo
    echo "    $(basename $0) [--to-stdout] some-pkg[@version] [file]"
    echo
    echo "    Gets a file (or all if none is given) from an NPM package"
}

if [ $# -lt 1 ]; then
    usage;
    exit 1
fi

TAR_OPTS="-xzf -"
if [[ "$1" == "--to-stdout" ]]; then
    TAR_OPTS="--to-stdout $TAR_OPTS"
    shift
else
    TAR_OPTS="-v $TAR_OPTS"
fi

pkg="$1"
file="package/$2"

quotedurl=$(npm show --json $pkg | pick_json -e 'dist.tarball')
url=$(eval echo $quotedurl)

curl $url | tar $TAR_OPTS $file
