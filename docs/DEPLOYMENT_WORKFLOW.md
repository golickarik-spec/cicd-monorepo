# Deployment Workflow Guide

This document explains the complete CI/CD deployment workflow using GitHub Actions and Terraform.

## Workflow Overview

```
┌─────────────┐
│   Feature   │
│  Development│
└──────┬──────┘
       │ Create PR
       ▼
┌─────────────┐      ┌──────────────┐
│Pull Request │─────▶│ Terraform    │
│   Review    │      │ Plan Comment │
└──────┬──────┘      └──────────────┘
       │ Merge
       ▼
┌─────────────┐      ┌──────────────┐
│   develop   │─────▶│  Deploy to   │
│   branch    │      │     Dev      │
└──────┬──────┘      └──────────────┘
       │ Promote
       ▼
┌─────────────┐      ┌──────────────┐
│   staging   │─────▶│  Deploy to   │
│   branch    │      │   Staging    │
└──────┬──────┘      └──────────────┘
       │ Promote
       ▼
┌─────────────┐      ┌──────────────┐      ┌──────────────┐
│    main     │─────▶│Manual Review │─────▶│  Deploy to   │
│   branch    │      │  (Optional)  │      │  Production  │
└─────────────┘      └──────────────┘      └──────────────┘
```

## Branch Strategy

### Branch → Environment Mapping

| Branch      | Environment | Auto-Deploy | Approval Required |
|-------------|-------------|-------------|-------------------|
| `develop`   | Dev         | ✅ Yes      | ❌ No             |
| `staging`   | Staging     | ✅ Yes      | ❌ No             |
| `main`      | Production  | ✅ Yes      | ⚠️ Optional       |

### Branch Purposes

- **`develop`**: Active development, frequent deployments
- **`staging`**: Pre-production testing, QA validation
- **`main`**: Production-ready code only

## Deployment Scenarios

### Scenario 1: New Feature Development

**Goal**: Develop a new feature and deploy through all environments.

#### Step 1: Create Feature Branch

```bash
# Create from develop
git checkout develop
git pull origin develop
git checkout -b feature/my-new-feature
```

#### Step 2: Make Changes

Edit Terraform files or application code:
```bash
# Example: Update ECS task CPU
vi terraform/environments/dev/terraform.tfvars

# Commit changes
git add .
git commit -m "feat: increase ECS task CPU for better performance"
git push origin feature/my-new-feature
```

#### Step 3: Create Pull Request

1. Go to GitHub → **Pull Requests** → **New pull request**
2. Base: `develop` ← Compare: `feature/my-new-feature`
3. GitHub Actions automatically runs:
   - ✅ Terraform format check
   - ✅ Terraform validate
   - ✅ Terraform plan
   - 💬 Posts plan as PR comment

#### Step 4: Review and Merge

1. Review the Terraform plan in PR comments
2. Approve the PR
3. Merge to `develop`
4. **Automatic deployment to Dev starts**

#### Step 5: Promote to Staging

After testing in Dev:

```bash
# Merge develop to staging
git checkout staging
git pull origin staging
git merge develop
git push origin staging
```

**Automatic deployment to Staging starts**

#### Step 6: Promote to Production

After testing in Staging:

```bash
# Merge staging to main
git checkout main
git pull origin main
git merge staging
git push origin main
```

**Deployment to Production starts** (may require approval)

---

### Scenario 2: Hotfix for Production

**Goal**: Fix a critical issue in production quickly.

#### Step 1: Create Hotfix Branch from Main

```bash
git checkout main
git pull origin main
git checkout -b hotfix/critical-security-fix
```

#### Step 2: Make Fix and Test

```bash
# Make changes
vi terraform/modules/security/main.tf

# Commit
git add .
git commit -m "fix: update security group rules"
git push origin hotfix/critical-security-fix
```

#### Step 3: Create PR to Main

1. Create PR: `main` ← `hotfix/critical-security-fix`
2. Review Terraform plan
3. Merge to `main`
4. **Deploys to Production**

#### Step 4: Backport to Other Branches

```bash
# Merge back to staging
git checkout staging
git merge main
git push origin staging

# Merge back to develop
git checkout develop
git merge staging
git push origin develop
```

