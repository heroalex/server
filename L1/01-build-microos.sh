#!/bin/bash
set -e

if [ -z $BUILD_TYPE ] && [ -z $1 ]; then
  echo "Defaulting build type to local"
  BUILD_TYPE=local
  source .secrets/secrets-local-l1-pre
fi
if [ -z $BUILD_TYPE ]; then
  echo "BUILD_TYPE is unset. Setting to $1"
  BUILD_TYPE=$1
  source .secrets/secrets-$1
fi
echo "BUILD_TYPE is set to '$BUILD_TYPE'"


# Check for HCLOUD_TOKEN if using hcloud environment
if [ $BUILD_TYPE != "local" ] && [ -z "${HCLOUD_TOKEN:-}" ]; then
    echo "Error: HCLOUD_TOKEN environment variable not set"
    exit 1
fi

SSH_KEY_PATH="$HOME/.ssh/hetzner_L1_ed25519"
# Create SSH key if it doesn't exist
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Creating SSH key... (remember to upload to hetzner)"
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "alex@L1"
fi

MICROOS_IMAGE_NAME="openSUSE-MicroOS.x86_64-ContainerHost-OpenStack-Cloud.qcow2"
MICROOS_IMAGE_URL="https://download.opensuse.org/tumbleweed/appliances/$MICROOS_IMAGE_NAME"
MICROOS_IMAGE_LOCAL="./OpenSUSE-MicroOS.qcow2"
# Download the images if it doesn't exist
if [ ! -f "$MICROOS_IMAGE_LOCAL" ]; then
    echo "Downloading OpenSUSE MicroOS image..."
    curl -L "$MICROOS_IMAGE_URL" -o "$MICROOS_IMAGE_LOCAL"
fi

#echo "Calculating checksum..."
#MICROOS_CHECKSUM="sha256:$(sha256sum "$MICROOS_IMAGE_LOCAL" | cut -d' ' -f1)"
MICROOS_CHECKSUM="sha256:a6288b97af5a40c89c28a528b9952e0a6ef3dfc49686e25d3957ff23459b5d8e"

# Create temporary directory for ubuntu cloud-init
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

# Process cloud-init configuration for local qemu
echo "Processing cloud-init configuration..."
export SSH_PUBLIC_KEY="$(cat ${SSH_KEY_PATH}.pub)"
cat > "${TEMP_DIR}/user-data" << EOF
#cloud-config
system_info:
  default_user:
    lock_passwd: True
    name: ${SSH_USERNAME}
    shell: /bin/bash

users:
  - default

disable_root: False
ssh_authorized_keys:
  - ${SSH_PUBLIC_KEY}
EOF

# Generate meta-data
cat > "${TEMP_DIR}/meta-data" << EOF
instance-id: packer
local-hostname: microos-local
EOF

# Create cloud-init ISO for QEMU
if [ $BUILD_TYPE = "local" ]; then
    echo "Creating cloud-init ISO for QEMU..."
    cloud-localds "${TEMP_DIR}/seed.img" "${TEMP_DIR}/user-data" "${TEMP_DIR}/meta-data"
    mv "${TEMP_DIR}/seed.img" "cloud-init/seed.img"
fi

if [ -d "output" ]; then
    echo "Removing existing output directory..."
    rm -rf output
fi

VOLUME_LOCAL="./volume10G.raw"
# Create volume for QEMU
if [ $BUILD_TYPE = "local" ] && [ ! -f "$VOLUME_LOCAL" ]; then
    echo "Creating volume for QEMU..."
    qemu-img create -f raw $VOLUME_LOCAL 10G
fi

# Export environment variables for Packer
export PKR_VAR_build_type="$BUILD_TYPE"
export PKR_VAR_ssh_username="$SSH_USERNAME"
export PKR_VAR_ssh_private_key="$SSH_KEY_PATH"
export PKR_VAR_microos_image_checksum="$MICROOS_CHECKSUM"
export PKR_VAR_microos_image_url="$MICROOS_IMAGE_URL"
export PKR_VAR_microos_image_local="$MICROOS_IMAGE_LOCAL"
#export PKR_VAR_volume_local="$VOLUME_LOCAL"

# Run packer
packer init hetzner.pkr.hcl
HCLOUD_TOKEN=$HCLOUD_TOKEN packer build -on-error=ask hetzner.pkr.hcl