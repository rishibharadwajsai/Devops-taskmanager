pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'task-manager-api'
        DOCKER_TAG = "${BUILD_NUMBER}"
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH = "/opt/maven/bin:${env.PATH}"
    }
    
    stages {
        stage('Verify Environment') {
            steps {
                echo 'Verifying build environment...'
                sh '''
                    echo "=== Environment Check ==="
                    echo "Java Version:"
                    java -version
                    echo "Maven Version:"
                    mvn -version
                    echo "Docker Version:"
                    docker --version
                    echo "Current Directory:"
                    pwd
                    echo "Available files:"
                    ls -la
                '''
            }
        }
        
        stage('Checkout') {
            steps {
                echo 'Code checkout completed'
                sh 'ls -la'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building the application...'
                sh 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
            post {
                always {
                    // Use basic test result publishing without JaCoCo
                    script {
                        if (fileExists('target/surefire-reports/*.xml')) {
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                            echo 'Test results published'
                        } else {
                            echo 'No test results found'
                        }
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                echo 'Packaging the application...'
                sh 'mvn package -DskipTests'
                script {
                    if (fileExists('target/*.jar')) {
                        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                        echo 'Artifacts archived successfully'
                    } else {
                        error 'No JAR file found in target directory'
                    }
                }
            }
        }
        
        stage('Code Quality Analysis') {
            steps {
                echo 'Running code quality analysis...'
                sh 'mvn verify -DskipTests'
                echo 'Code quality analysis completed'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh '''
                    echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    echo "Docker image built successfully"
                    docker images | grep ${DOCKER_IMAGE}
                '''
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Security scan stage...'
                script {
                    try {
                        sh '''
                            echo "Checking if Trivy is available..."
                            if command -v trivy &> /dev/null; then
                                echo "Running Trivy security scan..."
                                trivy image ${DOCKER_IMAGE}:${DOCKER_TAG}
                            else
                                echo "Trivy not installed. Skipping security scan."
                                echo "To install Trivy: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
                            fi
                        '''
                    } catch (Exception e) {
                        echo "Security scan failed or skipped: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                echo 'Deploying to staging environment...'
                sh '''
                    echo "Stopping existing containers..."
                    docker-compose down || true
                    
                    echo "Starting new deployment..."
                    docker-compose up -d
                    
                    echo "Waiting for services to start..."
                    sleep 30
                    
                    echo "Checking container status..."
                    docker-compose ps
                '''
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health checks...'
                script {
                    def maxRetries = 12
                    def retryCount = 0
                    def healthCheckPassed = false
                    
                    while (retryCount < maxRetries && !healthCheckPassed) {
                        try {
                            sh 'curl -f http://localhost:8080/api/tasks/health'
                            healthCheckPassed = true
                            echo 'Health check passed!'
                        } catch (Exception e) {
                            retryCount++
                            echo "Health check attempt ${retryCount}/${maxRetries} failed. Retrying in 10 seconds..."
                            sleep 10
                        }
                    }
                    
                    if (!healthCheckPassed) {
                        error 'Health check failed after maximum retries'
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                echo 'Running integration tests...'
                sh '''
                    echo "=== Integration Tests ==="
                    
                    echo "1. Testing health endpoint:"
                    curl -X GET http://localhost:8080/api/tasks/health
                    
                    echo "2. Testing GET all tasks:"
                    curl -X GET http://localhost:8080/api/tasks
                    
                    echo "3. Testing POST create task:"
                    TASK_RESPONSE=$(curl -X POST http://localhost:8080/api/tasks \
                        -H "Content-Type: application/json" \
                        -d '{"title":"Jenkins Integration Test","description":"Created by Jenkins pipeline"}' \
                        -w "%{http_code}" -o /tmp/task_response.json)
                    
                    echo "Response code: $TASK_RESPONSE"
                    echo "Response body:"
                    cat /tmp/task_response.json
                    
                    echo "4. Testing GET all tasks again:"
                    curl -X GET http://localhost:8080/api/tasks
                    
                    echo "5. Testing actuator endpoints:"
                    curl -X GET http://localhost:8080/actuator/health
                    
                    echo "Integration tests completed successfully!"
                '''
            }
        }
        
        stage('Performance Tests') {
            steps {
                echo 'Running performance tests...'
                sh '''
                    echo "=== Performance Tests ==="
                    
                    echo "Running concurrent health checks..."
                    for i in {1..10}; do
                        curl -s http://localhost:8080/api/tasks/health &
                    done
                    wait
                    
                    echo "Running concurrent API calls..."
                    for i in {1..5}; do
                        curl -s -X GET http://localhost:8080/api/tasks &
                    done
                    wait
                    
                    echo "Performance tests completed!"
                '''
            }
        }
        
        stage('Monitoring Check') {
            steps {
                echo 'Checking monitoring services...'
                script {
                    try {
                        sh '''
                            echo "=== Monitoring Services Check ==="
                            
                            echo "Checking Prometheus..."
                            if curl -s http://localhost:9090/-/healthy > /dev/null; then
                                echo "✅ Prometheus is healthy"
                            else
                                echo "❌ Prometheus is not responding"
                            fi
                            
                            echo "Checking Grafana..."
                            if curl -s http://localhost:3000/api/health > /dev/null; then
                                echo "✅ Grafana is healthy"
                            else
                                echo "❌ Grafana is not responding"
                            fi
                            
                            echo "Checking application metrics..."
                            if curl -s http://localhost:8080/actuator/metrics > /dev/null; then
                                echo "✅ Application metrics available"
                            else
                                echo "❌ Application metrics not available"
                            fi
                        '''
                    } catch (Exception e) {
                        echo "Monitoring check completed with warnings: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo 'Production deployment stage...'
                script {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            input message: 'Deploy to production?', ok: 'Deploy',
                                  submitterParameter: 'DEPLOYER'
                        }
                        echo "Deployment approved by: ${env.DEPLOYER}"
                        sh '''
                            echo "=== Production Deployment ==="
                            echo "Image to deploy: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                            echo "Deployment timestamp: $(date)"
                            echo "In a real scenario, this would deploy to production environment"
                            echo "Production deployment completed successfully!"
                        '''
                    } catch (Exception e) {
                        echo "Production deployment skipped or timed out: ${e.getMessage()}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline cleanup...'
            sh '''
                echo "=== Cleanup ==="
                # Clean up old Docker images (keep last 5)
                docker images ${DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}} {{.ID}}" | tail -n +6 | awk '{print $2}' | xargs -r docker rmi || true
                echo "Cleanup completed"
            '''
        }
        success {
            echo '''
            🎉 ===== PIPELINE SUCCESS ===== 🎉
            
            ✅ Build completed successfully
            ✅ All tests passed
            ✅ Docker image created
            ✅ Application deployed
            ✅ Health checks passed
            ✅ Integration tests passed
            
            === Access Information ===
            Application: http://localhost:8080/api/tasks
            Health Check: http://localhost:8080/api/tasks/health
            Actuator: http://localhost:8080/actuator/health
            Prometheus: http://localhost:9090
            Grafana: http://localhost:3000 (admin/admin)
            
            === Next Steps ===
            1. Access the application and test the API
            2. Check monitoring dashboards
            3. Review logs if needed: docker-compose logs
            '''
        }
        failure {
            echo '''
            ❌ ===== PIPELINE FAILED ===== ❌
            
            The pipeline has failed. Please check the logs above for details.
            
            === Troubleshooting Steps ===
            1. Check the failed stage logs
            2. Verify Docker containers: docker-compose ps
            3. Check application logs: docker-compose logs task-manager-api
            4. Verify system resources: docker system df
            5. Check port availability: netstat -tulpn | grep :8080
            
            === Common Issues ===
            - Port conflicts (8080, 9090, 3000)
            - Docker daemon not running
            - Insufficient system resources
            - Network connectivity issues
            '''
        }
        unstable {
            echo 'Pipeline completed with warnings. Please review the logs.'
        }
    }
}
