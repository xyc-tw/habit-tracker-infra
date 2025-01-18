variable "region" {
  description = "The AWS region to deploy to"
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "devops-vpc"
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr_block        = string
    map_public_ip_on_launch = bool
    availability_zone = string
    name              = string
  }))

  default = {
    public_staging = {
      cidr_block        = "10.0.1.0/24"
      map_public_ip_on_launch = true
      availability_zone = "eu-central-1a"
      name              = "public-staging-subnet"
    }
    public_production = {
      cidr_block        = "10.0.2.0/24"
      map_public_ip_on_launch = true
      availability_zone = "eu-central-1b"
      name              = "public-production-subnet"
    }
    private_staging = {
      cidr_block        = "10.0.3.0/24"
      map_public_ip_on_launch = false
      availability_zone = "eu-central-1a"
      name              = "private-staging-subnet"
    }
    private_production = {
      cidr_block        = "10.0.4.0/24"
      map_public_ip_on_launch = false
      availability_zone = "eu-central-1b"
      name              = "private-production-subnet"
    }
  }
}


/*variable "ami_id" {
  default = "ami-0c55b159cbfafe1f0" # Replace with your AMI
}

variable "instance_type" {
  default = "t3.medium"
}

variable "db_storage" {
  default = 20
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "admin123"
}*/





