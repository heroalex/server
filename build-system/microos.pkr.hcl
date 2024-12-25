packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.9"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "microos" {
  iso_urls      = [var.image_path, var.image_url]
  iso_checksum = var.image_checksum
  disk_image   = true

  output_directory = "output"
  vm_name         = "microos-test"

  cpus      = 2
  memory    = 2048
  disk_size = "40G"

  headless = true

  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key
  ssh_timeout         = "20m"
  ssh_port            = 2222
  ssh_host           = "127.0.0.1"
  skip_nat_mapping    = true
  vnc_port_min = 5900
  vnc_port_max = 5900

  shutdown_command = "sudo shutdown -P now"

  http_directory = "cloud-init"
  boot_wait      = "40s"

  qemuargs = [
    ["-cpu", "host"],
    ["-machine", "type=q35,accel=kvm"],
    ["-device", "virtio-net-pci,netdev=user.0"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::2222-:22"],
    ["-drive", "file=output/microos-test,format=qcow2,if=virtio,cache=writeback,discard=ignore,detect-zeroes=off"],
    ["-drive", "file=cloud-init/seed.img,format=raw,if=virtio"],
    ["-boot", "order=dc"]
  ]
}

build {
  sources = ["source.qemu.microos"]

  # Wait till Cloud-Init has finished setting up the image on first-boot
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for Cloud-Init...'; sleep 1; done"
    ]
    expect_disconnect = true
  }

  provisioner "shell" {
    inline = [
      "echo 'Testing SSH connection and base configuration'",
      "sudo transactional-update --continue pkg install -y curl wget"
    ]
  }
}