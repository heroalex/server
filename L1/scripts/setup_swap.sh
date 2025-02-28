#!/bin/bash
set -eux

cat > /etc/sysctl.d/50-swap.conf << EOF
vm.swappiness = 10
vm.vfs_cache_pressure=50
vm.overcommit_memory = 1
EOF

chmod 0644 /etc/sysctl.d/50-swap.conf

sysctl -p /etc/sysctl.d/50-swap.conf

dd if=/dev/zero of=/var/swapfile bs=1M count=4096
chmod 600 /var/swapfile
mkswap /var/swapfile

cat > /etc/systemd/system/var-swapfile.swap << EOF
[Unit]
Description=Swap file in /var

[Swap]
What=/var/swapfile

[Install]
WantedBy=multi-user.target
EOF

# Enable and start swap
#systemctl enable var-swapfile.swap
#systemctl start var-swapfile.swap
# swapon: /var/swapfile: swapon failed: Read-only file system