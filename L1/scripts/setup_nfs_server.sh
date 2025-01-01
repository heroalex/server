#!/bin/bash
set -eux

mkdir -p /etc/systemd/system/nfs-server.service.d/

cat > /etc/systemd/system/nfs-server.service.d/mount-dependencies.conf << EOF
[Unit]
After=var-mnt-cam1.mount var-mnt-cam2.mount
Requires=var-mnt-cam1.mount var-mnt-cam2.mount

# Make sure rpcbind is started before NFS
After=rpcbind.service
Requires=rpcbind.service

[Service]
# Add a short delay to ensure mounts are fully accessible
ExecStartPre=/bin/sleep 5

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/exports << EOF
/var/mnt/cam1 192.168.0.111(rw,sync,no_subtree_check)
/var/mnt/cam2 192.168.0.112(rw,sync,no_subtree_check)
EOF

systemctl daemon-reload
systemctl enable nfs-server
systemctl start nfs-server
