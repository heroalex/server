#!/bin/bash

podman load -q -i /home/nginxuser/.config/containers/storage/nginx1.tar

systemctl --user daemon-reload
systemctl --user start nginx
