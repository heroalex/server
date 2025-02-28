#!/bin/bash
set -eux

cat > /etc/containers/storage.conf << EOF
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/mnt/volume1/containers/storage"
EOF

chmod 0644 /etc/containers/storage.conf