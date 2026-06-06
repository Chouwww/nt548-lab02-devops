pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'hieulab03/nt548-microservice'
        IMAGE_TAG = "v${env.BUILD_NUMBER}"
        SONAR_SERVER = 'sonar-server' 
        K8S_CREDENTIAL_ID = 'k8s-kubeconfig'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Đang tải mã nguồn từ GitHub...'
                checkout scm
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                echo 'Kiểm tra chất lượng mã nguồn...'
                withSonarQubeEnv(SONAR_SERVER) {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                    docker run --rm \
                        -v "$(pwd):/usr/src" \
                        -e SONAR_HOST_URL="http://172.31.41.248:9000" \
                        sonarsource/sonar-scanner-cli \
                        -Dsonar.projectKey=nt548-microservice \
                        -Dsonar.sources=.
                    '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Đóng gói ứng dụng thành Docker Image...'
                sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
            }
        }

        stage('Trivy Security Scan') {
            steps {
                echo 'Quét bảo mật Image với Trivy...'
                sh '''
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy image \
                    --severity HIGH,CRITICAL \
                    --no-progress \
                    --exit-code 0 \
                    ${DOCKER_IMAGE}:${IMAGE_TAG}
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Đẩy Image lên Docker Hub...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Triển khai lên cụm K3s...'
                withKubeConfig([credentialsId: K8S_CREDENTIAL_ID]) {
                    sh 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl'
                    sh "./kubectl set image -f k8s/deployment.yaml microservice=${DOCKER_IMAGE}:${IMAGE_TAG} --local -o yaml > k8s/deploy-ready.yaml"
                    sh "./kubectl apply -f k8s/deploy-ready.yaml"
                    sh "./kubectl apply -f k8s/service.yaml"
                }
            }
        }
    }
}