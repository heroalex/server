#!/bin/bash
set -eux

# Configuration
IMG_SIZE="50G"
IMG1_PATH="/var/mnt/storage_l1/cam/cam1.img"
IMG2_PATH="/var/mnt/storage_l1/cam/cam2.img"
MOUNT1_PATH="/var/mnt/cam1"
MOUNT2_PATH="/var/mnt/cam2"

# Ensure loop module is loaded
modprobe loop

# Wait for CIFS mount to be active
while ! mountpoint -q /var/mnt/storage_l1; do
    echo "Waiting for storage_l1 mount..."
    sleep 5
done

# Create mount points
mkdir -p "${MOUNT1_PATH}" "${MOUNT2_PATH}"
#chgrp storage_cam "${MOUNT1_PATH}" "${MOUNT2_PATH}"
chmod 775 "${MOUNT1_PATH}" "${MOUNT2_PATH}"

# Create image files if they don't exist
for IMG_FILE in "${IMG1_PATH}" "${IMG2_PATH}"; do
    if [ ! -f "${IMG_FILE}" ]; then
        fallocate -l "${IMG_SIZE}" "${IMG_FILE}"
        chmod 660 "${IMG_FILE}"
#        chgrp storage_cam "${IMG_FILE}"

        # Initialize with XFS
        LOOP_DEV=$(losetup -f)
        losetup "${LOOP_DEV}" "${IMG_FILE}"
        mkfs.xfs "${LOOP_DEV}"
        losetup -d "${LOOP_DEV}"
    fi
done

# Create systemd service for loop device setup
cat > /etc/systemd/system/storage-cam-loop-setup.service << 'EOF'
[Unit]
Description=Setup loop devices for camera storage
After=var-mnt-storage_l1.mount
Wants=var-mnt-storage_l1.mount
Before=var-mnt-cam1.mount var-mnt-cam2.mount

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/setup-storage-loops.sh
ExecStop=/usr/local/sbin/cleanup-storage-loops.sh

[Install]
WantedBy=multi-user.target
EOF

# Create loop setup script
cat > /usr/local/sbin/setup-storage-loops.sh << 'EOF'
#!/bin/bash
set -eu

setup_loop() {
    local img_file="$1"
    local loop_name="$2"

    # Remove existing loop device if it exists
    if losetup -a | grep -q "${img_file}"; then
        losetup -d "/dev/${loop_name}"
    fi

    # Set up new loop device
    losetup -P "/dev/${loop_name}" "${img_file}"
}

setup_loop "/var/mnt/storage_l1/cam/cam1.img" "loop10"
setup_loop "/var/mnt/storage_l1/cam/cam2.img" "loop11"
EOF

# Create loop cleanup script
cat > /usr/local/sbin/cleanup-storage-loops.sh << 'EOF'
#!/bin/bash
set -eu

losetup -d /dev/loop10 || true
losetup -d /dev/loop11 || true
EOF

# Make scripts executable
chmod 755 /usr/local/sbin/setup-storage-loops.sh
chmod 755 /usr/local/sbin/cleanup-storage-loops.sh

# Create mount units for each filesystem
cat > /etc/systemd/system/var-mnt-cam1.mount << 'EOF'
[Unit]
Description=Camera 1 Storage
After=storage-cam-loop-setup.service
Wants=storage-cam-loop-setup.service

[Mount]
What=/dev/loop10
Where=/var/mnt/cam1
Type=xfs
Options=defaults,noatime,nofail

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/var-mnt-cam2.mount << 'EOF'
[Unit]
Description=Camera 2 Storage
After=storage-cam-loop-setup.service
Wants=storage-cam-loop-setup.service

[Mount]
What=/dev/loop11
Where=/var/mnt/cam2
Type=xfs
Options=defaults,noatime,nofail

[Install]
WantedBy=multi-user.target
EOF

# Create a service to set permissions after mounting
cat > /etc/systemd/system/storage-cam-permissions.service << 'EOF'
[Unit]
Description=Set permissions for camera storage
After=var-mnt-cam1.mount var-mnt-cam2.mount
Requires=var-mnt-cam1.mount var-mnt-cam2.mount

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/set-storage-permissions.sh

[Install]
WantedBy=multi-user.target
EOF

# Create the permissions setup script
cat > /usr/local/sbin/set-storage-permissions.sh << 'EOF'
#!/bin/bash
set -eu

# Set permissions for both mount points
#chgrp storage_cam /var/mnt/cam1 /var/mnt/cam2
chmod 777 /var/mnt/cam1 /var/mnt/cam2
EOF

# Make the script executable
chmod 755 /usr/local/sbin/set-storage-permissions.sh

# Set proper permissions
chmod 644 /etc/systemd/system/storage-cam-loop-setup.service
chmod 644 /etc/systemd/system/var-mnt-cam1.mount
chmod 644 /etc/systemd/system/var-mnt-cam2.mount
chmod 644 /etc/systemd/system/storage-cam-permissions.service

# Reload systemd and enable services
systemctl daemon-reload
systemctl enable storage-cam-loop-setup.service
systemctl enable var-mnt-cam1.mount
systemctl enable var-mnt-cam2.mount
systemctl enable storage-cam-permissions.service

# Start services
systemctl start storage-cam-loop-setup.service
systemctl start var-mnt-cam1.mount
systemctl start var-mnt-cam2.mount
systemctl start storage-cam-permissions.service