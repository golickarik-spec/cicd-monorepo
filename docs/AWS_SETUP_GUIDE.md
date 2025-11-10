# AWS Setup Guide for GitHub Actions Terraform Deployment

This guide walks you through setting up your AWS environment to allow GitHub Actions to deploy Terraform infrastructure securely using OpenID Connect (OIDC).

## Overview

Instead of storing long-lived AWS credentials in GitHub, we'll use **OIDC** to allow GitHub Actions to temporarily assume an IAM role in your AWS account. This is more secure and follows AWS best practices.

## What You Need to Prepare in AWS

### Summary Checklist

- [ ] AWS Account with admin access
- [ ] Create OIDC Identity Provider for GitHub
- [ ] Create IAM Role for GitHub Actions
- [ ] Attach appropriate permissions to the role
- [ ] (Optional) Create S3 bucket and DynamoDB table for Terraform state
- [ ] Note down the IAM Role ARN for GitHub Secrets

---

## Step-by-Step Setup

### Step 1: Create OIDC Identity Provider

GitHub uses OIDC to prove its identity to AWS. You need to register GitHub as an identity provider in your AWS account.

**Using AWS CLI:**

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**Using AWS Console:**

1. Go to **IAM** → **Identity providers** → **Add provider**
2. Select **OpenID Connect**
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Click **Add provider**

**Verify:**
```bash
aws iam list-open-id-connect-providers
```

---

### Step 2: Create IAM Role for GitHub Actions

This role will be assumed by GitHub Actions to deploy your infrastructure.

#### 2.1: Create Trust Policy

Create a file named `github-actions-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:GITHUB_ORG/REPO_NAME:*"
        }
      }
    }
  ]
}
```

**Replace:**
- `ACCOUNT_ID`: Your AWS account ID (12 digits)
- `GITHUB_ORG`: Your GitHub username or organization name
- `REPO_NAME`: Your repository name

**Get your AWS Account ID:**
```bash
aws sts get-caller-identity --query Account --output text
```

#### 2.2: Create the Role

```bash
aws iam create-role \
  --role-name GitHubActionsTerraformRole \
  --assume-role-policy-document file://github-actions-trust-policy.json \
  --description "Role for GitHub Actions to deploy Terraform infrastructure"
```

**Save the Role ARN** (you'll need this for GitHub Secrets):
```bash
aws iam get-role --role-name GitHubActionsTerraformRole --query 'Role.Arn' --output text
```

Example ARN: `arn:aws:iam::123456789012:role/GitHubActionsTerraformRole`

---

### Step 3: Attach Permissions to the Role

The role needs permissions to create and manage AWS resources.

#### Option A: Quick Start (Broader Permissions)

For getting started quickly, use AWS managed policies:

```bash
# Attach PowerUserAccess (allows most actions except IAM user/group management)
aws iam attach-role-policy \
  --role-name GitHubActionsTerraformRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# IAM permissions for ECS task roles
aws iam attach-role-policy \
  --role-name GitHubActionsTerraformRole \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

⚠️ **Warning**: `PowerUserAccess` and `IAMFullAccess` are broad permissions. Use Option B for production.

#### Option B: Least Privilege (Recommended for Production)

Create a custom policy with minimal required permissions:

**Create file** `terraform-minimal-permissions.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformEC2Networking",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformRDS",
      "Effect": "Allow",
      "Action": [
        "rds:Describe*",
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:ModifyDBInstance",
        "rds:CreateDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource",
        "rds:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformECS",
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ecr:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformLoadBalancing",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformS3CloudFront",
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "cloudfront:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformCloudWatch",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:PutRetentionPolicy",
        "logs:DescribeLogGroups",
        "logs:ListTagsLogGroup",
        "logs:TagLogGroup",
        "logs:UntagLogGroup"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformIAM",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies",
        "iam:GetRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:GetPolicyVersion",
        "iam:GetPolicy",
        "iam:ListPolicyVersions"
      ],
      "Resource": "*"
    }
  ]
}
```

**Create and attach the policy:**

```bash
# Create the policy
aws iam create-policy \
  --policy-name TerraformDeploymentPolicy \
  --policy-document file://terraform-minimal-permissions.json

# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Attach to the role
aws iam attach-role-policy \
  --role-name GitHubActionsTerraformRole \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/TerraformDeploymentPolicy
```

---

### Step 4: (Optional but Recommended) Set Up Terraform State Backend

Terraform stores the state of your infrastructure. For team collaboration and safety, store it in S3 with DynamoDB locking.

#### 4.1: Create S3 Bucket for State

```bash
# Choose a unique bucket name
BUCKET_NAME="your-company-terraform-state"
REGION="us-east-1"

# Create bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION

# Enable versioning (allows rollback)
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

#### 4.2: Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION
```

#### 4.3: Update Terraform Backend Configuration

Uncomment and update the backend block in each environment's `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-company-terraform-state"
    key            = "cicd/dev/terraform.tfstate"  # Change for each env
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

---

