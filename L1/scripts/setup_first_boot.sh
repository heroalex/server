#!/bin/bash
set -e

echo "Creating first-boot.sh..."
source /root/.secrets

set -x

cat > /root/first-boot.sh << EOF
#!/bin/bash
set -eux

STORAGE_VOLUME1=${STORAGE_VOLUME1} /root/scripts/setup_local_volume.sh
STORAGE_L1_U=${STORAGE_L1_U} STORAGE_L1_PW=${STORAGE_L1_PW} STORAGE_L1_URL=${STORAGE_L1_URL} /root/scripts/setup_storage_l1.sh
/root/scripts/setup_podman.sh
#/root/scripts/setup_storage_cam_loops.sh
#/root/scripts/setup_nfs_server.sh
#/root/scripts/setup_samba_container.sh
#/root/scripts/setup_node_exporter_container.sh
#/root/scripts/setup_prometheus_container.sh
#/root/scripts/setup_caddy_container.sh
#/root/scripts/setup_vaultwarden_container.sh

systemctl disable first-boot.service
rm -f /etc/systemd/system/first-boot.service
systemctl daemon-reload
rm -f /root/first-boot.sh
EOF

chmod 700 /root/first-boot.sh

cat > /etc/systemd/system/first-boot.service << EOF
[Unit]
After=local-fs.target
After=network.target

[Service]
Type=simple
ExecStart=/root/first-boot.sh

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/first-boot.service

systemctl daemon-reload
systemctl enable first-boot.service