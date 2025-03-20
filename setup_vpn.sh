#!/bin/bash

# Variables
WG_INTERFACE="wg0"
WG_DIR="/etc/wireguard"
WG_CONFIG="$WG_DIR/$WG_INTERFACE.conf"
SERVER_IP="10.0.0.1/24"
PORT="51820"

# Install necessary packages
echo "[+] Installing WireGuard and DHCP server..."
dnf install -y wireguard-tools dhcp-server

# Enable IP forwarding
echo "[+] Enabling IP forwarding..."
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-wireguard.conf
sysctl -p /etc/sysctl.d/99-wireguard.conf

# Create WireGuard directory
mkdir -p $WG_DIR
chmod 700 $WG_DIR

# Generate keys
echo "[+] Generating WireGuard keys..."
wg genkey | tee $WG_DIR/privatekey | wg pubkey > $WG_DIR/publickey
PRIVATE_KEY=$(cat $WG_DIR/privatekey)
PUBLIC_KEY=$(cat $WG_DIR/publickey)

# Configure WireGuard server
echo "[+] Creating WireGuard configuration..."
cat <<EOL > $WG_CONFIG
[Interface]
ListenPort = $PORT
PrivateKey = $PRIVATE_KEY

[Peer]
# Clients will be dynamically assigned via DHCP
PublicKey = OliQanmPXY7N+Pq69qYK3YjSMy1a8XscjuRS6pCMSkE=
Endpoint = 10.0.0.1:51820
AllowedIPs = 0.0.0.0/0  # Allows all traffic through the VPN
PersistentKeepalive = 25
EOL

# Set permissions
chmod 600 $WG_CONFIG

# Enable and start WireGuard
echo "[+] Starting WireGuard service..."
systemctl enable --now wg-quick@$WG_INTERFACE

# Configure DHCP for VPN clients
echo "[+] Configuring DHCP server..."
cat <<EOL > /etc/dhcp/dhcpd.conf
subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.100 10.0.0.200;
    option routers 10.0.0.2;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOL

# Start DHCP service
systemctl enable --now dhcpd

echo "[+] WireGuard VPN with DHCP setup complete!"

