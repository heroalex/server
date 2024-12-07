#!/bin/bash

podman load -q -i /home/registryuser/.config/containers/storage/registry2.tar

systemctl --user daemon-reload
systemctl --user enable storage.mount
systemctl --user start storage.mount
systemctl --user enable registry
systemctl --user start registry
