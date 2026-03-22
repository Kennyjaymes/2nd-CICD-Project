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
                    sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] Terraform stage started for ${env.JOB_NAME}@${env.BUILD_NUMBER}\"}' ${SLACK_WEBHOOK_URL}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -input=false -auto-approve tfplan'
                }
            }
        }

        stage('Set Outputs') {
            steps {
                dir('terraform') {
                    script {
                        env.ECR_URL = sh(script: 'terraform output -raw ecr_repository_url', returnStdout: true).trim()
                        env.EKS_CLUSTER = sh(script: 'terraform output -raw eks_cluster_name', returnStdout: true).trim()
                        env.EKS_ENDPOINT = sh(script: 'terraform output -raw eks_cluster_endpoint', returnStdout: true).trim()
                        env.EC2_IP = sh(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Notify Slack - Terraform Success') {
            steps {
                script {
                    sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] Terraform succeed. ECR: ${env.ECR_URL}, EKS cluster: ${env.EKS_CLUSTER}\"}' ${SLACK_WEBHOOK_URL}"
                }
            }
        }

        stage('Notify Slack - Build Start') {
            steps {
                script {
                    sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] Docker build+push started.\"}' ${SLACK_WEBHOOK_URL}"
                }
            }
        }

        stage('Login to ECR') {
            steps {
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${env.ECR_URL}"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${env.ECR_URL}:latest ."
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker push ${env.ECR_URL}:latest"
            }
        }

        stage('Notify Slack - Build Success') {
            steps {
                script {
                    sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] Docker image pushed to ${env.ECR_URL}\"}' ${SLACK_WEBHOOK_URL}"
                }
            }
        }

        stage('Notify Slack - EKS Deploy Start') {
            steps {
                script {
                    sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] EKS deploy started\"}' ${SLACK_WEBHOOK_URL}"
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                sh "aws eks update-kubeconfig --name ${env.EKS_CLUSTER} --region ${AWS_REGION}"
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh "sed -e 's|REPLACE_WITH_IMAGE|${env.ECR_URL}:latest|g' k8s-deployment.yaml > k8s-deployment-rendered.yaml"
                sh "kubectl apply -f k8s-deployment-rendered.yaml"
            }
        }

        stage('Notify Slack - EKS Success') {
            steps {
                script {
                    sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] EKS deployment complete\"}' ${SLACK_WEBHOOK_URL}"
                }
            }
        }

        stage('Verify EC2') {
            steps {
                script {
                    def response = sh(script: "curl -s -o /dev/null -w '%{http_code}' --retry 5 --retry-delay 10 --max-time 10 http://${env.EC2_IP} || echo '000'", returnStdout: true).trim()
                    if (response == '200') {
                        sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] EC2 app reachable at http://${env.EC2_IP}\"}' ${SLACK_WEBHOOK_URL}"
                    } else {
                        sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] EC2 app unreachable (code=${response}) at http://${env.EC2_IP}\"}' ${SLACK_WEBHOOK_URL}"
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                def slackUrl = credentials('SLACK_WEBHOOK_URL')
                sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] Pipeline completed successfully for ${env.JOB_NAME}@${env.BUILD_NUMBER}\"}' ${slackUrl}"
            }
        }
        failure {
            script {
                def slackUrl = credentials('SLACK_WEBHOOK_URL')
                sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"[Jenkins CI/CD] Pipeline failed for ${env.JOB_NAME}@${env.BUILD_NUMBER}\"}' ${slackUrl}"
            }
        }
    }
}