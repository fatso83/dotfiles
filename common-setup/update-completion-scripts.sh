SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Updating BASH completion scripts for Git ..."
curl -s -o "$SCRIPT_DIR/git" "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"

echo "Updating BASH completion scripts for NPM ..."
npm completion > "$SCRIPT_DIR/npm"
