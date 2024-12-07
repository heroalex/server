#!/bin/bash

podman load -q -i /home/registryuser/.config/containers/storage/registry2.tar

systemctl --user daemon-reload
systemctl --user enable home-registryuser-storage.mount
systemctl --user start home-registryuser-storage.mount
systemctl --user start registry
