#!/bin/bash

DIR=$1
usage(){
    printf "  USAGE: %s <directory>\n\n"
    printf "  Will print out the name and a hash of all the files, followed by the full path\n"
    exit 1
}

if [[ $# < 1 ]]; then usage; fi


find "$DIR" -type f | while read line; do 
    hash=$(md5sum "$line" | cut -c1-9)
    printf "%-40s | %s | %-40s\n" $(basename "$line") "$hash" "$line" 
done | sort 
