#!/usr/bin/env bash
set -euo pipefail

PRIVATEKEY_PATH="${PRIVATEKEY_PATH:-$HOME/Downloads/privatekey.asc}"
# Mestergruppen OpenPGP nøkkel
GPG_KEY_ID="${GPG_KEY_ID:-A9ED76646B3BCBCFA232F26BACFC4328FBE5C480}"

have_gpg_key() {
    gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -q "$GPG_KEY_ID"
}

prompt_for_private_key() {
    echo "GPG key $GPG_KEY_ID not found."
    echo "Open 1Password, export the private key, and save it to:"
    echo "  $PRIVATEKEY_PATH"
    echo "Press Enter when the file is in place (Ctrl+C to abort)."
    read -r
}

# Check and import key if missing
if ! have_gpg_key; then
    while [ ! -f "$PRIVATEKEY_PATH" ]; do
        prompt_for_private_key
    done
    gpg --import "$PRIVATEKEY_PATH"

    mkdir -p ~/.gnupg
    cat > ~/.gnupg/gpg-agent.conf <<'EOF'
pinentry-program /opt/homebrew/bin/pinentry-mac
default-cache-ttl 3600
max-cache-ttl 86400
EOF

    printf "%s:6:\n" "$GPG_KEY_ID" | gpg --import-ownertrust

    gpgconf --kill gpg-agent

    echo 'Next time you sign, the pinentry UI will offer “Save in Keychain” and macOS Keychain will remember the passphrase.'
else
    echo "Nothing to do! Key has already been imported"
fi

# ❯ ./per-host-config/mac-work/pgp-keychain.sh
# gpg: key ACFC4328FBE5C480: public key "Carl-Erik Kopseng (MesterGruppen AS) <carl.erik.kopseng@mestergruppen.no>" imported
# gpg: key ACFC4328FBE5C480: secret key imported
# gpg: Total number processed: 1
# gpg:               imported: 1
# gpg:       secret keys read: 1
# gpg:   secret keys imported: 1
# gpg: inserting ownertrust of 6
# Next time you sign, the pinentry UI will offer “Save in Keychain” and macOS Keychain will remember the passphrase.

# vi: ft=bash
