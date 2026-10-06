# 8Byte DevOps Assignment

## Overview

This project demonstrates an end-to-end DevOps implementation for deploying a containerized application on AWS using Infrastructure as Code, CI/CD automation, security scanning, monitoring, centralized logging, and controlled production deployment.

### Key Technologies

* **Cloud:** AWS
* **Infrastructure as Code:** Terraform
* **Compute:** Amazon EC2
* **Database:** Amazon RDS PostgreSQL
* **Load Balancer:** Application Load Balancer (ALB)
* **Containerization:** Docker
* **Container Registry:** Docker Hub
* **CI/CD:** Jenkins
* **Monitoring:** Amazon CloudWatch
* **Logging:** CloudWatch Logs
* **Security Scanning:** Trivy
* **Source Control:** GitHub
* **Application:** Python
* **Web Server:** Nginx
* **OS:** Amazon Linux

---

# Architecture

The solution uses Terraform to provision AWS infrastructure and Jenkins to automate application build, security scanning, deployment, and validation.

### High-Level Flow

```text
Developer
    |
    v
GitHub
    |
    | Webhook
    v
Jenkins
    |
    +--> Unit Tests
    |
    +--> Docker Build
    |
    +--> Trivy Security Scan
    |
    +--> Push Image to Docker Hub
    |
    v
AWS EC2
    |
    +--> Staging Container
    |       |
    |       +--> Health Check
    |
    +--> Manual Production Approval
            |
            v
        Production Container

AWS Infrastructure:

Internet
   |
   v
Application Load Balancer
   |
   v
EC2
   |
   +--> Docker Application

EC2
   |
   +--> CloudWatch Agent
           |
           +--> CPU Metrics
           +--> Memory Metrics
           +--> Disk Metrics
           +--> System Logs
           +--> Nginx Access Logs
           +--> Nginx Error Logs

Application
   |
   v
RDS PostgreSQL
```

---

# AWS Infrastructure

The AWS infrastructure is provisioned using Terraform.

### Infrastructure Components

* VPC
* Public and private subnets
* Internet Gateway
* Route tables
* Security groups
* EC2 instance
* Application Load Balancer
* Target group
* RDS PostgreSQL
* IAM role for CloudWatch Agent
* IAM instance profile
* CloudWatch monitoring configuration

Terraform modules are used to organize infrastructure components.

```text
terraform/
├── backend.tf
├── main.tf
├── provider.tf
├── variable.tf
├── output.tf
├── monitoring.tf
└── modules/
    ├── vpc/
    ├── ec2/
    ├── alb/
    └── rds/
```

---

# Terraform Setup

## Prerequisites

Install/configure:

* AWS CLI
* Terraform
* Git
* Docker
* Jenkins

Configure AWS credentials securely using the AWS CLI or another supported authentication mechanism.

Verify AWS access:

```bash
aws sts get-caller-identity
```

## Initialize Terraform

```bash
cd terraform
terraform init
```

## Validate Configuration

```bash
terraform validate
```

## Review Infrastructure Changes

```bash
terraform plan
```

## Provision Infrastructure

```bash
terraform apply
```

Review the Terraform plan and confirm the apply operation.

## View Outputs

```bash
terraform output
```

---

# Terraform State

Terraform state is used to track the AWS infrastructure managed by Terraform.

The project is structured to support proper state management through the Terraform backend configuration.

For a production environment, remote state such as an S3 backend with state locking should be used to provide:

* Centralized state
* State versioning
* Team collaboration
* Recovery from accidental changes

---

# Application

The application is containerized using Docker.

## Run Locally

Build the Docker image:

```bash
docker build -t 8byte-devops-app .
```

Run the application:

```bash
docker run -d \
  --name 8byte-devops-app \
  -p 8081:8081 \
  8byte-devops-app
```

Health check:

```bash
curl http://localhost:8081/health
```

Expected response:

```text
OK
```

---

# CI/CD Pipeline

Jenkins is used to implement the CI/CD pipeline.

## Pipeline Flow

```text
GitHub Push
     |
     v
Unit Tests
     |
     v
Docker Build
     |
     v
Trivy Vulnerability Scan
     |
     v
Docker Hub Push
     |
     v
CloudWatch Agent Configuration
     |
     v
Staging Deployment
     |
     v
Staging Health Check
     |
     v
Manual Production Approval
     |
     v
Production Deployment
     |
     v
Production Health Check
```

## Pipeline Stages

### 1. Unit Tests

Python unit tests are executed using:

```bash
python3 -m unittest discover -s app -p "test_*.py"
```

### 2. Docker Build

The application image is built using Docker.

### 3. Security Scan

Trivy scans the container image for HIGH and CRITICAL vulnerabilities.

The current pipeline reports vulnerabilities while allowing the assignment pipeline to continue so that the findings can be reviewed.

### 4. Docker Hub Push

