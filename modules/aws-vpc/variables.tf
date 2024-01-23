# Define variables for the AWS VPC module

# The name for the VPC
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

# Will the VPC be used for EKS
variable "is_eks_enabled" {
  description = "A flag to determine if this VPC will be used with EKS."
  type        = bool
  default     = false
}

# The AWS region where the resources will be created
variable "region" {
  description = "The AWS region"
}

# CIDR block for the VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
}

# List of CIDR blocks for public subnets
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

# List of CIDR blocks for private subnets
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

# List of availability zones to distribute subnets
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# Client tag for the VPC
variable "client_tag" {
  description = "Tag to specify the client"
}

# Environment tag for the VPC
variable "environment_tag" {
  description = "Tag to specify the environment"
}
