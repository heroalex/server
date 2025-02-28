#!/bin/bash
set -eux

# Create container configuration directory
mkdir -p /etc/prometheus
mkdir -p /mnt/volume1/prometheus

cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Create container definition using quadlet
cat > /etc/containers/systemd/prometheus.container << EOF
[Unit]
Description=Prometheus Container
After=network-online.target mnt-volume1.mount node_exporter.service
Requires=node_exporter.service mnt-volume1.mount

[Container]
Image=ghcr.io/heroalex/prometheus:main
Volume=/etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
Volume=/mnt/volume1/prometheus:/prometheus
Environment=TZ=UTC
Network=host
PublishPort=9090:9090
User=65534:65534
Label=io.containers.autoupdate=registry

[Service]
Restart=always
TimeoutStartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chmod 644 /etc/prometheus/prometheus.yml
chmod 644 /etc/containers/systemd/prometheus.container
chown -R 65534:65534 /mnt/volume1/prometheus

# Reload systemd and enable container
systemctl daemon-reload
systemctl start prometheus