#!/bin/bash
set -e

echo "Setting up WSL2 Ubuntu environment for QEMU/Packer testing..."

# Update package list
sudo apt-get update

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y \
    qemu-kvm \
    qemu-system-x86 \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    cpu-checker \
    cloud-init \
    cloud-utils \
    hcloud-cli \
    curl \
    unzip \
    jq \
    wget

# Check KVM capability
echo "Checking KVM capability..."
kvm-ok || {
    echo "KVM acceleration not available. This might impact performance."
}

# Add Hashicorp repository and install Packer
echo "Installing Packer..."
# Remove existing files if they exist
sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/hashicorp.list

# Download and set up repository
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

# Update and install
sudo apt-get update
sudo apt-get install -y packer

# Start and enable libvirt daemon
echo "Configuring and starting libvirt daemon..."
# First, ensure the directory exists
sudo mkdir -p /var/run/libvirt
sudo mkdir -p /var/lib/libvirt/qemu

# Configure libvirtd to listen on tcp
sudo tee /etc/libvirt/libvirtd.conf > /dev/null <<EOF
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
auth_unix_ro = "none"
auth_unix_rw = "none"
EOF

# Start libvirt daemon
sudo service libvirtd start || {
    echo "Failed to start libvirtd service. Trying to fix common issues..."

    # Try to fix common WSL2 systemd issues
    if ! systemctl is-active systemd-journald > /dev/null 2>&1; then
        sudo /lib/systemd/systemd-journald &
    fi

    echo "Waiting for services to initialize..."
    sleep 5

    # Try starting libvirtd again
    sudo service libvirtd start || {
        echo "Still unable to start libvirtd. You might need to:"
        echo "1. Enable systemd in WSL2 (add 'systemd=true' to /etc/wsl.conf)"
        echo "2. Restart your WSL2 instance"
        exit 1
    }
}

# Verify libvirt is running
echo "Verifying libvirt installation..."
if ! sudo service libvirtd status > /dev/null 2>&1; then
    echo "Warning: libvirtd service is not running properly"
    echo "You may need to enable systemd in WSL2 by adding:"
    echo "'[boot]' and 'systemd=true' to /etc/wsl.conf"
    echo "Then restart WSL2"
else
    echo "libvirtd service is running"
fi

# Configure libvirt for current user
echo "Configuring libvirt permissions..."
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Verify installations
echo "Verifying other installations..."
qemu-system-x86_64 --version
packer --version
cloud-init --version

echo "Setup completed!"
echo "Important notes:"
echo "1. If libvirt failed to start, you may need to enable systemd in WSL2:"
echo "   - Add these lines to /etc/wsl.conf:"
echo "     [boot]"
echo "     systemd=true"
echo "   - Then restart WSL2 using 'wsl --shutdown' from PowerShell"
echo "2. Log out and log back in for group changes to take effect"