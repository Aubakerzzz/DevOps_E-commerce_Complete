variable "region" {
  description = "IBM Cloud region for resources."
  type        = string
  default     = "us-south"
}

variable "zone" {
  description = "IBM Cloud zone within the region (e.g., us-south-1)."
  type        = string
  default     = "us-south-1"
}

variable "project_name" {
  description = "Short name used for resource names."
  type        = string
  default     = "leyo"
}

variable "ssh_public_key" {
  description = "Public SSH key content for VM access."
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

variable "profile" {
  description = "IBM Cloud VPC instance profile."
  type        = string
  default     = "bx2-2x8"
}