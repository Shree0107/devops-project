# Automated CI/CD & DevSecOps Pipeline

A production-style DevSecOps pipeline built with GitHub Actions, Docker, Terraform, and Google Cloud Run. Demonstrates automated testing, security scanning, container vulnerability scanning, and cloud deployment.

---

## What This Project Does

Every time you push code to `main`, this pipeline runs automatically:

```
Push to main
     │
     ▼
[1] Unit Tests + Coverage  ──── FAIL? → Pipeline stops, nothing deployed
     │
     ▼
[2] SAST Security Scan (Bandit) ── FAIL? → Pipeline stops
     │
     ▼
[3] Docker Build + Trivy Scan ──── FAIL? → Pipeline stops
     │
     ▼
[4] Deploy to Google Cloud Run ← Only reaches here if all above pass
```

---

## Project Structure

```
devops-pipeline/
│
├── app/
│   ├── app.py               # Flask API (4 endpoints)
│   └── requirements.txt     # Python dependencies
│
├── tests/
│   └── test_app.py          # 8 unit tests covering all endpoints
│
├── .github/
│   └── workflows/
│       └── pipeline.yml     # The full CI/CD pipeline (GitHub Actions)
│
├── terraform/
│   └── main.tf              # Infrastructure as Code — creates Cloud Run on GCP
│
├── monitoring/
│   └── prometheus.yml       # Prometheus scrape config
│
├── Dockerfile               # Multi-stage Docker build
├── docker-compose.yml       # Run app + Prometheus + Grafana locally
├── conftest.py              # Pytest path config
└── README.md
```

---

## Tools Used and Why

| Tool | What it does | Why it matters |
|------|-------------|----------------|
| **Flask** | Python web framework | Lightweight API server |
| **pytest** | Unit testing | Catches bugs before they reach production |
| **Bandit** | SAST security scanner | Finds security issues in Python code |
| **Docker** | Containerisation | App runs the same everywhere |
| **Trivy** | Container vulnerability scanner | Finds CVEs in Docker images |
| **GitHub Actions** | CI/CD automation | Automates the full pipeline on every push |
| **Terraform** | Infrastructure as Code | Provisions Cloud Run without clicking the console |
| **Google Cloud Run** | Serverless container hosting | Scales to 0 when no traffic (cost efficient) |
| **Prometheus** | Metrics collection | Monitors app health |
| **Grafana** | Metrics dashboards | Visualises Prometheus data |

---

## Run Locally (No Cloud Needed)

### Option A — Python only (fastest)

```bash
# 1. Install dependencies
pip install -r app/requirements.txt

# 2. Run the app
python app/app.py

# 3. Test it
curl http://localhost:8080/
curl http://localhost:8080/health
curl "http://localhost:8080/greet?name=Shree"
curl -X POST http://localhost:8080/add \
     -H "Content-Type: application/json" \
     -d '{"a": 5, "b": 3}'
```

### Option B — Docker + Grafana dashboard

```bash
# Starts Flask API + Prometheus + Grafana
docker-compose up --build

# Open these in your browser:
# App:        http://localhost:8080
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3000  (login: admin / admin)
```

---

## Run Tests Locally

```bash
# Run all tests with coverage report
pytest tests/ --cov=app --cov-report=term-missing -v
```

Expected output:
```
tests/test_app.py::test_home PASSED
tests/test_app.py::test_health PASSED
tests/test_app.py::test_greet_default PASSED
tests/test_app.py::test_greet_with_name PASSED
tests/test_app.py::test_greet_invalid_name PASSED
tests/test_app.py::test_add_success PASSED
tests/test_app.py::test_add_missing_fields PASSED
tests/test_app.py::test_add_invalid_types PASSED

Coverage: 95%+
```

---

## Run Security Scan Locally

```bash
pip install bandit
bandit -r app/ -ll
```

---

## Deploy to GCP (Optional)

### Step 1 — Prerequisites
- A Google Cloud account (free tier works)
- GCP project created
- `gcloud` CLI installed

### Step 2 — Add GitHub Secrets

Go to your GitHub repo → Settings → Secrets → Actions → New secret:

| Secret name | Value |
|-------------|-------|
| `GCP_PROJECT_ID` | Your GCP project ID (e.g. `my-project-123`) |
| `GCP_SA_KEY` | JSON key of a GCP service account (see below) |

### Step 3 — Create a GCP Service Account

```bash
# Create service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions"

# Give it permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Download the key (paste this JSON into the GCP_SA_KEY secret)
gcloud iam service-accounts keys create key.json \
  --iam-account=github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### Step 4 — Push to main

```bash
git add .
git commit -m "initial commit"
git push origin main
```

The pipeline runs automatically. Go to the Actions tab in GitHub to watch it.

### Step 5 — Deploy infrastructure with Terraform (optional)

```bash
cd terraform/
terraform init
terraform plan -var="project_id=YOUR_PROJECT_ID" -var="image_url=gcr.io/YOUR_PROJECT_ID/devops-demo-api:latest"
terraform apply -var="project_id=YOUR_PROJECT_ID" -var="image_url=gcr.io/YOUR_PROJECT_ID/devops-demo-api:latest"
```

---

## API Endpoints

| Method | Endpoint | Description | Example |
|--------|----------|-------------|---------|
| GET | `/` | API info | `curl localhost:8080/` |
| GET | `/health` | Health check | `curl localhost:8080/health` |
| GET | `/greet?name=X` | Greeting | `curl "localhost:8080/greet?name=Shree"` |
| POST | `/add` | Add two numbers | `curl -X POST localhost:8080/add -d '{"a":5,"b":3}'` |

---

## Key Concepts Explained Simply

**CI (Continuous Integration)** — Every code push automatically runs tests. If tests fail, you know immediately instead of finding out after deployment.

**CD (Continuous Deployment)** — If all checks pass, code is automatically deployed. No manual steps.

**SAST** — Static Application Security Testing. Reads your code without running it, looking for security mistakes like hardcoded passwords.

**Container scanning (Trivy)** — Even if your code is secure, the Docker base image might have known vulnerabilities (CVEs). Trivy checks for these.

**Infrastructure as Code (Terraform)** — Instead of clicking through the GCP console to create a Cloud Run service, you write a `.tf` file and Terraform creates it for you. Repeatable and version-controlled.

**Least-privilege IAM** — The service account used by GitHub Actions only has the exact permissions it needs (deploy to Cloud Run, push to container registry). Nothing more.
