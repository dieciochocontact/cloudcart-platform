# Architecture Documentation - VaultPay Platform

## Overview

VaultPay is a 3-tier fintech infrastructure designed for high availability, security isolation, and operational visibility. The architecture follows AWS Well-Architected Framework principles: multi-AZ deployment, least-privilege access, defense in depth, and infrastructure as code.

## Component Description

### Tier 1 - Presentation (Public Subnets)

An Application Load Balancer receives all incoming HTTP traffic and distributes it across the Auto Scaling Group instances. Health checks on /health every 10 seconds ensure traffic only reaches healthy instances.

### Tier 2 - Application (Private Subnets)

An Auto Scaling Group (min 3, max 6, desired 3) runs the application server, launched from a Launch Template defining the AMI, instance type, IAM instance profile, and user data script. The application is a lightweight Python HTTP server exposing:

- / - main page with interactive demo buttons
- /health - health check endpoint used by the ALB
- /api/db - tests live connection to RDS
- /api/metrics - pulls real-time CPU and alarm state from CloudWatch

Scaling policies add an instance when average CPU exceeds 70% for two consecutive periods, and remove one when CPU drops below 20%.

### Tier 3 - Data (Private Subnets, Isolated)

RDS PostgreSQL runs in a dedicated subnet group spanning two AZs, with no internet route. Credentials are generated randomly at creation time and stored exclusively in AWS Secrets Manager - never written in code or configuration files.

## Network Design

| Layer | CIDR | Purpose |
|---|---|---|
| VPC | 10.0.0.0/16 | Overall network boundary |
| Public Subnets | 10.0.0.0/24, 10.0.1.0/24 | ALB only |
| Private App Subnets | 10.0.10.0/24, 10.0.11.0/24 | EC2 instances |
| Private Data Subnets | 10.0.20.0/24, 10.0.21.0/24 | RDS only |

A single NAT Gateway in the public subnet allows private instances to reach the internet for package installs, without being reachable from the internet themselves.

## Security Groups

| Security Group | Inbound | Purpose |
|---|---|---|
| alb-sg | 80 from 0.0.0.0/0 | Public web traffic |
| app-sg | 80 from alb-sg only, 22 from VPC CIDR | App tier isolation |
| db-sg | 5432 from app-sg only | Database isolation |

## High Availability Strategy

- Resources span two Availability Zones (us-east-1a, us-east-1b)
- Auto Scaling Group automatically replaces unhealthy instances
- ALB health checks remove failing targets from rotation within seconds
- RDS subnet group spans both AZs, enabling future Multi-AZ failover

## Scalability Considerations

- Auto Scaling Group handles horizontal scaling automatically based on CPU
- Stateless application design (no local session storage) allows any instance to serve any request
- Database connection is established per-request, avoiding connection pool exhaustion at small scale

## Technology Choices and Rationale

| Choice | Why |
|---|---|
| Terraform over manual console clicks | Reproducible, versioned, reviewable in PRs |
| Modular structure (networking/compute/database/monitoring) | Reusability and separation of concerns |
| Python standard library over a framework | Zero external dependencies, fast boot time |
| RDS over self-managed database on EC2 | Automated backups, patching, and encryption |
| Secrets Manager over environment variables | Credentials never appear in code, Terraform state, or logs |

## Trade-offs and Alternatives Considered

- EC2 in Auto Scaling Group vs. ECS/Fargate: chose EC2 for simplicity within the bootcamp timeline; containerizing the app is a documented next step.
- Application code baked into user_data vs. separate deployment pipeline: chose user_data for speed of iteration; this means every code change requires instance replacement, which is acceptable for this scale but would not be for frequent deploys.
- Single NAT Gateway vs. one per AZ: chose single NAT for cost in the dev environment; production would use one per AZ for full AZ-independence.