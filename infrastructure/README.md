# Terraform Infrastructure - Modular Multi-Environment Setup

This directory contains Terraform code organized into reusable modules for deploying infrastructure across multiple environments (dev, staging, production).

## Directory Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, NAT, IGW
│   ├── security/              # Security groups
│   ├── rds/                   # RDS MySQL database
│   ├── ecr/                   # ECR repositories
│   ├── ecs/                   # ECS Fargate cluster and services
│   └── s3-cloudfront/         # S3 bucket and CloudFront CDN
└── environments/              # Environment-specific configurations
    ├── dev/                   # Development environment
    ├── staging/               # Staging environment
    └── prod/                  # Production environment
```

## Modules Overview

### 1. **Networking Module** (`modules/networking`)
Creates the foundational network infrastructure:
- VPC with customizable CIDR blocks
- Public and private subnets across multiple AZs
- Internet Gateway for public subnet connectivity
- NAT Gateway for private subnet internet access
- Route tables and associations

### 2. **Security Module** (`modules/security`)
Manages security groups:
- ALB security group (HTTP/HTTPS ingress)
- ECS security group (backend port access from ALB)
- RDS security group (MySQL access from ECS)

### 3. **RDS Module** (`modules/rds`)
Provisions managed MySQL database:
- Configurable instance class and storage
- Multi-AZ support for production
- Automated backups with configurable retention
- Subnet group for private subnet placement

### 4. **ECR Module** (`modules/ecr`)
Creates container registries:
- Backend and frontend ECR repositories
- Image scanning on push
- Lifecycle policies to manage image retention

### 5. **ECS Module** (`modules/ecs`)
Deploys containerized applications:
- ECS Fargate cluster
- Application Load Balancer (ALB)
- Task definitions and services
- CloudWatch log groups
- IAM roles for task execution

### 6. **S3-CloudFront Module** (`modules/s3-cloudfront`)
Hosts static frontend:
- S3 bucket with private access
- CloudFront distribution with OAC
- Custom error pages for SPA routing
- Optional versioning

## Environment Configurations

Each environment has its own configuration with environment-specific settings:

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Subnets | 2 AZs | 2 AZs | 3 AZs |
| ECS CPU | 256 | 512 | 1024 |
| ECS Memory | 512 MB | 1024 MB | 2048 MB |
| ECS Tasks | 1 | 2 | 3 |
| RDS Instance | db.t3.micro | db.t3.small | db.t3.medium |
| RDS Multi-AZ | No | No | Yes |
| RDS Backup Retention | 0 days | 7 days | 30 days |
| Deletion Protection | No | No | Yes |
| CloudWatch Logs | 7 days | 14 days | 30 days |
| Container Insights | Disabled | Enabled | Enabled |

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (v1.5.0 or later)
3. **AWS CLI** configured
4. **GitHub repository** with Actions enabled

## AWS Setup Requirements

### 1. Create IAM OIDC Identity Provider for GitHub Actions

This allows GitHub Actions to authenticate with AWS without storing long-lived credentials.

```bash
# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create OIDC provider for GitHub
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. Create IAM Role for GitHub Actions

Create an IAM role that GitHub Actions will assume:

