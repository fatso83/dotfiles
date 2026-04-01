SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPLETIONS="$SCRIPT_DIR/bash_completion.d"
cd $SCRIPT_DIR
ROOT="$SCRIPT_DIR/.."

shopt -s expand_aliases     # to use alias definitions
source "$ROOT"/shared.lib

echo "Updating BASH completion scripts for Git ..."
curl -s -o "$COMPLETIONS/git" "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"

if which npm > /dev/null; then
    echo "Updating BASH completion scripts for NPM ..."
    npm completion > "$COMPLETIONS/npm"
fi

if which bun > /dev/null; then
    bun completions
    # Patch the bun completion script because of a bug in bun where re_comp_word_script is undefined
    # See https://github.com/oven-sh/bun/issues/24847
    # Note that on macOS, sed -i requires an empty string for the extension: sed -i ''
    sed -i '' 's/re_prev_script="(^| )${prev}($| )";/re_prev_script="(^| )${prev}($| )"; local re_comp_word_script=".*";/' "$COMPLETIONS/bun.completion.bash"
fi
