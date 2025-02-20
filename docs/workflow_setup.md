# Infrastructure Deployment Workflow

This repository uses GitHub Actions to automate infrastructure deployments to different environments using Terraform.

## Workflow Overview

The workflow automatically manages infrastructure deployments:
- `staging` branch deploys to staging environment
- `main` branch deploys to production environment

## Prerequisites

1. **AWS Setup**:
   - Create an IAM OIDC provider for GitHub Actions
   - Create separate IAM roles for staging and production with appropriate permissions
   - Roles should have permissions for your AWS resources (VPC, ECS, RDS, etc.)

2. **GitHub Secrets**:
   ```
   AWS_ROLE_ARN_PROD      - IAM role ARN for production
   AWS_ROLE_ARN_STAGING   - IAM role ARN for staging
   SLACK_WEBHOOK_URL      - (Optional) For deployment notifications
   ```

3. **Repository Structure**:
   ```
   .
   ├── .github/
   │   └── workflows/
   │       └── deploy.yml
   ├── environments/
   │   ├── staging/
   │   │   ├── main.tf
   │   │   ├── variables.tf
   │   │   └── staging.tfvars
   │   └── production/
   │       ├── main.tf
   │       ├── variables.tf
   │       └── prod.tfvars
   └── modules/
       ├── networking/
       ├── database/
       └── ecs/
   ```

## Workflow Features

1. **Safe Deployments**:
   - Runs `terraform fmt` check
   - Validates Terraform configuration
   - Creates plan and posts to PR comments
   - Only applies changes on merge/push to protected branches

2. **Environment Separation**:
   - Different AWS roles per environment
   - Separate state files
   - Environment-specific variables

3. **Security**:
   - Uses OIDC for AWS authentication
   - Minimal required permissions
   - Protected branches recommended for `main` and `staging`

## Setting Up OIDC Authentication

1. Create an OIDC provider in AWS:
   ```bash
   aws iam create-oidc-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1"
   ```

2. Create IAM roles:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:<ORGANIZATION>/*"
           }
         }
       }
     ]
   }
   ```

## Usage

1. **For Infrastructure Changes**:
   - Create a branch from `staging`
   - Make infrastructure changes
   - Create PR to `staging`
   - Review Terraform plan in PR comments
   - Merge to deploy to staging
   - Create PR from `staging` to `main` for production deployment

2. **Manual Triggers**:
   - Workflow can be triggered manually from GitHub Actions tab
   - Useful for re-running failed deployments

3. **Monitoring Deployments**:
   - Check GitHub Actions tab for deployment status
   - Review Slack notifications (if configured)
   - Terraform state stored in S3 (configure backend)

## Best Practices

1. **Branch Protection**:
   - Enable branch protection for `main` and `staging`
   - Require PR reviews
   - Enable status checks

2. **State Management**:
   - Use remote state (S3 + DynamoDB)
   - Separate state files per environment
   - Enable state locking

3. **Security**:
   - Regularly rotate AWS credentials
   - Review and update IAM roles permissions
   - Monitor CloudTrail for API activity

## Troubleshooting

Common issues and solutions:

1. **Terraform Init Fails**:
   - Check AWS credentials
   - Verify S3 backend access
   - Check for module source changes

2. **Plan Shows Unexpected Changes**:
   - Review state file for drift
   - Check for manual AWS console changes
   - Verify variable values in tfvars

3. **Apply Fails**:
   - Check AWS service quotas
   - Review IAM role permissions
   - Verify resource dependencies