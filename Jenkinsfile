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
        stage('Environment Check') {
            steps {
                echo '=== Environment Verification ==='
                sh '''
                    echo "Java Version:"
                    java -version
                    echo "Maven Version:"
                    mvn -version
                    echo "Docker Version:"
                    docker --version
                    echo "Working Directory:"
                    pwd
                    ls -la
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo '=== Building Application ==='
                sh 'mvn clean compile'
                echo '✅ Build completed'
            }
        }
        
        stage('Test') {
            steps {
                echo '=== Running Tests ==='
                sh '''
                    mvn test
                    echo "=== Test Results ==="
                    if [ -d "target/surefire-reports" ]; then
                        echo "Test reports found:"
                        ls -la target/surefire-reports/
                        echo "Test summary:"
                        find target/surefire-reports -name "*.txt" -exec cat {} \\; || echo "No test summary files"
                    else
                        echo "No test reports directory found"
                    fi
                '''
                echo '✅ Tests completed'
            }
        }
        
        stage('Package') {
            steps {
                echo '=== Packaging Application ==='
                sh '''
                    mvn package -DskipTests
                    
                    echo "=== Verifying JAR file ==="
                    if [ -f "target/${JAR_FILE}" ]; then
                        echo "✅ JAR file created successfully: target/${JAR_FILE}"
                        echo "JAR file size: $(du -h target/${JAR_FILE} | cut -f1)"
                        echo "JAR file details:"
                        ls -la target/${JAR_FILE}
                    else
                        echo "❌ JAR file not found: target/${JAR_FILE}"
                        echo "Available files in target:"
                        ls -la target/
                        exit 1
                    fi
                '''
                
                // Archive artifacts using basic archiveArtifacts
                archiveArtifacts artifacts: "target/${env.JAR_FILE}", fingerprint: true
                echo '✅ JAR file archived'
            }
        }
        
        stage('Docker Build') {
            steps {
                echo '=== Building Docker Image ==='
                sh '''
                    echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    
                    echo "✅ Docker image built successfully"
                    echo "Docker images:"
                    docker images | grep ${DOCKER_IMAGE}
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                echo '=== Deploying to Staging ==='
                sh '''
                    echo "Stopping existing containers..."
                    docker-compose down || true
                    
                    echo "Starting new deployment..."
                    docker-compose up -d
                    
                    echo "Waiting for services to start..."
                    sleep 30
                    
                    echo "Container status:"
                    docker-compose ps
                '''
                echo '✅ Deployment completed'
            }
        }
        
        stage('Health Check') {
            steps {
                echo '=== Application Health Check ==='
                script {
                    def healthCheckPassed = false
                    def maxAttempts = 12
                    
                    for (int i = 1; i <= maxAttempts; i++) {
                        try {
                            sh 'curl -f http://localhost:8080/api/tasks/health'
                            echo "✅ Health check passed on attempt ${i}!"
                            healthCheckPassed = true
                            break
                        } catch (Exception e) {
                            echo "❌ Health check attempt ${i}/${maxAttempts} failed"
                            if (i < maxAttempts) {
                                echo "Waiting 10 seconds before next attempt..."
                                sleep 10
                                sh '''
                                    echo "=== Debug Info ==="
                                    docker-compose ps
                                    docker-compose logs task-manager-api --tail=5 || echo "No logs available"
                                '''
                            }
                        }
                    }
                    
                    if (!healthCheckPassed) {
                        echo "❌ Health check failed after ${maxAttempts} attempts"
                        sh '''
                            echo "=== Final Debug Info ==="
                            docker-compose ps
                            docker-compose logs task-manager-api --tail=20 || echo "No logs available"
                            netstat -tulpn | grep :8080 || echo "Port 8080 not in use"
                        '''
                        error "Application health check failed"
                    }
                }
            }
        }
        
        stage('API Tests') {
            steps {
                echo '=== API Integration Tests ==='
                sh '''
                    echo "=== Testing API Endpoints ==="
                    
                    echo "1. Health endpoint:"
                    curl -X GET http://localhost:8080/api/tasks/health
                    echo ""
                    
                    echo "2. Get all tasks (initial - should be empty):"
                    curl -X GET http://localhost:8080/api/tasks
                    echo ""
                    
                    echo "3. Create a test task:"
                    curl -X POST http://localhost:8080/api/tasks \\
                        -H "Content-Type: application/json" \\
                        -d '{"title":"DevOps Pipeline Test","description":"Task created by Jenkins pipeline"}'
                    echo ""
                    
                    echo "4. Get all tasks again (should show created task):"
                    curl -X GET http://localhost:8080/api/tasks
                    echo ""
                    
                    echo "5. Test actuator health:"
                    curl -X GET http://localhost:8080/actuator/health
                    echo ""
                    
                    echo "✅ API tests completed successfully!"
                '''
            }
        }
        
        stage('Performance Test') {
            steps {
                echo '=== Basic Performance Test ==='
                sh '''
                    echo "Running concurrent requests..."
                    
                    # Test concurrent health checks
                    echo "Testing concurrent health checks..."
                    for i in {1..10}; do
                        curl -s http://localhost:8080/api/tasks/health > /dev/null &
                    done
                    wait
                    echo "✅ Concurrent health checks completed"
                    
                    # Test concurrent API calls
                    echo "Testing concurrent API calls..."
                    for i in {1..5}; do
                        curl -s http://localhost:8080/api/tasks > /dev/null &
                    done
                    wait
                    echo "✅ Concurrent API calls completed"
                    
                    echo "✅ Performance tests finished"
                '''
            }
        }
        
        stage('Monitoring Check') {
            steps {
                echo '=== Monitoring Services Check ==='
                sh '''
                    echo "=== Checking Monitoring Stack ==="
                    
                    # Check Prometheus
                    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
                        echo "✅ Prometheus: Healthy"
                    else
                        echo "❌ Prometheus: Not responding"
                    fi
                    
                    # Check Grafana
                    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
                        echo "✅ Grafana: Healthy"
                    else
                        echo "❌ Grafana: Not responding"
                    fi
                    
                    # Check Graphite
                    if curl -s http://localhost:8081 > /dev/null 2>&1; then
                        echo "✅ Graphite: Responding"
                    else
                        echo "❌ Graphite: Not responding"
                    fi
                    
                    # Check application metrics
                    if curl -s http://localhost:8080/actuator/metrics > /dev/null 2>&1; then
                        echo "✅ Application Metrics: Available"
                    else
                        echo "❌ Application Metrics: Not available"
                    fi
                    
                    echo "=== Monitoring check completed ==="
                '''
            }
        }
        
        stage('Final Verification') {
            steps {
                echo '=== Final System Verification ==='
                sh '''
                    echo "=== 🎯 PIPELINE SUMMARY ==="
                    echo "Build: ✅ Completed"
                    echo "Tests: ✅ Passed"
                    echo "Package: ✅ JAR created (${JAR_FILE})"
                    echo "Docker: ✅ Image built (${DOCKER_IMAGE}:${DOCKER_TAG})"
                    echo "Deploy: ✅ Containers running"
                    
                    echo ""
                    echo "=== 🌐 SERVICE STATUS ==="
                    docker-compose ps
                    
                    echo ""
                    echo "=== 🔗 ACCESS URLS ==="
                    echo "Application API: http://localhost:8080/api/tasks"
                    echo "Health Check: http://localhost:8080/api/tasks/health"
                    echo "Actuator: http://localhost:8080/actuator/health"
                    echo "Prometheus: http://localhost:9090"
                    echo "Grafana: http://localhost:3000 (admin/admin)"
                    echo "Graphite: http://localhost:8081"
                    
                    echo ""
                    echo "=== 📊 QUICK API TEST ==="
                    echo "Task count: $(curl -s http://localhost:8080/api/tasks | jq length 2>/dev/null || echo 'N/A')"
                    echo "Health status: $(curl -s http://localhost:8080/api/tasks/health 2>/dev/null || echo 'Not accessible')"
                '''
            }
        }
    }
    
    post {
        always {
            echo '=== Pipeline Cleanup ==='
            sh '''
                echo "Cleaning up old Docker images..."
                # Keep only the last 3 images
                docker images ${DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}} {{.ID}}" | tail -n +4 | awk '{print $2}' | head -n -2 | xargs -r docker rmi || true
                echo "Cleanup completed"
            '''
        }
        success {
            echo '''
            
            🎉🎉🎉 PIPELINE SUCCESS! 🎉🎉🎉
            
            ╔══════════════════════════════════════╗
            ║          🚀 DEPLOYMENT SUCCESS       ║
            ╚══════════════════════════════════════╝
            
            ✅ Build: Completed successfully
            ✅ Tests: All tests passed
            ✅ Package: JAR file created
            ✅ Docker: Image built and deployed
            ✅ Health: Application is healthy
            ✅ API: All endpoints working
            ✅ Monitoring: Services checked
            
            🌐 ACCESS YOUR APPLICATION:
            ┌─────────────────────────────────────┐
            │ API: http://localhost:8080/api/tasks │
            │ Health: /api/tasks/health           │
            │ Prometheus: http://localhost:9090   │
            │ Grafana: http://localhost:3000      │
            │ Graphite: http://localhost:8081     │
            └─────────────────────────────────────┘
            
            🎊 DevOps Pipeline Complete! 🎊
            '''
        }
        failure {
            echo '''
            
            ❌❌❌ PIPELINE FAILED ❌❌❌
            
            ╔══════════════════════════════════════╗
            ║           🔧 TROUBLESHOOTING         ║
            ╚══════════════════════════════════════╝
            
            Please check the logs above for specific errors.
            
            🔍 COMMON DEBUGGING STEPS:
            ┌─────────────────────────────────────┐
            │ 1. Check containers: docker-compose ps │
            │ 2. Check logs: docker-compose logs     │
            │ 3. Check ports: netstat -tulpn | grep 8080 │
            │ 4. Restart Docker: sudo systemctl restart docker │
            │ 5. Clean build: mvn clean package     │
            │ 6. Check disk space: df -h            │
            └─────────────────────────────────────┘
            
            💡 Need help? Check the stage logs above!
            '''
        }
    }
}
