#!/bin/bash
set -eux

# Create container configuration directory
mkdir -p /etc/containers/systemd
chown root:root /etc/containers/systemd

# Create Samba configuration
cat > /etc/samba/smb.conf << EOF
[global]
    workgroup = WORKGROUP
    server string = L1 Storage
    security = user
    log file = /var/log/samba/log.%m
    max log size = 50
    map to guest = never

[alex]
    path = /shares/alex
    valid users = storage_alex
    writable = yes
    browseable = yes

[anika]
    path = /shares/anika
    valid users = storage_anika
    writable = yes
    browseable = yes
EOF

# Create container definition using quadlet
cat > /etc/containers/systemd/samba.container << EOF
[Unit]
Description=Samba Container
After=network-online.target var-mnt-storage_l1.mount wg-quick@wg0.service mnt-volume1.mount
Requires=var-mnt-storage_l1.mount wg-quick@wg0.service mnt-volume1.mount

[Container]
Image=ghcr.io/heroalex/samba:master
Network=host
Volume=/etc/samba/smb.conf:/etc/samba/smb.conf
Volume=/var/mnt/storage_l1:/shares
PublishPort=0.0.0.0::139
PublishPort=0.0.0.0::445
Environment=USER="storage_alex;password"
Environment=USER2="storage_anika;password"
Label=io.containers.autoupdate=registry

[Service]
Restart=always
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chmod 644 /etc/samba/smb.conf
chmod 644 /etc/containers/systemd/samba.container

# Reload systemd and enable container
systemctl daemon-reload
systemctl start samba