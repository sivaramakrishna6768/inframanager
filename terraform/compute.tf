########################################
# InfraManager - Compute (no duplicate locals)
########################################

# Only a unique local here (project/tags live in main.tf)
locals {
  # Extract the ECR registry host from the full repo URL, e.g.
  # 503561455720.dkr.ecr.us-east-1.amazonaws.com/inframanager
  # -> 503561455720.dkr.ecr.us-east-1.amazonaws.com
  ecr_registry = regex("^([0-9]+\\.dkr\\.ecr\\.[^/]+\\.amazonaws\\.com)", var.ecr_repository_url)[0]
}

# ---------------------------
# IAM role for EC2 (SSM + ECR)
# ---------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${local.project}-ec2-role" # local.project comes from main.tf
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = local.tags # local.tags comes from main.tf
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------------------
# Security Group (HTTP + optional SSH)
# ---------------------------
resource "aws_security_group" "web_sg" {
  name        = "${local.project}-web-sg"
  description = "Allow HTTP from anywhere and (optional) SSH from my IP"
  vpc_id      = aws_vpc.main.id

  # HTTP for the app (exposed on instance port 80)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH for troubleshooting (optional /32 from var.allow_ssh_my_ip)
  dynamic "ingress" {
    for_each = var.allow_ssh_my_ip != "" ? [1] : []
    content {
      description = "temporary ssh from my ip"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.allow_ssh_my_ip]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# ---------------------------
# Latest Amazon Linux 2023 AMI
# ---------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ---------------------------
# EC2 Instance with bootstrap
# ---------------------------
resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    dnf -y update
    dnf -y install docker awscli

    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user || true

    # Login to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${local.ecr_registry}

    # Pull and run image
    docker pull ${var.ecr_repository_url}:latest || true
    docker rm -f inframanager || true
    docker run -d --name inframanager -p 80:${var.app_port} ${var.ecr_repository_url}:latest

    # Simple health wait
    for i in $(seq 1 30); do
      sleep 2
      if curl -fsS http://localhost/healthz >/dev/null 2>&1; then
        exit 0
      fi
    done
    exit 1
  EOT

  tags = merge(local.tags, { Name = "${local.project}-ec2" })
}
