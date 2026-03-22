# ═══════════════════════════════════════════════════════════════════
# Terraform — Infrastructure as Code for GCP
# ═══════════════════════════════════════════════════════════════════
#
# This file tells Terraform WHAT infrastructure to create on GCP.
# Instead of clicking around the GCP console, you run:
#
#   terraform init    → download the GCP provider
#   terraform plan    → preview what will be created
#   terraform apply   → actually create the resources
#
# Resources created:
#   - Google Cloud Run service  (runs your container)
#   - IAM policy               (allows public access to the API)
# ═══════════════════════════════════════════════════════════════════

# ── Tell Terraform which cloud provider to use ──────────────────────
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.6"
}

# ── Configure the GCP provider ───────────────────────────────────────
provider "google" {
  project = var.project_id
  region  = var.region
}

# ── Input variables (values passed in from outside) ─────────────────
variable "project_id" {
  description = "Your GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy to"
  type        = string
  default     = "europe-west1"
}

variable "image_url" {
  description = "Full Docker image URL from Google Container Registry"
  type        = string
  # Example: gcr.io/my-project-id/devops-demo-api:abc123
}

variable "service_name" {
  description = "Name for the Cloud Run service"
  type        = string
  default     = "devops-demo-api"
}

# ── Cloud Run Service ────────────────────────────────────────────────
# This is the actual serverless container that runs your Flask API.
# Cloud Run automatically scales from 0 to N instances based on traffic.
resource "google_cloud_run_service" "api" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.image_url

        # Environment variables your app can read with os.environ.get(...)
        env {
          name  = "ENV"
          value = "production"
        }

        # Resource limits — keeps costs low
        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        # Health check — Cloud Run calls this to know the app is ready
        liveness_probe {
          http_get {
            path = "/health"
          }
        }
      }

      # Scale to 0 when no traffic (cost saving)
      container_concurrency = 80
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "0"
        "autoscaling.knative.dev/maxScale" = "3"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ── IAM Policy: Allow public access ─────────────────────────────────
# Without this, only authenticated GCP users can call the API.
# This makes it publicly accessible (suitable for a demo project).
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.api.name
  location = google_cloud_run_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ── Outputs (printed after terraform apply) ─────────────────────────
output "service_url" {
  description = "The public URL of your deployed Cloud Run service"
  value       = google_cloud_run_service.api.status[0].url
}
