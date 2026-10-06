```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME = "kajalkumarikkv/8byte-devops-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        EC2_HOST = "13.223.98.225"
    }

    stages {

        stage('Unit Tests') {
            steps {
                sh 'python3 -m unittest discover -s app -p "test_*.py"'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
                sh 'docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Docker Hub Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                            -u "$DOCKER_USERNAME" \
                            --password-stdin

                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Configure CloudWatch Agent') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} << 'EOF'

sudo dnf install -y amazon-cloudwatch-agent

sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'CONFIG'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/8byte/ec2/system",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/8byte/ec2/nginx-access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/8byte/ec2/nginx-error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CONFIG

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl restart amazon-cloudwatch-agent

sudo systemctl status amazon-cloudwatch-agent --no-pager

EOF
                    '''
                }
            }
        }

        stage('Staging Deploy') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} "
                            docker pull ${IMAGE_NAME}:${IMAGE_TAG}
                            docker rm -f 8byte-staging || true
                            docker run -d \
                                --name 8byte-staging \
                                -p 8082:8081 \
                                ${IMAGE_NAME}:${IMAGE_TAG}
                        "
                    '''
                }
            }
        }

        stage('Staging Test') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} "
                            curl -f http://localhost:8082/health
                        "
                    '''
                }
            }
        }

        stage('Production Approval') {
            steps {
                input message: 'Staging is successful. Approve production deployment?'
            }
        }

        stage('Production Deploy') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} "
                            docker pull ${IMAGE_NAME}:${IMAGE_TAG}
                            docker rm -f 8byte-production || true
                            docker run -d \
                                --name 8byte-production \
                                -p 8081:8081 \
                                ${IMAGE_NAME}:${IMAGE_TAG}
                        "
                    '''
                }
            }
        }

        stage('Production Test') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} "
                            curl -f http://localhost:8081/health
                        "
                    '''
                }
            }
        }
    }

    post {

        success {
            echo "Pipeline completed successfully."
            echo "Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "Staging deployment: SUCCESS"
            echo "Production deployment: SUCCESS"

            emailext(
                subject: "SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}",
                to: "kajalkumarikkv@gmail.com",
                body: """
Hello,

The Jenkins pipeline completed successfully.

Job: ${JOB_NAME}
Build Number: #${BUILD_NUMBER}
Status: SUCCESS

Docker Image:
${IMAGE_NAME}:${IMAGE_TAG}

Staging Deployment: SUCCESS
Staging Health Check: SUCCESS

Production Deployment: SUCCESS
Production Health Check: SUCCESS

Jenkins Build:
${BUILD_URL}

Regards,
Jenkins
"""
            )
        }

        failure {
            echo "Pipeline failed. Check the failed stage in Jenkins."

            emailext(
                subject: "FAILURE: ${JOB_NAME} #${BUILD_NUMBER}",
                to: "kajalkumarikkv@gmail.com",
                body: """
Hello,

The Jenkins pipeline has FAILED.

Job: ${JOB_NAME}
Build Number: #${BUILD_NUMBER}
Status: FAILURE

Please check the Jenkins console output.

Jenkins Build:
${BUILD_URL}

Regards,
Jenkins
"""
            )
        }
    }
}
```
