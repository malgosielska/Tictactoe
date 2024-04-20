# Określamy wymaganych dostawców dla Terraforma
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1"
    }
  }
}

# Konfigurujemy dostawcow AWS, ustawiamy region na "us-east-1".
provider "aws" {
  region = "us-east-1"
}

# Tworzymy VPC (Virtual Private Cloud) w AWSie
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "app_vpc"
  }
}

# Tworzymy Internet Gateway (IGW)
resource "aws_internet_gateway" "tic_tac_toe_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "tic_tac_toe_igw"
  }
}

# Tworzymy podsieć (subnet) w VPC
resource "aws_subnet" "tic_tac_toe_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true 
  tags = {
    Name = "tic_tac_toe_subnet"
  }
}

# Tworzymu tablice routingu dla VPC
resource "aws_route_table" "tic_tac_toe_rt" { 
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tic_tac_toe_igw.id
  }

  tags = {
    Name = "tic_tac_toe_rt"
  }
}

# Łączymy tablice routingu z podsiecią
resource "aws_route_table_association" "tic_tac_toe_rta" {
  subnet_id      = aws_subnet.tic_tac_toe_subnet.id
  route_table_id = aws_route_table.tic_tac_toe_rt.id
}

# Tworzymy grupę bezpieczeństwa z regułami dla ruchu przychodzącego (ingress) i wychodzącego (egress).
resource "aws_security_group" "tic_tac_toe_sg" {
  name        = "tic_tac_toe_sg"
  vpc_id      = aws_vpc.app_vpc.id
  description = "Security group for accessing application and ec2 via SSH"
  
  # Reguły dla ruchu przychodzącego: HTTP (80), HTTPS (443), custom application (8080, 3000) i SSH (22).
    # Reguły dla portu 80 (HTTP)
  ingress {
    description = "http ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reguły dla portu 443 (HTTPS)
  ingress {
    description = "https ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reguły dla portu 8080 (backend)
  ingress {
    description = "backend ingress"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  # Reguła dla całego ruchu wychodzącego (bez ograniczeń).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tic_tac_toe_sg"
  }
}

# Tworzymy instancję EC2 z określonym obrazem AMI, typem instancji i grupą bezpieczeństwa.
resource "aws_instance" "tic_tac_toe_ec2" {
  ami                      = "ami-0cf43e890af9e3351"
  instance_type            = "t2.micro"
  subnet_id                = aws_subnet.tic_tac_toe_subnet.id
  vpc_security_group_ids   = [aws_security_group.tic_tac_toe_sg.id]
  key_name                 = "vockey"
  tags = {
    Name = "tic_tac_toe_instance"
  }
}

# Tworzymy Elastic IP
resource "aws_eip" "app_eip" {
  domain     = "vpc"
  depends_on = [aws_vpc.app_vpc]
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.tic_tac_toe_ec2.id
  allocation_id = aws_eip.app_eip.id
}