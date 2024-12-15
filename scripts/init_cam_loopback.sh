#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Configuration
IMAGE_SIZE="51200"
STORAGE_BASE="/media/storage/cam"
MOUNT_BASE="/media"
CAM1_IMAGE="${STORAGE_BASE}/cam1_.img"
CAM2_IMAGE="${STORAGE_BASE}/cam2_.img"
CAM1_MOUNT="${MOUNT_BASE}/cam1"
CAM2_MOUNT="${MOUNT_BASE}/cam2"

# Create necessary directories
echo "*** create cam mount directories"
mkdir -p "${CAM1_MOUNT}"
mkdir -p "${CAM2_MOUNT}"

# Set ownership
echo "*** set cam mount directories ownership"
chgrp storage-cam "${CAM1_MOUNT}"
chgrp storage-cam "${CAM2_MOUNT}"
chmod 770 "${CAM1_MOUNT}" "${CAM2_MOUNT}"

# Create image files if they don't exist
echo "*** create image files"
for img in "${CAM1_IMAGE}" "${CAM2_IMAGE}"; do
    if [ ! -f "${img}" ]; then
        dd if=/dev/zero of="${img}" bs=1M count=0 seek=${IMAGE_SIZE} status=progress
        mkfs.ext4 -F "${img}"
    fi
done

# Create systemd mount units
echo "*** create media-cam1.mount"
cat > /etc/systemd/system/media-cam1.mount << EOF
[Unit]
Description=Camera 1 Storage Mount
After=media-storage-cam.mount
Requires=media-storage-cam.mount

[Mount]
What=${CAM1_IMAGE}
Where=${CAM1_MOUNT}
Type=ext4
Options=loop,rw,nosuid,nodev,noexec,relatime,gid=storage-cam,dmask=027,fmask=137

[Install]
WantedBy=default.target
EOF

echo "*** create media-cam2.mount"
cat > /etc/systemd/system/media-cam2.mount << EOF
[Unit]
Description=Camera 2 Storage Mount
After=media-storage-cam.mount
Requires=media-storage-cam.mount

[Mount]
What=${CAM2_IMAGE}
Where=${CAM2_MOUNT}
Type=ext4
Options=loop,rw,nosuid,nodev,noexec,relatime,gid=storage-cam,dmask=027,fmask=137

[Install]
WantedBy=default.target
EOF

# Reload systemd and enable mounts
echo "*** enable & start media-cam1 & cam2 mounts"
systemctl daemon-reload
systemctl enable media-cam1.mount
systemctl enable media-cam2.mount
systemctl start media-cam1.mount
systemctl start media-cam2.mount
