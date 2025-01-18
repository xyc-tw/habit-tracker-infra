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
    Name = var.vpc_name
  }
}

# --------------- 2. Create Subnets ---------------
# Availability zones (across different zones to increase reliability and fault tolerance).
# Public vs. Private subnets (public for web servers, private for databases, etc.).
# Public Subnets:
# Public Subnet (Staging): 10.0.1.0/24 (can be used for Load Balancers, Web Servers for Staging)
# Public Subnet (Production): 10.0.2.0/24 (can be used for Load Balancers, Web Servers for Production)
# Private Subnets:
# Private Subnet (Staging): 10.0.3.0/24 (for Databases, Backend Services for Staging)
# Private Subnet (Production): 10.0.4.0/24 (for Databases, Backend Services for Production)

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.value.name
  }
}


# --------------- 3. Create Security Group ---------------
# Port 80: Default port for HTTP traffic (web applications).
# Port 443: Default port for HTTPS traffic (secure web applications).
# Port 22: Default port for SSH (used for remote access to Linux-based EC2 instances).
# Port 5432 for PostgreSQL database.
# Port 3306 for MySQL database.
# Port 6379 for Redis.
# Generally, you set security group rules for individual resources (like EC2 instances, RDS databases, etc.), not necessarily for the subnets. However, Network ACLs (NACLs) can be set at the subnet level to control traffic in and out of entire subnets, but they are more restrictive and are usually not the primary choice for managing security on EC2 instances.

# ----- for k8s master in both staging and production -----
/* resource "aws_security_group" "k8s_master" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "k8s-master-sg"
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP later
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}*/

# ----- for Jenkins and ArgoCD in both staging and production -----


# ----- for RDS in both staging and production -----
/*resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rds-sg"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_staging.cidr_block, aws_subnet.private_production.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- load balancer --- 
resource "aws_security_group" "alb_sg" {
  name        = "nextjs-alb-sg"
  description = "Allow HTTP and HTTPS traffic to ALB"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}*/



# 4. Create IAM Role for EC2 Instance (Assume role for EC2)
/*resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}*/


# 5. Create EC2 instance in the VPC
/* resource "aws_instance" "k8s_master_staging" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_staging.id
  security_groups = [aws_security_group.k8s_master.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "k8s-master-staging"
  }
}

resource "aws_instance" "k8s_worker_staging" {
  count         = 3
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_staging.id
  security_groups = [aws_security_group.k8s_master.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "k8s-worker-staging-${count.index + 1}"
  }
}

resource "aws_rds_instance" "staging" {
  allocated_storage    = var.db_storage
  engine               = "postgres"
  engine_version       = "13"
  instance_class       = var.db_instance_class
  name                 = "staging-db"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.private_staging.name
  security_group_names = [aws_security_group.rds.id]
  skip_final_snapshot  = true
}

resource "aws_instance" "k8s_master_production" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_production.id
  security_groups = [aws_security_group.k8s_master.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "k8s-master-staging"
  }
}*/

# Use a Load Balancer (ALB or NGINX Ingress Controller) to expose the application publicly. 
/* resource "aws_instance" "k8s_worker_production" {
  count         = 3
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_production.id
  security_groups = [aws_security_group.k8s_master.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "k8s-worker-staging-${count.index + 1}"
  }
}

resource "aws_rds_instance" "production" {
  allocated_storage    = var.db_storage
  engine               = "postgres"
  engine_version       = "13"
  instance_class       = var.db_instance_class
  name                 = "production-db"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.private_production.name
  security_group_names = [aws_security_group.rds.id]
  skip_final_snapshot  = true
}

resource "aws_lb" "nextjs_alb" {
  name               = "nextjs-alb"
  internal           = false
  load_balancer_type = "application" # For HTTP/HTTPS traffic
  security_groups    = [aws_security_group.nextjs_sg.id]
  subnets            = [
    aws_subnet.public_staging.id,
    aws_subnet.public_production.id,
  ]
  enable_deletion_protection = false
  enable_http2              = true
  idle_timeout {
    seconds = 60
  }
}*/

# Create an Application Load Balancer
/*resource "aws_lb" "nextjs_alb" {
  name               = "nextjs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_staging.id, aws_subnet.public_production.id]

  enable_deletion_protection = false
  idle_timeout {
    minutes = 60
  }
}*/

# Create a Target Group for Next.js pods (Kubernetes)
# A Target Group is essentially a group of resources (like EC2 instances, IP addresses, or Lambda functions) that the load balancer will route traffic to. 
# The Target Group is where the ALB sends traffic after the listener accepts it.
/*resource "aws_lb_target_group" "nextjs_target_group" {
  name     = "nextjs-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}*/

# Create HTTPS Listener for ALB (SSL/TLS)
# A Listener is a process that checks for incoming connection requests to the load balancer.
/*resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.nextjs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    redirect {
      protocol = "HTTPS"
      port     = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.nextjs_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.nextjs_certificate.arn  # Use your ACM certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nextjs_target_group.arn
  }
}*/






