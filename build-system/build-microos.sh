#!/bin/bash
set -e

# Configuration
IMAGE_URL="https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-ContainerHost-OpenStack-Cloud.qcow2"
IMAGE_PATH="./OpenSUSE-MicroOS.qcow2"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"

# Create SSH key if it doesn't exist
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Creating SSH key..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_KEY_PATH" -N ""
fi

# Download the image if it doesn't exist
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Downloading OpenSUSE MicroOS image..."
    curl -L "$IMAGE_URL" -o "$IMAGE_PATH"
fi

echo "Calculating checksum..."
CHECKSUM="sha256:$(sha256sum "$IMAGE_PATH" | cut -d' ' -f1)"

# Export environment variables for Packer
export MICROOS_IMAGE_PATH="$IMAGE_PATH"
export MICROOS_IMAGE_URL="$IMAGE_URL"
export MICROOS_IMAGE_CHECKSUM="$CHECKSUM"
export MICROOS_SSH_PUBLIC_KEY="$(cat ${SSH_KEY_PATH}.pub)"
export MICROOS_SSH_PRIVATE_KEY="$SSH_KEY_PATH"

# Create HTTP directory for cloud-init files
mkdir -p cloud-init

# Process templates with envsubst
export SSH_PUBLIC_KEY="$(cat ${SSH_KEY_PATH}.pub)"
envsubst < meta-data.template > cloud-init/meta-data
envsubst < user-data.template > cloud-init/user-data

echo "Creating cloud-init ISO..."
cloud-localds cloud-init/seed.img cloud-init/user-data cloud-init/meta-data

# Print configuration
echo "Environment variables set:"
echo "MICROOS_IMAGE_URL=$MICROOS_IMAGE_URL"
echo "MICROOS_IMAGE_CHECKSUM=$MICROOS_IMAGE_CHECKSUM"
echo "MICROOS_SSH_PRIVATE_KEY=$MICROOS_SSH_PRIVATE_KEY"
echo "Public key is configured"

if [ -d "output" ]; then
    echo "Removing existing output directory..."
    rm -rf output
fi

mkdir -p samba-share

echo "Start docker samba share..."
if docker ps -a --format '{{.Names}}' | grep -q "^samba-share$"; then
    echo "Found existing samba-share container"

    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q "^samba-share$"; then
        echo "Container is already running"
    else
        echo "Starting existing container"
        docker start samba-share
    fi
else
  docker run -d \
    --name samba-share \
    --network bridge \
    -p 4445:445 \
    -v ./samba-share:/share \
    dperson/samba \
    -s "share;/share;yes;no;yes;all;none;all" \
    -p
fi

# Run packer
packer init .
packer build .