variable "proxmox-host" {
  description = "The PVE hostname/IP"
  type        = string
  default     = "pve"
}

variable "username" {
  description = "The username for the PVE host"
  type        = string
  sensitive   = false
  default     = "root"
}

variable "password" {
  description = "The password for the PVE user"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "pvt_key_file" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "template_vm_name" {
  type    = string
  default = "ubuntu-focal-cloudinit-template"
}

variable "metallb_config" {
  description = "Configuration for metalLB"
  type        = string
  default     = "{}"
}

variable "argo_password" {
  description = "Admin password for arcoCD"
  type        = string
  nullable    = false
}
