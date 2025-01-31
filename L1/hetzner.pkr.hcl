packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.9"
      source  = "github.com/hashicorp/qemu"
    }
    hcloud = {
      version = ">= 1.0.5"
      source  = "github.com/hetznercloud/hcloud"
    }
  }
}

variable "build_type" {}
variable "ssh_username" {}
variable "ssh_private_key" {}
variable "microos_image_checksum" {}
variable "microos_image_url" {}
variable "microos_image_local" {}
variable "wg0_pk" {}
variable "wg0_peer_1" {}
variable "wg0_peer_2" {}
variable "storage_l1_u" {}
variable "storage_l1_pw" {}
variable "storage_l1_url" {}

locals {
  needed_packages = "policycoreutils setools-console audit bind-utils wireguard-tools open-iscsi nfs-kernel-server nfs-client xfsprogs cryptsetup lvm2 git cifs-utils bash-completion mtr tcpdump systemd-container"
  # needed_packages = "wireguard-tools cifs-utils"

  download_image = "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only "

  write_image = <<-EOT
    set -ex
    echo 'MicroOS image loaded, writing to disk... '
    qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda
    echo 'done. Rebooting...'
    sleep 1 && udevadm settle && reboot
  EOT

  install_packages = <<-EOT
    set -ex
    echo "First reboot successful, installing needed packages..."
    transactional-update --continue pkg install -y ${local.needed_packages}
    transactional-update --continue shell <<- EOF
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet systemd.show_status=yes console=ttyS0,115200 console=tty0 ignition.platform.id=openstack security=selinux selinux=0"/' /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
    setenforce 0
    restorecon -Rv /etc/selinux/targeted/policy
    restorecon -Rv /var/lib
    setenforce 1
    EOF
    sleep 1 && udevadm settle && reboot
  EOT

  prepare_setup_scripts = <<-EOT
    set -ex
    chmod 0700 /root/scripts/*
  EOT
}

source "qemu" "microos" {
  iso_urls      = [var.microos_image_local, var.microos_image_url]
  iso_checksum = var.microos_image_checksum
  disk_image   = true

  output_directory = "output"
  vm_name         = "microos"

  cpus      = 2
  memory    = 4096
  disk_size = "40G"

  headless = true

  ssh_username  = var.ssh_username
  ssh_private_key_file = var.ssh_private_key
  ssh_timeout         = "20m"
  ssh_port            = 2222
  ssh_host           = "127.0.0.1"
  skip_nat_mapping    = true
  vnc_port_min = 5900
  vnc_port_max = 5900

  shutdown_command = "sudo shutdown -P now"
  boot_wait      = "30s"

  qemuargs = [
    ["-cpu", "host"],
    ["-machine", "type=q35,accel=kvm"],
    ["-device", "virtio-net-pci,netdev=user.0"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::2222-:22"],
    ["-drive", "file=output/microos,format=qcow2,if=virtio,cache=writeback,discard=ignore,detect-zeroes=off"],
    ["-drive", "file=cloud-init/seed.img,format=raw,if=virtio"],
    ["-boot", "order=dc"]
  ]
}

source "hcloud" "microos" {
  image       = "debian-12"
  rescue      = "linux64"
  #location    = "nbg1"
  location    = "fsn1"
  # server_type = "cx32"  # 4 / 8  / 80  / 7.4970€
  # server_type = "cx42"  # 8 / 16 / 160 / 18.9210€
  # server_type = "cpx11" # 2 / 2  / 40  / 4.5815€
  server_type = "cpx21" # 3 / 4  / 80  / 8.3895€
  # server_type = "cpx31"   # 4 / 8  / 160 / 15.5890€
  # server_type = "cax21" # 4 / 8  / 80  / 7.1281€
  # server_type = "cax31" # 8 / 16 / 160 / 14.2681€
  # server_type = "ccx13" # 2 / 8  / 80  / 14.2681€
  snapshot_labels = {
    microos-snapshot = "yes"
    creator          = "packer"
  }
  snapshot_name = "OpenSUSE MicroOS x86"
  ssh_username  = var.ssh_username
  ssh_keys = [8691126]  // alex@LAPTOP
  public_ipv4 = "75865727" // 159.69.48.78 L1-Pre-FSN
  # public_ipv4 = "80062906" // 138.201.172.23 L1-Prod-FSN
  # public_ipv4 = "77958777" // 128.140.64.198 L1-Pre-NBG
  # public_ipv4 = "15513901" // 78.47.124.59 L1-Prod-NBG
  public_ipv6_disabled  = true
}

# Build the MicroOS x86 snapshot
build {
  sources = [
      var.build_type == "local" ? "qemu.microos" : "hcloud.microos"
  ]

  # Download the MicroOS x86 image
  provisioner "shell" {
    only  = ["hcloud.microos"]
    inline = ["${local.download_image}${var.microos_image_url}"]
  }

  # Write the MicroOS x86 image to disk
  provisioner "shell" {
    only=["hcloud.microos"]
    inline            = [local.write_image]
    expect_disconnect = true
  }

  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_packages]
    expect_disconnect = true
  }

  provisioner "breakpoint" {
    disable = true
    note    = "breakpoint before scripts"
  }

  provisioner "shell" {
    pause_before      = "5s"
    scripts       = [
      "scripts/enable_ipv4_forwarding.sh",
    ]
  }

  provisioner "shell" {
    scripts       = [
      "scripts/disable_ipv6.sh",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "WG0_PK=${var.wg0_pk}",
      "WG0_PEER_1=${var.wg0_peer_1}",
      "WG0_PEER_2=${var.wg0_peer_2}",
    ]
    scripts       = [
      "scripts/setup_wg0.sh",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "USERNAME=${var.ssh_username}",
    ]
    scripts       = [
      "scripts/setup_sshd.sh",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "STORAGE_L1_U=${var.storage_l1_u}",
      "STORAGE_L1_PW=${var.storage_l1_pw}",
      "STORAGE_L1_URL=${var.storage_l1_url}",
    ]
    scripts       = [
      "scripts/setup_storage_l1.sh",
    ]
  }

  provisioner "shell" {
    scripts       = [
      "scripts/setup_storage_cam_loops.sh",
    ]
  }

  provisioner "shell" {
    scripts       = [
      "scripts/setup_nfs_server.sh",
    ]
  }

  provisioner "shell" {
    scripts       = [
      "scripts/setup_samba_container.sh",
    ]
  }

  provisioner "shell" {
    scripts       = [
      "scripts/setup_firewall.sh",
    ]
  }

  provisioner "file" {
    source = "scripts"
    destination = "/root"
  }

  provisioner "shell" {
    inline            = [local.prepare_setup_scripts]
    valid_exit_codes  = [0, 1]
  }

  # provisioner "shell" {
  #   scripts       = [
  #     "scripts/setup_nginx_container.sh",
  #   ]
  # }
  #
  # provisioner "shell" {
  #   scripts       = [
  #     "scripts/setup_nextcloud_container.sh",
  #   ]
  # }

  #
  # provisioner "shell" {
  #   scripts       = [
  #     # "scripts/setup_swap.sh",
  #   ]
  # }

  provisioner "shell" {
    scripts       = [
      "scripts/cleanup.sh",
    ]
  }

  provisioner "breakpoint" {
    only = ["qemu.microos"]
    disable = true
    note    = "breakpoint when finished"
  }
}