SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASH_D="$SCRIPT_DIR/bash_completion.d"
cd $SCRIPT_DIR
ROOT="$SCRIPT_DIR/.."

shopt -s expand_aliases     # to use alias definitions
source "$ROOT"/shared.lib

echo "Updating BASH completion scripts for Git ..."
curl -s -o "$BASH_D/git" "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"

if which npm > /dev/null; then
    echo "Updating BASH completion scripts for NPM ..."
    npm completion > "$BASH_D/npm"
fi
