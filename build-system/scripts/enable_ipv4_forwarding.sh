#!/bin/bash
set -eux

cat > /etc/sysctl.d/45-enable_ipv4_forwarding.conf << EOF
net.ipv4.ip_forward=1
EOF

chmod 0644 /etc/sysctl.d/45-enable_ipv4_forwarding.conf

sysctl -p /etc/sysctl.d/45-enable_ipv4_forwarding.conf