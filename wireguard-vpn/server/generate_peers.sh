#!/bin/sh
set -e
. ../.env

PEERS_CONFIG="peers.generated.conf"
> "$PEERS_CONFIG"

while read client _ip || [ -n "$client" ]; do
  [ -z "$client" ] && continue
  PUBKEY=$(cat ../keys/"$client"/publickey 2>/dev/null || echo "MISSING_PUBLIC_KEY")
  if [ "$PUBKEY" = "MISSING_PUBLIC_KEY" ]; then
    echo "⚠️  Public key for $client not found, skipping"
    continue
  fi
  ip=$(grep "^$client " ../ip_map.txt | awk '{print $2}')
  [ -n "$ip" ] && echo "[Peer]
PublicKey = $PUBKEY
AllowedIPs = $ip/32

" >> "$PEERS_CONFIG"
done < ../clients.list

echo "✅ Generated $PEERS_CONFIG"
