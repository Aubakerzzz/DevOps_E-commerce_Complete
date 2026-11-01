variable "location" {
  description = "Azure region for resources."
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "Short name used for resource names."
  type        = string
  default     = "leyo"
}

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file for VM access."
  type        = string
}

variable "admin_cidr" {
  description = "Your public IPv4 address in CIDR notation for SSH access."
  type        = string
  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be valid CIDR notation, e.g. 203.0.113.10/32."
  }
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B2s"
}