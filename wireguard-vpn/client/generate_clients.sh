#!/bin/sh
set -e
. ../.env

mkdir -p ../keys
touch ../ip_map.txt

get_ip_for_client() {
  client="$1"
  ip=$(grep "^$client " ../ip_map.txt | awk '{print $2}')
  if [ -n "$ip" ]; then
    echo "$ip"
  else
    used_ips=$(awk '{print $2}' ../ip_map.txt)
    next=2
    while :; do
      candidate="10.0.0.$next"
      echo "$used_ips" | grep -q "$candidate" || break
      next=$((next + 1))
    done
    echo "$client $candidate" >> ../ip_map.txt
    echo "$candidate"
  fi
}

i=0
while read client || [ -n "$client" ]; do
  [ -z "$client" ] && continue

  CLIENT_DIR="../keys/$client"
  mkdir -p "$CLIENT_DIR"

  if [ ! -f "$CLIENT_DIR/privatekey" ]; then
    echo "🔐 No private key found for '$client'. Generating one automatically."
    wg genkey > "$CLIENT_DIR/privatekey"
    cat "$CLIENT_DIR/privatekey" | wg pubkey > "$CLIENT_DIR/publickey"
  fi

  PRIVATE_KEY=$(cat "$CLIENT_DIR/privatekey")
  WG_IP=$(get_ip_for_client "$client")

  echo "💡 Select mode for $client:"
  echo "1) Full tunnel (route all traffic)"
  echo "2) Peer-to-peer only (route to server + selected peers)"
  printf "Mode [1/2]: "
  read mode

  if [ "$mode" = "2" ]; then
    printf "Enter peer IPs (comma-separated, e.g. 10.0.0.3,10.0.0.4): "
    read extra_peers
    allowed_ips="10.0.0.1/32"
    IFS=','; for peer in $extra_peers; do
      peer_trim=$(echo "$peer" | tr -d ' ')
      allowed_ips="$allowed_ips, $peer_trim/32"
    done
  else
    allowed_ips="0.0.0.0/0, ::/0"
  fi

  CONFIG_FILE="$CLIENT_DIR/wg0.conf"
  {
    echo "[Interface]"
    echo "Address = $WG_IP/24"
    echo "PrivateKey = $PRIVATE_KEY"
    echo ""
    echo "[Peer]"
    echo "PublicKey = $SERVER_PUBLIC_KEY"
    echo "Endpoint = $SERVER_PUBLIC_IP:$SERVER_WG_PORT"
    echo "AllowedIPs = $allowed_ips"
    echo "PersistentKeepalive = 25"
  } > "$CONFIG_FILE"

  if command -v qrencode >/dev/null 2>&1; then
    qrencode -o "$CLIENT_DIR/wg0.png" < "$CONFIG_FILE"
    echo "📱 QR code saved to $CLIENT_DIR/wg0.png"
  fi

  echo "✅ Config created: $CONFIG_FILE"
done < ../clients.list
