#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Create Samba configuration
echo "*** create Samba container configuration"
cat > /etc/containers/systemd/samba-share.container << EOF
[Unit]
Description=Samba Share Container
After=network-online.target media-cam1.mount media-cam2.mount
Wants=network-online.target
Requires=media-cam1.mount media-cam2.mount

[Container]
Image=docker.io/dperson/samba:latest
ContainerName=samba-share
Volume=/media/cam1:/share/cam1:Z
Volume=/media/cam2:/share/cam2:Z
Network=host
Environment=SHARE="cam1;/share/cam1;yes;no;yes;all;none;none"
Environment=SHARE2="cam2;/share/cam2;yes;no;yes;all;none;none"
Environment=WORKGROUP=WORKGROUP
Environment=USER="guest;guest"
Environment=RECYCLE=false
Environment=PERMISSIONS
#UserNS=keep-id

[Service]
Restart=no
TimeoutStartSec=900

[Install]
WantedBy=default.target
EOF

echo "*** start Samba container"
systemctl daemon-reload
systemctl start samba-share
