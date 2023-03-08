SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

curl -s -o "$SCRIPT_DIR/git" "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"

npm completion > "$SCRIPT_DIR/npm"
