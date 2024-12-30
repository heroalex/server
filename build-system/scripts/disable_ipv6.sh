#!/bin/bash
set -eux

cat > /etc/sysctl.d/40-disable-ipv6.conf << EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF

chmod 0644 /etc/sysctl.d/40-disable-ipv6.conf

sysctl -p /etc/sysctl.d/40-disable-ipv6.conf
echo "blacklist ipv6" > /etc/modprobe.d/disable-ipv6.conf