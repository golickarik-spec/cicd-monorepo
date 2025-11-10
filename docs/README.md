# Documentation

This directory contains comprehensive documentation for deploying infrastructure with Terraform and GitHub Actions.

## 📚 Documentation Index

### 🚀 Getting Started

1. **[Quick Start Guide](QUICK_START.md)** ⭐ **Start here!**
   - 15-minute setup guide
   - AWS and GitHub configuration
   - First deployment walkthrough
   - Perfect for beginners

### 🔐 AWS Configuration

2. **[AWS Setup Guide](AWS_SETUP_GUIDE.md)**
   - Detailed AWS prerequisites
   - OIDC authentication setup
   - IAM roles and permissions
   - Security best practices
   - Troubleshooting common issues

### 🏗️ Infrastructure

3. **[Terraform README](../terraform/README.md)**
   - Module architecture overview
   - Environment configurations
   - Resource specifications
   - Cost estimates
   - Local development guide

### 🔄 Deployment

4. **[Deployment Workflow Guide](DEPLOYMENT_WORKFLOW.md)**
   - Complete CI/CD workflow
   - Branch strategies
   - Deployment scenarios
   - Rollback procedures
   - Monitoring and validation

## 📖 Quick Navigation

### I want to...

| Goal | Document | Section |
|------|----------|---------|
| **Get started from scratch** | [Quick Start](QUICK_START.md) | Full guide |
| **Configure AWS for GitHub Actions** | [AWS Setup Guide](AWS_SETUP_GUIDE.md) | Steps 1-5 |
| **Understand the modules** | [Infrastructure README](../infrastructure/README.md) | Modules Overview |
| **Deploy to dev/staging/prod** | [Deployment Workflow](DEPLOYMENT_WORKFLOW.md) | Deployment Scenarios |
| **Roll back a deployment** | [Deployment Workflow](DEPLOYMENT_WORKFLOW.md) | Scenario 4 |
| **Customize infrastructure** | [Infrastructure README](../infrastructure/README.md) | Environment Configs |
| **Troubleshoot issues** | [AWS Setup Guide](AWS_SETUP_GUIDE.md) | Troubleshooting |
| **Destroy infrastructure** | [Deployment Workflow](DEPLOYMENT_WORKFLOW.md) | Scenario 5 |

## 🏗️ Architecture

### Infrastructure Modules

```
infrastructure/modules/
├── networking/      → VPC, Subnets, NAT, IGW, Route Tables
├── security/        → Security Groups (ALB, ECS, RDS)
├── rds/            → MySQL Database (Multi-AZ capable)
├── ecr/            → Container Registries (Backend, Frontend)
├── ecs/            → ECS Fargate Cluster, Tasks, ALB
└── s3-cloudfront/  → Static Site Hosting (S3 + CloudFront)
```

### Environments

Each environment is fully isolated with its own VPC and resources:

- **Dev** (`infrastructure/environments/dev/`)
  - Small instances, no Multi-AZ
  - Fast iteration, cost-optimized
  
- **Staging** (`infrastructure/environments/staging/`)
  - Medium instances, backups enabled
  - Production-like for testing
  
- **Production** (`infrastructure/environments/prod/`)
  - Large instances, Multi-AZ
  - Full backups, monitoring, HA

## 🚦 Deployment Flow

```
Feature Branch
     │
     ├─→ Pull Request to develop
     │   └─→ Terraform Plan (auto-comment)
     │
     ├─→ Merge to develop
     │   └─→ ✅ Deploy to Dev
     │
     ├─→ Promote to staging
     │   └─→ ✅ Deploy to Staging
     │
     └─→ Promote to main
         └─→ ⚠️ Deploy to Production (approval required)
```

## 🔑 Key Concepts

### OIDC Authentication

Uses OpenID Connect for secure, keyless authentication between GitHub Actions and AWS:

- ✅ No long-lived credentials
- ✅ Automatic credential rotation
- ✅ Fine-grained access control
- ✅ AWS best practices

### Terraform Modules

Reusable infrastructure components:

- 🧩 **Modular**: Each service is independent
- 🔄 **Reusable**: Same modules across environments
- 📝 **Documented**: Variables and outputs explained
- ✅ **Tested**: Used in all three environments

### GitHub Actions Workflows

Automated deployment pipelines:

- 📋 **terraform-plan.yml**: Preview changes on PRs
- 🚀 **terraform-apply-dev.yml**: Deploy to dev
- 🏗️ **terraform-apply-staging.yml**: Deploy to staging
- 🎯 **terraform-apply-prod.yml**: Deploy to production
- 💥 **terraform-destroy.yml**: Destroy infrastructure

