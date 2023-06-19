SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BASH_D="$SCRIPT_DIR/bash_completion.d"

echo "Updating BASH completion scripts for Git ..."
curl -s -o "$BASH_D/git" "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"

echo "Updating BASH completion scripts for NPM ..."
npm completion > "$BASH_D/npm"
