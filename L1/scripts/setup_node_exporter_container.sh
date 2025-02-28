#!/bin/bash
set -eux

# Create container definition using quadlet
cat > /etc/containers/systemd/node_exporter.container << EOF
[Unit]
Description=node_exporter Container
After=network-online.target mnt-volume1.mount
Requires=mnt-volume1.mount

[Container]
Image=ghcr.io/heroalex/node_exporter:master
Network=host
PublishPort=9100:9100
Volume=/:/host:ro,rslave
Exec=--collector.systemd --collector.processes --path.rootfs=/host
Label=io.containers.autoupdate=registry

[Service]
Restart=always
TimeoutStartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chmod 644 /etc/containers/systemd/node_exporter.container

# Reload systemd and enable container
systemctl daemon-reload
systemctl start node_exporter
