# AWS 3-tier Architecture

This AWS Architecture is a fully modular, production-grade 3-tier infrastructure built on AWS using Terraform. It was created to showcase practical, real-world cloud engineering skills through secure, scalable architecture, infrastructure as code, monitoring, and CI/CD automation. It simulates a backend foundation suitable for internal business tools, CRMs, or enterprise web apps.

---

## Tech Stack

- Cloud: AWS  
- Infrastructure as Code: Terraform  
- Compute: EC2 (Auto Scaling Group)  
- Load Balancer: Application Load Balancer (ALB)  
- Database: RDS MySQL  
- Secrets Management: AWS Secrets Manager / SSM Parameter Store  
- Monitoring: Amazon CloudWatch  
- CI/CD: GitHub Actions  
- State Management: S3 + DynamoDB  
- Scripting: Bash

---

## Features

- Provisions a full 3-tier AWS architecture using Terraform  
- Deploys EC2 instances in an Auto Scaling Group behind an ALB  
- Uses secure IAM roles and policies for access control  
- Stores secrets in AWS-managed encrypted services  
- Sends alarms and monitors metrics using CloudWatch  
- Separates dev and prod environments via tfvars files  
- Enables push-based deployments using GitHub Actions CI/CD  
- Manages Terraform state remotely with S3 backend and DynamoDB locking

---

## Deployment Verification

**Infrastructure Status**: Deployed and operational in us-east-1

**Validated Components**:
- Auto Scaling Group maintaining 1-3 instances based on CPU metrics
- Application Load Balancer distributing traffic with passing health checks
- RDS MySQL database accessible from application tier
- CloudWatch alarms configured and tested (CPU, unhealthy targets)
- Secrets Manager storing database credentials securely
- Terraform state management with S3 backend and DynamoDB locking

**Testing Performed**:
- Load tested ALB with Apache Bench (1000 requests, 10 concurrent)
- Triggered auto-scaling by inducing CPU load with stress tool
- Verified RDS connection from EC2 instances using mysql client
- Simulated instance failure and confirmed ASG auto-recovery
- Validated CloudWatch alarms by crossing configured thresholds

**For common issues and resolutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**

---

## Monthly Cost Estimate (Dev Setup)

| Service                   | Est. Monthly Cost |
|---------------------------|-------------------|
| EC2 t3.micro (1x)         | $7.60             |
| EBS gp3 (20 GB)           | $1.60             |
| ALB + 1 LCU               | $24.24            |
| RDS db.t3.micro + 20GB    | $15–22            |
| Secrets Manager (1x)      | $0.40             |
| CloudWatch (logs + alarms)| $0.90             |
| S3 + DynamoDB backend     | $0.30             |
| Data Transfer (~50GB)     | $4.50             |
| **Total**                 | **$50–$55/month** |

> Small production setup with 2 EC2s and higher traffic: ~$60–$80/month

---

## Cost Optimization

- Disable ALB in dev and use EC2 public IPs  
- Replace Secrets Manager with free SSM Parameter Store  
- Use t4g.micro instead of t3.micro if AMI supports ARM  
- Stop EC2 and RDS when not in use  
- Use Aurora Serverless v2 for bursty or intermittent workloads  
- Set log retention in CloudWatch to 1–3 days  
- Stay within Free Tier where eligible

---

## CI/CD Pipeline

CI/CD is managed with GitHub Actions. It performs:

- `terraform fmt` formatting checks  
- `terraform validate` syntax validation  
- Terraform plan with optional manual approval  
- Secure secret management via GitHub repository settings  

All commits to `main` or pull requests trigger the pipeline.

---

## Manual Deployment

```bash
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

To destroy and remove all infrastructure:

```bash
terraform destroy -var-file="dev.tfvars"
```

---

## Author

**Steven Lewis**  
GitHub: [github.com/sjlewis25](https://github.com/sjlewis25)
