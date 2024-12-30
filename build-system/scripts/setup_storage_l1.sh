#!/bin/bash
set -eux

groupadd storage_l1

mkdir -p /var/mnt/storage_l1
chgrp storage_l1 /var/mnt/storage_l1
chmod 775 /var/mnt/storage_l1

cat > /etc/storage_l1.creds <<  EOF
username=u324047-sub5
password=${STORAGE_L1}
EOF
chmod 0600 /etc/storage_l1.creds

cat > /etc/systemd/system/var-mnt-storage_l1.mount << EOF
[Unit]
Description=Storage L1 CIFS Share Mount
After=network-online.target
Wants=network-online.target

[Mount]
What=${STORAGE_L1_URL}
Where=/var/mnt/storage_l1
Type=cifs
Options=vers=3.1.1,gid=storage_l1,credentials=/etc/storage_l1.creds,file_mode=0660,dir_mode=0770,rw,_netdev
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/var-mnt-storage_l1.mount

systemctl daemon-reload
systemctl enable var-mnt-storage_l1.mount
systemctl start var-mnt-storage_l1.mount