The image is pushed to Docker Hub with:

* Build-specific tag
* `latest` tag

Example:

```text
kajalkumarikkv/8byte-devops-app:<BUILD_NUMBER>
kajalkumarikkv/8byte-devops-app:latest
```

### 5. Staging Deployment

The image is pulled on the EC2 instance and deployed as the staging container.

Staging uses:

```text
Port 8082
```

### 6. Staging Health Check

Jenkins validates the deployment using:

```bash
curl -f http://localhost:8082/health
```

### 7. Production Approval

Production deployment requires manual approval in Jenkins.

This provides a deployment gate between staging and production.

### 8. Production Deployment

After approval, Jenkins deploys the same validated image to the production container.

Production uses:

```text
Port 8081
```

### 9. Production Health Check

Jenkins validates production using:

```bash
curl -f http://localhost:8081/health
```

---

# Security

Security has been considered throughout the implementation.

## Jenkins Credentials

Sensitive credentials are stored in the Jenkins Credentials Store instead of being hard-coded in the Jenkinsfile.

Examples include:

* Docker Hub credentials
* EC2 SSH credentials
* SMTP credentials

The Jenkinsfile references credential IDs rather than storing passwords or private keys directly.

## AWS IAM

An IAM role and instance profile are attached to EC2 for CloudWatch Agent access.

The role uses:

```text
CloudWatchAgentServerPolicy
```

This avoids storing AWS access keys directly on the EC2 instance.

## Network Security

Security groups are used to control network access between:

* ALB
* EC2
* RDS

Only required ports should be exposed.

## Container Security

Trivy is integrated into the Jenkins pipeline to identify container vulnerabilities.

Docker images are also built using a controlled Dockerfile.

---

# Secret Management

Jenkins Credentials Store is used for CI/CD secrets.

Secrets are not stored directly inside:

* Jenkinsfile
* Terraform files
* Dockerfile
* GitHub repository

For a production-grade implementation, AWS Secrets Manager can additionally be used for application secrets such as database credentials.

---

# Monitoring

Amazon CloudWatch is used for infrastructure and application monitoring.

Two dashboards are configured.

## Dashboard 1: 8Byte-Infrastructure

The infrastructure dashboard contains:

* EC2 CPU Utilization
* EC2 Memory Utilization
* EC2 Disk Utilization
* RDS CPU Utilization
* RDS Database Connections
* RDS Free Storage
* RDS Freeable Memory
* RDS Read Latency

## Dashboard 2: 8Byte-Application

The application dashboard contains ALB/application-related metrics including:

* Request Count
* 5XX Error Count
* Target Response Time

---

# CloudWatch Agent

The CloudWatch Agent is installed on the EC2 instance.

It collects:

* Memory utilization
* Disk utilization
* System logs
* Nginx access logs
* Nginx error logs

CloudWatch log groups include:

```text
/8byte/ec2/system
/8byte/ec2/nginx-access
/8byte/ec2/nginx-error
```

---

# CloudWatch Alarm

An ALB 5XX alarm has been configured.

### Alarm

```text
8byte-ALB-5XX-Alarm
```

### Condition

```text
HTTPCode_ELB_5XX_Count > 0
```

within:

```text
5 minutes
```

When the alarm enters the **In Alarm** state, an SNS notification is sent to the configured email endpoint.

This provides an alert when the Application Load Balancer starts returning server-side 5XX errors.

---

# Logging

Centralized logging is implemented using CloudWatch Logs.

The following logs are collected:

### System Logs

```text
/var/log/messages
```

### Nginx Access Logs

```text
/var/log/nginx/access.log
```

### Nginx Error Logs

```text
/var/log/nginx/error.log
```

This provides centralized visibility into infrastructure and web-server activity.

---

# Testing

The project includes multiple levels of validation.

## Unit Testing

Python unit tests are executed during the Jenkins pipeline.

```bash
python3 -m unittest discover -s app -p "test_*.py"
```

## Container Testing

The Docker image is scanned using Trivy.

## Staging Integration/Smoke Test

Jenkins verifies the staging application using the health endpoint:

```bash
curl -f http://localhost:8082/health
```

## Production Smoke Test

Jenkins verifies production using:

```bash
curl -f http://localhost:8081/health
```

This prevents a deployment from being considered successful if the application is not responding correctly.

---

# Deployment Strategy

The deployment follows a controlled staging-to-production approach.

```text
Build
  |
  v
Security Scan
  |
  v
Staging
  |
  v
Health Check
  |
  v
Manual Approval
  |
  v
Production
  |
  v
Health Check
```

This reduces the risk of deploying an untested build directly to production.

---

# Cost Optimization

The implementation considers AWS cost optimization.

Approaches include:

