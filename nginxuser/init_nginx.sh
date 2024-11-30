#!/bin/bash

mkdir -p ~/.bashrc.d

echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" > ~/.bashrc.d/systemd
source ~/.bashrc.d/systemd
systemctl --user daemon-reload
systemctl --user status nginx