## 📊 Infrastructure Resources

### What Gets Created

Per environment, Terraform provisions:

| Resource | Dev | Staging | Prod |
|----------|-----|---------|------|
| VPC | 1 | 1 | 1 |
| Subnets | 4 | 4 | 6 |
| NAT Gateway | 1 | 1 | 1 |
| RDS Instance | 1 | 1 | 1 (Multi-AZ) |
| ECS Cluster | 1 | 1 | 1 |
| ECS Tasks | 1 | 2 | 3 |
| ALB | 1 | 1 | 1 |
| S3 Bucket | 1 | 1 | 1 |
| CloudFront | 1 | 1 | 1 |
| ECR Repos | 2 | 2 | 2 |

### Estimated Costs

| Environment | Monthly Cost |
|-------------|--------------|
| Dev | $50-80 |
| Staging | $150-200 |
| Production | $400-600 |

## 🔒 Security Features

- ✅ Private subnets for databases and compute
- ✅ Security groups with least-privilege access
- ✅ OIDC authentication (no stored credentials)
- ✅ Encrypted RDS storage
- ✅ S3 bucket encryption
- ✅ CloudFront with OAC (Origin Access Control)
- ✅ VPC isolation per environment
- ✅ Automated backups (staging/prod)
- ✅ Deletion protection (prod)

## 🎯 Best Practices Implemented

1. **Infrastructure as Code**: Everything defined in Terraform
2. **Immutable Infrastructure**: Replace, don't modify
3. **Environment Parity**: Same modules, different configs
4. **Automated Deployments**: GitHub Actions for CI/CD
5. **State Management**: Remote state in S3 (optional)
6. **Least Privilege**: Minimal IAM permissions
7. **Monitoring**: CloudWatch logs and Container Insights
8. **Backups**: Automated RDS backups with retention
9. **High Availability**: Multi-AZ for production
10. **Cost Optimization**: Right-sizing per environment

## 🛠️ Prerequisites

Before starting, ensure you have:

- [ ] AWS Account with admin access
- [ ] GitHub repository with Actions enabled
- [ ] AWS CLI installed and configured
- [ ] Terraform v1.5+ installed
- [ ] Docker installed (for building images)
- [ ] Git installed

## 📝 Conventions

### Naming

Resources follow this pattern: `{project}-{environment}-{resource}`

Examples:
- VPC: `cicd-dev-vpc`
- ECS Cluster: `cicd-prod-cluster`
- RDS: `cicd-staging-mysql`

### Tags

All resources are tagged with:
- `Environment`: dev/staging/prod
- `Project`: cicd (or your project name)
- `ManagedBy`: Terraform

### Branches

- `main`: Production-ready code
- `staging`: Pre-production testing
- `develop`: Active development
- `feature/*`: Feature branches
- `hotfix/*`: Emergency fixes

## 🔍 Monitoring

### CloudWatch

- **Logs**: `/ecs/{project}-{environment}-backend`
- **Container Insights**: Enabled for staging/prod
- **Retention**: 7/14/30 days (dev/staging/prod)

### AWS Console

Check deployment status:
```bash
# ECS Services
aws ecs list-services --cluster cicd-dev-cluster

# RDS Instances
aws rds describe-db-instances

# CloudFront Distributions
aws cloudfront list-distributions
```

## 🆘 Common Issues

| Issue | Quick Fix | Doc Reference |
|-------|-----------|---------------|
| OIDC provider not found | Run OIDC creation command | [AWS Setup Guide](AWS_SETUP_GUIDE.md#step-1) |
| AccessDenied errors | Check IAM permissions | [AWS Setup Guide](AWS_SETUP_GUIDE.md#step-3) |
| State lock error | Wait or release lock | [Deployment Workflow](DEPLOYMENT_WORKFLOW.md#troubleshooting) |
| ECS tasks not starting | Check ECR images | [Quick Start](QUICK_START.md#build-and-push-docker-images) |

## 📚 Additional Resources

### Terraform

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Modules Best Practices](https://www.terraform.io/language/modules/develop)

### AWS

- [AWS IAM OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)

### GitHub Actions

- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

## 🤝 Contributing

Improvements to documentation are welcome! Please:

1. Check existing docs for similar content
2. Follow the established format
3. Test all commands before documenting
4. Update this index if adding new docs

## 📜 License

[Your License Here]

## 💬 Support

Need help? 

1. Check the troubleshooting sections
2. Review GitHub Actions logs
3. Consult AWS CloudWatch logs
4. Open an issue in the repository

---

**Ready to start?** → [Quick Start Guide](QUICK_START.md) ⭐


