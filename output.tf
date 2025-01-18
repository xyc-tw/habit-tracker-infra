output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = { for k, v in aws_subnet.this : k => v.id }
}

# output "k8s_master_staging_public_ip" {
#   value = aws_instance.k8s_master_staging.public_ip
# }

# output "rds_staging_endpoint" {
#   value = aws_rds_instance.staging.endpoint
# }
