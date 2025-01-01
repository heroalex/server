#!/bin/bash
set -eux

# Create container configuration directory
mkdir -p /var/lib/grafana/provisioning/datasources

cat > /var/lib/grafana/provisioning/datasources/prometheus.yaml << 'EOF'
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
After=network-online.target

[Container]
Image=docker.io/grafana/grafana:latest
PublishPort=3000:3000
Network=host
Volume=/var/lib/grafana:/var/lib/grafana:Z
Environment=GF_SECURITY_ALLOW_EMBEDDING=false
Environment=GF_SECURITY_DISABLE_GRAVATAR=true
Environment=GF_USERS_ALLOW_SIGN_UP=false
Label=io.containers.autoupdate=registry

[Service]
Restart=always
TimeoutStartSec=30
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chmod 644 /var/lib/grafana/provisioning/datasources/prometheus.yaml
chmod 644 /etc/containers/systemd/grafana.container
chown -R 472:472 /var/lib/grafana

# Reload systemd and enable container
systemctl daemon-reload
systemctl start grafana