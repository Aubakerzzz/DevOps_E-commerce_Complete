variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for AWS resource names."
  type        = string
  default     = "leyo"
}

variable "dockerhub_username" {
  description = "Docker Hub username containing the public leyo images."
  type        = string
}

variable "mongo_root_username" {
  description = "Root username for the mongo container."
  type        = string
  default     = "leyo_admin"
}

variable "mongo_root_password" {
  description = "Root password for the mongo container."
  type        = string
  sensitive   = true
}

variable "desired_count" {
  description = "Number of ECS Fargate tasks."
  type        = number
  default     = 1
}