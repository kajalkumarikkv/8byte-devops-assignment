```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME = "kajalkumarikkv/8byte-devops-app"
        IMAGE_TAG  = "${BUILD_NUMBER}"
        EC2_HOST   = "13.223.98.225"
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
        }

        failure {
            echo "Pipeline failed. Check the failed stage in Jenkins."
        }
    }
}

