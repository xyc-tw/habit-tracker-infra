# Repo for the Infrastructure (Terraform & Ansible) setting


<!-- Step 1: install terraform, for knowing the version installed, run terraform -v
Step 2: Initialize Terraform
Run terraform init
Downloads necessary provider plugins (e.g., AWS or Google Cloud provider).
Sets up the working directory for Terraform.
Step 3. Plan the Infrastructure
Run the plan command to preview the changes Terraform will make:
terraform plan -out=tfplan
Terraform evaluates the configurations and shows what resources will be created, updated, or destroyed.
Optional: Save the plan to a file (tfplan) to ensure the applied plan matches what you previewed.
Step 4. Apply the Configuration
Apply the planned changes to provision your infrastructure:
terraform apply tfplan
Terraform will execute the plan saved in the tfplan file.
You’ll be prompted to confirm before proceeding. Type yes to continue.
If you didn’t save a plan file in the previous step, you can simply run:
terraform apply
Step 5: Verify Outputs
After applying, Terraform will display the values defined in your outputs.tf file. These might include:
VPC IDs
Subnet IDs
EC2 instance public IPs
Database connection strings
Load Balancer DNS names
Step 6. Access Resources
Use the AWS Console (or other provider console) to view the resources.
Retrieve public IPs or DNS names for services like EC2 or load balancers from Terraform's output.
Step 7. Update or Change Resources
If you modify your Terraform files:

Run terraform plan again to preview the changes.
Run terraform apply to update the infrastructure.
8. Destroy Resources (Optional)
If you want to tear down your infrastructure, use:

bash
Copy code
terraform destroy
Terraform will prompt you to confirm.
This will remove all resources defined in your configuration. -->


## After the research is the decision made for the infrastructure
- using aws services
- separate staging and production environments

## directory structure
terraform/
├── main.tf           # Shared configurations
├── variables.tf      # Variables for all environments
├── outputs.tf        # Outputs for all environments
├── staging.tfvars    # Environment-specific values for staging
└── production.tfvars # Environment-specific values for production


## Summary of Requirements:
 1. 1 VPC
 2. 4 subnets: Public Staging, Public Production, Private Staging, Private Production
 3. Security Groups for RDS, k8s master and k8s cluster, Additional Considerations for Next.js, Jenkins, and ArgoCD
 4. IAM Role for EC2 instances
 5. EC2 Instances:
- 2 EC2 for the Kubernetes master node(staging and production).
- 2 Kubernetes cluster, each contains 3 nodes(Nextjs, Jenkins, ArgoCD)
- 2 RDS

Security Group Strategy for Your Setup
Component	SG Rules
Master Node	- Allow port 6443 from trusted sources.
Worker Nodes	- Allow port 80/443 (HTTP/HTTPS) for Next.js traffic.
- Allow internal cluster communication (ports 10250–10255).
RDS	- Allow port 5432 (Postgres) only from worker nodes.
Jenkins	- Allow port 8080 for external access (trusted IPs only).
ArgoCD	- Allow port 8080 (or Ingress) for trusted sources.

Provisioning the Load Balancer infrastructure using Terraform.
Configuring Kubernetes (K8s) to use the Load Balancer.



Staging Environment:
1 EC2 for running Next.js (staging).
1 EC2 for Jenkins (CI/CD for staging).
1 EC2 for ArgoCD (staging deployment).
Production Environment:
1 EC2 for running Next.js (production).
1 EC2 for Jenkins (CI/CD for production).
1 EC2 for ArgoCD (production deployment).

1 EC2 for k8s master node

2 RDS



## 1. Define Application Requirements
- **Web App**: server to host the Next.js app
  - Type: Web application.
  - Requirement: 
    - A server to host the Next.js app.
    - Elastic Load Balancer (ELB) to distribute traffic (for scalability).
Compute resources for the server.
Elastic Load Balancer (ELB) to distribute traffic (for scalability).
- **Database**: 
  - Type: Relational database.
  - Requirement:
    - Database instances (RDS).
    - Persistent storage for data (e.g., EBS volumes for EC2 or automatic storage for RDS).
    - Network security: Security groups to allow access to the database.
- **Kubernetes**:
  - Type: Cluster of virtual machines to run Docker containers.
  - Requirement:
    - AWS EKS on EC2 instances.
    - Master node(s) for controlling the cluster.
    - Worker nodes to run your application containers (Next.js, Database).
    - Auto Scaling: to scale worker nodes as per load.
    - VPC, Subnets: For networking.
    - Ingress controller: for routing external traffic to internal services in Kubernetes.
    - Persistent Volumes: For storing data, especially for your database.    
