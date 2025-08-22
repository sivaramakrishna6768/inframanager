########################################
# InfraManager - Networking (free-tier)
########################################

# Use the first available AZ in the region (e.g., us-east-1a)
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  project = "inframanager"
  az      = data.aws_availability_zones.available.names[0]
  tags = {
    Project = local.project
    Env     = "dev"
    Owner   = "portfolio"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${local.project}-vpc" })
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${local.project}-public-subnet" })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${local.project}-igw" })
}

# Route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.tags, { Name = "${local.project}-public-rt" })
}

# Associate the route table to the public subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
