variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_url" {
  description = "Full ECR repo URL (without tag)"
  type        = string
  default     = "503561455720.dkr.ecr.us-east-1.amazonaws.com/inframanager"
}

variable "app_port" {
  description = "Container port the app listens on"
  type        = number
  default     = 80
}

variable "allow_ssh_my_ip" {
  description = "Your IPv4 /32 to allow temporary SSH (optional hardening)"
  type        = string
  default     = "" # leave blank to skip; we already allow EC2 Instance Connect
}
