# Retrospective - VaultPay Platform

## What Went Well

- Successfully built a complete 3-tier architecture entirely as Terraform code, with clean module separation (networking, compute, database, monitoring)
- Got a real, working connection from the application to RDS PostgreSQL using Secrets Manager, with no hardcoded credentials anywhere
- Integrated live CloudWatch metrics directly into the application UI, which made the project feel like a real product rather than just infrastructure
- CI/CD pipeline with GitHub Actions worked end to end, validating every change before it could reach AWS
- Migrated from fixed EC2 instances to a proper Auto Scaling Group mid-project, which pushed the monitoring design to be more production-realistic

## Challenges Faced

- Ran into a 502 Bad Gateway issue after updating the application code, because Terraform does not restart existing instances when user_data changes - only new instances pick it up
- Had to recreate instances multiple times during development, which highlighted the limitation of embedding application code directly inside user_data instead of using a real deployment pipeline
- Switching to an Auto Scaling Group broke several Terraform outputs and CloudWatch alarms that were tied to individual instance IDs, requiring a redesign of the monitoring module
- Time constraints meant some planned features (HTTPS, CloudFront frontend, containerization) could not be implemented in this phase

## How Challenges Were Overcome

- Used `terraform apply -replace` to force clean instance recreation when user_data changes needed to take effect
- Refactored the monitoring module to use Auto Scaling Group-level and Load Balancer-level metrics instead of per-instance metrics, which is actually the more correct approach for a scaling environment
- Prioritized core requirements (networking, compute, database, monitoring, security, CI/CD) over advanced features given the limited timeline, and documented the rest as a clear roadmap

## Technical Skills Learned

- Designing and wiring together multiple Terraform modules with proper input/output relationships
- Managing Terraform remote state with S3 and DynamoDB locking in a real multi-environment setup
- Implementing least-privilege IAM roles and runtime secret retrieval instead of static credentials
- Building a CI/CD pipeline that validates infrastructure changes automatically
- Debugging real AWS issues (502 errors, target health, IAM permission errors) under time pressure

## Key Takeaways

- Infrastructure as Code is not just about automation - it is about making infrastructure reviewable, reproducible, and safe to change
- Security and observability are much easier to get right when designed in from the start, rather than added afterward
- Auto Scaling and load balancing concepts only really make sense once you have broken something by treating instances as permanent rather than disposable

## What I Would Do Differently

- Start with the Auto Scaling Group design from day one instead of fixed instances, to avoid the mid-project refactor
- Separate the application code from the Terraform user_data earlier, using a small deployment script or container image instead
- Write the documentation incrementally as each module was completed, rather than at the very end

## Future Improvements Planned

- Add HTTPS via ACM and a custom domain through Route 53
- Move the frontend to S3 + CloudFront, keeping only the API logic on EC2/containers
- Containerize the application for zero-downtime deployments
- Design a multi-region disaster recovery strategy
- Continue evolving VaultPay beyond the bootcamp as a long-term portfolio project