provider "aws" {
  region = var.region
}

# --------------- 1. Create VPC ---------------
# CIDR stands for Classless Inter-Domain Routing
# 10.0.0.0/16 = 10.0.0.0 ~ 10.0.255.255

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}

# --------------- 2. Create Subnets ---------------
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = false
}

# --------------- 3. create internet gateways ----------
# 1. Internet Gateway
resource "aws_internet_gateway" "vpc-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# 2. Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-gw.id
  }
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# 3. Associate the Route Table with Public Subnets
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id              = aws_subnet.public_subnet.id
  route_table_id         = aws_route_table.public.id 
}

# --------------- 4. Create Security Group ---------------
resource "aws_security_group" "ssh_http_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add the rule to allow traffic on port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rds-sg"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ssh_http_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------- 5. Create Instance ---------------
resource "aws_instance" "app_server" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_http_sg.id]
  key_name        = "habit-tracker-app"

  tags = {
    Name = "AppServer"
  }
}

# --------------- 6. Create RDS ---------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "rds" {
  identifier             = "habit-tracker-db"
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                = "postgres"
  engine_version        = "13"
  instance_class        = var.db_instance_class
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az             = false
  publicly_accessible  = false
  storage_encrypted    = true
  backup_retention_period = 7
  skip_final_snapshot  = true
  
  tags = {
    Name = "habit-tracker-db"
  }
}

# --------------- 7. Create Image Register ECR ---------------
resource "aws_ecr_repository" "habit_tracker_repo" {
  name                 = "habit-tracker"
  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "habit-tracker-ecr"
  }
}