### Step 5: Configure GitHub Repository

#### 5.1: Add Repository Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add:
- **Name**: `AWS_ROLE_ARN`
- **Value**: `arn:aws:iam::123456789012:role/GitHubActionsTerraformRole` (from Step 2)

Add:
- **Name**: `MYSQL_PASSWORD`
- **Value**: A secure password for your RDS database

#### 5.2: Add Repository Variables

Go to **Variables** tab → **New repository variable**

Add:
- **Name**: `AWS_REGION`
- **Value**: `us-east-1` (or your preferred region)

#### 5.3: (Optional) Configure Environments

For better control, set up GitHub Environments:

1. Go to **Settings** → **Environments**
2. Create three environments: `dev`, `staging`, `prod`
3. For `prod`, enable **Required reviewers** (add yourself/team)
4. Add environment-specific secrets if needed (e.g., different DB passwords)

---

## Testing the Setup

### Verify OIDC Setup Locally

You can test if your IAM role trust policy is correct:

1. Go to the GitHub Actions workflow file
2. Trigger a workflow run
3. Check the "Configure AWS Credentials" step
4. It should successfully assume the role

### Test Terraform Deployment

1. Push changes to the `develop` branch
2. GitHub Actions will automatically run terraform plan and apply
3. Check the Actions tab for workflow status
4. Review the deployment summary

---

## Security Best Practices

### 1. Limit Role to Specific Branches

Update the trust policy to only allow specific branches:

```json
"Condition": {
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
  },
  "StringLike": {
    "token.actions.githubusercontent.com:sub": [
      "repo:GITHUB_ORG/REPO_NAME:ref:refs/heads/main",
      "repo:GITHUB_ORG/REPO_NAME:ref:refs/heads/develop",
      "repo:GITHUB_ORG/REPO_NAME:ref:refs/heads/staging"
    ]
  }
}
```

### 2. Use Separate Roles per Environment

Create separate IAM roles for dev, staging, and prod:
- `GitHubActionsDevRole`
- `GitHubActionsStagingRole`
- `GitHubActionsProdRole`

Then use environment-specific secrets in GitHub.

### 3. Enable CloudTrail

Monitor all API calls:

```bash
aws cloudtrail create-trail \
  --name github-actions-trail \
  --s3-bucket-name your-cloudtrail-bucket
```

### 4. Rotate Database Passwords

Store RDS passwords in AWS Secrets Manager and reference them in Terraform:

```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "rds/mysql/password"
}
```

### 5. Enable MFA for Destructive Operations

For production, require MFA for terraform destroy or database deletions.

---

## Troubleshooting

### Error: "No OpenID Connect provider found"

**Solution**: Ensure you created the OIDC provider in Step 1. Verify:

```bash
aws iam list-open-id-connect-providers
```

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Solution**: Check your trust policy. Ensure:
- The Federated ARN matches your OIDC provider
- The `token.actions.githubusercontent.com:sub` matches your repo

### Error: "Access Denied" when creating resources

**Solution**: The IAM role lacks necessary permissions. Review and update the permissions policy in Step 3.

### Error: "Error acquiring state lock"

**Solution**: 
- Another workflow is running (wait for it to complete)
- Previous workflow failed (manually release lock in DynamoDB table)

```bash
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "your-lock-id"}}'
```

---

## Cost Considerations

### AWS Resources Created:
- **Free**:
  - IAM Role and Policies
  - OIDC Provider
  
- **Minimal Cost**:
  - S3 State Bucket: ~$0.023/GB/month
  - DynamoDB Table: Free tier (25 WCU/RCU)

### Infrastructure Costs (when deployed):
- **Dev**: ~$50-80/month
- **Staging**: ~$150-200/month  
- **Production**: ~$400-600/month

---

## Next Steps

1. ✅ Complete all steps in this guide
2. ✅ Test deployment to dev environment
3. Configure branch protection rules in GitHub
4. Set up monitoring and alerting (CloudWatch)
5. Document your deployment process for the team
6. Consider setting up AWS Cost Alerts

---

## Quick Reference

### Important ARNs and IDs

```bash
# Get Account ID
aws sts get-caller-identity --query Account --output text

# Get Role ARN
aws iam get-role --role-name GitHubActionsTerraformRole --query 'Role.Arn' --output text

# List OIDC Providers
aws iam list-open-id-connect-providers

# List Attached Policies
aws iam list-attached-role-policies --role-name GitHubActionsTerraformRole
```

### Useful Commands

```bash
# Validate trust policy
aws iam get-role --role-name GitHubActionsTerraformRole --query 'Role.AssumeRolePolicyDocument'

# Test S3 state bucket
aws s3 ls s3://your-terraform-state-bucket/

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock

# View CloudTrail events
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=GitHubActionsTerraformRole
```

---

## Support and Resources

- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform S3 Backend](https://www.terraform.io/language/settings/backends/s3)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

**You're all set!** 🚀 Your AWS environment is now configured for secure Terraform deployments via GitHub Actions.


