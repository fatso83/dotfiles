#!/bin/sh
set -e
. ../.env

PEERS_CONFIG="peers.generated.conf"
> "$PEERS_CONFIG"

while IFS= read -r line || [ -n "$line" ]; do
  set -- $line
  client="$1"
  ip="$2"

  [ -z "$client" ] && continue
  [ "${client#\#}" != "$client" ] && continue

  if [ -z "$ip" ]; then
    echo "Missing IP for client '$client' in ../clients.list"
    echo "Expected format: <client> <ip>"
    exit 2
  fi

  PUBKEY=$(cat ../keys/"$client"/publickey 2>/dev/null || echo "MISSING_PUBLIC_KEY")
  if [ "$PUBKEY" = "MISSING_PUBLIC_KEY" ]; then
    echo "⚠️  Public key for $client not found, skipping"
    continue
  fi
  [ -n "$ip" ] && echo "[Peer]
PublicKey = $PUBKEY
AllowedIPs = $ip/32

" >> "$PEERS_CONFIG"
done < ../clients.list

echo "✅ Generated $PEERS_CONFIG"
