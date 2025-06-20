# Terraform configuration for infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Docker network
resource "docker_network" "app_network" {
  name = "task-manager-network"
}

# Task Manager API Container
resource "docker_container" "task_manager_api" {
  image = "task-manager-api:latest"
  name  = "task-manager-api"
  
  ports {
    internal = 8080
    external = 8080
  }
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  
  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:8080/api/tasks/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "40s"
  }
}

# Prometheus Container
resource "docker_container" "prometheus" {
  image = "prom/prometheus:latest"
  name  = "prometheus"
  
  ports {
    internal = 9090
    external = 9090
  }
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  
  volumes {
    host_path      = "${path.cwd}/monitoring/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

# Grafana Container
resource "docker_container" "grafana" {
  image = "grafana/grafana:latest"
  name  = "grafana"
  
  ports {
    internal = 3000
    external = 3000
  }
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  
  env = [
    "GF_SECURITY_ADMIN_PASSWORD=admin"
  ]
  
  volumes {
    host_path      = "${path.cwd}/monitoring/grafana/datasources"
    container_path = "/etc/grafana/provisioning/datasources"
  }
  
  volumes {
    host_path      = "${path.cwd}/monitoring/grafana/dashboards"
    container_path = "/etc/grafana/provisioning/dashboards"
  }
}

# Graphite Container
resource "docker_container" "graphite" {
  image = "graphiteapp/graphite-statsd:latest"
  name  = "graphite"
  
  ports {
    internal = 80
    external = 8081
  }
  
  ports {
    internal = 2003
    external = 2003
  }
  
  ports {
    internal = 8125
    external = 8125
    protocol = "udp"
  }
  
  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Output values
output "application_url" {
  value = "http://localhost:8080"
}

output "prometheus_url" {
  value = "http://localhost:9090"
}

output "grafana_url" {
  value = "http://localhost:3000"
}

output "graphite_url" {
  value = "http://localhost:8081"
}
