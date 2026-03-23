output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repo.repository_url
  description = "ECR repository URL"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster API endpoint"
}

output "eks_cluster_kubeconfig" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster API endpoint (kubeconfig data not directly exposed in this module output)"
  sensitive   = true
}

output "ec2_public_ip" {
  value       = aws_instance.app_ec2.public_ip
  description = "Public IP of the EC2 app server"
}

output "ec2_id" {
  value       = aws_instance.app_ec2.id
  description = "EC2 instance ID"
}
