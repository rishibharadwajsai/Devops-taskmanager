#!/bin/bash

# DevOps Pipeline Setup Script for Ubuntu
set -e

echo "=== DevOps Pipeline Setup Started ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install basic dependencies
print_status "Installing basic dependencies..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Java 11
print_status "Installing Java 11..."
sudo apt install -y openjdk-11-jdk
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Install Maven
print_status "Installing Maven..."
cd /tmp
wget https://archive.apache.org/dist/maven/maven-3/3.9.4/binaries/apache-maven-3.9.4-bin.tar.gz
sudo tar xzf apache-maven-3.9.4-bin.tar.gz -C /opt
sudo ln -sf /opt/apache-maven-3.9.4 /opt/maven
echo 'export PATH=/opt/maven/bin:$PATH' >> ~/.bashrc
export PATH=/opt/maven/bin:$PATH

# Install Docker
print_status "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER

# Install Docker Compose
print_status "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Jenkins
print_status "Installing Jenkins..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo apt-key add -
echo "deb https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Terraform
print_status "Installing Terraform..."
cd /tmp
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform

# Install Ansible
print_status "Installing Ansible..."
sudo apt install -y python3-pip
pip3 install ansible

# Create project directory
print_status "Creating project directory..."
mkdir -p ~/task-manager-devops
cd ~/task-manager-devops

# Set up local Docker registry
print_status "Setting up local Docker registry..."
docker run -d -p 5000:5000 --restart=always --name registry registry:2

print_status "Setup completed successfully!"
print_warning "Please log out and log back in for Docker group changes to take effect."

echo ""
echo "=== Next Steps ==="
echo "1. Log out and log back in"
echo "2. Clone your project repository"
echo "3. Navigate to the project directory"
echo "4. Run: mvn clean install"
echo "5. Run: docker-compose up -d"
echo "6. Access Jenkins at: http://localhost:8080"
echo "7. Access Grafana at: http://localhost:3000 (admin/admin)"
echo "8. Access Prometheus at: http://localhost:9090"
echo "9. Access your API at: http://localhost:8080/api/tasks"
echo ""
echo "Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
