#!/bin/bash

mkdir -p ~/.bashrc.d

# Get actual user ID
USER_ID=$(id -u)

# Create runtime directories
mkdir -p /run/user/$USER_ID/containers
mkdir -p ~/.local/share/containers/storage

# Set up environment variables
cat > ~/.bashrc.d/systemd <<EOF
export XDG_RUNTIME_DIR=/run/user/$USER_ID
export RUNROOT=/run/user/$USER_ID/containers
EOF

source ~/.bashrc.d/systemd

# Set proper permissions
chmod 700 /run/user/$USER_ID
chmod 700 /run/user/$USER_ID/containers

# Reload systemd
systemctl --user daemon-reload
systemctl --user start nginx