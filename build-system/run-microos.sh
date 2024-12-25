#!/bin/bash
set -e

echo "Starting MicroOS test instance..."
qemu-system-x86_64 \
  -cpu host \
  -machine type=q35,accel=kvm \
  -smp 2 \
  -m 2048 \
  -device virtio-net-pci,netdev=user.0 \
  -netdev user,id=user.0,hostfwd=tcp::2222-:22 \
  -drive file=output/microos-test,format=qcow2,if=virtio \
  -boot order=dc \
  -display vnc=:0 \
  -daemonize &

echo "VM started in background. You can:"
echo "1. Connect via VNC at localhost:5900"
echo "2. SSH using: ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -p 2222 opensuse@localhost"