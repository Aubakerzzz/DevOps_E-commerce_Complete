variable "aws_region" {
  description = "AWS region for the EC2 instance."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used for resource names."
  type        = string
  default     = "leyo"
}

variable "instance_type" {
  description = "EC2 instance type; t3.medium is a general-purpose medium instance."
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Existing EC2 key pair name for emergency/manual SSH access."
  type        = string
}

variable "admin_cidr" {
  description = "Your public IPv4 address in CIDR notation, e.g. 203.0.113.10/32. SSH is allowed only from this range."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be valid CIDR notation, e.g. 203.0.113.10/32."
  }
}

variable "root_volume_size" {
  description = "EC2 root volume size in GiB."
  type        = number
  default     = 20
}
