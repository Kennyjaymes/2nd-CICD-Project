# Script to import orphaned resources into Terraform state
# Manual version (No AWS CLI required)

$VPC_ID = "vpc-0ec21263e37068a3d"
$ECR_REPO_NAME = "my-app-repo"
$EKS_CLUSTER_NAME = "my-eks-cluster"

# UPDATE THIS ID: Find '2nd-cicd-project-ec2-sg' in AWS Console > Security Groups
$SG_ID = "REPLACE_WITH_YOUR_SG_ID" 

Write-Host "--- Starting State Import ---" -ForegroundColor Cyan

if ($SG_ID -like "sg-*") {
    Write-Host "Importing Security Group $SG_ID..."
    terraform import aws_security_group.ec2_sg $SG_ID
} else {
    Write-Host "Please edit this script and set `$SG_ID` to your Security Group ID from the AWS Console." -ForegroundColor Red
}

Write-Host "Importing ECR Repository..."
terraform import aws_ecr_repository.app_repo $ECR_REPO_NAME

Write-Host "Importing KMS Alias..."
terraform import 'module.eks.module.kms.aws_kms_alias.this["cluster"]' "alias/eks/$EKS_CLUSTER_NAME"

Write-Host "Importing Log Group..."
terraform import 'module.eks.aws_cloudwatch_log_group.this[0]' "/aws/eks/$EKS_CLUSTER_NAME/cluster"

Write-Host "--- Import Process Complete ---" -ForegroundColor Green
