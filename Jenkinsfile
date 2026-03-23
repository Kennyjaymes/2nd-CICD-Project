pipeline {
    agent any

    environment {
        AWS_REGION = credentials('AWS_REGION')
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        SLACK_WEBHOOK_URL = credentials('SLACK_WEBHOOK_URL')
    }

    stages {
        stage('Notify Slack - Terraform Start') {
            steps {
                script {
                    powershell "Invoke-WebRequest -Uri \$env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] Terraform stage started for \$env:JOB_NAME@\$env:BUILD_NUMBER\"}'"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    powershell 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    powershell 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    powershell 'terraform apply -input=false -auto-approve tfplan'
                }
            }
        }

        stage('Set Outputs') {
            steps {
                dir('terraform') {
                    script {
                        env.ECR_URL = powershell(script: 'terraform output -raw ecr_repository_url', returnStdout: true).trim()
                        env.EKS_CLUSTER = powershell(script: 'terraform output -raw eks_cluster_name', returnStdout: true).trim()
                        env.EKS_ENDPOINT = powershell(script: 'terraform output -raw eks_cluster_endpoint', returnStdout: true).trim()
                        env.EC2_IP = powershell(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Notify Slack - Terraform Success') {
            steps {
                script {
                    powershell "Invoke-WebRequest -Uri \$env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] Terraform succeed. ECR: \$env:ECR_URL, EKS cluster: \$env:EKS_CLUSTER\"}'"
                }
            }
        }

        stage('Notify Slack - Build Start') {
            steps {
                script {
                    powershell "Invoke-WebRequest -Uri \$env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] Docker build+push started.\"}'"
                }
            }
        }

        stage('Login to ECR') {
            steps {
                powershell "aws ecr get-login-password --region \$env:AWS_REGION | docker login --username AWS --password-stdin \$env:ECR_URL"
            }
        }

        stage('Build Docker Image') {
            steps {
                powershell "docker build -t \$env:ECR_URL:latest ."
            }
        }

        stage('Push Docker Image') {
            steps {
                powershell "docker push \$env:ECR_URL:latest"
            }
        }

        stage('Notify Slack - Build Success') {
            steps {
                script {
                    powershell "Invoke-WebRequest -Uri \$env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] Docker image pushed to \$env:ECR_URL\"}'"
                }
            }
        }

        stage('Notify Slack - EKS Deploy Start') {
            steps {
                script {
                    powershell "Invoke-WebRequest -Uri \$env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] EKS deploy started\"}'"
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                powershell "aws eks update-kubeconfig --name \$env:EKS_CLUSTER --region \$env:AWS_REGION"
            }
        }

        stage('Deploy to EKS') {
            steps {
                powershell "(Get-Content k8s-deployment.yaml) -replace 'REPLACE_WITH_IMAGE', \"\$env:ECR_URL:latest\" | Set-Content k8s-deployment-rendered.yaml"
                powershell "kubectl apply -f k8s-deployment-rendered.yaml"
            }
        }

        stage('Notify Slack - EKS Success') {
            steps {
                script {
                    powershell "Invoke-WebRequest -Uri \$env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] EKS deployment complete\"}'"
                }
            }
        }

        stage('Verify EC2') {
            steps {
                script {
                    def response = powershell(script: "try { \$response = Invoke-WebRequest -Uri \"http://\$env:EC2_IP\" -TimeoutSec 10; \$response.StatusCode } catch { 000 }", returnStdout: true).trim()
                    if (response == '200') {
                        powershell "Invoke-WebRequest -Uri \$env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] EC2 app reachable at http://\$env:EC2_IP\"}'"
                    } else {
                        powershell "Invoke-WebRequest -Uri \$env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] EC2 app unreachable (code=\$response) at http://\$env:EC2_IP\"}'"
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                def slackUrl = credentials('SLACK_WEBHOOK_URL')
                powershell "Invoke-WebRequest -Uri \$slackUrl -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] Pipeline completed successfully for \$env:JOB_NAME@\$env:BUILD_NUMBER\"}'"
            }
        }
        failure {
            script {
                def slackUrl = credentials('SLACK_WEBHOOK_URL')
                powershell "Invoke-WebRequest -Uri \$slackUrl -Method Post -ContentType 'application/json' -Body '{\"text\":\"[Jenkins CI/CD] Pipeline failed for \$env:JOB_NAME@\$env:BUILD_NUMBER\"}'"
            }
        }
    }
}