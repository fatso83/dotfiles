#!/usr/bin/env bash
#
#  split-chain.sh  HOST  [PORT]  [OUTPUT_DIR]
#
#  Connects to HOST:PORT (default 443), fetches the full certificate chain
#  with openssl s_client, splits every certificate into its own PEM file
#  and names each file
#
#     <index>-<host>-<CN>.pem
#
#  Example:
#     ./split-chain.sh  www.vg.no
#       → 0-www.vg.no-vg.no.pem
#         1-www.vg.no-ZeroSSL_RSA_Domain_Secure_Site_CA.pem
#         2-www.vg.no-USERTrust_RSA_Certification_Authority.pem

set -euo pipefail

HOST=${1:-}
PORT=${2:-443}
OUT=${3:-.}

if [ -z "$HOST" ]; then
    echo "Usage: $0 HOST [PORT] [OUTPUT_DIR]" >&2
    exit 1
fi

mkdir -p "$OUT"

TMP=$(mktemp)
trap 'rm -f "$TMP" "$OUT"/tmp-cert-*.pem' EXIT INT TERM

##############################################################################
# 1. Grab the chain – no “Q” trick, just close stdin immediately.
##############################################################################
openssl s_client \
        -connect "${HOST}:${PORT}" \
        -servername "${HOST}" \
        -showcerts </dev/null 2>/dev/null >"$TMP"

##############################################################################
# 2. Split the PEM blocks with awk into numbered tmp files.
##############################################################################
awk -v dir="$OUT" '
/-----BEGIN CERTIFICATE-----/ {f=sprintf("%s/tmp-cert-%02d.pem",dir,n++); write=1}
write {print >> f}
/-----END CERTIFICATE-----/   {write=0; close(f)}
#END {print n > "/dev/stderr"}
' "$TMP"

COUNT=0
##############################################################################
# 3. For every tmp‑file: extract CN, sanitise, rename.
##############################################################################
for f in "$OUT"/tmp-cert-*.pem; do
    [ -e "$f" ] || continue          # (just in case glob is empty)

    CN=$(openssl x509 -in "$f" -noout -subject |
         sed -n 's/.*CN[ =]*//p' | head -1)

    # Fallback if CN was empty
    [ -n "$CN" ] || CN="unknown"

    # Make the CN file‑system safe
    CN=${CN//[^A-Za-z0-9_.-]/_}

    NEW=$(printf "%d-%s-%s.pem" "$COUNT" "$HOST" "$CN")
    mv -- "$f" "$OUT/$NEW"
    echo "Extracted certificate: $OUT/$NEW"
    COUNT=$((COUNT+1))
done

if [ "$OUT" = "" ]; then
    echo "Wrote $COUNT certificate file(s) to $OUT"
fi
