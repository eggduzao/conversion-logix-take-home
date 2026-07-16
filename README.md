# Delivery Package

Contents:

- `SOLUTION.md`: compressed human-readable report.
- `SOURCE_NOTE.txt`: provenance note for the source document used to prepare this package.
- `scripts/`: sanitized, reusable shell/project scripts organized by completed step.
- `infrastructure/`: sanitized bootstrapping approach to build the infrastructure using Terraform

Important:

- Scripts are reference/reproduction artifacts, not a single unattended installer.
- Review environment variables and cloud context before executing anything.
- No credentials or service-account keys are included.
- `terraform apply` is intentionally absent because the current checkpoint is plan review.
