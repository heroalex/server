#!/bin/bash
set -eux

if [ -z "`lsblk ${STORAGE_VOLUME1} -no fstype`" ]; then
  mkfs.xfs ${STORAGE_VOLUME1}
fi

cat > /etc/systemd/system/mnt-volume1.mount << EOF
[Unit]
Description=Volume 1 Mount

[Mount]
What=${STORAGE_VOLUME1}
Where=/mnt/volume1
Type=xfs
Options=discard,defaults
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/mnt-volume1.mount

systemctl daemon-reload
systemctl enable mnt-volume1.mount
systemctl start mnt-volume1.mount