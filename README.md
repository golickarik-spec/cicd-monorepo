# AWS ECS Fargate CI/CD Platform

A production-ready full-stack application with automated infrastructure deployment using Terraform and GitHub Actions. Deploy to AWS ECS Fargate with a single push.

## 🏗️ Architecture

```
┌─────────────────────┐
│   CloudFront CDN    │  → Frontend (React/Vite in S3)
└─────────────────────┘
           │
┌─────────────────────┐
│Application Load     │  → Distributes HTTP traffic
│    Balancer (ALB)   │
└─────────────────────┘
           │
    ┌──────┴──────┐
    │   ECS       │  → Backend (FastAPI in Fargate)
    │  Fargate    │     Auto-scaling containers
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │  RDS MySQL  │  → Database (managed)
    └─────────────┘
```

## 📁 Project Structure

```
.
├── .github/workflows/          # CI/CD pipelines
│   ├── terraform-apply-dev.yml    # Deploy to dev
│   ├── terraform-apply-staging.yml # Deploy to staging
│   ├── terraform-apply-prod.yml   # Deploy to production
│   └── terraform-plan.yml          # Preview changes on PRs
│
├── infrastructure/             # Terraform IaC
│   ├── modules/               # Reusable modules
│   │   ├── networking/       # VPC, subnets, NAT gateway
│   │   ├── security/         # Security groups
│   │   ├── rds/             # MySQL database
│   │   ├── ecr/             # Docker registries
│   │   ├── ecs/             # ECS Fargate + ALB
│   │   └── s3-cloudfront/   # Frontend hosting
│   │
│   └── environments/          # Environment configs
│       ├── dev/              # Development
│       ├── staging/          # Staging
│       └── prod/             # Production
│
├── services/                  # Application services
│   ├── backend/              # FastAPI backend
│   └── frontend/             # React frontend
│
└── docker-compose.yml        # Local development

```

---

## 🚀 Quick Start (15 minutes)

### Prerequisites

- AWS Account with admin access
- GitHub Account
- AWS CLI installed
- Git installed

### Step 1: Fork/Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
```

### Step 2: Configure AWS

See [AWS Setup](#-aws-setup-step-by-step) section below.

### Step 3: Configure GitHub

See [GitHub Setup](#-github-setup) section below.

### Step 4: Deploy

```bash
git checkout -b dev
git push origin dev
```

**That's it!** GitHub Actions will automatically deploy your application.

---

## 🔧 AWS Setup (Step-by-Step)

### 1. Install AWS CLI

**Windows:**
```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

**macOS:**
```bash
brew install awscli
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 2. Configure AWS Credentials

```bash
aws configure
```

Enter:
- **AWS Access Key ID**: Your access key
- **AWS Secret Access Key**: Your secret key
- **Default region**: `us-east-1` (or your preferred region)
- **Default output format**: `json`

> **How to get Access Keys:**
> 1. Go to AWS Console → IAM → Users → Your User
> 2. Security credentials tab → Create access key
> 3. Choose "Command Line Interface (CLI)"
> 4. Copy Access Key ID and Secret Access Key

### 3. Create OIDC Provider for GitHub Actions

This allows GitHub Actions to authenticate with AWS without storing credentials.

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 4. Create IAM Role for GitHub Actions

**Step 4a: Create trust policy file**

Create `github-trust-policy.json`:

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

**Replace:**
- `YOUR_ACCOUNT_ID`: Your AWS account ID (find with `aws sts get-caller-identity --query Account --output text`)
- `YOUR_GITHUB_USERNAME`: Your GitHub username
- `YOUR_REPO_NAME`: Your repository name

**Step 4b: Create the role**

```bash
aws iam create-role \
  --role-name GitHubActionsTerraformRole \
  --assume-role-policy-document file://github-trust-policy.json \
  --description "Role for GitHub Actions to deploy with Terraform"
```

**Step 4c: Attach policies**

```bash
# PowerUserAccess (for deploying infrastructure)
aws iam attach-role-policy \
  --role-name GitHubActionsTerraformRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# IAMFullAccess (for creating roles for ECS tasks)
aws iam attach-role-policy \
  --role-name GitHubActionsTerraformRole \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

**Step 4d: Get the Role ARN**

```bash
aws iam get-role \
  --role-name GitHubActionsTerraformRole \
  --query 'Role.Arn' \
  --output text
```

**Save this ARN** - you'll need it for GitHub secrets!

### 5. Create S3 Bucket for Terraform State

