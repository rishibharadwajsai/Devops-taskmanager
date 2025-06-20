# Task Manager DevOps Pipeline

A complete DevOps CI/CD pipeline implementation for a simple Task Manager REST API using Spring Boot.

## Architecture

This project demonstrates a full DevOps pipeline with the following components:

- **Application**: Spring Boot REST API for task management
- **Build Tool**: Maven
- **Version Control**: Git
- **CI/CD**: Jenkins
- **Containerization**: Docker & Docker Compose
- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible
- **Monitoring**: Prometheus, Grafana, Graphite
- **Testing**: JUnit, Integration Tests

## Features

- CRUD operations for tasks
- RESTful API endpoints
- In-memory H2 database
- Health check endpoints
- Metrics and monitoring
- Automated testing
- Docker containerization
- Complete CI/CD pipeline

## API Endpoints

- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/{id}` - Get task by ID
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task
- `GET /api/tasks/completed` - Get completed tasks
- `GET /api/tasks/pending` - Get pending tasks
- `GET /api/tasks/health` - Health check

## Quick Start

1. Run the setup script:
   \`\`\`bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   \`\`\`

2. Log out and log back in for Docker group changes

3. Build and run the application:
   \`\`\`bash
   chmod +x scripts/run-pipeline.sh
   ./scripts/run-pipeline.sh
   \`\`\`

## Manual Setup Steps

### Prerequisites
- Ubuntu 20.04+ (VirtualBox VM recommended)
- 4GB RAM minimum
- 20GB disk space

### Step-by-Step Setup

1. **Update System**
   \`\`\`bash
   sudo apt update && sudo apt upgrade -y
   \`\`\`

2. **Install Java 11**
   \`\`\`bash
   sudo apt install -y openjdk-11-jdk
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   \`\`\`

3. **Install Maven**
   \`\`\`bash
   cd /tmp
   wget https://archive.apache.org/dist/maven/maven-3/3.9.4/binaries/apache-maven-3.9.4-bin.tar.gz
   sudo tar xzf apache-maven-3.9.4-bin.tar.gz -C /opt
   sudo ln -sf /opt/apache-maven-3.9.4 /opt/maven
   export PATH=/opt/maven/bin:$PATH
   \`\`\`

4. **Install Docker**
   \`\`\`bash
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt update
   sudo apt install -y docker-ce docker-ce-cli containerd.io
   sudo usermod -aG docker $USER
   \`\`\`

5. **Install Jenkins**
   \`\`\`bash
   wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo apt-key add -
   echo "deb https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
   sudo apt update
   sudo apt install -y jenkins
   sudo systemctl start jenkins
   sudo systemctl enable jenkins
   \`\`\`

6. **Install Terraform**
   \`\`\`bash
   cd /tmp
   wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
   unzip terraform_1.5.7_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   \`\`\`

## Running the Application

### Local Development
\`\`\`bash
mvn spring-boot:run
\`\`\`

### Docker
\`\`\`bash
docker build -t task-manager-api .
docker run -p 8080:8080 task-manager-api
\`\`\`

### Docker Compose
\`\`\`bash
docker-compose up -d
\`\`\`

### Terraform
\`\`\`bash
cd terraform
terraform init
terraform apply
\`\`\`

## Testing

### Unit Tests
\`\`\`bash
mvn test
\`\`\`

### Integration Tests
\`\`\`bash
mvn verify
\`\`\`

### API Testing
\`\`\`bash
# Health check
curl http://localhost:8080/api/tasks/health

# Get all tasks
curl http://localhost:8080/api/tasks

# Create a task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Test Description"}'
\`\`\`

## Monitoring

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Graphite**: http://localhost:8081

## Jenkins Setup

1. Access Jenkins at http://localhost:8080
2. Get initial admin password:
   \`\`\`bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   \`\`\`
3. Install suggested plugins
4. Create admin user
5. Create new pipeline job
6. Use the provided Jenkinsfile

## Troubleshooting

### Maven Issues
- Ensure Java 11 is installed and JAVA_HOME is set
- Check Maven installation and PATH
- Clear Maven cache: `rm -rf ~/.m2/repository`

### Docker Issues
- Ensure user is in docker group: `sudo usermod -aG docker $USER`
- Restart Docker service: `sudo systemctl restart docker`
- Check Docker status: `sudo systemctl status docker`

### Port Conflicts
- Check running services: `sudo netstat -tulpn`
- Stop conflicting services or change ports in configuration

## Project Structure
\`\`\`
├── src/
│   ├── main/java/com/taskmanager/
│   │   ├── TaskManagerApplication.java
│   │   ├── controller/TaskController.java
│   │   ├── service/TaskService.java
│   │   ├── model/Task.java
│   │   └── repository/TaskRepository.java
│   ├── main/resources/
│   │   └── application.properties
│   └── test/java/com/taskmanager/
├── terraform/
├── ansible/
├── monitoring/
├── scripts/
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
└── pom.xml
\`\`\`

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Run tests
5. Submit pull request

## License

This project is licensed under the MIT License.
#   D e v o p s - t a s k m a n a g e r  
 