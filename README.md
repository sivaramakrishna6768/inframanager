# InfraManager – Infrastructure Automation (Terraform · AWS · Docker · Python/Flask)

Small, portfolio-ready infrastructure-as-code project:
- Terraform provisions a minimal AWS stack (VPC, subnet, SG, EC2, ECR, IAM/SSM, CloudWatch).
- A Dockerized Flask app runs on the EC2 instance.
- Goal: reproducible, low-cost (free-tier), small-scale cloud service.

## Local quick start (Docker)
```bash
docker build -t inframanager:dev ./app
docker run --rm -p 8080:80 inframanager:dev
# Visit http://localhost:8080 and http://localhost:8080/healthz
