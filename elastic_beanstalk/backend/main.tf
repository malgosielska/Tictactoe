# Set up the AWS provider with the desired region where the resources will be created
provider "aws" {
  region = "us-east-1" # Eastern USA region for deploying the resources
}

# Tworzy Virtual Private Cloud (VPC) z określonym blokiem CIDR.
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16" # Zakres adresów IP dla VPC.
  enable_dns_support   = true          # Aktywuje wsparcie DNS w VPC.
  enable_dns_hostnames = true          # Pozwala na używanie nazw hostów DNS w VPC.
  tags = {
    Name = "app_vpc" # Nazwa dla VPC w tagach.
  }
}

# Tworzy Internet Gateway i kojarzy go z wcześniej utworzonym VPC.
resource "aws_internet_gateway" "tic_tac_toe_igw" {
  vpc_id = aws_vpc.app_vpc.id # Przypisuje ten IGW do VPC.
  tags = {
    Name = "tic_tac_toe_igw" # Nazwa dla IGW w tagach.
  }
}

# Tworzy podsieć w obrębie VPC z automatycznym przydzielaniem publicznych IP dla instancji EC2.
resource "aws_subnet" "tic_tac_toe_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id # Przypisuje podsieć do VPC.
  cidr_block              = "10.0.1.0/24"      # Blok CIDR dla podsieci.
  map_public_ip_on_launch = true               # Automatycznie przydzielane publiczne IP dla instancji EC2.
  tags = {
    Name = "tic_tac_toe_subnet" # Nazwa dla podsieci w tagach.
  }
}

# Tworzy tabelę routingu dla VPC, dodając trasę domyślną przez Internet Gateway.
resource "aws_route_table" "tic_tac_toe_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                             # Trasa domyślna dla całego ruchu internetowego.
    gateway_id = aws_internet_gateway.tic_tac_toe_igw.id # Przypisuje IGW jako bramę dla ruchu.
  }

  tags = {
    Name = "tic_tac_toe_rt" # Nazwa dla tabeli routingu w tagach.
  }
}

# Kojarzy tabelę routingu z podsiecią, umożliwiając jej dostęp do internetu.
resource "aws_route_table_association" "tic_tac_toe_rta" {
  subnet_id      = aws_subnet.tic_tac_toe_subnet.id  # Podsieć, którą kojarzymy.
  route_table_id = aws_route_table.tic_tac_toe_rt.id # Tabela routingu do skojarzenia.
}

# Tworzy grupę bezpieczeństwa z regułami dla ruchu przychodzącego i wychodzącego.
resource "aws_security_group" "tic_tac_toe_sg" {
  name        = "tic_tac_toe_sg" # Nazwa grupy bezpieczeństwa.
  vpc_id      = aws_vpc.app_vpc.id
  description = "Security group for accessing application and ec2 via SSH"

  # Reguły dla ruchu przychodzącego (ingress) dla różnych protokołów i portów.
  ingress {
    description = "http ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Pozwala na dostęp z dowolnego adresu IP.
  }
  # Powtarza się dla HTTPS, backend (port 8080) i SSH.

  ingress {
    description = "https ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  # Reguła dla całego ruchu wychodzącego (egress).
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


# Define an Elastic Beanstalk application for the backend
resource "aws_elastic_beanstalk_application" "my_app" {
  name        = "Tic-tac-toe-backend"  # Name of the application
  description = "Tic-tac-toe backend app" # Description of what the application is
}


# Create an IAM instance profile for the Elastic Beanstalk environment to grant necessary permissions
resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "eb-tic-tac-toe-backend-instance-profile" # Instance profile name
  role = "LabRole"                                 # Existing IAM role to associate with the instance profile
}


# Create an S3 bucket to store the application's version source code
resource "aws_s3_bucket" "app_version_backend_bucket" {
}


# Upload the application's source code to the S3 bucket
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.app_version_backend_bucket.bucket # Reference to the above-created S3 bucket
  key    = "backend.zip"                                   # The object key within the S3 bucket (file name in the bucket)
  source = "backend.zip"                                   # Local source file path to be uploaded to the S3 bucket
  etag   = filemd5("backend.zip")                          # MD5 hash of the file for change detection
}

# Define a version of the Elastic Beanstalk application using the uploaded S3 object
resource "aws_elastic_beanstalk_application_version" "my_version" {
  name        = "v1"                                            # Version label for the application version
  application = aws_elastic_beanstalk_application.my_app.name   # Link to the EB application defined above
  bucket      = aws_s3_bucket.app_version_backend_bucket.bucket # S3 bucket containing the source bundle
  key         = aws_s3_object.app_version.key                   # File path in S3 bucket to the source bundle
}

# Create an Elastic Beanstalk environment for deploying the application version
resource "aws_elastic_beanstalk_environment" "my_env" {
  name                = "Tic-tac-toe-backend-env"                                 # Environment name within Elastic Beanstalk
  application         = aws_elastic_beanstalk_application.my_app.name             # Link to the EB application
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Docker"           # Platform for the environment
  version_label       = aws_elastic_beanstalk_application_version.my_version.name # Version of the application to deploy

  # Configuration settings for the Elastic Beanstalk environment:
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance" # Environment type, could be LoadBalanced or SingleInstance
  }

  # By setting MinSize and MaxSize, you define the scaling boundaries for environment, ensuring that it can automatically scale within these limits 
  # based on the performance requirements of your application. This helps in managing the cost while ensuring availability and performance.
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1" # Minimum size of the Auto Scaling Group
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2" # Maximum size of the Auto Scaling Group
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name # The IAM instance profile to use
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.app_vpc.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.tic_tac_toe_sg.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.tic_tac_toe_subnet.id
  }
}
