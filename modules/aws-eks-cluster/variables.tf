variable "name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "eks_version" {
  description = "Desired EKS version for the cluster."
  type        = string
}

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IPs."
  type        = string
}

variable "core_dns_ip" {
  description = "IP address used for Kubernetes Core DNS."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster."
  type        = list(string)
}

variable "public_subnet_id" {
  description = "Public Subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster."
  type        = string
}

variable "node_pools" {
  description = "Values for deploying the worker node pools."
}

variable "addons" {
  description = "Addons to enable on the EKS cluster."
  type        = list(object({
    name    = string
    version = string
  }))
  default = []
}

variable "client_tag" {
  description = "Client tag to be attached to all resources"
  type        = string
}

variable "product_tag" {
  description = "Deployment product (e.g., afms, dip, cs)"
  type        = string
}

variable "environment_tag" {
  description = "Deployment environment (e.g., prod, dev, staging)"
  type        = string
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
