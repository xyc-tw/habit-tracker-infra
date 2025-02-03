#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Ensure pipe failures cause script to fail
set -x  # Debug mode (optional, for troubleshooting)

# Define paths
INFRA_DIR=$(realpath $(dirname "$0"))
TERRAFORM_DIR="$INFRA_DIR/terraform"
ANSIBLE_DIR="$INFRA_DIR/ansible"
INVENTORY_DIR="$ANSIBLE_DIR/inventories"
INVENTORY_FILE="$INVENTORY_DIR/dynamic_inventory.ini"
PLAYBOOK_FILE="$ANSIBLE_DIR/playbooks/setup.yml"
SSH_KEY_FILE="$HOME/.ssh/habit-tracker-app.pem"

echo "🚀 Starting Deployment Process..."

# 1. Terraform Apply - Provision AWS infrastructure
echo "🔧 Running Terraform..."
cd "$TERRAFORM_DIR"
terraform init
terraform apply -auto-approve

# Ensure the inventory directory exists
mkdir -p "$INVENTORY_DIR"

# 2. Generate Dynamic Inventory for Ansible
echo "🔧 Generating Dynamic Inventory..."
terraform output -raw ansible_inventory | jq -r '
  "[app]\napp_host ansible_host=\(.all.hosts.app.ansible_host) ansible_user=\(.all.hosts.app.ansible_user) ansible_ssh_private_key_file=\(.all.hosts.app.ansible_ssh_private_key_file)\n\n[all:vars]\nansible_python_interpreter=\(.all.vars.ansible_python_interpreter)"' > "$INVENTORY_FILE"

if [ -f "$INVENTORY_FILE" ]; then
  echo "✅ Dynamic Inventory Created: $INVENTORY_FILE"
else
  echo "❌ Failed to create Dynamic Inventory: $INVENTORY_FILE"
  exit 1
fi

# Export RDS credentials and ECR repo URL for Ansible
export RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
export RDS_DB_NAME=$(terraform output -raw rds_database_name)
export RDS_USER=$(terraform output -raw rds_username)
export RDS_PASSWORD=$(terraform output -raw rds_password)
export ECR_REPO_URL=$(terraform output -raw ecr_repository_url)

# Automatically accept SSH host keys
APP_SERVER_IP=$(terraform output -raw app_server_ip)
echo "🔧 Adding SSH host key for $APP_SERVER_IP"
if command -v ssh-keyscan > /dev/null; then
  ssh-keyscan -H $APP_SERVER_IP >> ~/.ssh/known_hosts || { echo "❌ Failed to add SSH host key for $APP_SERVER_IP"; exit 1; }
else
  echo "❌ ssh-keyscan command not found"
  exit 1
fi

# 3. Run Ansible Playbooks to Configure Instances
echo "🔧 Running Ansible..."
cd "$ANSIBLE_DIR"
if [ -f "$PLAYBOOK_FILE" ]; then
  ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE" --extra-vars "rds_endpoint=$RDS_ENDPOINT rds_db_name=$RDS_DB_NAME rds_user=$RDS_USER rds_password=$RDS_PASSWORD ecr_repo_url=$ECR_REPO_URL"
else
  echo "❌ Playbook file not found: $PLAYBOOK_FILE"
  exit 1
fi

echo "🎉 Deployment Completed Successfully!"