- **CI/CD**:
  - Jenkins:
    - EC2 instance(s) to host Jenkins.
    - ECR (Elastic Container Registry) to store Docker images.
    - IAM roles and policies to allow Jenkins to push to ECR and deploy to Kubernetes.
  - ArgoCD:
    - Kubernetes resources to run ArgoCD.
    - Kubernetes cluster access for ArgoCD to deploy changes automatically.
- **Monitoring** (Grafana, Prometheus, Metabase):
  - Compute resources for monitoring tools.
  - Storage for metrics and logs.
  - Network access to communicate with Kubernetes and databases.




Optional
5. Elastic Load Balancer (Optional for Next.js):
6. Monitoring




You have a Next.js application running inside Kubernetes, which is exposed to the public internet through an Application Load Balancer (ALB) on AWS. We want both HTTP (port 80) and HTTPS (port 443) to be accessible, and we also want to handle the security part using an SSL certificate.

To summarize, these components are involved:

Listener on the ALB to accept traffic (both HTTP and HTTPS)
ACM Certificate ARN to secure the HTTPS traffic
Target Group to route traffic to your Next.js application running in Kubernetes
Security Group to control access between ALB, your Kubernetes pods, and other resources.
Now let's break down how everything works:

1. The Listener and HTTP/HTTPS Traffic
A Listener on the ALB listens for incoming traffic on specific ports (in your case, port 80 for HTTP and port 443 for HTTPS).

HTTP Listener (port 80): The listener will accept non-secure HTTP traffic (just plain text communication).
HTTPS Listener (port 443): The listener will accept secure HTTPS traffic, which is encrypted. The encryption and decryption happen using an SSL/TLS certificate, which we'll get from AWS ACM (AWS Certificate Manager).
You can configure the Listener to handle both types of traffic (HTTP and HTTPS):

When traffic arrives at port 80 (HTTP), it will be redirected to port 443 (HTTPS) for security. This is handled through the Nginx Ingress Controller or ALB itself if you have the proper rules set.
The HTTPS Listener will decrypt the traffic using the SSL/TLS certificate.

2. ACM Certificate ARN and HTTPS
ACM Certificate ARN is the Amazon Resource Name for your SSL/TLS certificate stored in AWS Certificate Manager (ACM).

This certificate is used to encrypt HTTPS traffic.
You will need to provision an SSL certificate using ACM for your domain (e.g., yourdomain.com) and use the ARN (Amazon Resource Name) of this certificate in the ALB listener.
To generate an ACM certificate:

Go to AWS ACM (Certificate Manager) and request a certificate for your domain.
AWS will ask you to validate ownership of the domain (e.g., via email or DNS).
Once validated, you can get the ARN (Amazon Resource Name) for the certificate.
Use this ARN in the ALB Listener to enable secure HTTPS traffic.

3. Target Group (How ALB Routes Traffic)
The Target Group is where the ALB sends traffic after the listener accepts it.

A Target Group defines the EC2 instances or pods that the load balancer will route traffic to.
In your case, the Target Group will contain the Kubernetes pods that run Next.js.
How it works:

When the ALB receives an HTTP or HTTPS request, it forwards the traffic to the Target Group (based on your listener configuration).
The Target Group can register targets dynamically, which are the pods running in your Kubernetes cluster.
The Target Group knows which pods are part of it by using the AWS Load Balancer Controller in your Kubernetes cluster.

4. Security Groups
A Security Group acts as a virtual firewall to control inbound and outbound traffic to your resources (e.g., EC2 instances, ALBs, etc.).

Here’s how it works for your scenario:

Security Group for ALB: The ALB will have a security group allowing inbound traffic from the internet (anyone can access it on HTTP/HTTPS ports 80/443).
ALB Security Group allows traffic on ports 80 (HTTP) and 443 (HTTPS).
Security Group for Kubernetes (EC2 instances that are worker nodes):

You would need a Security Group for your EC2 instances that allows traffic from the ALB (on the HTTP/HTTPS ports).
The Kubernetes pods running Next.js will be the targets for the ALB's target group, but traffic will flow through the EC2 instances hosting the Kubernetes nodes.

5. Kubernetes Integration
In Kubernetes, you will define a Service of type LoadBalancer to allow Kubernetes to create the actual load balancer in AWS (ALB in this case).

This Kubernetes Service will:

Automatically create an AWS Load Balancer (ALB).
Register the EC2 nodes that are part of your Kubernetes cluster as targets in the Target Group.
You will use the AWS Load Balancer Controller in Kubernetes to automate the provisioning and management of the ALB and routing.