---

### Scenario 3: Infrastructure-Only Change

**Goal**: Update only Terraform infrastructure without application changes.

#### Step 1: Create Infrastructure Branch

```bash
git checkout develop
git checkout -b infra/update-rds-instance-class
```

#### Step 2: Update Terraform Configuration

```bash
# Edit environment config
vi terraform/environments/staging/terraform.tfvars

# Change:
# rds_instance_class = "db.t3.small"
# To:
# rds_instance_class = "db.t3.medium"
```

#### Step 3: Follow Normal PR Process

Same as Scenario 1:
1. Create PR → review plan → merge
2. Deploy through dev → staging → production

---

### Scenario 4: Rollback Deployment

**Goal**: Revert infrastructure to previous state.

#### Option A: Revert Git Commit

```bash
# Find commit to revert
git log --oneline

# Revert the commit
git revert abc123
git push origin main
```

GitHub Actions will automatically deploy the reverted configuration.

#### Option B: Re-apply Previous Terraform State

```bash
# Checkout previous version
git checkout <previous-commit-hash>

# Create revert branch
git checkout -b revert/rollback-to-previous

# Push and merge through normal process
```

---

### Scenario 5: Manual Terraform Destroy

**Goal**: Tear down an environment's infrastructure.

#### Step 1: Go to GitHub Actions

1. Navigate to **Actions** tab
2. Select **Destroy Terraform Infrastructure** workflow
3. Click **Run workflow**

#### Step 2: Fill Parameters

- **Environment**: Select `dev`, `staging`, or `prod`
- **Confirmation**: Type `destroy` exactly

#### Step 3: Confirm and Run

Workflow will:
1. Validate confirmation
2. Initialize Terraform
3. Run `terraform destroy -auto-approve`
4. Post summary

⚠️ **Warning**: This is irreversible! All data will be lost.

---

## GitHub Actions Workflows

### 1. Terraform Plan (Pull Requests)

**File**: `.github/workflows/terraform-plan.yml`

**Triggers**:
- Pull requests to `main`, `develop`, `staging`
- Changes in `terraform/**`

**Steps**:
1. Detect target environment based on base branch
2. Checkout code
3. Configure AWS credentials (OIDC)
4. Setup Terraform
5. Run `terraform fmt -check`
6. Run `terraform init`
7. Run `terraform validate`
8. Run `terraform plan`
9. Post plan as PR comment

**Environment Variables**:
- `TF_VAR_mysql_password`: From GitHub Secrets
- `TF_VAR_image_tag`: Set to commit SHA

---

### 2. Deploy to Dev

**File**: `.github/workflows/terraform-apply-dev.yml`

**Triggers**:
- Push to `develop` branch
- Manual workflow dispatch

**Steps**:
1. Checkout code
2. Configure AWS credentials
3. Setup Terraform
4. Run `terraform init`
5. Run `terraform apply -auto-approve`
6. Extract outputs (ALB URL, CDN URL, ECR URLs)
7. Post deployment summary

**Auto-Approval**: ✅ Yes (no manual intervention)

---

### 3. Deploy to Staging

**File**: `.github/workflows/terraform-apply-staging.yml`

**Triggers**:
- Push to `staging` branch
- Manual workflow dispatch

**Steps**:
Same as Dev, but:
- Uses `terraform/environments/staging`
- Creates plan file before applying
- May have longer retention periods

**Auto-Approval**: ✅ Yes

---

### 4. Deploy to Production

**File**: `.github/workflows/terraform-apply-prod.yml`

**Triggers**:
- Push to `main` branch
- Manual workflow dispatch

**Steps**:
Same as Staging, but:
- Uses `terraform/environments/prod`
- May require manual approval (if environment protection enabled)
- Uses production-grade resources (Multi-AZ, backups, etc.)

**Auto-Approval**: ⚠️ Configurable (recommend requiring approval)

**To Enable Manual Approval**:
1. Go to **Settings** → **Environments** → **prod**
2. Check **Required reviewers**
3. Add team members

---

### 5. Destroy Infrastructure

**File**: `.github/workflows/terraform-destroy.yml`

