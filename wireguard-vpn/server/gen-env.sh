#!/bin/sh
set -e

ENV_FILE="../.env"

echo "🔐 Generating WireGuard server key pair..."
mkdir -p ../keys/server
umask 077
wg genkey > ../keys/server/privatekey
cat ../keys/server/privatekey | wg pubkey > ../keys/server/publickey

SERVER_PRIVATE_KEY=$(cat ../keys/server/privatekey)
SERVER_PUBLIC_KEY=$(cat ../keys/server/publickey)

echo "🌐 Enter your server's public IP or DNS name:"
read SERVER_PUBLIC_IP

DEFAULT_PORT=51820
printf "🔢 Enter WireGuard port [default: %s]: " "$DEFAULT_PORT"
read SERVER_WG_PORT
[ -z "$SERVER_WG_PORT" ] && SERVER_WG_PORT=$DEFAULT_PORT

SERVER_WG_IP="10.0.0.1"
WG_SUBNET="10.0.0.0/24"

echo "✅ Writing new .env to $ENV_FILE"
cat > "$ENV_FILE" <<EOF
SERVER_PUBLIC_IP=$SERVER_PUBLIC_IP
SERVER_WG_PORT=$SERVER_WG_PORT
SERVER_PUBLIC_KEY=$SERVER_PUBLIC_KEY
SERVER_PRIVATE_KEY=$SERVER_PRIVATE_KEY
SERVER_WG_IP=$SERVER_WG_IP
WG_SUBNET=$WG_SUBNET
EOF

echo "🎉 Done. Server keys saved in $PWD/../keys/server/, and .env is ready."

