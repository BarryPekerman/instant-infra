variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "ssh_location" {
  description = "CIDR block for SSH access"
  type        = string
  default     = "0.0.0.0/0" # Fallback if get_ip fails or not used
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "instant-infra-cluster"
}

variable "region" {
  description = "AWS Region"
  default     = "eu-west-1"
}
