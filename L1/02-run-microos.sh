#!/bin/bash
set -eu

VOLUME_LOCAL="./volume10G.raw"
source .secrets/secrets-local-l1-pre

echo "Starting MicroOS test instance..."
qemu-system-x86_64 \
  -cpu host \
  -machine type=q35,accel=kvm \
  -smp 2 \
  -m 4096 \
  -device virtio-net-pci,netdev=user.0 \
  -netdev user,id=user.0,hostfwd=udp:127.0.0.1:13231-:13231,hostfwd=tcp:127.0.0.1:80-:80,hostfwd=tcp:127.0.0.1:443-:443,hostfwd=udp:127.0.0.1:443-:443 \
  -drive file=output/microos,format=qcow2,if=virtio,index=0 \
  -drive file=${VOLUME_LOCAL},format=raw,if=virtio,index=1 \
  -display vnc=:0 \
  -daemonize &

echo "VM started in background. You can:"
echo "1. Connect via VNC at localhost:5900"
echo "2. connect WG and SSH using: ssh -o StrictHostKeyChecking=no -i ~/.ssh/hetzner_L1_ed25519 root@${WG0_DOMAIN_1}"