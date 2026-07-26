#!/bin/sh
set -e
. ../.env

assert_defined(){
    eval env_var_value='$'$1
    if [ -z "$env_var_value" ]; then
        echo "Missing value: \$$1"
        echo "Set value in .env"
        exit 2
    fi
}

assert_defined SERVER_PUBLIC_IP
assert_defined SERVER_WG_PORT
assert_defined SERVER_PUBLIC_KEY
assert_defined SERVER_PRIVATE_KEY
assert_defined SERVER_WG_IP
assert_defined WG_SUBNET
assert_defined EXT_IF

export SERVER_PUBLIC_IP
export SERVER_WG_PORT
export SERVER_PUBLIC_KEY
export SERVER_PRIVATE_KEY
export SERVER_WG_IP
export WG_SUBNET
export EXT_IF

# Create WireGuard config from template + peers
echo "Generating wg0.conf from template and peers..."
cd "$(dirname "$0")"
./generate_peers.sh
envsubst < wg0.conf.template > wg0.header.tmp
cat wg0.header.tmp peers.generated.conf > /etc/wireguard/wg0.conf
rm wg0.header.tmp
rm peers.generated.conf