**Trust Policy** (`github-actions-trust-policy.json`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

Create the role:
```bash
# Replace with your values
ACCOUNT_ID="123456789012"
GITHUB_ORG="your-org"
GITHUB_REPO="your-repo"

# Update trust policy with your values
sed -i "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" github-actions-trust-policy.json
sed -i "s/YOUR_GITHUB_ORG/$GITHUB_ORG/g" github-actions-trust-policy.json
sed -i "s/YOUR_REPO_NAME/$GITHUB_REPO/g" github-actions-trust-policy.json

# Create the role
aws iam create-role \
  --role-name GitHubActionsTerraformRole \
  --assume-role-policy-document file://github-actions-trust-policy.json \
  --description "Role for GitHub Actions to deploy Terraform"
```

### 3. Attach Permissions to the Role

Attach necessary permissions for Terraform to create resources:

```bash
# Attach AWS managed policies
aws iam attach-role-policy \
  --role-name GitHubActionsTerraformRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# For production, use least-privilege custom policy instead
# Create a custom policy with only required permissions:
# - EC2 (VPC, Subnets, Security Groups, NAT, IGW)
# - RDS (Create/Modify/Delete DB instances)
# - ECS (Cluster, Service, Task Definition)
# - ECR (Repository management)
# - S3 (Bucket creation and management)
# - CloudFront (Distribution management)
# - IAM (Role creation for ECS tasks)
# - CloudWatch (Log groups)
```

**Recommended: Create Custom Policy** (`terraform-permissions.json`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "ecs:*",
        "ecr:*",
        "s3:*",
        "cloudfront:*",
        "elasticloadbalancing:*",
        "logs:*",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies",
        "iam:GetRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### 4. (Optional) Set Up S3 Backend for State Management

For team collaboration, store Terraform state in S3:

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Then uncomment the backend configuration in each environment's `main.tf`.

### 5. Configure GitHub Secrets and Variables

Add the following to your GitHub repository:

**Secrets** (Settings → Secrets and variables → Actions → Secrets):
- `AWS_ROLE_ARN`: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsTerraformRole`
- `MYSQL_PASSWORD`: Secure password for RDS (per environment if needed)

**Variables** (Settings → Secrets and variables → Actions → Variables):
- `AWS_REGION`: `us-east-1` (or your preferred region)

**Environment-specific secrets** (Settings → Environments):
Create three environments: `dev`, `staging`, `prod`
- Each can have its own `MYSQL_PASSWORD` and `AWS_ROLE_ARN` if needed

## Local Development

### Initialize and Deploy

1. Navigate to the environment directory:
```bash
cd terraform/environments/dev
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review the plan:
```bash
export TF_VAR_mysql_password="your-secure-password"
terraform plan
```

4. Apply the configuration:
```bash
terraform apply
```

5. View outputs:
```bash
terraform output
```

### Destroy Infrastructure

```bash
terraform destroy
```

## GitHub Actions Workflows

The repository includes several workflows:

### 1. **terraform-plan.yml**
- Triggers on PRs to main/develop
- Runs `terraform plan` for the target environment
- Posts plan results as PR comment

### 2. **terraform-apply-dev.yml**
- Triggers on push to `develop` branch
- Automatically deploys to dev environment

### 3. **terraform-apply-staging.yml**
- Triggers on push to `staging` branch
- Deploys to staging environment

### 4. **terraform-apply-prod.yml**
- Triggers on push to `main` branch
- Deploys to production environment
- Requires manual approval (configure in GitHub environment settings)

### 5. **terraform-destroy.yml**
- Manual workflow to destroy infrastructure
- Requires confirmation input

## Workflow Strategy

```
Feature Branch → PR → develop → Deploy to Dev
                               ↓
                          staging → Deploy to Staging
                               ↓
                            main → Deploy to Production
```

## Best Practices

1. **State Management**: Use S3 backend for team collaboration
2. **Secrets**: Never commit secrets; use GitHub Secrets or AWS Secrets Manager
3. **Plan Before Apply**: Always review terraform plan output
4. **Environment Isolation**: Each environment has separate VPCs and resources
5. **Tags**: All resources are tagged with Environment and Project
6. **Least Privilege**: Use minimal IAM permissions required
7. **Multi-AZ**: Enable for production (already configured)
8. **Backups**: RDS automated backups enabled for staging/prod
9. **Monitoring**: CloudWatch Container Insights enabled for staging/prod
10. **Branch Protection**: Require PR reviews before merging to main

## Troubleshooting

### Issue: "No valid credential sources found"
**Solution**: Ensure AWS credentials are configured or GitHub OIDC is set up correctly.

### Issue: "Error acquiring the state lock"
**Solution**: Another deployment is in progress, or previous deployment failed. Check DynamoDB lock table.

### Issue: "AccessDenied" errors
**Solution**: Verify IAM role permissions are sufficient for all required AWS services.

### Issue: RDS creation takes long time
**Solution**: RDS instances typically take 10-15 minutes to create. This is normal.

## Cost Optimization

- **Dev**: Uses smallest instance sizes, no Multi-AZ
- **Staging**: Moderate sizes, automated backups
- **Production**: Production-grade with HA, backups, and monitoring

Estimated monthly costs (us-east-1):
- **Dev**: ~$50-80/month
- **Staging**: ~$150-200/month
- **Production**: ~$400-600/month

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review GitHub Actions logs
3. Check CloudWatch logs for ECS tasks
4. Review Terraform state for resource details
