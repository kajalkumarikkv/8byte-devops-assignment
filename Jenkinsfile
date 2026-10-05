pipeline {
    agent any

    stages {
        stage('Unit Tests') {
            steps {
                sh 'python3 -m unittest discover -s app -p "test_*.py"'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t 8byte-devops-app:jenkins .'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL --exit-code 1 8byte-devops-app:jenkins'
            }
        }
    }
}
