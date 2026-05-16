# HA-SYSTEM AWS Multi-Region Terraform

This repository contains a scalable Terraform scaffold for a high-availability multi-region AWS deployment.

## What is included

- `modules/network` - VPC, public/private subnets, NAT gateway, routing, security groups
- `modules/compute` - EKS cluster with ALB integration, optional ACM HTTPS
- `modules/database` - Aurora PostgreSQL cluster and optional global cluster support
- `modules/global` - Route53 health checks and weighted DNS routing across regions
- `environments/prod` - provider configuration, backend state, and environment-specific module wiring

## Regions supported
- `us-east-1` (primary)
- `eu-west-1` (secondary)

## Setup
1. Create the Terraform S3 backend bucket and DynamoDB lock table before running.
2. Update `environments/prod/terraform.tfvars` with your Route53 hosted zone, domain, and secrets.
3. Run `terraform init` from `environments/prod`.
4. Run `terraform plan` and `terraform apply`.

## Notes
- This project uses AWS EKS for stateless app deployment and Aurora for regional database clusters.
- The database module can be configured for Aurora Global Database replication by setting `global_cluster_identifier`.
- Route53 health checks and weighted DNS route traffic to both regions with failover support.
