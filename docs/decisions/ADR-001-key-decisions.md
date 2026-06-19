# Architecture Decision Record - VaultPay Platform

## ADR-001: Modular Terraform Structure

**Status:** Accepted

**Context:** The project needed to manage networking, compute, database, and monitoring resources for a multi-tier application.

**Decision:** Split the infrastructure into four independent Terraform modules (networking, compute, database, monitoring), called from a single environment configuration (environments/dev).

**Consequences:** Each module can be understood, tested, and modified independently. Adding a second environment (prod) would only require a new environments/prod folder reusing the same modules with different variable values.

---

## ADR-002: Auto Scaling Group instead of Fixed EC2 Instances

**Status:** Accepted (superseded an earlier design)

**Context:** The initial design used 3 fixed EC2 instances created directly by Terraform. This does not reflect real production behavior and does not handle load increases automatically.

**Decision:** Replace fixed instances with a Launch Template and Auto Scaling Group (min 3, max 6), scaling based on CPU utilization.

**Consequences:** Required refactoring monitoring to use ASG-level and ALB-level metrics instead of per-instance alarms. Resulted in a more realistic and resilient architecture, at the cost of additional complexity during the migration.

---

## ADR-003: Secrets Manager over Environment Variables

**Status:** Accepted

**Context:** The application needs database credentials to connect to RDS.

**Decision:** Generate the database password randomly with Terraform and store it exclusively in AWS Secrets Manager. The application retrieves it at runtime using its IAM role - never via environment variables or hardcoded values.

**Consequences:** Slightly more complex application code (one extra API call per request), but credentials are never exposed in the codebase, Terraform configuration files, or version control.

---

## ADR-004: Single NAT Gateway in Development

**Status:** Accepted, with a documented limitation

**Context:** A NAT Gateway is required for private subnets to reach the internet. AWS best practice is one NAT Gateway per Availability Zone for full AZ-independence.

**Decision:** Use a single NAT Gateway for the development environment to reduce cost, accepting that a NAT Gateway failure would affect both AZs.

**Consequences:** Lower monthly cost (~$33 saved). Documented in COSTS.md and SECURITY.md as a known risk, with the production recommendation being one NAT Gateway per AZ.