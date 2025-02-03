variable "region" {
  description = "The AWS region to deploy to"
  default     = "eu-central-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "habit-tracker-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default = "10.0.0.0/16"
}

variable "ami_id" {
  default = "ami-05a3eb67a5a882338" 
}

variable "instance_type" {
  default = "t3.micro"
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance"
  default     = "db.t3.micro"
}

variable "db_username" {
  default = "dbadmin"
}

variable "db_password" {
  default = "admin123"
}





