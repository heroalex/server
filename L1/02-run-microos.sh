#!/bin/bash
set -e

echo "Starting MicroOS test instance..."
qemu-system-x86_64 \
  -cpu host \
  -machine type=q35,accel=kvm \
  -smp 2 \
  -m 4096 \
  -device virtio-net-pci,netdev=user.0 \
  -netdev user,id=user.0,hostfwd=udp::13231-:13231 \
  -drive file=output/microos,format=qcow2,if=virtio \
  -boot order=dc \
  -display vnc=:0 \
  -daemonize &

echo "VM started in background. You can:"
echo "1. Connect via VNC at localhost:5900"
echo "2. connect WG and SSH using: ssh -o StrictHostKeyChecking=no -i ~/.ssh/hetzner_L1_ed25519 root@172.16.16.1"