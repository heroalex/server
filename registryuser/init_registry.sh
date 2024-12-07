#!/bin/bash

podman load -q -i /home/registryuser/.config/containers/storage/registry2.tar

mkdir -p /home/registryuser/storage/local
mkdir -p /home/registryuser/storage/docker
mkdir -p /home/registryuser/storage/quay

systemctl --user daemon-reload
systemctl --user start local-registry
systemctl --user start docker-mirror-registry
systemctl --user start quay-mirror-registry
