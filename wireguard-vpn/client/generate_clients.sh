#!/bin/sh
set -e
. ../.env

mkdir -p ../keys
touch ../ip_map.txt

assert_defined(){
    eval env_var_value='$'$1
    if [ -z "$env_var_value" ]; then
        echo "Missing value: \$$1"
        echo "Set value in .env"
        exit 2
    fi
}

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

assert_defined SERVER_PUBLIC_IP
assert_defined SERVER_WG_PORT
assert_defined SERVER_PUBLIC_KEY

while IFS= read -r client || [ -n "$client" ]; do
  [ -z "$client" ] && continue

  CLIENT_DIR="../keys/$client"
  mkdir -p "$CLIENT_DIR"

  if [ ! -f "$CLIENT_DIR/privatekey" ]; then
    echo "🔐 No private key found for '$client'. Generating one automatically."
    (
      umask 077
      wg genkey > "$CLIENT_DIR/privatekey"
    )
    cat "$CLIENT_DIR/privatekey" | wg pubkey > "$CLIENT_DIR/publickey"
  fi

  PRIVATE_KEY=$(cat "$CLIENT_DIR/privatekey")
  WG_IP=$(get_ip_for_client "$client")

  printf "\n\n💡 Select mode for $client:\n"
  echo "1) Full tunnel (route all traffic)"
  echo "2) Peer-to-peer only (route to server + subnet)"
  echo "3) Skip"
  printf "Mode [1/2/3]: " > /dev/tty
  read mode < /dev/tty

  if [ "$mode" = "3" ]; then
      continue
  fi

  if [ "$mode" = "2" ]; then
    printf "Enter subnet to allow (default 10.0.0.0/24): " > /dev/tty
    read extra_subnet < /dev/tty
    [ -z "$extra_subnet" ] && extra_subnet="10.0.0.0/24"
    allowed_ips="10.0.0.1/32, $extra_subnet"
    suffix="peer-to-peer"
  else
    allowed_ips="0.0.0.0/0, ::/0"
    suffix="full"
  fi

  CONFIG_FILE="$CLIENT_DIR/wg0-$suffix.conf"
  {
    echo "[Interface]"
    echo "Address = $WG_IP/24"
    echo "PrivateKey = $PRIVATE_KEY"
    # Use DNS from env or fallback to 1.1.1.1 (Cloudflare)
    DNS_SERVER="${CLIENT_DNS:-1.1.1.1}"
    echo "DNS = $DNS_SERVER"
    echo ""

    echo "[Peer]"
    echo "PublicKey = $SERVER_PUBLIC_KEY"
    echo "Endpoint = $SERVER_PUBLIC_IP:$SERVER_WG_PORT"
    echo "AllowedIPs = $allowed_ips"
    echo "PersistentKeepalive = 25"
  } > "$CONFIG_FILE"

  echo "✅ Config created: $CONFIG_FILE"

  if command -v qrencode >/dev/null 2>&1; then
    qrencode -o "$CLIENT_DIR/wg0-$suffix.png" < "$CONFIG_FILE"
    echo "📱 QR code saved to $CLIENT_DIR/wg0-$suffix.png"
  fi

  echo

done < ../clients.list