```bash
# Replace YOUR_ACCOUNT_ID with your AWS account ID
aws s3api create-bucket \
  --bucket cicd-terraform-state-YOUR_ACCOUNT_ID \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket cicd-terraform-state-YOUR_ACCOUNT_ID \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket cicd-terraform-state-YOUR_ACCOUNT_ID \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### 6. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 7. Update Terraform Backend Configuration

Edit `infrastructure/environments/dev/main.tf` (lines 14-20):

```hcl
backend "s3" {
  bucket         = "cicd-terraform-state-YOUR_ACCOUNT_ID"  # <-- Update this
  key            = "cicd/dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

Do the same for `infrastructure/environments/staging/main.tf` and `infrastructure/environments/prod/main.tf`.

---

## 🔐 GitHub Setup

### 1. Create GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Create these secrets:

| Secret Name | Value | Where to get it |
|-------------|-------|-----------------|
| `AWS_ROLE_ARN` | `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsTerraformRole` | From Step 4d above |
| `MYSQL_PASSWORD` | Any secure password (e.g., `MySecurePassword123!`) | Generate a strong password |

### 2. Create GitHub Repository Variables

Go to your GitHub repository → Settings → Secrets and variables → Actions → Variables tab → New repository variable

Create this variable:

| Variable Name | Value |
|---------------|-------|
| `AWS_REGION` | `us-east-1` (or your preferred region) |

### 3. Create GitHub Environments

Go to Settings → Environments → New environment

Create three environments:
- **dev** (no protection rules)
- **staging** (optional: require reviewers)
- **prod** (optional: require reviewers)

---

## 🌿 Branch Setup

Create and push the required branches:

```bash
# Create dev branch
git checkout -b dev
git push origin dev

# Create staging branch
git checkout -b staging
git push origin staging

# Create main branch (if not exists)
git checkout -b main
git push origin main
```

**Branch → Environment Mapping:**
- `dev` → Dev environment
- `staging` → Staging environment
- `main` → Production environment

---

## 🎯 Deployment Workflow

### First Deployment

```bash
# 1. Push to dev branch
git checkout dev
git add .
git commit -m "Initial deployment"
git push origin dev
```

GitHub Actions will automatically:
1. ✅ Provision AWS infrastructure (VPC, RDS, ECS, ALB, CloudFront)
2. ✅ Build and push Docker image to ECR
3. ✅ Deploy backend to ECS Fargate
4. ✅ Build and deploy frontend to S3/CloudFront

**Timeline: ~15-20 minutes**

### Access Your Application

After deployment completes, check the GitHub Actions summary for URLs:

```
Frontend URL: http://dXXXXXXXXXXXXX.cloudfront.net
Backend URL: http://your-alb-XXXXXXXXX.us-east-1.elb.amazonaws.com
```

**⚠️ Important:** Use `http://` (not `https://`) to access the frontend.

### Promote to Staging

```bash
git checkout staging
git merge dev
git push origin staging
```

### Promote to Production

```bash
git checkout main
git merge staging
git push origin main
```

---

## 🔧 Configuration Variables

### Required Variables

These must be configured in `infrastructure/environments/{env}/terraform.tfvars`:

| Variable | Description | Example |
|----------|-------------|---------|
| `project_name` | Project identifier | `"cicd"` |
| `environment` | Environment name | `"dev"`, `"staging"`, `"prod"` |
| `aws_region` | AWS region | `"us-east-1"` |
| `vpc_cidr` | VPC CIDR block | `"10.0.0.0/16"` |
| `availability_zones` | AZ list | `["us-east-1a", "us-east-1b"]` |
| `mysql_username` | Database username | `"admin"` |
| `mysql_database` | Database name | `"appdb"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ecs_task_count` | Number of ECS tasks | `1` (dev), `2` (staging), `3` (prod) |
| `rds_instance_class` | RDS instance type | `"db.t3.micro"` (dev) |
| `rds_multi_az` | Enable Multi-AZ | `false` (dev), `true` (prod) |
| `enable_deletion_protection` | Protect RDS from deletion | `false` (dev), `true` (prod) |

---

## 💻 Local Development

### Start All Services

```bash
docker-compose up
```

- Backend: http://localhost:8000
- Frontend: http://localhost:5173
- Database: localhost:3306

### Backend Only

```bash
cd services/backend
pip install -r requirements.txt
python app/main.py
```

### Frontend Only

```bash
cd services/frontend
npm install
npm run dev
```

---

## 🧪 Testing

### Backend Tests

```bash
cd services/backend
pytest
```

### Manual Testing

**Health Check:**
```bash
curl http://your-alb-url/api/health
```

**List Items:**
```bash
curl http://your-alb-url/api/items
```

**Create Item:**
```bash
curl -X POST http://your-alb-url/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"test item"}'
```

---

## 🔄 Common Operations

### View Deployment Logs

```bash
aws logs tail /ecs/cicd-dev-backend --follow --region us-east-1
```

### Check ECS Service Status

```bash
aws ecs describe-services \
  --cluster cicd-dev-cluster \
  --services cicd-dev-backend \
  --region us-east-1
```

### Update Environment Variables

1. Edit `infrastructure/environments/{env}/terraform.tfvars`
2. Commit and push
3. GitHub Actions will apply changes automatically

### Rollback Deployment

```bash
# Revert commit and push
git revert HEAD
git push origin dev
```

### Destroy Infrastructure

**⚠️ Warning: This will delete ALL resources!**

```bash
# Manually trigger destroy workflow
# Go to GitHub Actions → terraform-destroy.yml → Run workflow
```

Or via CLI:

```bash
cd infrastructure/environments/dev
terraform destroy
```

---

## 📊 Cost Estimates

### Monthly Costs (USD)

| Environment | Estimated Cost |
|-------------|---------------|
| **Dev** | $50-80 |
| **Staging** | $150-200 |
| **Production** | $400-600 |

**Main cost drivers:**
- NAT Gateway: ~$32/month
- RDS MySQL: ~$15-100/month (depending on instance)
- ECS Fargate: ~$30-200/month (depending on task count)
- ALB: ~$20/month
- CloudFront: ~$1-10/month (depending on traffic)

**Cost optimization tips:**
- Use t3/t4g instances for dev/staging
- Stop dev environment outside business hours
- Use single AZ for dev
- Enable ECS auto-scaling

---

## 🔒 Security Best Practices

✅ **Implemented:**
- OIDC authentication (no long-lived credentials)
- Private subnets for databases and compute
- Security groups with least-privilege access
- Encrypted RDS storage
- Encrypted S3 buckets
- VPC isolation per environment
- Automated backups

⚠️ **Additional recommendations:**
- Enable AWS GuardDuty
- Add WAF to ALB
- Enable CloudTrail
- Implement secrets rotation
- Add HTTPS to ALB (requires SSL certificate)

---

## 🐛 Troubleshooting

### Issue: `Error: No OpenIDConnect provider found`

**Solution:** Run step 3 in [AWS Setup](#-aws-setup-step-by-step)

### Issue: `Error: Could not assume role with OIDC`

**Solution:** 
1. Verify role trust policy has correct GitHub repo
2. Check AWS_ROLE_ARN secret in GitHub

### Issue: `Error: Repository already exists`

**Solution:** Existing resources from previous deployment. Either:
1. Delete resources manually
2. Import into Terraform state
3. Use different project name

### Issue: Backend returns 503

**Solution:** Check ECS logs for errors:
```bash
aws logs tail /ecs/cicd-dev-backend --follow
```

### Issue: Frontend shows "Loading..." forever

**Solution:** 
1. Ensure you're using `http://` (not `https://`)
2. Check browser console for CORS errors
3. Verify backend ALB URL is correct

### Issue: Mixed Content blocking

**Solution:** Always access frontend via `http://` not `https://`

---

## 📚 Technology Stack

### Infrastructure
- **Terraform** - Infrastructure as Code
- **AWS ECS Fargate** - Serverless containers
- **AWS RDS MySQL** - Managed database
- **AWS ALB** - Load balancing
- **AWS CloudFront** - CDN
- **GitHub Actions** - CI/CD

### Backend
- **Python 3.11**
- **FastAPI** - Web framework
- **PyMySQL** - Database driver
- **Uvicorn** - ASGI server

### Frontend
- **React 18**
- **Vite** - Build tool
- **JavaScript**

---

## 🤝 Contributing

### Development Workflow

1. Create feature branch from `dev`
```bash
git checkout dev
git checkout -b feature/my-feature
```

2. Make changes and test locally
```bash
docker-compose up
```

3. Commit and push
```bash
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature
```

4. Create Pull Request to `dev` branch

5. After review, merge to `dev` (auto-deploys)

### Commit Message Format

```
feat: Add new feature
fix: Fix bug
docs: Update documentation
chore: Update dependencies
refactor: Refactor code
test: Add tests
```

---

## 📞 Support

### Useful AWS Commands

```bash
# Get AWS Account ID
aws sts get-caller-identity --query Account --output text

# List all ECS clusters
aws ecs list-clusters

# List all RDS instances
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'

# List all S3 buckets
aws s3 ls

# View CloudFront distributions
aws cloudfront list-distributions --query 'DistributionList.Items[*].[DomainName,Status]'
```

### Common Issues

- **Deployment fails**: Check GitHub Actions logs
- **Application errors**: Check CloudWatch logs
- **Infrastructure issues**: Check Terraform state
- **AWS costs**: Review AWS Cost Explorer

---

## 📝 License

MIT License - See LICENSE file for details

---

## ✅ Quick Checklist

Before deploying, ensure:

- [ ] AWS CLI installed and configured
- [ ] OIDC provider created in AWS
- [ ] IAM role created for GitHub Actions
- [ ] S3 bucket created for Terraform state
- [ ] DynamoDB table created for state locking
- [ ] GitHub secrets configured (AWS_ROLE_ARN, MYSQL_PASSWORD)
- [ ] GitHub variable configured (AWS_REGION)
- [ ] Terraform backend updated with your S3 bucket name
- [ ] Branches created (dev, staging, main)
- [ ] Repository pushed to GitHub

**Ready to deploy!** 🚀

```bash
git checkout dev
git push origin dev
```

---

**Questions?** Open an issue on GitHub!
