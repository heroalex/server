#!/bin/bash
set -eux

cd /root
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
chown root:root /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.processes \
    --web.listen-address=127.0.0.1:9100

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /etc/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
