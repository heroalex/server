#!/bin/bash
set -eux

cat > /etc/containers/systemd/nextcloud-aio-mastercontainer.container << EOF
[Unit]
Description=Nextcloud AIO Master Container
Documentation=https://github.com/nextcloud/all-in-one/blob/main/docker-rootless.md
After=local-fs.target
Requires=podman.socket

[Container]
ContainerName=nextcloud-aio-mastercontainer
Image=docker.io/nextcloud/all-in-one:latest
PublishPort=127.0.0.1:11001:8080
Volume=nextcloud_aio_mastercontainer:/mnt/docker-aio-config
Volume=/run/podman/podman.sock:/var/run/docker.sock:ro
Network=bridge
SecurityLabelDisable=true

Environment=APACHE_PORT=11000
Environment=APACHE_IP_BINDING=127.0.0.1
Environment=WATCHTOWER_DOCKER_SOCKET_PATH=/run/podman/podman.sock

[Install]
WantedBy=multi-user.target default.target
EOF

cat > /etc/containers/systemd/nextcloud-aio-mastercontainer.volume << EOF
[Volume]
VolumeName=nextcloud_aio_mastercontainer
EOF