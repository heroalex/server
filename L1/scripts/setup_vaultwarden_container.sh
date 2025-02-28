#!/bin/bash
set -eux

# Create container configuration directory
mkdir -p /mnt/volume1/vaultwarden

# Create container definition using quadlet
cat > /etc/containers/systemd/vaultwarden.container << EOF
[Unit]
Description=Vaultwarden Container
After=network-online.target mnt-volume1.mount
Requires=mnt-volume1.mount

[Container]
Image=ghcr.io/heroalex/vaultwarden:main
Volume=/mnt/volume1/vaultwarden/:/data/
PublishPort=8880:80
Environment=SIGNUPS_ALLOWED=false
Environment=ADMIN_TOKEN=alex
#Environment=DOMAIN="https://microos-local"
Label=io.containers.autoupdate=registry

[Service]
Restart=on-failure
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chmod 644 /etc/containers/systemd/vaultwarden.container

# Reload systemd and enable container
systemctl daemon-reload
systemctl start vaultwarden