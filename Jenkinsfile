pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'task-manager-api'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = 'localhost:5000'
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH = "/opt/maven/bin:${env.PATH}"
    }
    
    
    stages {
        stage('Verify Tools') {
            steps {
                echo 'Verifying installed tools...'
                sh 'java -version'
                sh 'mvn -version'
                sh 'docker --version'
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Code checked out successfully'
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
                    junit 'target/surefire-reports/*.xml'
                    publishCoverage adapters: [jacocoAdapter('target/site/jacoco/jacoco.xml')], sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
                }
            }
        }

        
        stage('Package') {
            steps {
                echo 'Packaging the application...'
                sh 'mvn package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
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
                script {
                    def image = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    docker.withRegistry('http://localhost:5000') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Running security scan...'
                sh 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $PWD:/root/.cache/ aquasec/trivy:latest image ${DOCKER_IMAGE}:${DOCKER_TAG} || true'
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                echo 'Deploying to staging environment...'
                sh '''
                    docker-compose down || true
                    docker-compose up -d
                    sleep 30
                '''
            }
        }
        
        stage('Integration Tests') {
            steps {
                echo 'Running integration tests...'
                sh '''
                    # Wait for application to be ready
                    timeout 60 bash -c 'until curl -f http://localhost:8080/api/tasks/health; do sleep 2; done'
                    
                    # Run basic API tests
                    curl -X GET http://localhost:8080/api/tasks
                    curl -X POST http://localhost:8080/api/tasks -H "Content-Type: application/json" -d '{"title":"Test Task","description":"Integration test task"}'
                '''
            }
        }
        
        stage('Performance Tests') {
            steps {
                echo 'Running performance tests...'
                sh '''
                    # Simple load test using curl
                    for i in {1..10}; do
                        curl -s http://localhost:8080/api/tasks/health &
                    done
                    wait
                    echo "Basic performance test completed"
                '''
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to production...'
                input message: 'Deploy to production?', ok: 'Deploy'
                sh '''
                    echo "Production deployment would happen here"
                    # In real scenario, this would deploy to production environment
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            sh 'docker system prune -f || true'
        }
        success {
            echo 'Pipeline completed successfully!'
            emailext (
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "Good news! The build ${env.BUILD_NUMBER} was successful.",
                to: "admin@company.com"
            )
        }
        failure {
            echo 'Pipeline failed!'
            emailext (
                subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "Bad news! The build ${env.BUILD_NUMBER} failed. Please check the logs.",
                to: "admin@company.com"
            )
        }
    }
}