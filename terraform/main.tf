# # ═══════════════════════════════════════════════════════════════════
# # Terraform — Infrastructure as Code for GCP
# # ═══════════════════════════════════════════════════════════════════
# #
# # This file tells Terraform WHAT infrastructure to create on GCP.
# # Instead of clicking around the GCP console, you run:
# #
# #   terraform init    → download the GCP provider
# #   terraform plan    → preview what will be created
# #   terraform apply   → actually create the resources
# #
# # Resources created:
# #   - Google Cloud Run service  (runs your container)
# #   - IAM policy               (allows public access to the API)
# # ═══════════════════════════════════════════════════════════════════

# # ── Tell Terraform which cloud provider to use ──────────────────────
# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "~> 5.0"
#     }
#   }
#   required_version = ">= 1.6"
# }

# # ── Configure the GCP provider ───────────────────────────────────────
# provider "google" {
#   project = var.project_id
#   region  = var.region
# }

# # ── Input variables (values passed in from outside) ─────────────────
# variable "project_id" {
#   description = "Your GCP project ID"
#   type        = string
# }

# variable "region" {
#   description = "GCP region to deploy to"
#   type        = string
#   default     = "europe-west1"
# }

# variable "image_url" {
#   description = "Full Docker image URL from Google Container Registry"
#   type        = string
#   # Example: gcr.io/my-project-id/devops-demo-api:abc123
# }

# variable "service_name" {
#   description = "Name for the Cloud Run service"
#   type        = string
#   default     = "devops-demo-api"
# }

# # ── Cloud Run Service ────────────────────────────────────────────────
# # This is the actual serverless container that runs your Flask API.
# # Cloud Run automatically scales from 0 to N instances based on traffic.
# resource "google_cloud_run_service" "api" {
#   name     = var.service_name
#   location = var.region

#   template {
#     spec {
#       containers {
#         image = var.image_url

#         # Environment variables your app can read with os.environ.get(...)
#         env {
#           name  = "ENV"
#           value = "production"
#         }

#         # Resource limits — keeps costs low
#         resources {
#           limits = {
#             cpu    = "1"
#             memory = "512Mi"
#           }
#         }

#         # Health check — Cloud Run calls this to know the app is ready
#         liveness_probe {
#           http_get {
#             path = "/health"
#           }
#         }
#       }

#       # Scale to 0 when no traffic (cost saving)
#       container_concurrency = 80
#     }

#     metadata {
#       annotations = {
#         "autoscaling.knative.dev/minScale" = "0"
#         "autoscaling.knative.dev/maxScale" = "3"
#       }
#     }
#   }

#   traffic {
#     percent         = 100
#     latest_revision = true
#   }
# }

# # ── IAM Policy: Allow public access ─────────────────────────────────
# # Without this, only authenticated GCP users can call the API.
# # This makes it publicly accessible (suitable for a demo project).
# resource "google_cloud_run_service_iam_member" "public_access" {
#   service  = google_cloud_run_service.api.name
#   location = google_cloud_run_service.api.location
#   role     = "roles/run.invoker"
#   member   = "allUsers"
# }

# # ── Outputs (printed after terraform apply) ─────────────────────────
# output "service_url" {
#   description = "The public URL of your deployed Cloud Run service"
#   value       = google_cloud_run_service.api.status[0].url
# }





terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.6"
}

provider "aws" {
  region = "eu-west-3"
}

# ── Key Pair — lets you SSH into the EC2 instance ──────────────────
resource "aws_key_pair" "devops_key" {
  key_name   = "devops-key"
  public_key = file("C:/Users/Shree/.ssh/devops-key.pub")
}

# ── Security Group — firewall rules ────────────────────────────────
resource "aws_security_group" "devops_sg" {
  name        = "devops-pipeline-sg"
  description = "Allow SSH, Flask API, Prometheus, Grafana"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── EC2 Instance — free tier t2.micro ──────────────────────────────
resource "aws_instance" "devops_server" {
  ami                    = "ami-0f61de2873e29e866" # Ubuntu 22.04 eu-west-3
  instance_type          = "t3.micro"              # free tier
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "devops-pipeline-server"
  }
}

# ── Elastic IP — gives your server a fixed public IP ───────────────
resource "aws_eip" "devops_eip" {
  instance = aws_instance.devops_server.id
  domain   = "vpc"
}

# ── Outputs — printed after terraform apply ────────────────────────
output "public_ip" {
  description = "Your server public IP"
  value       = aws_eip.devops_eip.public_ip
}

output "ssh_command" {
  description = "Command to SSH into your server"
  value       = "ssh -i ~/.ssh/devops-key ubuntu@${aws_eip.devops_eip.public_ip}"
}

output "flask_api_url" {
  description = "Your Flask API URL"
  value       = "http://${aws_eip.devops_eip.public_ip}:8080"
}

output "grafana_url" {
  description = "Your Grafana URL"
  value       = "http://${aws_eip.devops_eip.public_ip}:3000"
}
