#!/bin/bash

podman load -q -i /home/registryuser/.config/containers/storage/registry2.tar

systemctl --user start registry
