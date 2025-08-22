# InfraManager — Terraform · AWS EC2 · Docker (Flask)

A compact, well-scoped project that **provisions AWS infrastructure with Terraform** and **deploys a Dockerized Flask app** to an EC2 instance via **Amazon ECR**. It demonstrates Infrastructure‑as‑Code, containerization, and reproducible deployments without over‑engineering.

> **Live demo note:** The EC2 instance is not kept running to avoid costs. The app is fully reproducible by following the steps below.

---

## What this proves (aligns with resume/LinkedIn)
- **IaC with Terraform**: EC2, Security Group, IAM role + instance profile (SSM + ECR read), and bootstrapping via `user_data`.
- **AWS cloud setup**: Runs in **us‑east‑1** on a Free‑Tier instance type.
- **Dockerized app**: Flask app container is built locally, pushed to **ECR**, and pulled/run on EC2.
- **Health checks**: `/healthz` endpoint confirms the container is healthy after boot.

---

## Architecture (high‑level)
```
Developer (local) ── docker build/push ──▶ Amazon ECR  (repo: inframanager)
                                   │
                               terraform apply
                                   │
                                   ▼
                 EC2 (Amazon Linux) boots → user_data installs Docker
                               → docker login to ECR → docker run
                                   │
                                   ▼
                     Public HTTP on port 80 (Flask / and /healthz)
```
Security group: allow **HTTP :80** from anywhere; SSH can be limited to **EC2 Instance Connect** and/or “My IP” during troubleshooting.

---

## Repo layout
```
infra-manager/
│
├── src/
│   ├── app.py              # Flask application
│   ├── Dockerfile          # Docker build definition
│   └── requirements.txt    # Python dependencies
│
├── terraform/
│   ├── backend.tf          # Terraform backend configuration (state mgmt)
│   ├── compute.tf          # EC2 and networking resources
│   ├── ecr.tf              # AWS Elastic Container Registry setup
│   ├── main.tf             # Root Terraform config tying modules together
│   ├── outputs.tf          # Output values after provisioning
│   ├── tfplan              # Terraform execution plan file
│   ├── variables.tf        # Input variables for configs
│   ├── versions.tf         # Terraform + provider version constraints
│
├── .gitignore              # Git ignore rules
├── bucket-encryption.json  # Sample JSON for bucket encryption policy
└── README.md               # Documentation
```

---

## Prerequisites
- **Docker Desktop**
- **AWS CLI v2** (authenticated to your AWS account)
- **Terraform** (v1.4+)
- An **ECR repository** named `inframanager` (create once if needed)

> Region: `us-east-1`. If you use a different region, update Terraform variables and commands accordingly.

---

## Build & push the Docker image to ECR
**PowerShell** (Windows):

```powershell
# From repo root
docker build -t inframanager:latest .\app

$ACCOUNT = (aws sts get-caller-identity --query Account --output text)
$REGION  = "us-east-1"
$REPO    = "inframanager"
$ECR_URL = "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$REPO"

# Create ECR repo if missing
aws ecr describe-repositories --repository-names $REPO --region $REGION *> $null
if ($LASTEXITCODE -ne 0) {
  aws ecr create-repository --repository-name $REPO --region $REGION | Out-Null
}

# Login & push
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
docker tag inframanager:latest "${ECR_URL}:latest"
docker push "${ECR_URL}:latest"
```

---

## Provision with Terraform
From the `terraform` folder:

```powershell
terraform init
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply "tfplan"
```

**Outputs** will include:
- `web_public_ip`
- `web_public_dns`

---

## Test
Open in your browser:

- `http://<web_public_ip>/`
- `http://<web_public_ip>/healthz` → should return `{"status":"ok"}`

You can also verify on the instance (via EC2 Instance Connect or SSM shell):
```bash
docker ps
curl -s http://localhost/healthz
```

---

## Troubleshooting
- **403/No basic auth when pulling from ECR**  
  Re‑run the ECR login on the instance:  
  `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com`

- **Site not loading**  
  Confirm the EC2 security group allows **TCP 80** from `0.0.0.0/0`.  
  Check container logs: `docker logs --tail=100 inframanager`.

- **EC2 Instance Connect not listing the instance**  
  Ensure the instance role has `AmazonSSMManagedInstanceCore` and the AMI has `amazon-ssm-agent` installed (user_data in this repo does that).

---

## Cost control
- **Stop** the EC2 instance when not using it (keeps EBS volume; fits Free Tier).
- No Elastic IP is allocated by default.
- Destroy everything if needed:
```powershell
cd terraform
terraform destroy -auto-approve
```

---

## 👤 Author

**Siva Ramakrishna Palaparthy**\
LinkedIn: [Your LinkedIn](https://www.linkedin.com/in/siva-ramakrishna-palaparthy)\
