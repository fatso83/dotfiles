#!/bin/bash
set -e
[[ -n $DEBUG ]] && set -x
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SCRIPT_DIR/../.."
pushd "$SCRIPT_DIR" > /dev/null
source "$ROOT/shared.lib"
shopt -s expand_aliases
source ../../common-setup/bash.d/aliases_functions

# Homebrew CLI. mise installs the formulae itself (see mise.toml), but `brew` is still
# wanted for brew services, brew --prefix, brew postinstall and formulae mise cannot build.
if [[ ! -x /opt/homebrew/bin/brew ]]; then
    h2 "Installing Homebrew\n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"   # the installer does not change the running shell's PATH

# Everything declarative: packages, login shell, Touch ID, defaults, launchd agent, tools.
# Idempotent; re-run after editing mise.toml. sudo prompts once for /etc/pam.d/sudo_local
# (MISE_YES only answers mise's own confirmations). One failing package must not stop the rest.
h2 "Applying the mac-work mise module (mise bootstrap)"
use_mise_shims
MISE_YES=1 "$MISE_BIN" bootstrap || warn "mise bootstrap reported failures. Fix and re-run ./setup.sh (continuing)"

# Third-party tap that mise would have to build from source; real brew pours the tap's bottle
brew install shivammathur/php/php@7.4 < /dev/null || true

# ---- Things mise has no section for ----
source ../_shared/install-utils.inc
install_language_packages          # Python libraries (pynvim, keyring ...)

h2 "Registering the mise JDK for GUI apps (IntelliJ, /usr/libexec/java_home)"
# Re-linked on every run: `mise where java` is version-specific and the link does not follow upgrades
mise_java_home="$("$MISE_BIN" where java 2>/dev/null || true)"
if [[ -n "$mise_java_home" && -d "$mise_java_home/Contents" ]]; then
    sudo mkdir -p /Library/Java/JavaVirtualMachines/mise-java.jdk
    sudo ln -sfn "$mise_java_home/Contents" /Library/Java/JavaVirtualMachines/mise-java.jdk/Contents
fi

./chezmoi-mac.sh

h2 "Use 1Password for SSH"
add_1password_identity_agent_ssh_config

./pgp-keychain.sh
popd > /dev/null
