#!/bin/bash
set -e

echo "Creating wg0 config..."
source /root/.secrets

set -x

cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = ${WG0_PK}
ListenPort = 13231
Address = ${WG0_IP_PREFIX}.1/24

[Peer]
PublicKey = ${WG0_PEER_1}
AllowedIPs = ${WG0_IP_PREFIX}.90/32

[Peer]
PublicKey = ${WG0_PEER_2}
AllowedIPs = ${WG0_IP_PREFIX}.10/32,192.168.0.0/16

[Peer]
PublicKey = ${WG0_PEER_3}
AllowedIPs = ${WG0_IP_PREFIX}.92/32
EOF

chmod 0600 /etc/wireguard/wg0.conf

mkdir /etc/systemd/system/wg-quick@.service.d
cat > /etc/systemd/system/wg-quick@.service.d/override.conf << EOF
[Unit]
Before=sshd.service

[Service]
Type=oneshot
RemainAfterExit=yes
EOF

chmod 0644 /etc/systemd/system/wg-quick@.service.d/override.conf

systemctl daemon-reload
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
