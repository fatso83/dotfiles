# Wireguard setup for full VPN and or peer-to-peer traffic

## Up and running on the VPN Gateway

- Populate .env by `./server/gen-env.sh`
- Try running `./server/setup.sh` and add what is missing to `.env`, like the public IP
- Add some clients in `clients.list`. Run `client/generate-clients.sh`
- Run `./server/setup.sh` for one-time setup
- Export the configs (use `imcat wg0-full.png` to get a QR code for the Android/iPhone apps )

Now try the config and see that it works.

## Persistent config:

### 1. Wireguard setup and enabling IP forwarding persistently
See above, the `server/setup.sh` does this

### 2. Enable and start WireGuard on boot

```
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

### 3 Make NAT persistent

```
sudo apt install iptables-persistent
```

To save any later changes, just do:
```
sudo netfilter-persistent save
```

## Up and runnong on mobile
Just scan the generated QR code

## Up and running on Ubuntu
Almost same steps as for the gateway, except we
don't need to setup forwarding and iptables rules.

## Various keys

🔐 SERVER_PRIVATE_KEY
This is the private key used by your WireGuard server.

🔐 SERVER_PUBLIC_KEY
This is derived from the private key above.

🌐 SERVER_PUBLIC_IP
This is your server’s public-facing IP address or DNS hostname, which clients will connect to.

Examples:
```
SERVER_PUBLIC_IP=203.0.113.42             # static IP
SERVER_PUBLIC_IP=vpn.example.com          # DNS name (useful if IP changes)
```
If you're hosting on a VPS, it's just the public IP. If you're behind NAT, use dynamic DNS.


🔢 SERVER_WG_PORT
This is the UDP port WireGuard listens on.

Defaults to:
```
SERVER_WG_PORT=51820
```
You can change it if needed, but remember to open it in your firewall and NAT (if applicable).