**Triggers**:
- Manual workflow dispatch only

**Inputs**:
- `environment`: Choice of dev/staging/prod
- `confirmation`: Must type "destroy"

**Steps**:
1. Validate confirmation input
2. Configure AWS credentials
3. Run `terraform destroy -auto-approve`

**Safety**: Requires typing "destroy" + optional environment protection

---

## Monitoring and Validation

### During Deployment

Monitor the GitHub Actions workflow:

1. Go to **Actions** tab
2. Click on the running workflow
3. Expand steps to see detailed logs

### After Deployment

#### Check Deployment Summary

GitHub Actions posts a summary with:
- ✅ Backend ALB URL
- ✅ Frontend CDN URL
- ✅ ECR Repository URLs

#### Verify Infrastructure

```bash
# SSH or use AWS Console to verify resources
aws ecs list-services --cluster cicd-dev-cluster
aws rds describe-db-instances --db-instance-identifier cicd-dev-mysql
aws s3 ls | grep cicd-dev
```

#### Check Application Health

```bash
# Test backend
curl http://<alb-url>/api/health

# Test frontend
curl https://<cloudfront-url>
```

### View Terraform Outputs

From GitHub Actions:
- Check the "Get Terraform Outputs" step

Locally:
```bash
cd terraform/environments/dev
terraform output
```

---

## Best Practices

### 1. Always Review Plans

Never merge a PR without reviewing the Terraform plan:
- ✅ Resources to be created/destroyed
- ✅ Changes to existing resources
- ⚠️ Data-loss operations (destroy database, etc.)

### 2. Test in Lower Environments First

- **Dev** → Test basic functionality
- **Staging** → Full integration/QA testing
- **Production** → Only after staging validation

### 3. Use Descriptive Commit Messages

```bash
# Good
git commit -m "feat(ecs): increase task count for high availability"

# Bad
git commit -m "update stuff"
```

### 4. Tag Production Releases

```bash
git tag -a v1.0.0 -m "Production release v1.0.0"
git push origin v1.0.0
```

### 5. Enable Branch Protection

Recommended settings for `main` and `staging`:
- ✅ Require pull request reviews
- ✅ Require status checks (Terraform plan must pass)
- ✅ Require branches to be up to date
- ❌ Allow force pushes

### 6. Monitor Costs

After deployments:
- Check AWS Cost Explorer
- Set up billing alerts
- Review resources for optimization

### 7. Document Changes

For major infrastructure changes:
- Update documentation
- Notify team members
- Document any manual steps required

---

## Troubleshooting

### Deployment Failed: "Error acquiring state lock"

**Cause**: Another deployment is running or previous deployment didn't release lock.

**Solution**:
```bash
# Check DynamoDB for locks
aws dynamodb scan --table-name terraform-state-lock

# If stuck, manually delete lock
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "terraform-state-bucket/cicd/dev/terraform.tfstate"}}'
```

### Deployment Failed: "AccessDenied"

**Cause**: IAM role lacks permissions.

**Solution**:
1. Check IAM role permissions
2. Verify role trust policy
3. Ensure GitHub OIDC is configured correctly

### Plan Shows Unexpected Changes

**Cause**: State drift or manual changes in AWS console.

**Solution**:
```bash
# Import resources if created manually
terraform import aws_security_group.example sg-1234567890

# Or refresh state
terraform refresh
```

### ECS Service Won't Start

**Cause**: Container image doesn't exist in ECR.

**Solution**:
1. Build and push Docker images first
2. Update image tag in terraform.tfvars
3. Re-run deployment

---

## Quick Reference

### Commands

```bash
# View workflow runs
gh run list --workflow=terraform-apply-dev.yml

# View workflow logs
gh run view <run-id> --log

# Trigger manual deployment
gh workflow run terraform-apply-dev.yml

# Check environment status
cd terraform/environments/dev && terraform show
```

### Important Files

- `.github/workflows/terraform-plan.yml` - PR checks
- `.github/workflows/terraform-apply-*.yml` - Environment deployments
- `terraform/environments/*/main.tf` - Environment configurations
- `terraform/modules/*/` - Reusable components

---

**Happy Deploying!** 🚀


