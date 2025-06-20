#!/bin/bash

# Script to run the complete DevOps pipeline
set -e

echo "=== Running DevOps Pipeline ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Step 1: Clean and build
print_status "Step 1: Building application..."
mvn clean compile

# Step 2: Run tests
print_status "Step 2: Running tests..."
mvn test

# Step 3: Package application
print_status "Step 3: Packaging application..."
mvn package -DskipTests

# Step 4: Build Docker image
print_status "Step 4: Building Docker image..."
docker build -t task-manager-api:latest .

# Step 5: Run infrastructure with Terraform
print_status "Step 5: Deploying infrastructure with Terraform..."
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
cd ..

# Step 6: Verify deployment
print_status "Step 6: Verifying deployment..."
sleep 30

# Health check
print_status "Checking application health..."
timeout 60 bash -c 'until curl -f http://localhost:8080/api/tasks/health; do sleep 2; done'

# Test API endpoints
print_status "Testing API endpoints..."
curl -X GET http://localhost:8080/api/tasks
curl -X POST http://localhost:8080/api/tasks -H "Content-Type: application/json" -d '{"title":"Pipeline Test Task","description":"Created by pipeline"}'

print_status "Pipeline completed successfully!"
echo ""
echo "=== Access URLs ==="
echo "Application: http://localhost:8080"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (admin/admin)"
echo "Graphite: http://localhost:8081"
