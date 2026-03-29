# Script to import orphaned resources into Terraform state
# Manual version (No AWS CLI required)

$ECR_REPO_NAME = "my-app-repo"
$EKS_CLUSTER_NAME = "my-eks-cluster"

Write-Host "--- Starting State Import ---" -ForegroundColor Cyan

Write-Host "Importing ECR Repository..."
$null = & terraform import aws_ecr_repository.app_repo $ECR_REPO_NAME *>&1

Write-Host "Importing KMS Alias..."
$null = & terraform import 'module.eks.module.kms.aws_kms_alias.this["cluster"]' "alias/eks/$EKS_CLUSTER_NAME" *>&1

Write-Host "Importing Log Group..."
$null = & terraform import 'module.eks.aws_cloudwatch_log_group.this[0]' "/aws/eks/$EKS_CLUSTER_NAME/cluster" *>&1

$global:LASTEXITCODE = 0
Write-Host "--- Import Process Complete ---" -ForegroundColor Green
