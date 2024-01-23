output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.arn
}

output "eks_cluster_version" {
  description = "The Kubernetes version of the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.version
}

output "eks_worker_nodes_security_group_id" {
  description = "The ID of the security group for the worker nodes."
  value       = aws_security_group.eks_worker_nodes_sg.id
}

output "eks_cluster_security_group_id" {
  description = "The ID of the security group for the EKS cluster."
  value       = aws_security_group.eks_cluster_sg.id
}

output "eks_cluster_kms_key_arn" {
  description = "The ARN of the KMS key used for secret encryption in the EKS cluster."
  value       = aws_kms_key.eks.arn
}

output "encrypted_password_data" {
  value = aws_instance.jumpbox.password_data
  sensitive = true
}
