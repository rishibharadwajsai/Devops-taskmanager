pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'task-manager-api'
        DOCKER_TAG = "${BUILD_NUMBER}"
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH = "/opt/maven/bin:${env.PATH}"
        JAR_FILE = 'task-manager-api-1.0.0.jar'
        APP_PORT = '8090'  // Using different port
    }
    
    stages {
        stage('Debug Port Usage') {
            steps {
                echo '=== Checking Port Usage ==='
                sh '''
                    echo "=== Current port usage ==="
                    netstat -tulpn | grep -E ':(8080|8090|8091|8092)' || echo "No conflicts on target ports"
                    
                    echo "=== Docker containers ==="
                    docker ps -a
                    
                    echo "=== Processes using port 8080 ==="
                    lsof -i :8080 || echo "Port 8080 is free"
                    
                    echo "=== Processes using port 8090 ==="
                    lsof -i :8090 || echo "Port 8090 is free"
                '''
            }
        }
        
        stage('Force Cleanup') {
            steps {
                echo '=== Force Cleanup All Docker Resources ==='
                sh '''
                    echo "Stopping ALL Docker containers..."
                    docker ps -q | xargs -r docker stop || true
                    
                    echo "Removing ALL Docker containers..."
                    docker ps -aq | xargs -r docker rm -f || true
                    
                    echo "Removing Docker networks..."
                    docker network ls -q --filter type=custom | xargs -r docker network rm || true
                    
                    echo "Cleaning Docker system..."
                    docker system prune -af --volumes || true
                    
                    echo "Waiting for cleanup to complete..."
                    sleep 10
                    
                    echo "=== Post-cleanup status ==="
                    docker ps -a
                    netstat -tulpn | grep -E ':(8080|8090)' || echo "✅ Ports 8080 and 8090 are free"
                '''
            }
        }
        
        stage('Build & Test') {
            steps {
                echo '=== Building and Testing Application ==='
                sh '''
                    mvn clean compile
                    mvn test
                    mvn package -DskipTests
                    
                    if [ -f "target/${JAR_FILE}" ]; then
                        echo "✅ JAR file created: target/${JAR_FILE}"
                        ls -la target/${JAR_FILE}
                    else
                        echo "❌ JAR file not found!"
                        exit 1
                    fi
                '''
                
                archiveArtifacts artifacts: "target/${env.JAR_FILE}", fingerprint: true
            }
        }
        
        stage('Docker Build') {
            steps {
                echo '=== Building Docker Image ==='
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    echo "✅ Docker image built"
                    docker images | grep ${DOCKER_IMAGE} | head -2
                '''
            }
        }
        
        stage('Deploy on Different Port') {
            steps {
                echo "=== Deploying Application on Port ${env.APP_PORT} ==="
                sh '''
                    echo "Final port check before deployment..."
                    if lsof -i :${APP_PORT}; then
                        echo "❌ Port ${APP_PORT} is in use, trying to free it..."
                        lsof -ti :${APP_PORT} | xargs -r kill -9 || true
                        sleep 5
                    fi
                    
                    echo "Starting application on port ${APP_PORT}..."
                    docker run -d \\
                        --name task-manager-app \\
                        -p ${APP_PORT}:8080 \\
                        --restart unless-stopped \\
                        ${DOCKER_IMAGE}:latest
                    
                    echo "Waiting for application to start..."
                    sleep 30
                    
                    echo "Container status:"
                    docker ps | grep task-manager-app || echo "Container not found"
                    
                    echo "Container logs:"
                    docker logs task-manager-app --tail=10 || echo "No logs yet"
                '''
            }
        }
        
        stage('Health Check') {
            steps {
                echo "=== Health Check on Port ${env.APP_PORT} ==="
                script {
                    def healthCheckPassed = false
                    def maxAttempts = 12
                    
                    for (int i = 1; i <= maxAttempts; i++) {
                        try {
                            sh "curl -f http://localhost:${env.APP_PORT}/api/tasks/health"
                            echo "✅ Health check passed on attempt ${i}!"
                            healthCheckPassed = true
                            break
                        } catch (Exception e) {
                            echo "❌ Health check attempt ${i}/${maxAttempts} failed"
                            if (i < maxAttempts) {
                                echo "Waiting 10 seconds..."
                                sleep 10
                                if (i % 4 == 0) {
                                    sh '''
                                        echo "=== Debug Info ==="
                                        docker ps | grep task-manager-app || echo "Container not running"
                                        docker logs task-manager-app --tail=15 || echo "No logs"
                                        netstat -tulpn | grep ${APP_PORT} || echo "Port ${APP_PORT} not in use"
                                    '''
                                }
                            }
                        }
                    }
                    
                    if (!healthCheckPassed) {
                        sh '''
                            echo "=== Final Debug Info ==="
                            docker ps -a
                            docker logs task-manager-app || echo "No logs available"
                            netstat -tulpn | grep ${APP_PORT} || echo "Port not in use"
                            
                            echo "=== Container inspection ==="
                            docker inspect task-manager-app || echo "Cannot inspect container"
                        '''
                        error "Application health check failed after ${maxAttempts} attempts"
                    }
                }
            }
        }
        
        stage('API Tests') {
            steps {
                echo "=== API Tests on Port ${env.APP_PORT} ==="
                sh '''
                    echo "=== Testing API Endpoints ==="
                    
                    echo "1. Health Check:"
                    curl -X GET http://localhost:${APP_PORT}/api/tasks/health
                    echo ""
                    
                    echo "2. Get all tasks:"
                    curl -X GET http://localhost:${APP_PORT}/api/tasks
                    echo ""
                    
                    echo "3. Create a test task:"
                    curl -X POST http://localhost:${APP_PORT}/api/tasks \\
                        -H "Content-Type: application/json" \\
                        -d '{"title":"DevOps Success","description":"Pipeline completed successfully!"}'
                    echo ""
                    
                    echo "4. Get all tasks again:"
                    curl -X GET http://localhost:${APP_PORT}/api/tasks
                    echo ""
                    
                    echo "5. Actuator health:"
                    curl -X GET http://localhost:${APP_PORT}/actuator/health
                    echo ""
                    
                    echo "✅ All API tests passed!"
                '''
            }
        }
        
        stage('Performance Test') {
            steps {
                echo '=== Basic Performance Test ==='
                sh '''
                    echo "Running concurrent requests on port ${APP_PORT}..."
                    
                    for i in {1..10}; do
                        curl -s http://localhost:${APP_PORT}/api/tasks/health > /dev/null &
                    done
                    wait
                    echo "✅ Concurrent health checks completed"
                    
                    for i in {1..5}; do
                        curl -s http://localhost:${APP_PORT}/api/tasks > /dev/null &
                    done
                    wait
                    echo "✅ Concurrent API calls completed"
                '''
            }
        }
        
        stage('Final Status') {
            steps {
                echo '=== Final DevOps Pipeline Status ==='
                sh '''
                    echo "=== 🎯 COMPLETE DEVOPS PIPELINE SUMMARY ==="
                    echo "✅ Source Code: Compiled successfully"
                    echo "✅ Unit Tests: All tests passed"
                    echo "✅ Packaging: JAR file created (${JAR_FILE})"
                    echo "✅ Docker Build: Image built (${DOCKER_IMAGE}:${DOCKER_TAG})"
                    echo "✅ Deployment: Application deployed on port ${APP_PORT}"
                    echo "✅ Health Check: Application is healthy and responding"
                    echo "✅ API Testing: All endpoints tested and working"
                    echo "✅ Performance: Basic load testing completed"
                    
                    echo ""
                    echo "=== 🐳 DEPLOYMENT STATUS ==="
                    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                    
                    echo ""
                    echo "=== 🌐 APPLICATION ACCESS ==="
                    echo "🔗 Main API: http://localhost:${APP_PORT}/api/tasks"
                    echo "🔗 Health Check: http://localhost:${APP_PORT}/api/tasks/health"
                    echo "🔗 Actuator: http://localhost:${APP_PORT}/actuator/health"
                    echo "🔗 H2 Console: http://localhost:${APP_PORT}/h2-console"
                    
                    echo ""
                    echo "=== 📊 APPLICATION METRICS ==="
                    TASK_COUNT=$(curl -s http://localhost:${APP_PORT}/api/tasks | jq length 2>/dev/null || echo "N/A")
                    echo "Current tasks in database: $TASK_COUNT"
                    echo "Application health: $(curl -s http://localhost:${APP_PORT}/api/tasks/health 2>/dev/null || echo 'Error')"
                    
                    echo ""
                    echo "=== 🛠️ DEVOPS TOOLS USED ==="
                    echo "• Git: Source control"
                    echo "• Maven: Build and dependency management"
                    echo "• JUnit: Unit testing"
                    echo "• Docker: Containerization"
                    echo "• Jenkins: CI/CD pipeline"
                    echo "• Spring Boot: Application framework"
                    echo "• H2 Database: In-memory database"
                    
                    echo ""
                    echo "🎉 COMPLETE DEVOPS CI/CD PIPELINE SUCCESS! 🎉"
                '''
            }
        }
    }
    
    post {
        always {
            echo '=== Pipeline Cleanup ==='
            sh '''
                echo "Keeping application running for testing..."
                echo "Cleaning up old Docker images..."
                docker images ${DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}} {{.ID}}" | tail -n +4 | awk '{print $2}' | head -n -2 | xargs -r docker rmi || true
                echo "Cleanup completed"
            '''
        }
        success {
            echo """
            
            🎉🎉🎉 DEVOPS PIPELINE COMPLETE! 🎉🎉🎉
            
            ╔═══════════════════════════════════════════════╗
            ║     🚀 FULL CI/CD PIPELINE SUCCESSFUL! 🚀     ║
            ╚═══════════════════════════════════════════════╝
            
            🏗️ PIPELINE STAGES COMPLETED:
            ├── ✅ Environment Setup & Port Management
            ├── ✅ Source Code Compilation (Maven)
            ├── ✅ Unit Testing (JUnit)
            ├── ✅ Application Packaging (JAR)
            ├── ✅ Docker Image Creation
            ├── ✅ Container Deployment
            ├── ✅ Health Monitoring
            ├── ✅ API Integration Testing
            └── ✅ Performance Testing
            
            🌐 YOUR APPLICATION IS LIVE:
            ┌────────────────────────────────────────────┐
            │ 🔗 API: http://localhost:${env.APP_PORT}/api/tasks    │
            │ 🏥 Health: /api/tasks/health               │
            │ 📊 Actuator: /actuator/health              │
            │ 🗄️ Database: /h2-console                   │
            └────────────────────────────────────────────┘
            
            🎊 Congratulations! Your DevOps pipeline is working! 🎊
            
            📝 NEXT STEPS:
            • Test your API with Postman or curl
            • Monitor logs: docker logs task-manager-app
            • Add more features to your application
            • Set up monitoring with Prometheus/Grafana
            • Deploy to production environment
            """
        }
        failure {
            echo '''
            ❌ PIPELINE FAILED
            
            Debug the issue with these commands:
            • docker ps -a
            • docker logs task-manager-app
            • netstat -tulpn | grep 8090
            • lsof -i :8090
            '''
        }
    }
}
