# Incident Report INC-001: 502 Bad Gateway After Application Update

## Summary

After updating the application's user_data script to add RDS connectivity, the ALB began returning 502 Bad Gateway errors for all requests.

## Timeline

1. Updated `modules/compute/main.tf` to add database connectivity code in the user_data script
2. Ran `terraform apply` - Terraform reported changes applied successfully (4 changed)
3. Tested the ALB endpoint - received 502 Bad Gateway
4. Checked target group health - all targets unhealthy
5. Connected via SSM Session Manager to inspect instance logs
6. Found `/tmp/server.log` empty and `cloud-init-output.log` showing the original boot sequence, not the updated script

## Root Cause

Terraform's `user_data` field only re-runs cloud-init on instances created from scratch. Updating `user_data` in the Terraform configuration and running `apply` updates the instance attribute in AWS, but does not trigger the instance to re-execute the new script if the instance already exists and was not replaced.

## Resolution

Used Terraform's `-replace` flag to force destruction and recreation of the affected resources:

```bash
terraform apply -replace="module.compute.aws_instance.app[0]" -replace="module.compute.aws_instance.app[1]" -replace="module.compute.aws_instance.app[2]"
```

This forced new instances to boot with the updated user_data, resolving the issue within 5 minutes.

## Impact

Development environment only, no production traffic affected. Total downtime: approximately 15 minutes during development and testing.

## Prevention / Follow-up Actions

- Documented this behavior in RUNBOOK.md under "How to Update the Application"
- Identified as a key argument for moving application deployment out of user_data and into a proper CI/CD-driven deployment pipeline (containerization or a configuration management tool) as a future improvement