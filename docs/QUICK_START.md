# Quick Start Guide - Terraform Multi-Environment Deployment

Get up and running with Terraform and GitHub Actions in 15 minutes.

## Prerequisites

- AWS Account with admin access
- GitHub repository
- AWS CLI installed and configured locally
- Terraform installed (v1.5+)

---

## Setup Steps

### 1️⃣ AWS Setup (5 minutes)

#### Create OIDC Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Create IAM Role

Replace `YOUR_GITHUB_ORG/YOUR_REPO`:

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create trust policy file
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO:*"
      }
    }
  }]
}
EOF

# Create role
aws iam create-role \
  --role-name GitHubActionsTerraformRole \
  --assume-role-policy-document file://trust-policy.json

# Attach permissions (use minimal permissions for production)
aws iam attach-role-policy \
  --role-name GitHubActionsTerraformRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Get role ARN (save this!)
aws iam get-role --role-name GitHubActionsTerraformRole --query 'Role.Arn' --output text
```

**Output**: `arn:aws:iam::123456789012:role/GitHubActionsTerraformRole`

---

### 2️⃣ GitHub Setup (3 minutes)

#### Add Secrets

Go to **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

1. **AWS_ROLE_ARN**
   - Value: `arn:aws:iam::123456789012:role/GitHubActionsTerraformRole`

2. **MYSQL_PASSWORD**
   - Value: Choose a secure password (e.g., `MySecurePass123!`)

#### Add Variables

Go to **Variables** tab → **New repository variable**

1. **AWS_REGION**
   - Value: `us-east-1`

#### Create Environments (Optional but Recommended)

1. Go to **Settings** → **Environments**
2. Click **New environment** → Name: `prod`
3. Check **Required reviewers** → Add yourself
4. Repeat for `staging` and `dev` if you want environment-specific secrets

---

### 3️⃣ Create Branches (2 minutes)

```bash
# Ensure you're on main
git checkout main

# Create staging branch
git checkout -b staging
git push origin staging

# Create develop branch
git checkout -b develop
git push origin develop

# Go back to main
git checkout main
```

---

### 4️⃣ First Deployment to Dev (5 minutes)

#### Update Configuration (Optional)

Edit `terraform/environments/dev/terraform.tfvars` if needed:

```hcl
project_name = "myapp"
aws_region   = "us-east-1"
mysql_db     = "myapp_dev"
```

#### Commit and Push

```bash
git checkout develop
git add .
git commit -m "feat: initial terraform configuration"
git push origin develop
```

**🎉 GitHub Actions will automatically deploy to Dev!**

#### Monitor Deployment

1. Go to **Actions** tab in GitHub
2. Click on the running workflow
3. Wait 10-15 minutes for resources to create

#### Get URLs

After deployment completes, check the workflow summary for:
- Backend ALB URL
- Frontend CloudFront URL
- ECR Repository URLs

---

## Test Your Deployment

### Test Backend

```bash
curl http://<alb-url>/api/health
```

### Test Frontend

```bash
curl https://<cloudfront-url>
```

### View Outputs Locally

```bash
cd terraform/environments/dev
terraform init
terraform output
```

---

## Deploy to Staging and Production

### Deploy to Staging

```bash
# Merge develop to staging
git checkout staging
git merge develop
git push origin staging
```

### Deploy to Production

```bash
# Merge staging to main
git checkout main
git merge staging
git push origin main
```

If you configured required reviewers for prod, you'll need to approve the deployment in GitHub Actions.

---

## Common Commands

### View Deployed Resources

```bash
# ECS Cluster
aws ecs describe-clusters --clusters cicd-dev-cluster

# RDS Database
aws rds describe-db-instances --db-instance-identifier cicd-dev-mysql

# ECR Repositories
aws ecr describe-repositories --repository-names cicd-dev-backend

# S3 Buckets
aws s3 ls | grep cicd-dev
```

### Build and Push Docker Images

After infrastructure is deployed, build and push your application:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend
cd backend
docker build -t <ecr-backend-url>:latest .
docker push <ecr-backend-url>:latest

# Build and push frontend
cd frontend
docker build -t <ecr-frontend-url>:latest .
docker push <ecr-frontend-url>:latest
```

### Force ECS Service Update

After pushing new images:

```bash
aws ecs update-service \
  --cluster cicd-dev-cluster \
  --service cicd-dev-backend \
  --force-new-deployment
```

---

## Troubleshooting

### "No OpenID Connect provider found"

**Fix**: Run the OIDC provider creation command from Step 1

### "AccessDenied" errors

**Fix**: Verify IAM role permissions. For quick start, ensure PowerUserAccess is attached.

### "State lock" error

**Fix**: Wait for other deployments to complete, or manually release lock:

```bash
# Create state backend first if using S3
# Otherwise, lock is local and resolved automatically
```

### RDS takes forever to create

**Expected**: RDS instances take 10-15 minutes to create. This is normal.

### ECS tasks not starting

**Fix**: 
1. Check if Docker images exist in ECR
2. View ECS task logs in CloudWatch
3. Verify security group rules

---

## Next Steps

✅ **You're all set!** Here's what to do next:

1. **Customize Your Infrastructure**
   - Edit module variables
   - Adjust instance sizes
   - Add custom security rules

2. **Set Up CI/CD for Applications**
   - Build Docker images on every push
   - Auto-deploy to ECS after Terraform

3. **Add Monitoring**
   - Set up CloudWatch alarms
   - Configure SNS notifications
   - Enable AWS Cost Alerts

4. **Secure Your Setup**
   - Use least-privilege IAM policies
   - Enable CloudTrail logging
   - Store secrets in AWS Secrets Manager

5. **Optimize Costs**
   - Review instance sizes
   - Use spot instances for dev
   - Set up auto-scaling

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      CloudFront CDN                      │
│                     (Frontend - S3)                      │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Application Load Balancer              │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   ┌────────┐          ┌────────┐          ┌────────┐
   │  ECS   │          │  ECS   │          │  ECS   │
   │ Task 1 │          │ Task 2 │          │ Task 3 │
   └────────┘          └────────┘          └────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
                    ┌──────────────┐
                    │  RDS MySQL   │
                    │  (Private)   │
                    └──────────────┘

All in isolated VPCs per environment (dev/staging/prod)
```

---

## Cost Estimate

**Development Environment** (~$50-80/month):
- VPC & Networking: Free tier
- RDS db.t3.micro: ~$15
- ECS Fargate (1 task): ~$15
- NAT Gateway: ~$32
- ALB: ~$16
- CloudFront: ~$1
- S3: <$1

**Note**: Costs vary by usage. Set up billing alerts!

---

## Resources

- 📖 [Full Documentation](../terraform/README.md)
- 🔐 [AWS Setup Guide](./AWS_SETUP_GUIDE.md)
- 🚀 [Deployment Workflow](./DEPLOYMENT_WORKFLOW.md)
- 💻 [Terraform Modules](../terraform/modules/)

---

## Getting Help

If you encounter issues:

1. Check GitHub Actions logs
2. Review CloudWatch logs
3. Verify AWS credentials
4. Check Terraform state
5. Consult documentation links above

---

**Happy deploying!** 🚀

If this helped you, give the repo a ⭐!


