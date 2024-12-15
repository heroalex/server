#!/bin/bash

mkdir -p /home/wwwuser/storage/nextcloud/data

podman load -q -i /home/wwwuser/.config/containers/storage/nc-aio.tar

systemctl --user daemon-reload
systemctl --user start nextcloud