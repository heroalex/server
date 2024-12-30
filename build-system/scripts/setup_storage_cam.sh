#!/bin/bash
set -eux

groupadd storage_cam

mkdir -p /var/mnt/storage_cam
chgrp storage_cam /var/mnt/storage_cam
chmod 775 /var/mnt/storage_cam

cat > /etc/storage_cam.creds <<  EOF
username=u324047-sub4
password=${STORAGE_CAM}
EOF
chmod 0600 /etc/storage_cam.creds

cat > /etc/systemd/system/var-mnt-storage_cam.mount << EOF
[Unit]
Description=Storage Cam CIFS Share Mount
After=network-online.target
Wants=network-online.target

[Mount]
What=${STORAGE_CAM_URL}
Where=/var/mnt/storage_cam
Type=cifs
Options=vers=3.1.1,gid=storage_cam,credentials=/etc/storage_cam.creds,file_mode=0660,dir_mode=0770,rw,_netdev
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/var-mnt-storage_cam.mount

systemctl daemon-reload
systemctl enable var-mnt-storage_cam.mount
systemctl start var-mnt-storage_cam.mount