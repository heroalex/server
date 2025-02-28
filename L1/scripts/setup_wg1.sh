#!/bin/bash
set -e

echo "Creating wg1 config..."
source /root/.secrets

set -x

cat > /etc/wireguard/wg1.conf << EOF
[Interface]
Address = 10.11.11.1/24
ListenPort = 13232
PrivateKey = $WG1_PK

[Peer]
PublicKey = $WG1_PEER_1
AllowedIPs = 10.11.11.2/32

[Peer]
PublicKey = $WG1_PEER_2
AllowedIPs = 10.11.11.3/32

[Peer]
PublicKey = $WG1_PEER_3
AllowedIPs = 10.11.11.4/32

[Peer]
PublicKey = $WG1_PEER_4
AllowedIPs = 10.11.11.11/32

[Peer]
PublicKey = $WG1_PEER_5
AllowedIPs = 10.11.11.12/32

[Peer]
PublicKey = $WG1_PEER_6
AllowedIPs = 10.11.11.13/32
EOF

chmod 0600 /etc/wireguard/wg1.conf

systemctl daemon-reload
systemctl enable wg-quick@wg1
systemctl start wg-quick@wg1
