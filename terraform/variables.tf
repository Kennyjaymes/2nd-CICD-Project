variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"  # Changed from us-east-1 for EU region
}

variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "2nd-cicd-project"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "my-app-repo"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "my-eks-cluster"
}

variable "eks_version" {
  description = "EKS version"
  type        = string
  default     = "1.29"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"  # Changed from t3.micro for better performance
}

variable "ec2_key_pair_name" {
  description = "SSH key pair name for EC2 and EKS worker nodes"
  type        = string
  default     = "my-cicd-keypair"
}
