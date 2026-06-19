# VaultPay Platform

Production-ready fintech infrastructure on AWS, built as a Cloud Engineering Bootcamp capstone project.

## Live Demo

http://vaultpay-dev-alb-355929396.us-east-1.elb.amazonaws.com

Try the interactive buttons: Health Check, Database Status, and Live Metrics (pulls real data from CloudWatch).

## Architecture

Internet -> ALB -> Auto Scaling Group (EC2, Multi-AZ) -> RDS PostgreSQL
                          |
                  AWS Secrets Manager
                  CloudWatch Dashboard + Alarms + SNS
                  VPC Flow Logs + CloudTrail
                  Security Hub (CIS Benchmark)

## Infrastructure

- **VPC**: 10.0.0.0/16, multi-AZ (us-east-1a, us-east-1b)
- **Subnets**: Public (ALB), Private-App (EC2), Private-Data (RDS) - fully isolated tiers
- **Load Balancer**: Application Load Balancer with health checks on /health
- **Compute**: Auto Scaling Group (3-6 instances) scaling on CPU utilization
- **Database**: RDS PostgreSQL, encrypted at rest, private subnet only
- **Secrets**: AWS Secrets Manager for database credentials (no hardcoded secrets)
- **Monitoring**: CloudWatch dashboard, alarms, SNS email alerts
- **Security**: VPC Flow Logs, CloudTrail multi-region trail, Security Hub CIS Benchmark
- **CI/CD**: GitHub Actions - Terraform format check, validate, plan on every push

## Tech Stack

- Terraform (modular IaC, remote state on S3 + DynamoDB with locking)
- AWS: VPC, EC2, Auto Scaling, ALB, RDS, Secrets Manager, CloudWatch, SNS, CloudTrail, Security Hub
- GitHub Actions for CI/CD
- Python (standard library) for the application server

## Modules

| Module | Responsibility |
|---|---|
| terraform/modules/networking | VPC, subnets, NAT Gateway, route tables |
| terraform/modules/compute | Auto Scaling Group, ALB, IAM roles, security groups |
| terraform/modules/database | RDS PostgreSQL, Secrets Manager |
| terraform/modules/monitoring | CloudWatch dashboard, alarms, SNS |

## Quick Start

cd terraform/bootstrap && terraform init && terraform apply
cd ../enviroments/dev && terraform init && terraform apply

## Testing

./scripts/stress-test.sh      # Generates load to test CPU alarms and auto scaling
./scripts/failover-demo.sh    # Demonstrates ALB failover when an instance fails

## Cost Estimate

See COSTS.md for full breakdown.

## Documentation

- ARCHITECTURE.md - Detailed component design and decisions
- SECURITY.md - Security controls and compliance
- RUNBOOK.md - Operations guide
- COSTS.md - Cost analysis
- RETROSPECTIVE.md - Lessons learned