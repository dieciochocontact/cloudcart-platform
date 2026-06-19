# Operations Runbook - VaultPay Platform

## How to Deploy Infrastructure

```bash
# 1. Deploy the remote state backend (one time only)
cd terraform/bootstrap
terraform init
terraform apply

# 2. Deploy the full platform
cd ../enviroments/dev
terraform init
terraform apply
```

## How to Update the Application

The application code lives inside the EC2 user_data script in `terraform/modules/compute/main.tf`. To deploy a code change:

```bash
cd terraform/enviroments/dev
# After editing main.tf, force instance recreation:
terraform apply -replace="module.compute.aws_autoscaling_group.app"
```

Wait 3-5 minutes for new instances to boot and pass health checks before verifying.

## How to Monitor System Health

1. **CloudWatch Dashboard**: AWS Console -> CloudWatch -> Dashboards -> vaultpay-dev-dashboard
2. **In-app Live Metrics**: visit the ALB DNS name and click "Live Metrics"
3. **Target health**: 
```bash
TG_ARN=$(aws elbv2 describe-target-groups --names vaultpay-dev-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN --output table
```
4. **Auto Scaling status**:
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names vaultpay-dev-asg --query 'AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize,Instances]'
```

## Common Troubleshooting Scenarios

### Targets showing unhealthy

Check the application log via SSM Session Manager:
```bash
aws ssm start-session --target <instance-id>
sudo cat /var/log/cloud-init-output.log
cat /tmp/server.log
```

### 502 Bad Gateway from the ALB

Usually means instances are still booting or the user_data script failed. Wait 3-5 minutes; if it persists, force replacement:
```bash
terraform apply -replace="module.compute.aws_autoscaling_group.app"
```

### Database connection errors

Verify the secret exists and the app role has access:
```bash
aws secretsmanager get-secret-value --secret-id vaultpay-dev/db-credentials --query SecretString
aws iam list-role-policies --role-name vaultpay-dev-app-role
```

## Incident Response Procedures

1. Check CloudWatch alarms first - they indicate which component triggered the alert
2. Check target health and Auto Scaling Group status
3. Check CloudTrail for any recent unexpected API calls
4. If instances are unhealthy, allow Auto Scaling Group to self-heal (it replaces unhealthy instances automatically)
5. If database is unreachable, check the db-sg security group rules and RDS instance status
6. Document the incident: what happened, root cause, and resolution

## Backup and Recovery Procedures

- RDS automated backups: 7-day retention, configured by default
- Terraform state: versioned in S3, previous versions recoverable via S3 console
- To restore RDS from a backup: use AWS Console -> RDS -> Snapshots, or `aws rds restore-db-instance-from-db-snapshot`

## Scaling Procedures

Scaling is automatic via CloudWatch alarms:
- Scale up: CPU > 70% for 2 consecutive 60-second periods
- Scale down: CPU < 20% for 2 consecutive 60-second periods

To manually adjust capacity:
```bash
aws autoscaling set-desired-capacity --auto-scaling-group-name vaultpay-dev-asg --desired-capacity 5
```

## Cleanup / Destroy

```bash
cd terraform/enviroments/dev
terraform destroy
# Only if decommissioning the project entirely:
cd ../../bootstrap
terraform destroy
```