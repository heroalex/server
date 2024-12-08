#!/bin/bash

podman load -q -i /home/registryuser/.config/containers/storage/gitea1.tar

mkdir -p /home/registryuser/storage/gitea/data
mkdir -p /home/registryuser/storage/gitea/config

systemctl --user daemon-reload
systemctl --user start gitea
