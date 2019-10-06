#!/bin/bash
#@author   Carl-Erik Kopseng
#@date     2008-03-27
#@version  0.2

#Backup-server that usually is the destination
#If you specify DEST, this won't be needed, as this is just used as default
SERVER=my_backup_server
PORT=22     #standard SSH port - change if different

#Variables than can be specified on the commandline,
# or simply changed here permanently
#the value after the ":-" is the default, when not specified otherwise
SRC=${SRC:-$HOME}
DEST=${DEST:-$SERVER:"~"}

# Files that specify what the sync job should include/exclude
EXCLUDE_FILE=${EXCLUDE_FILE:-~/.sync_exclude}
INCLUDE_FILE=${INCLUDE_FILE:-~/.sync_include}

KBPS=${KBPS:-40}

### No need to change anything below this point ###

function usage ()
{
    echo "Usage: $0 [--doit] [--delete]"
    echo -e "\nOptions:"
    echo -e "  --doit\tPerform the syncronization"
    echo -e "  --delete\tDelete server-side files not present locally\n"
    echo "Note: "--delete" requires "--doit""
    echo "Override default values on commandline like this:"\
     "[PARAM1=XXX [PARAM2=YYY [...]]] $0"
    echo -e "\nExamples"
    echo -e "\tSRC=/dir/to/backup DEST="backupserver.com:/backupdir" INCLUDE_FILE=files.txt $0"
    echo -e "\tINCLUDE_FILE=files.txt $0 --doit"
    echo -e "\nTo learn more, open the script with your favorite text editor"
    exit 1
}

function missing_file()
{
    echo "Need an include file with files and directories to include" \
        > /dev/stderr
    echo "Please make a file $INCLUDE_FILE or set the variable"\
        "\$INCLUDE_FILE" > /dev/stderr
    exit 1
}

function syncronize ()
{
    if [ -e "$EXCLUDE_FILE" ]; then
            EXCLUDE="--exclude-from $EXCLUDE_FILE"
    fi

    if [ -e "$INCLUDE_FILE" ]; then
            INCLUDE="--files-from $INCLUDE_FILE"
    else
        missing_file
    fi

#From the rsync manual
#      -K, --keep-dirlinks
#              This  option  causes  the  receiving  side  to treat a symlink to a directory as
#              though it were a real directory, but only if it matches a  real  directory  from
#              the  sender.   Without  this option, the receiver’s symlink would be deleted and
#              replaced with a real directory.

    rsync --rsh="ssh -p $PORT" --perms --times --group --progress \
    --recursive  --hard-links --keep-dirlinks --links --bwlimit \
    $KBPS  $DRY_RUN $DELETE $INCLUDE $EXCLUDE  "$SRC" "$DEST"
}

case "$1" in
    -h|--help)
        usage;
        ;;
    --doit)
        #No dry run, so cancelling effect
        DRY_RUN=""
        echo "Performing update syncronization."

        #Do we want to delete files?
        if [ x"$2" != x"--delete" ] ; then
            echo -n "Deletes not performed "
                echo "(specify "--delete" as second argument)"
        else
            DELETE="--delete-after"
            echo "WILL DELETE FILES ON SERVERSIDE!"
        fi

        #Starting actions
        echo "Abort within 5 seconds with Ctrl-C ..."
        sleep 5 && syncronize
        ;;
    --delete)
        DRY_RUN="--dry-run"
        #Performing DRY-RUN, BUT with delete
        DELETE="--delete-after"
        echo "Performing dry-run WITH delete"
        syncronize
        exit 1
        ;;
    *)
        DRY_RUN="--dry-run"
        echo "Performing dry-run ("--doit" not specified)"
        sleep 1;
        syncronize
        exit 1
esac