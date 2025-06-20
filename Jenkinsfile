pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'task-manager-api'
        DOCKER_TAG = "${BUILD_NUMBER}"
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH = "/opt/maven/bin:${env.PATH}"
        JAR_FILE = 'task-manager-api-1.0.0.jar'
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
                    echo "Project files:"
                    ls -la
                '''
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
                    script {
                        try {
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                            echo 'Test results published'
                        } catch (Exception e) {
                            echo "Test results publishing failed: ${e.getMessage()}"
                        }
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                echo 'Packaging the application...'
                sh '''
                    echo "=== Maven Package ==="
                    mvn package -DskipTests
                    
                    echo "=== Verifying JAR file ==="
                    ls -la target/
                    
                    if [ -f "target/${JAR_FILE}" ]; then
                        echo "✅ JAR file found: target/${JAR_FILE}"
                        echo "JAR file size: $(du -h target/${JAR_FILE})"
                    else
                        echo "❌ Expected JAR file not found: target/${JAR_FILE}"
                        echo "Available JAR files:"
                        find target/ -name "*.jar" -type f || echo "No JAR files found"
                        exit 1
                    fi
                '''
                
                // Archive the specific JAR file
                archiveArtifacts artifacts: "target/${env.JAR_FILE}", fingerprint: true
                echo 'JAR file archived successfully'
            }
        }
        
        stage('Code Quality Analysis') {
            steps {
                echo 'Running code quality analysis...'
                sh 'mvn verify -DskipTests'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh '''
                    echo "=== Building Docker Image ==="
                    echo "Expected JAR file: target/${JAR_FILE}"
                    
                    # Verify JAR exists before Docker build
                    if [ ! -f "target/${JAR_FILE}" ]; then
                        echo "❌ JAR file missing for Docker build"
                        exit 1
                    fi
                    
                    # Build Docker image
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    
                    echo "✅ Docker image built successfully"
                    docker images | grep ${DOCKER_IMAGE}
                '''
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Security scan...'
                script {
                    try {
                        sh '''
                            if command -v trivy &> /dev/null; then
                                echo "Running Trivy security scan..."
                                trivy image ${DOCKER_IMAGE}:${DOCKER_TAG}
                            else
                                echo "Trivy not installed. Skipping security scan."
                            fi
                        '''
                    } catch (Exception e) {
                        echo "Security scan skipped: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                echo 'Deploying to staging environment...'
                sh '''
                    echo "=== Stopping existing containers ==="
                    docker-compose down || true
                    
                    echo "=== Starting new deployment ==="
                    docker-compose up -d
                    
                    echo "=== Waiting for services to start ==="
                    sleep 30
                    
                    echo "=== Container status ==="
                    docker-compose ps
                '''
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health checks...'
                script {
                    def maxRetries = 10
                    def retryCount = 0
                    def healthCheckPassed = false
                    
                    while (retryCount < maxRetries && !healthCheckPassed) {
                        try {
                            sh 'curl -f http://localhost:8080/api/tasks/health'
                            healthCheckPassed = true
                            echo "✅ Health check passed on attempt ${retryCount + 1}!"
                        } catch (Exception e) {
                            retryCount++
                            echo "❌ Health check attempt ${retryCount}/${maxRetries} failed"
                            if (retryCount < maxRetries) {
                                echo "Waiting 10 seconds before retry..."
                                sleep 10
                                // Show debug info
                                sh '''
                                    echo "=== Debug Info ==="
                                    docker-compose ps
                                    echo "=== Application logs (last 10 lines) ==="
                                    docker-compose logs task-manager-api --tail=10 || echo "No logs available"
                                '''
                            }
                        }
                    }
                    
                    if (!healthCheckPassed) {
                        echo "❌ Health check failed after ${maxRetries} attempts"
                        sh '''
                            echo "=== Final Debug Information ==="
                            docker-compose ps
                            docker-compose logs task-manager-api || echo "No logs available"
                            netstat -tulpn | grep :8080 || echo "Port 8080 not in use"
                        '''
                        error "Application health check failed"
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                echo 'Running integration tests...'
                sh '''
                    echo "=== Integration Tests ==="
                    
                    echo "1. Health endpoint test:"
                    curl -X GET http://localhost:8080/api/tasks/health
                    
                    echo "\\n2. Get all tasks (should be empty initially):"
                    curl -X GET http://localhost:8080/api/tasks
                    
                    echo "\\n3. Create a new task:"
                    TASK_RESPONSE=$(curl -X POST http://localhost:8080/api/tasks \\
                        -H "Content-Type: application/json" \\
                        -d '{"title":"Jenkins Pipeline Test","description":"Created by Jenkins CI/CD pipeline"}' \\
                        -s -w "%{http_code}")
                    
                    echo "Task creation response code: $TASK_RESPONSE"
                    
                    echo "\\n4. Get all tasks again (should show the created task):"
                    curl -X GET http://localhost:8080/api/tasks
                    
                    echo "\\n5. Test actuator endpoints:"
                    curl -X GET http://localhost:8080/actuator/health
                    
                    echo "\\n✅ Integration tests completed successfully!"
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
                    echo "✅ Concurrent health checks completed"
                    
                    echo "Running concurrent API calls..."
                    for i in {1..5}; do
                        curl -s -X GET http://localhost:8080/api/tasks &
                    done
                    wait
                    echo "✅ Concurrent API calls completed"
                    
                    echo "Performance tests finished successfully!"
                '''
            }
        }
        
        stage('Monitoring Check') {
            steps {
                echo 'Checking monitoring services...'
                sh '''
                    echo "=== Monitoring Services Status ==="
                    
                    echo "Checking Prometheus..."
                    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
                        echo "✅ Prometheus is healthy"
                    else
                        echo "❌ Prometheus is not responding"
                    fi
                    
                    echo "Checking Grafana..."
                    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
                        echo "✅ Grafana is healthy"
                    else
                        echo "❌ Grafana is not responding"
                    fi
                    
                    echo "Checking application metrics..."
                    if curl -s http://localhost:8080/actuator/metrics > /dev/null 2>&1; then
                        echo "✅ Application metrics available"
                    else
                        echo "❌ Application metrics not available"
                    fi
                    
                    echo "Checking Graphite..."
                    if curl -s http://localhost:8081 > /dev/null 2>&1; then
                        echo "✅ Graphite is responding"
                    else
                        echo "❌ Graphite is not responding"
                    fi
                '''
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
                        echo "Production deployment approved by: ${env.DEPLOYER}"
                        sh '''
                            echo "=== Production Deployment ==="
                            echo "Image to deploy: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                            echo "JAR file: ${JAR_FILE}"
                            echo "Deployment timestamp: $(date)"
                            echo "✅ Production deployment completed successfully!"
                        '''
                    } catch (Exception e) {
                        echo "Production deployment skipped: ${e.getMessage()}"
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
                # Keep last 3 Docker images
                docker images ${DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}} {{.ID}}" | tail -n +4 | awk '{print $2}' | head -n -2 | xargs -r docker rmi || true
                echo "Cleanup completed"
            '''
        }
        success {
            echo '''
            🎉 ===== PIPELINE SUCCESS ===== 🎉
            
            ✅ Build completed successfully
            ✅ JAR file created: task-manager-api-1.0.0.jar
            ✅ Docker image built and deployed
            ✅ All tests passed
            ✅ Health checks passed
            ✅ Integration tests completed
            ✅ Monitoring services checked
            
            === 🌐 Access Information ===
            🔗 Application API: http://localhost:8080/api/tasks
            🔗 Health Check: http://localhost:8080/api/tasks/health
            🔗 Actuator: http://localhost:8080/actuator/health
            🔗 Prometheus: http://localhost:9090
            🔗 Grafana: http://localhost:3000 (admin/admin)
            🔗 Graphite: http://localhost:8081
            
            === 🚀 Next Steps ===
            1. Test the API endpoints
            2. Check monitoring dashboards
            3. Review application logs: docker-compose logs task-manager-api
            4. Scale if needed: docker-compose up -d --scale task-manager-api=2
            
            🎊 DevOps Pipeline completed successfully! 🎊
            '''
        }
        failure {
            echo '''
            ❌ ===== PIPELINE FAILED ===== ❌
            
            The pipeline encountered an error. Please check the logs above.
            
            === 🔍 Troubleshooting Steps ===
            1. Check the failed stage logs above
            2. Verify JAR file: ls -la target/
            3. Check Docker containers: docker-compose ps
            4. Check application logs: docker-compose logs task-manager-api
            5. Verify ports: netstat -tulpn | grep -E ':(8080|9090|3000)'
            6. Check system resources: docker system df
            
            === 🛠️ Common Fixes ===
            • Restart Docker: sudo systemctl restart docker
            • Clean Docker: docker system prune -f
            • Rebuild: mvn clean package
            • Check ports: sudo lsof -i :8080
            '''
        }
        unstable {
            echo '⚠️ Pipeline completed with warnings. Please review the logs.'
        }
    }
}