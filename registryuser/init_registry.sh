#!/bin/bash

podman load -q -i /home/registryuser/.config/containers/storage/gitea1.22.tar

mkdir -p /home/registryuser/storage/gitea

systemctl --user daemon-reload
systemctl --user start gitea
