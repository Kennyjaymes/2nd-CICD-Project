provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_ecr_repository" "app_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  tags = {
    Environment = var.environment
  }
}

module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  name               = var.eks_cluster_name
  kubernetes_version = var.eks_version

  create_vpc = true
  vpc_cidr   = "10.0.0.0/16"
  azs        = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  eks_managed_node_groups = {
    on_demand = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = [var.ec2_instance_type]
      key_name       = var.ec2_key_pair_name
    }
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow HTTP and SSH to EC2"
  vpc_id      = module.eks.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_instance" "app_ec2" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.ec2_instance_type
  subnet_id              = module.eks.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.ec2_key_pair_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user

              $(aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app_repo.repository_url})
              docker pull ${aws_ecr_repository.app_repo.repository_url}:latest || true
              docker run -d -p 80:80 --name app ${aws_ecr_repository.app_repo.repository_url}:latest || true
              EOF

  tags = {
    Name        = "${var.project_name}-web"
    Environment = var.environment
  }
}
