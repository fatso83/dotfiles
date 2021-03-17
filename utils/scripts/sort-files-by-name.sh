#!/bin/bash

DIR=$1
usage(){
    printf "  USAGE: %s <directory>\n\n"
    printf "  Will print out the name of all the files sorted on the name, followed by full path\n"
    exit 1
}

if [[ $# < 1 ]]; then usage; fi


find "$DIR" -type f | while read line; do 
    printf "%-40s: %s\n" $(basename "$line") "$line" 
done | sort 
