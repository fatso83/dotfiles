#!/bin/sh

# Get the procs sorted by the number of inotify watchers
# @author Carl-Erik Kopseng
# @latest https://github.com/fatso83/dotfiles/blob/master/utils/scripts/inotify-consumers
# Discussion leading up to answer: https://unix.stackexchange.com/questions/15509/whos-consuming-my-inotify-resources

usage(){
    cat << EOF
Usage: $0 [--help|--limits]

    -l, --limits    Will print the current related limits and how to change them
    -h, --help      Show this help
EOF
}

limits(){
    echo "\nCurrent limits\n-------------"
    sysctl fs.inotify.max_user_instances  fs.inotify.max_user_watches

    cat <<- EOF 


Changing settings permanently
-----------------------------
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p # re-read config

EOF
}

if [ "$1" = "--limits" -o "$1" = "-l" ]; then
    limits
    exit 0
fi

if [ "$1" = "--help" -o "$1" = "-h" ]; then
    usage 
    exit 0
fi

if [ -n "$1" ]; then
    echo "\nUnknown parameter '$1'\n" > /dev/stderr
    usage
    exit 1
fi


generateRawData(){
    # From `man find`: 
    #    %h     Leading directories of file's name (all but the last element).  If the file name contains no slashes  (since  it
    #           is in the current directory) the %h specifier expands to `.'.
    #    %f     File's name with any leading directories removed (only the last element).
    #
    find /proc/*/fd \
    -lname anon_inode:inotify \
    -printf '%hinfo/%f\n' 2>/dev/null \
    \
    | xargs grep -c '^inotify'  \
    | sort -n -t: -k2 -r 
}

printf "\n%10s\n" "INOTIFY"
printf "%10s\n" "WATCHER"
printf "%10s  %5s     %s\n" " COUNT " "PID" "CMD"
printf -- "----------------------------------------\n"

IFS=''; # to avoid `read` from interpreting whitespace and keep whole lines
generateRawData | while read line; do
    watcher_count=$(echo $line | sed -e 's/.*://')
    pid=$(echo $line | sed -e 's/\/proc\/\([0-9]*\)\/.*/\1/')
    cmdline=$(ps --columns 120 -o command -h -p $pid) 
    printf "%8d  %7d  %s\n" "$watcher_count" "$pid" "$cmdline"
done
