#!/bin/bash
set -eux

# Create container configuration directory
mkdir -p /mnt/volume1/omada/{data,logs}

# Create container definition using quadlet
cat > /etc/containers/systemd/omada.container << EOF
[Unit]
Description=Omada Container
After=network-online.target mnt-volume1.mount
Requires=mnt-volume1.mount

[Container]
Image=ghcr.io/heroalex/docker-omada-controller:master
Volume=/mnt/volume1/omada/data/:/opt/tplink/EAPController/data/
Volume=/mnt/volume1/omada/logs/:/opt/tplink/EAPController/logs/
StopTimeout=60
Network=host
Ulimit=nofile=4096:8192
Environment=MANAGE_HTTP_PORT=8088
Environment=MANAGE_HTTPS_PORT=8043
Environment=PGID=508
Environment=PORTAL_HTTP_PORT=8088
Environment=PORTAL_HTTPS_PORT=8843
Environment=PORT_ADOPT_V1=29812
Environment=PORT_APP_DISCOVERY=27001
Environment=PORT_DISCOVERY=29810
Environment=PORT_MANAGER_V1=29811
Environment=PORT_MANAGER_V2=29814
Environment=PORT_TRANSFER_V2=29815
Environment=PORT_RTTY=29816
Environment=PORT_UPGRADE_V1=29813
Environment=PUID=508
Environment=SHOW_SERVER_LOGS=true
Environment=SHOW_MONGODB_LOGS=false
#Environment=SSL_CERT_NAME=tls.crt
#Environment=SSL_KEY_NAME=tls.key
Environment=TZ=Etc/UTC
Label=io.containers.autoupdate=registry

[Service]
Restart=on-failure
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chmod 644 /etc/containers/systemd/omada.container

# Reload systemd and enable container
systemctl daemon-reload
systemctl start omada