# 2nd CICD Project

This repository demonstrates a complete CI/CD pipeline that creates and deploys infrastructure and application workloads in AWS using:

- Terraform for IaC (ECR, EKS, EC2, networking default VPC)
- GitHub Actions for pipeline orchestration
- Docker image build and push to Amazon ECR
- App deployment to EKS using Kubernetes manifests
- App deployment verification on EC2 via `user_data`
- Slack notifications at each pipeline step

## Architecture

1. Terraform provisions:
   - `aws_ecr_repository` for container images
   - `module.eks` cluster + managed node group
   - `aws_instance` EC2 app host
   - Security group for EC2 (HTTP 80, SSH 22)
2. GitHub Actions pipeline tasks:
   - `terraform` job: init, plan, apply
   - `build_and_push` job: docker build+push to ECR
   - `deploy_eks` job: deploy Kubernetes workload to EKS
   - `verify_ec2` job: check EC2 app endpoint
3. Slack notifications are sent for start/success/failure events in each job.

## CI/CD Options

This project supports two CI/CD platforms:

### Option 1: GitHub Actions (Default)
- Uses `.github/workflows/cicd.yml`
- Fully automated on GitHub's infrastructure
- Requires GitHub repository secrets

### Option 2: Jenkins
- Uses `Jenkinsfile` for pipeline definition
- Requires a self-hosted Jenkins server
- Uses Jenkins credentials for AWS and Slack

## Jenkins Setup

1. **Install Jenkins** on a server (e.g., EC2 instance) with Docker, AWS CLI, Terraform, kubectl installed.

2. **Install Plugins**:
   - Pipeline
   - AWS Credentials
   - Docker Pipeline

3. **Configure Credentials** in Jenkins:
   - `AWS_ACCESS_KEY_ID`: AWS access key
   - `AWS_SECRET_ACCESS_KEY`: AWS secret key
   - `AWS_REGION`: e.g., `eu-west-1`
   - `SLACK_WEBHOOK_URL`: Slack webhook URL

4. **Create Pipeline Job**:
   - New Item > Pipeline
   - Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your repo
   - Script Path: `Jenkinsfile`

5. **Trigger Builds**:
   - Poll SCM or webhook for pushes to `main`

## Setup

1. Create and commit an SSH key pair or set `ec2_key_pair_name` to an existing key.
2. Add GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (e.g. `us-east-1`)
   - `AWS_ROLE_ARN` (optional: for role-based cross-account access)
   - `SLACK_WEBHOOK_URL`
   - `HASHICORP_CLOUD_TOKEN` (optional for terraform setup tool, or remove from workflow)
3. Ensure your EKS node group key config, and the EC2 `ec2_key_pair_name` key is in the target account.

## Commands (local)

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

## Deploy manifest

`k8s-deployment.yaml` is the application manifest with placeholders:
- `REPLACE_WITH_IMAGE` gets replaced by the GitHub workflow to `$ECR_REPO:latest`.

## Application

- `Dockerfile`: Simple Nginx-based container serving static files.
- `app/index.html`: Basic HTML page displayed by the app.

## Slack Alerts

Pipeline uses `curl` to send standard text notifications to the Slack webhook in:
- `terraform` stage
- `build_and_push` stage
- `deploy_eks` stage
- `verify_ec2` stage

## How it works

- After `terraform apply`, `aws_ecr_repository.app_repo.repository_url` and cluster outputs are available via Terraform outputs.
- Docker image build/push runs from the source repository.
- EKS deploy loads manifest and updates the image tag.
- EC2 instance has `user_data` to pull the latest image from ECR and run on port 80.

## Notes

- This pipeline is fully automated for infra and app deployment, no manual AWS console steps except secrets setup.
- For production, improve security with least privilege IAM, private subnets and SSM session manager.