* Using a small EC2 instance suitable for the assignment
* Avoiding EKS where it is not required
* Using a single EC2 instance for the demonstration environment
* Using standard CloudWatch monitoring where possible
* Avoiding unnecessary Multi-AZ resources for the assignment environment
* Stopping non-production resources when they are not required
* Removing unused AWS resources after testing
* Using Docker containers instead of additional compute instances

For a production environment, capacity and availability requirements would be reviewed before applying these cost-saving measures.

---

# Backup Strategy

RDS backup capabilities should be enabled for production workloads.

The database backup strategy should include:

* Automated backups
* Appropriate retention period
* Recovery testing
* Point-in-time recovery where required

For this assignment environment, the focus is on demonstrating the RDS infrastructure and monitoring configuration.

---

# Architecture Decisions

## Why Terraform?

Terraform provides:

* Infrastructure as Code
* Repeatable deployments
* Version-controlled infrastructure
* Reusable modules
* Infrastructure change tracking

## Why Jenkins?

Jenkins provides:

* GitHub integration
* Automated builds
* Testing
* Docker image creation
* Security scanning
* Deployment automation
* Manual production approval

## Why Docker?

Docker provides a consistent runtime environment across development, staging, and production.

## Why AWS ALB?

ALB provides:

* HTTP/HTTPS load balancing
* Health checks
* Target group management
* Application-level routing
* CloudWatch integration

## Why CloudWatch?

CloudWatch provides centralized AWS monitoring, metrics, alarms, and logs without requiring a separate monitoring platform.

---

# Challenges and Resolutions

## Challenge 1: Terraform Provider Initialization

### Problem

Terraform provider initialization experienced a provider process/installation issue.

### Resolution

The Terraform provider process was cleaned up and Terraform was initialized again successfully.

---

## Challenge 2: Jenkins CloudWatch Agent Configuration

### Problem

The CloudWatch Agent configuration required remote execution on the EC2 instance and correct handling of configuration content.

### Resolution

The Jenkins pipeline was updated to create the CloudWatch Agent configuration remotely and validate the configuration before restarting the agent.

---

## Challenge 3: Jenkins Docker Permissions

### Problem

Jenkins required permission to communicate with the Docker daemon.

### Resolution

The Jenkins service user was configured with the required Docker access so pipeline Docker commands could execute successfully.

---

## Challenge 4: Secure Credential Handling

### Problem

The CI/CD pipeline requires Docker Hub and EC2 SSH credentials.

### Resolution

Credentials were stored in Jenkins Credentials Store and referenced by credential IDs instead of placing secrets directly in the Jenkinsfile.

---

## Challenge 5: Production Deployment Safety

### Problem

Automatically deploying every successful staging build directly to production can increase deployment risk.

### Resolution

A manual approval stage was added between staging validation and production deployment.

---

# Successful Pipeline Validation

The Jenkins pipeline successfully demonstrated:

* Unit tests
* Docker image build
* Trivy security scan
* Docker Hub image push
* CloudWatch Agent configuration
* Staging deployment
* Staging health check
* Manual production approval
* Production deployment
* Production health check

The deployment flow therefore validates the application from source code through production.

---

# Repository Structure

```text
8byte-devops-assignment/
│
├── app/
│   ├── application files
│   └── test files
│
├── terraform/
│   ├── backend.tf
│   ├── main.tf
│   ├── provider.tf
│   ├── variable.tf
│   ├── output.tf
│   ├── monitoring.tf
│   │
│   └── modules/
│       ├── vpc/
│       ├── ec2/
│       ├── alb/
│       └── rds/
│
├── Dockerfile
├── Jenkinsfile
└── README.md
```

---

# How to Reproduce the Deployment

## 1. Clone the Repository

```bash
git clone https://github.com/kajalkumarikkv/8byte-devops-assignment.git
cd 8byte-devops-assignment
```

## 2. Provision AWS Infrastructure

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

## 3. Configure Jenkins

Create a Jenkins Pipeline connected to the GitHub repository.

Configure the required Jenkins credentials:

```text
dockerhub-credentials
ec2-ssh-key
gmail-smtp
```

## 4. Run the Pipeline

Jenkins executes:

```text
Unit Tests
     ↓
Docker Build
     ↓
Trivy Scan
     ↓
Docker Hub Push
     ↓
CloudWatch Configuration
     ↓
Staging Deployment
     ↓
Staging Test
     ↓
Production Approval
     ↓
Production Deployment
     ↓
Production Test
```

## 5. Monitor the Environment

Use Amazon CloudWatch to review:

* Infrastructure dashboard
* Application dashboard
* CloudWatch Logs
* ALB metrics
* RDS metrics
* 5XX alarm

---

# Conclusion

This project demonstrates a complete DevOps workflow covering infrastructure provisioning, containerization, CI/CD, security scanning, staged deployment, production approval, monitoring, logging, alerting, and documentation.

The implementation is designed to be reproducible using Terraform and Jenkins while following basic DevOps security and operational practices.
