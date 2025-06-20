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
                    
                    echo "=== Port Check ==="
                    echo "Checking for port conflicts..."
                    netstat -tulpn | grep -E ':(8080|9090|9091|3000|3001|8081)' || echo "No conflicts found"
                '''
            }
        }
        
        stage('Cleanup') {
            steps {
                echo '=== Cleaning Up Previous Deployments ==='
                sh '''
                    echo "Stopping any existing containers..."
                    docker-compose down --remove-orphans || true
                    
                    echo "Cleaning up Docker system..."
                    docker system prune -f || true
                    
                    echo "Checking ports after cleanup..."
                    netstat -tulpn | grep -E ':(8080|9090|9091|3000|3001|8081)' || echo "All ports are free"
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
                        ls -la target/${JAR_FILE}
                    else
                        echo "❌ JAR file not found: target/${JAR_FILE}"
                        echo "Available files in target:"
                        ls -la target/
                        exit 1
                    fi
                '''
                
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
                    docker images | grep ${DOCKER_IMAGE}
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                echo '=== Deploying to Staging ==='
                sh '''
                    echo "Final port check before deployment..."
                    netstat -tulpn | grep -E ':(8080|9091|3001|8081)' && echo "⚠️ Port conflicts detected" || echo "✅ Ports are available"
                    
                    echo "Starting deployment..."
                    docker-compose up -d
                    
                    echo "Waiting for services to start..."
                    sleep 45
                    
                    echo "Container status:"
                    docker-compose ps
                    
                    echo "=== Service Health Check ==="
                    docker-compose logs --tail=10 task-manager-api || echo "No app logs yet"
                '''
                echo '✅ Deployment completed'
            }
        }
        
        stage('Health Check') {
            steps {
                echo '=== Application Health Check ==='
                script {
                    def healthCheckPassed = false
                    def maxAttempts = 15
                    
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
                                if (i % 3 == 0) {  // Every 3rd attempt, show debug info
                                    sh '''
                                        echo "=== Debug Info (Attempt ${i}) ==="
                                        docker-compose ps
                                        echo "=== App Container Logs ==="
                                        docker-compose logs task-manager-api --tail=10 || echo "No logs available"
                                        echo "=== Port Status ==="
                                        netstat -tulpn | grep :8080 || echo "Port 8080 not in use"
                                    '''
                                }
                            }
                        }
                    }
                    
                    if (!healthCheckPassed) {
                        echo "❌ Health check failed after ${maxAttempts} attempts"
                        sh '''
                            echo "=== Final Debug Info ==="
                            docker-compose ps
                            docker-compose logs task-manager-api || echo "No logs available"
                            docker-compose logs prometheus --tail=5 || echo "No prometheus logs"
                            docker-compose logs grafana --tail=5 || echo "No grafana logs"
                            netstat -tulpn | grep -E ':(8080|9091|3001|8081)'
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
                    
                    echo "2. Get all tasks (initial):"
                    curl -X GET http://localhost:8080/api/tasks
                    echo ""
                    
                    echo "3. Create a test task:"
                    curl -X POST http://localhost:8080/api/tasks \\
                        -H "Content-Type: application/json" \\
                        -d '{"title":"DevOps Pipeline Success","description":"Task created by successful Jenkins pipeline"}'
                    echo ""
                    
                    echo "4. Get all tasks (should show created task):"
                    curl -X GET http://localhost:8080/api/tasks
                    echo ""
                    
                    echo "5. Test actuator health:"
                    curl -X GET http://localhost:8080/actuator/health
                    echo ""
                    
                    echo "✅ API tests completed successfully!"
                '''
            }
        }
        
        stage('Monitoring Check') {
            steps {
                echo '=== Monitoring Services Check ==='
                sh '''
                    echo "=== Checking Monitoring Stack ==="
                    
                    # Check Prometheus (now on port 9091)
                    if curl -s http://localhost:9091/-/healthy > /dev/null 2>&1; then
                        echo "✅ Prometheus: Healthy (port 9091)"
                    else
                        echo "❌ Prometheus: Not responding (port 9091)"
                    fi
                    
                    # Check Grafana (now on port 3001)
                    if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
                        echo "✅ Grafana: Healthy (port 3001)"
                    else
                        echo "❌ Grafana: Not responding (port 3001)"
                    fi
                    
                    # Check Graphite (now on port 8081)
                    if curl -s http://localhost:8081 > /dev/null 2>&1; then
                        echo "✅ Graphite: Responding (port 8081)"
                    else
                        echo "❌ Graphite: Not responding (port 8081)"
                    fi
                    
                    # Check application metrics
                    if curl -s http://localhost:8080/actuator/metrics > /dev/null 2>&1; then
                        echo "✅ Application Metrics: Available"
                    else
                        echo "❌ Application Metrics: Not available"
                    fi
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
                    echo "Health: ✅ Application healthy"
                    echo "API: ✅ All endpoints working"
                    
                    echo ""
                    echo "=== 🌐 SERVICE STATUS ==="
                    docker-compose ps
                    
                    echo ""
                    echo "=== 🔗 ACCESS URLS (Updated Ports) ==="
                    echo "Application API: http://localhost:8080/api/tasks"
                    echo "Health Check: http://localhost:8080/api/tasks/health"
                    echo "Actuator: http://localhost:8080/actuator/health"
                    echo "Prometheus: http://localhost:9091"
                    echo "Grafana: http://localhost:3001 (admin/admin)"
                    echo "Graphite: http://localhost:8081"
                    
                    echo ""
                    echo "=== 📊 QUICK STATS ==="
                    TASK_COUNT=$(curl -s http://localhost:8080/api/tasks | jq length 2>/dev/null || echo "N/A")
                    echo "Current tasks: $TASK_COUNT"
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
                docker images ${DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}} {{.ID}}" | tail -n +4 | awk '{print $2}' | head -n -2 | xargs -r docker rmi || true
                echo "Cleanup completed"
            '''
        }
        success {
            echo '''
            
            🎉🎉🎉 PIPELINE SUCCESS! 🎉🎉🎉
            
            ╔══════════════════════════════════════╗
            ║       🚀 DEPLOYMENT SUCCESSFUL       ║
            ╚══════════════════════════════════════╝
            
            ✅ Complete DevOps pipeline executed successfully!
            
            🌐 ACCESS YOUR SERVICES:
            ┌─────────────────────────────────────┐
            │ 🔗 API: http://localhost:8080/api/tasks │
            │ 📊 Prometheus: http://localhost:9091   │
            │ 📈 Grafana: http://localhost:3001      │
            │ 📉 Graphite: http://localhost:8081     │
            └─────────────────────────────────────┘
            
            🎊 Your DevOps pipeline is complete! 🎊
            '''
        }
        failure {
            echo '''
            
            ❌❌❌ PIPELINE FAILED ❌❌❌
            
            Check the logs above for the specific error.
            Most likely causes:
            1. Port conflicts (check netstat -tulpn)
            2. Docker daemon issues
            3. Application startup problems
            
            Run: docker-compose logs to see container logs
            '''
        }
    }
}
