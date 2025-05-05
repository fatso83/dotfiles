#!/usr/bin/env bash
#
#  verify-chain.sh  leaf.pem  [intermediate1.pem …]  [root.pem]
#
#  • Takes the PEM files you give it (order doesn’t matter apart from the
#    leaf being first).                ──────────────────────────────────
#  • Verifies that they form one valid certificate path that ends in a
#    root CA already present in the machine’s trust store.

set -eu

die() { echo "ERROR: $*" >&2; exit 1; }

prompt_to_install(){
    local yesno
    echo
    read -p "Do you want me to install the intermediary certificate as a trust anchor? (yes/NO)" yesno

    if ( shopt -s nocasematch; 
        [[ ! "${yesno}" =~ ^y(es)?$ ]]
        ); then 
        return 1
    fi

    install_certificate "$1"
    echo "Certificate installed. Retry verification to see that it works."
}

install_certificate(){
    local DOWNLOADED_CERT
    local CONVERTED
    DOWNLOADED_CERT="$1"
    CONVERTED="$DOWNLOADED_CERT"

    # Ensure it ends in .crt, as it is required for update-ca-certificates
    if ! (echo $DOWNLOADED_CERT |  grep -q '\.crt$'); then
        CONVERTED="$DOWNLOADED_CERT.crt"
    fi
    NEW_LOCATION="/usr/local/share/ca-certificates/$CONVERTED"

    printf "\nInstalling the intermediate certificate in your trust store:\n"
    # Ensure we install a PEM encoded certificate
    openssl x509 -in "$DOWNLOADED_CERT" | sudo tee "$NEW_LOCATION" > /dev/null
    sudo update-ca-certificates
}

decode(){
    python3 -c "import sys, urllib.parse as p; print(p.unquote_plus(sys.argv[1]))" "$1"
}

filename_of(){
    url="$1"
    # Use curl to fetch headers and extract the filename from the Content-Disposition header
    filename=$(curl -sI "$url" | grep -i "Content-Disposition" | sed -n 's/.*filename="\([^"]*\)".*/\1/p')

    # If the Content-Disposition header is not present, use the last part of the URL
    if [ -z "$filename" ]; then
        filename=$(basename "$url")
    fi

    decode "$filename"
}

[ $# -ge 1 ] || die "usage: $0 leaf.pem [intermediate.pem …] [root.pem]"

##############################################################################
# 1. split the argument list
##############################################################################
leaf=$1; shift
intermediates=""          # will become a space‑separated list
root=""

if [ $# -gt 0 ]; then
    last=$(
      # print the last argument
      printf '%s\n' "$*" | awk 'END{print}'
    )

    # self‑signed?  (Issuer == Subject)
    if [ "$(openssl x509 -in "$last" -noout -subject)" = \
         "$(openssl x509 -in "$last" -noout -issuer)" ]; then
        root=$last
        # everything before it are intermediates
        intermediates=$(printf '%s\n' "$*" | sed '$d')
    else
        intermediates=$*
    fi
fi

##############################################################################
# 2. build an “‑untrusted” bundle for openssl verify
##############################################################################
tmp_untrusted=""
if [ -n "$intermediates" ]; then
    tmp_untrusted=$(mktemp)
    trap 'rm -f "$tmp_untrusted"' EXIT INT TERM
    cat $intermediates >"$tmp_untrusted"
    untrusted_opt="-untrusted $tmp_untrusted"
else
    untrusted_opt=""
fi

##############################################################################
# 3. verify the chain against the system CA store
##############################################################################
echo "• Verifying chain with openssl …"
if ! /usr/bin/openssl verify -CApath /etc/ssl/certs \
                        $untrusted_opt \
                        "$leaf" ; then
    intermediate_url=$(openssl x509 -in "$leaf" -noout -text \
        | grep -A3 'Authority Information Access:' | grep 'CA Issuers - URI' | sed 's/.*http/http/')

    if [ -z $intermediate_url ]; then
        die "chain validation FAILED"
    fi

    # No longer exit at non-ok statuses: we are already planning on failing, so make life easier!
    set +e
    # Make the intermediate file url file‑system safe
    filename="$(filename_of $intermediate_url)"

    printf '\nLeaf verification failed :( \n... but found CA Issuer URI in the leaf \n... attempting download and verification using %s\n' "$intermediate_url"

    # we skip security when it comes to getting hold of the intermediate certificate
    curl -s -k -L -o "$filename" $intermediate_url

    if openssl verify "$filename" > /dev/null; then
        echo "Intermediate verified. As we could verify the intermediate using existing trust anchors, it should originally have been added to the chain."
        if openssl verify -untrusted "$filename" "$leaf" > /dev/null; then
            echo "Leaf certificate verified using the intermediate certificate!"
            echo "This means it should be safe to install this in the trust store, although the 'correct' thing to do would be to fix the deployed certificate by including it in the chain"
            prompt_to_install "$filename"
            exit 1
        fi
    else
        echo "Intermediate failed verification as well"
    fi

    die "chain validation FAILED."
fi

echo "  ✔  chain is valid and ends in a trusted root"

##############################################################################
# 4. if caller supplied a root, be sure that exact cert *is* trusted
##############################################################################
if [ -n "$root" ]; then
    hash=$(openssl x509 -in "$root" -noout -hash)
    if [ -e "/etc/ssl/certs/$hash.0" ]; then
        link=$(readlink "/etc/ssl/certs/$hash.0" || true)
        echo "  ✔ root ‘$root’ is present in trust store (hash $hash → $link)"
    else
        die "root ‘$root’ is NOT present in /etc/ssl/certs – not trusted"
    fi
fi

echo "✓ Everything checks out."

