# Security Documentation - VaultPay Platform

## Security Controls Implemented

### Network Security

- VPC with 3 isolated subnet tiers (public, private-app, private-data)
- Database subnet has no route to the internet
- Security groups follow least privilege: each tier only accepts traffic from the tier directly above it
- VPC Flow Logs capture all accepted and rejected traffic, sent to CloudWatch Logs

### Identity and Access Management

- EC2 instances use an IAM role via instance profile - no access keys stored anywhere
- IAM role scoped to exactly three permissions: CloudWatch Agent, SSM Session Manager, and read-only access to one specific Secrets Manager secret
- No wildcard (*) resource permissions except where AWS requires it (CloudWatch read-only metrics)

### Secrets Management

- Database password generated randomly by Terraform (random_password resource) at creation time
- Credentials stored exclusively in AWS Secrets Manager as a single JSON secret
- Application retrieves credentials at runtime via the AWS SDK - never hardcoded, never in environment variables, never in Terraform state in plaintext on disk (state is stored encrypted in S3)

### Encryption

- RDS storage encrypted at rest
- Terraform state bucket encrypted with AES256, versioned, and blocks all public access
- CloudTrail logs delivered to an S3 bucket with a policy restricting write access to the CloudTrail service only

### Audit and Compliance

- CloudTrail: multi-region trail logging every API call made in the account
- VPC Flow Logs: full network traffic visibility with 30-day retention
- AWS Security Hub: enabled with AWS Foundational Security Best Practices and CIS AWS Foundations Benchmark standards

## Compliance Frameworks Addressed

| Framework | Status |
|---|---|
| CIS AWS Foundations Benchmark | Enabled via Security Hub |
| AWS Foundational Security Best Practices | Enabled via Security Hub |

## IAM Roles and Policies Summary

| Role | Attached Policies | Purpose |
|---|---|---|
| vaultpay-dev-app-role | CloudWatchAgentServerPolicy, AmazonSSMManagedInstanceCore, custom Secrets Manager read policy, custom CloudWatch read policy | Allows app servers to report metrics, accept SSM sessions, read DB credentials, and read CloudWatch metrics |
| vaultpay-flow-logs-role | Custom CloudWatch Logs write policy | Allows VPC Flow Logs service to deliver logs |

## Network Security Strategy

Traffic can only move in one direction through the tiers: Internet to ALB, ALB to App, App to Database. There is no path that allows the internet to reach the application servers or the database directly. SSH access to app servers is restricted to the VPC CIDR range only, and SSM Session Manager is available as a keyless alternative.

## Security Testing Results

- Verified database security group only accepts connections from the app tier security group, confirmed via Terraform plan output
- Verified IAM role does not include any wildcard permissions beyond AWS-managed read-only policies
- Confirmed Secrets Manager secret is not exposed in any application HTTP response (the app only reports connection status, not credential values)

## Known Risks and Mitigations

| Risk | Mitigation | Status |
|---|---|---|
| No HTTPS on the ALB | Documented as a next step; would require ACM certificate and a custom domain | Accepted for this phase |
| Single NAT Gateway is a potential availability bottleneck | Acceptable for dev; production design would use one NAT per AZ | Documented |
| Application code embedded in user_data | Limits independent code deployment; documented tradeoff in ARCHITECTURE.md | Accepted for this phase |