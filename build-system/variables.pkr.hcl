variable "ssh_username" {
  type    = string
  default = "opensuse"
}

variable "ssh_private_key" {
  type    = string
  default = env("MICROOS_SSH_PRIVATE_KEY")
}

variable "image_checksum" {
  type    = string
  default = env("MICROOS_IMAGE_CHECKSUM")
}

variable "image_url" {
  type    = string
  default = env("MICROOS_IMAGE_URL")
}

variable "image_path" {
  type    = string
  default = env("MICROOS_IMAGE_PATH")
}