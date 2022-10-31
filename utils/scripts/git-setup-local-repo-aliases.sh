#!/bin/bash
# Useful git aliases that can be included as part of some setup
# Just customize the variables below and run the script to 
# add these aliases to your local repo

# some of these git aliases rely on embedding bash functions
# which explains the use of these one-off functions like `_f`

#split up over multiple lines for easier reading/editing
_f() 
{
    # based on the root of the repo
    local CSS_DIR="Web/Static/styles"
    local RE_IGNORE_CSS_FILES='_graphics-generated.scss|framework'

    if [[ x$1 = x ]]; then 
        printf "No class name received"
        exit 1 
    fi

    git ls-tree -r --full-tree --name-only HEAD "$CSS_DIR" \
    | egrep -v "$RE_IGNORE_CSS_FILES" \
    | xargs grep --color -H "$1" 
}
# get the stringified source
_source=$(declare -f _f);

git config alias.css-class-usage "! $_source; _f"
