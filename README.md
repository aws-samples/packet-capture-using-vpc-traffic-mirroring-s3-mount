# traffic-mirroring-pkt-capture-s3

This Terraform code is the companion to the blog post [here](https://www.comingsoon.lab).

## Prerequisites

To deploy this code, you will need a `terraform-deployment-role` in each of the accounts you plan to deploy to (both hub and spokes). The role will require sufficient permissions that includes access to create IAM roles, S3 bucket, SNS topics, KMS keys, Lambda, EC2, VPC, ELB, CloudWatch logs to deploy the infrastructure.

## Getting Started

To get started, update the `terraform.tfvars` file with your variables, then deploy `terraform` on the root directory via the deployment mechanism of your choice.

### Warning to Windows users

Git may change line endings for files in this repository. This can prevent scripts from executing correctly on the EC2 instances. To prevent this, you can run `git config core.autocrlf false` or change the line endings of the `.sh` amd `.tpl` files manually.
