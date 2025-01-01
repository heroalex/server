#!/bin/bash
set -eux

mkdir -p /var/mnt/storage_l1
chmod 770 /var/mnt/storage_l1

cat > /etc/storage_l1.creds <<  EOF
username=${STORAGE_L1_U}
password=${STORAGE_L1_PW}
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
Options=vers=3.1.1,credentials=/etc/storage_l1.creds,file_mode=0666,dir_mode=0777,rw,_netdev,nofail
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/var-mnt-storage_l1.mount

systemctl daemon-reload
systemctl enable var-mnt-storage_l1.mount
systemctl start var-mnt-storage_l1.mount