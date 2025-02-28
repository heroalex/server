#!/bin/bash
set -e

echo "Creating Grafana config..."
source /root/.secrets

set -x

# Create container configuration directory
mkdir -p /mnt/volume1/grafana/provisioning/datasources

cat > /mnt/volume1/grafana/provisioning/datasources/prometheus.yaml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: false
EOF

# Create container definition using quadlet
cat > /etc/containers/systemd/grafana.container << EOF
[Unit]
Description=Prometheus Container
After=network-online.target prometheus.service
Requires=prometheus.service

[Container]
Image=ghcr.io/heroalex/grafana:main
PublishPort=3000:3000
Network=host
Volume=/mnt/volume1/grafana:/var/lib/grafana
Environment=GF_SECURITY_ALLOW_EMBEDDING=false
Environment=GF_SECURITY_DISABLE_GRAVATAR=true
Environment=GF_USERS_ALLOW_SIGN_UP=false
Environment=GF_SERVER_ROOT_URL=https://${GRAFANA_DOMAIN_1}
Label=io.containers.autoupdate=registry

[Service]
Restart=always
TimeoutStartSec=30
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chmod 644 /mnt/volume1/grafana/provisioning/datasources/prometheus.yaml
chmod 644 /etc/containers/systemd/grafana.container
chown -R 472:472 /mnt/volume1/grafana

# Reload systemd and enable container
systemctl daemon-reload
systemctl start grafana