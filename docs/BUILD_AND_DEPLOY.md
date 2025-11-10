# Build and Deploy Pipeline

This document explains how the automated build and deployment pipeline works for the CI/CD project.

## Overview

The GitHub Actions pipeline automatically builds, tests, and deploys your application whenever you push code to the appropriate branches:

- **`develop`** → Dev environment
- **`staging`** → Staging environment
- **`main`** → Production environment

## Pipeline Stages

Each deployment follows these stages in order:

### 1. Infrastructure Provisioning (Terraform)

**Steps:**
- Checkout code
- Configure AWS credentials (via OIDC)
- Initialize Terraform
- Apply infrastructure changes
- Capture outputs (URLs, ECR repos, S3 buckets, etc.)

**What it creates:**
- VPC, subnets, security groups
- RDS MySQL database
- ECR repositories
- ECS Fargate cluster
- Application Load Balancer
- S3 bucket + CloudFront distribution

### 2. Backend Build and Deploy

**Steps:**
- Login to Amazon ECR
- Build Docker image from `services/backend/`
- Tag image with commit SHA and `latest`
- Push to ECR
- Force ECS service to deploy new image
- Wait for ECS service to stabilize

**Backend Image Tags:**
```
835807883333.dkr.ecr.us-east-1.amazonaws.com/cicd-dev-backend:<commit-sha>
835807883333.dkr.ecr.us-east-1.amazonaws.com/cicd-dev-backend:latest
```

### 3. Frontend Build and Deploy

**Steps:**
- Setup Node.js 18
- Install dependencies (`npm ci`)
- Build frontend with environment-specific API URL
- Upload build artifacts to S3
- Set appropriate cache headers
- Invalidate CloudFront cache

**Cache Strategy:**
- Static assets (JS, CSS, images): `max-age=31536000` (1 year)
- `index.html`: `no-cache, no-store, must-revalidate`

### 4. Deployment Summary

The pipeline generates a summary showing:
- Backend and frontend URLs
- ECR repository URLs
- Deployed image tag
- Service status

## Triggering Deployments

### Automatic Triggers

Deployments trigger automatically on pushes to:
- `infrastructure/**` (Terraform changes)
- `services/**` (Application code changes)
- `.github/workflows/terraform-*.yml` (Pipeline changes)

### Manual Trigger

You can manually trigger deployments from GitHub Actions:
1. Go to **Actions** tab
2. Select the workflow (e.g., "Deploy to Dev")
3. Click **Run workflow**
4. Select the branch
5. Click **Run workflow**

## Environment-Specific Configuration

### Dev Environment
- **Branch:** `develop`
- **Cluster:** `cicd-dev-cluster`
- **ECR Repo:** `cicd-dev-backend`
- **Approval:** Not required

### Staging Environment
- **Branch:** `staging`
- **Cluster:** `cicd-staging-cluster`
- **ECR Repo:** `cicd-staging-backend`
- **Approval:** Not required
- **Extra:** Terraform plan runs before apply

### Production Environment
- **Branch:** `main`
- **Cluster:** `cicd-prod-cluster`
- **ECR Repo:** `cicd-prod-backend`
- **Approval:** Required (manual approval in GitHub)
- **Extra:** Terraform plan runs before apply

## Deployment Workflow

### Deploy to Dev (Development)

```bash
# Make changes to code
git checkout develop
git add .
git commit -m "feat: new feature"
git push origin develop

# Pipeline automatically:
# 1. Provisions/updates infrastructure
# 2. Builds and pushes Docker image
# 3. Deploys to ECS
# 4. Builds and deploys frontend to S3/CloudFront
```

### Promote to Staging

```bash
# Merge develop to staging
git checkout staging
git merge develop
git push origin staging

# Pipeline automatically deploys to staging environment
```

### Promote to Production

```bash
# Merge staging to main
git checkout main
git merge staging
git push origin main

# Pipeline runs and waits for manual approval
# Approve in GitHub Actions UI
# Then deploys to production
```

## Monitoring Deployments

### GitHub Actions UI

1. Go to **Actions** tab in GitHub
2. Click on the running workflow
3. View real-time logs for each step
4. Check deployment summary at the bottom

### AWS Console

