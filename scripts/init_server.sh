#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

echo "*** source /root/.envncreds"
source /root/.envncreds

# mount l1 storage
echo "*** create /etc/systemd/system/media-storage-l1.mount"
cat > /etc/systemd/system/media-storage-l1.mount << EOF
[Unit]
Description=CIFS Mount for l1 storage
After=network-online.target
Wants=network-online.target

[Mount]
What=//u324047-sub5.your-storagebox.de/u324047-sub5
Where=/media/storage/l1
Type=cifs
Options=vers=3.1.1,gid=storage-l1,credentials=/etc/.storage-l1.creds,file_mode=0660,dir_mode=0770,rw,_netdev
TimeoutSec=30

[Install]
WantedBy=default.target
EOF

echo "*** create /etc/.storage-l1.creds"
cat > /etc/.storage-l1.creds << EOF
username=u324047-sub5
password=${STORAGE_L1}
EOF

echo "*** start media-storage-l1.mount"
systemctl daemon-reload
systemctl enable media-storage-l1.mount
systemctl start media-storage-l1.mount

# mount cam storage
echo "*** create /etc/systemd/system/media-storage-cam.mount"
cat > /etc/systemd/system/media-storage-cam.mount << EOF
[Unit]
Description=CIFS Mount for cam storage
After=network-online.target
Wants=network-online.target

[Mount]
What=//u324047-sub4.your-storagebox.de/u324047-sub4
Where=/media/storage/cam
Type=cifs
Options=vers=3.1.1,gid=storage-cam,credentials=/etc/.storage-cam.creds,file_mode=0660,dir_mode=0770,rw,_netdev
TimeoutSec=30

[Install]
WantedBy=default.target
EOF

echo "*** create /etc/.storage-cam.creds"
cat > /etc/.storage-cam.creds << EOF
username=u324047-sub4
password=${STORAGE_CAM}
EOF

echo "*** start media-storage-cam.mount"
systemctl daemon-reload
systemctl enable media-storage-cam.mount
systemctl start media-storage-cam.mount

# init userhome
echo "*** init userhome"
find /root/server/userhome -type f -exec bash -c 'echo "Processing: $0"; cp "$0" "/home/$1/" && chown "$1:$1" "/home/$1/$(basename "$0")";' {} "${USER_NAME}" \;

echo "*** enable-linger & add subuids & subgids"
loginctl enable-linger ${USER_NAME}
usermod --add-subuids 100000-165535 ${USER_NAME}
usermod --add-subgids 100000-165535 ${USER_NAME}
