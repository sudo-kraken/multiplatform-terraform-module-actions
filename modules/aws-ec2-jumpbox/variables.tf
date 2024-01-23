variable "name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "client_tag" {
  description = "Client tag for resource identification"
  type        = string
  default     = "default_client"
}

variable "product_tag" {
  description = "Product tag for resource identification"
  type        = string
  default     = "default_client"
}

variable "environment_tag" {
  description = "Environment tag for resource identification"
  type        = string
  default     = "default_env"
}

variable "aws_access" {
  description = "AWS Access Key ID for AWS CLI configuration"
  type        = string
  sensitive   = true
}

variable "aws_secret" {
  description = "AWS Secret Access Key for AWS CLI configuration"
  type        = string
  sensitive   = true
}


