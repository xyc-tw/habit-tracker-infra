output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.public_subnet.id
}

output "app_server_ip" {
  value = aws_instance.app_server.public_ip
}

# Output the public IP addresses of the instances
output "app_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "rds_database_name" {
  value = "habit_tracker"
}

output "rds_username" {
  value = var.db_username
}

output "rds_password" {
  sensitive = true
  value     = var.db_password
}

output "ecr_repository_url" {
  value = aws_ecr_repository.habit_tracker_repo.repository_url
}

# Create Terraform Output for Ansible
output "ansible_inventory" {
  value = <<EOT
{
  "all": {
    "hosts": {
      "app": {
        "ansible_host": "${aws_instance.app_server.public_ip}",
        "ansible_user": "ubuntu",
        "ansible_ssh_private_key_file": "/Users/xinyu/.ssh/habit-tracker-app.pem"
      }
    },
    "vars": {
      "ansible_python_interpreter": "/usr/bin/python3"
    }
  }
}
EOT
}






