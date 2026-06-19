# Cost Analysis - VaultPay Platform

## Monthly Cost Breakdown by Service (Estimated, us-east-1)

| Service | Resource | Estimated Monthly Cost |
|---|---|---|
| EC2 | 3x t3.micro (avg, auto-scaled 3-6) | ~$22.50 |
| RDS | 1x db.t3.micro, 20GB storage | ~$13.50 |
| NAT Gateway | 1x (hourly + data processing) | ~$33.00 |
| Application Load Balancer | 1x ALB | ~$16.50 |
| Data Transfer | Estimated low traffic (dev) | ~$2.00 |
| CloudWatch | Dashboard + 5 alarms + logs | ~$3.00 |
| Secrets Manager | 1x secret | ~$0.40 |
| S3 (Terraform state + CloudTrail) | Minimal storage | ~$1.00 |
| **Total Estimated** | | **~$92/month** |

Note: This is a development environment running continuously. Actual cost depends on traffic, scaling events, and whether the environment is destroyed when not in use.

## Cost Allocation Strategy

Resources are tagged with:
- `Project = vaultpay-dev`
- `Name = <resource-specific>`

Recommended next step: add `Environment` and `Owner` tags consistently across all modules for chargeback reporting in Cost Explorer.

## Cost Optimization Strategies Applied

1. **Auto Scaling Group** - avoids paying for fixed peak capacity 24/7; scales down to minimum (3 instances) during low traffic
2. **Right-sized instances** - t3.micro for both EC2 and RDS, appropriate for a dev/demo workload with low sustained load
3. **Single NAT Gateway** - in dev, one NAT Gateway shared across both AZs instead of one per AZ, reducing fixed hourly cost
4. **CloudWatch log retention set to 30 days** - prevents unbounded log storage cost growth

## Savings Achieved

Compared to a fixed-capacity design with 6 always-on EC2 instances and one NAT Gateway per AZ:
- Auto Scaling at minimum capacity (3 vs 6 instances): ~$22.50/month saved
- Single NAT Gateway vs two: ~$33/month saved

**Total estimated savings: ~$55/month (around 37% lower than a non-optimized equivalent)**

## Scaling Cost Projections

| Scenario | Estimated Monthly Cost |
|---|---|
| Minimum load (3 instances, low traffic) | ~$92 |
| Peak load (6 instances, high traffic) | ~$115 |
| Production (Multi-AZ RDS, 2x NAT, HTTPS/ACM) | ~$160-180 |

## Reserved Instance Recommendations

For a production deployment with predictable baseline traffic, switching the minimum 3 EC2 instances and the RDS instance to 1-year Reserved Instances could reduce compute costs by approximately 30-40%. Not applied in this dev environment due to the short-lived nature of the project.

## Budget Alerts Configured

CloudWatch alarms are configured for performance (CPU, unhealthy hosts, 5xx errors) as documented in SECURITY.md and the monitoring module. A dedicated AWS Budget with a monthly threshold alert is a recommended next step, not yet implemented in this phase.