**ECS Service:**
```bash
# View service status
aws ecs describe-services \
  --cluster cicd-dev-cluster \
  --services cicd-dev-backend \
  --region us-east-1

# View running tasks
aws ecs list-tasks \
  --cluster cicd-dev-cluster \
  --service-name cicd-dev-backend \
  --region us-east-1
```

**CloudWatch Logs:**
```bash
# View backend logs
aws logs tail /ecs/cicd-dev-backend --follow --region us-east-1
```

**S3 Bucket:**
```bash
# List frontend files
aws s3 ls s3://cicd-dev-frontend-<bucket-id>/
```

**CloudFront:**
```bash
# Check distribution status
aws cloudfront get-distribution --id <distribution-id> --region us-east-1
```

## Rollback Strategy

### Backend Rollback

If a deployment fails or has issues:

```bash
# Option 1: Deploy previous commit
git revert HEAD
git push origin develop

# Option 2: Use specific image tag
aws ecs update-service \
  --cluster cicd-dev-cluster \
  --service cicd-dev-backend \
  --task-definition cicd-dev-backend:<previous-revision> \
  --force-new-deployment \
  --region us-east-1
```

### Frontend Rollback

```bash
# Restore previous version from S3 versioning
aws s3api list-object-versions \
  --bucket cicd-dev-frontend-<bucket-id> \
  --prefix index.html

# Copy specific version
aws s3api copy-object \
  --copy-source cicd-dev-frontend-<bucket-id>/index.html?versionId=<version-id> \
  --bucket cicd-dev-frontend-<bucket-id> \
  --key index.html

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"
```

## Troubleshooting

### Build Fails

**Docker build errors:**
- Check Dockerfile syntax
- Verify all dependencies are listed in requirements.txt
- Check if base image is accessible

**Frontend build errors:**
- Check package.json scripts
- Verify all dependencies are in package.json
- Check if VITE_API_URL is correct

### Deployment Fails

**ECS task fails to start:**
```bash
# Check task logs
aws ecs describe-tasks \
  --cluster cicd-dev-cluster \
  --tasks <task-id> \
  --region us-east-1
```

**CloudFront not updating:**
- Wait 5-10 minutes for propagation
- Check invalidation status in CloudFront console
- Verify S3 bucket has new files

### Health Check Fails

**ALB health checks failing:**
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region us-east-1
```

Possible causes:
- Application not listening on correct port (8000)
- Security group blocking ALB → ECS traffic
- Application crashes on startup (check logs)

## Best Practices

### 1. Always Test Locally First

```bash
# Test with docker-compose
docker-compose up --build

# Test backend
curl http://localhost:8000/health

# Test frontend
open http://localhost:5173
```

### 2. Small, Incremental Changes

- Deploy small changes frequently
- Easier to identify issues
- Faster rollbacks if needed

### 3. Use Feature Branches

```bash
git checkout -b feature/new-feature
# Make changes
git push origin feature/new-feature
# Create PR to develop
```

### 4. Monitor After Deployment

- Check application logs for errors
- Verify health checks are passing
- Test critical user flows
- Monitor CloudWatch metrics

### 5. Keep Secrets Secure

- Never commit secrets to Git
- Use GitHub Secrets for sensitive data
- Rotate credentials regularly
- Use least-privilege IAM policies

## Pipeline Performance

**Average deployment times:**
- Infrastructure (first time): ~10-15 minutes
- Infrastructure (updates): ~2-5 minutes
- Backend build + deploy: ~3-5 minutes
- Frontend build + deploy: ~2-3 minutes
- **Total (full deployment): ~15-20 minutes**

**Optimization tips:**
- Use Docker layer caching
- Minimize npm package count
- Use CloudFront edge caching
- Enable ECS service auto-scaling

## Next Steps

- [Quick Start Guide](./QUICK_START.md)
- [AWS Setup Guide](./AWS_SETUP_GUIDE.md)
- [Complete Deployment Workflow](./DEPLOYMENT_WORKFLOW.md)
- [Infrastructure Modules Documentation](../infrastructure/modules/README.md)

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review GitHub Actions logs
3. Check AWS service health dashboard
4. Review Terraform state for inconsistencies

