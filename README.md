# CICD Platform - Multi-Environment Monorepo

[![Deploy to Dev](https://github.com/YOUR_ORG/YOUR_REPO/workflows/Deploy%20to%20Dev/badge.svg)](https://github.com/YOUR_ORG/YOUR_REPO/actions)
[![Deploy to Production](https://github.com/YOUR_ORG/YOUR_REPO/workflows/Deploy%20to%20Production/badge.svg)](https://github.com/YOUR_ORG/YOUR_REPO/actions)

A production-ready monorepo with automated infrastructure deployment using Terraform and GitHub Actions. Supports multiple environments (dev, staging, production) with isolated infrastructure.

## 🚀 Quick Start

**New to this project?** Start here:

1. **[Quick Start Guide](docs/QUICK_START.md)** - Get up and running in 15 minutes
2. **[AWS Setup Guide](docs/AWS_SETUP_GUIDE.md)** - Configure AWS for deployments
3. **[Deployment Workflow](docs/DEPLOYMENT_WORKFLOW.md)** - Understand the CI/CD pipeline

## 📁 Repository Structure

```
cicd/  (monorepo)
├── .github/
│   └── workflows/              # GitHub Actions CI/CD pipelines
│       ├── terraform-plan.yml  # Preview infrastructure changes
│       ├── terraform-apply-*.yml # Deploy to environments
│       └── terraform-destroy.yml # Tear down infrastructure
│
├── services/                   # Application services
│   ├── backend/               # Backend API (Python/FastAPI)
│   │   ├── app/              # Application code
│   │   ├── tests/            # Unit & integration tests
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   │
│   └── frontend/              # Frontend web app (React/Vite)
│       ├── src/              # Source code
│       ├── Dockerfile
│       └── package.json
│
├── infrastructure/            # Infrastructure as Code (Terraform)
│   ├── modules/              # Reusable Terraform modules
│   │   ├── networking/      # VPC, Subnets, NAT, IGW
│   │   ├── security/        # Security Groups
│   │   ├── rds/            # MySQL Database
│   │   ├── ecr/            # Container Registries
│   │   ├── ecs/            # ECS Fargate & ALB
│   │   └── s3-cloudfront/  # Static Site Hosting
│   │
│   └── environments/         # Environment-specific configs
│       ├── dev/             # Development
│       ├── staging/         # Staging
│       └── prod/            # Production
│
├── shared/                   # Shared code across services
│   ├── configs/             # Common configurations
│   └── utils/               # Utility functions
│
├── scripts/                  # Utility scripts
├── docs/                     # Documentation
├── docker-compose.yml        # Local development
└── README.md                # This file
```

## 🏗️ Architecture

### AWS Infrastructure

```
┌─────────────────────┐
│   CloudFront CDN    │  → Frontend (Static Site in S3)
└─────────────────────┘
           │
┌─────────────────────┐
│Application Load     │  → Distributes traffic
│    Balancer (ALB)   │
└─────────────────────┘
           │
    ┌──────┴──────┐
    │   ECS       │  → Backend containers (Fargate)
    │  Cluster    │     • Auto-scaling
    │             │     • High availability
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │  RDS MySQL  │  → Database (Multi-AZ in prod)
    └─────────────┘
```

### Environment Isolation

Each environment has:
- ✅ Separate VPC with isolated network
- ✅ Independent databases
- ✅ Dedicated ECR repositories
- ✅ Environment-specific configuration
- ✅ Isolated secrets and credentials

## 🛠️ Local Development

### Prerequisites

- Docker & Docker Compose
- Node.js 18+ (for frontend)
- Python 3.11+ (for backend)

### Start All Services

```bash
# Start backend, frontend, and database
docker-compose up

# Backend:  http://localhost:8000
# Frontend: http://localhost:5173
# Database: localhost:3306
```

### Development Commands

```bash
# Backend
cd services/backend
pip install -r requirements.txt
python app/main.py

# Frontend
cd services/frontend
npm install
npm run dev

# Run tests
cd services/backend
pytest

cd services/frontend
npm test
```

## 🚀 Deployment

### Branch Strategy

```
feature/xxx  →  develop  →  staging  →  main
                   ↓          ↓         ↓
                  Dev      Staging   Production
```

### Automatic Deployments

- **Push to `develop`** → Deploys to Dev
- **Push to `staging`** → Deploys to Staging  
- **Push to `main`** → Deploys to Production

### Manual Deployment

Trigger deployments manually via GitHub Actions:
1. Go to **Actions** tab
2. Select workflow (e.g., "Deploy to Dev")
3. Click **Run workflow**

### Infrastructure Changes

1. Create feature branch
2. Modify Terraform files in `infrastructure/`
3. Create Pull Request
4. Review Terraform plan in PR comments
5. Merge to trigger deployment

## 📊 Infrastructure Details

### Environments

| Environment | Purpose | Auto-Deploy | Approval Required |
|-------------|---------|-------------|-------------------|
| **Dev** | Development & testing | ✅ Yes | ❌ No |
| **Staging** | Pre-production QA | ✅ Yes | ❌ No |
| **Production** | Live production | ✅ Yes | ⚠️ Optional |

### Resources per Environment

| Resource | Dev | Staging | Production |
|----------|-----|---------|------------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| AZs | 2 | 2 | 3 |
| ECS Tasks | 1 | 2 | 3 |
| RDS Instance | t3.micro | t3.small | t3.medium |
| Multi-AZ | ❌ No | ❌ No | ✅ Yes |
| Backups | None | 7 days | 30 days |

### Cost Estimates (Monthly)

- **Dev**: ~$50-80
- **Staging**: ~$150-200
- **Production**: ~$400-600

## 🔐 Security Features

- ✅ **OIDC Authentication** - No long-lived AWS credentials
- ✅ **Private Subnets** - Databases and compute isolated
- ✅ **Security Groups** - Least-privilege network access
- ✅ **Encrypted Storage** - RDS and S3 encrypted at rest
- ✅ **VPC Isolation** - Each environment in separate VPC
- ✅ **Secrets Management** - Sensitive data in GitHub Secrets
- ✅ **Deletion Protection** - Enabled for production databases

## 📚 Documentation

### Getting Started
- [Quick Start Guide](docs/QUICK_START.md) - 15-minute setup
- [AWS Setup Guide](docs/AWS_SETUP_GUIDE.md) - Configure AWS
- [Repository Structure](RESTRUCTURE_GUIDE.md) - Understanding the layout

### Operations
- [Deployment Workflow](docs/DEPLOYMENT_WORKFLOW.md) - CI/CD pipeline
- [Infrastructure README](infrastructure/README.md) - Terraform details
- [Backend README](services/backend/README.md) - Backend service
- [Frontend README](services/frontend/README.md) - Frontend service

### Reference
- [Troubleshooting](docs/AWS_SETUP_GUIDE.md#troubleshooting)
- [Best Practices](docs/DEPLOYMENT_WORKFLOW.md#best-practices)
- [Cost Optimization](infrastructure/README.md#cost-optimization)

## 🧪 Testing

```bash
# Backend tests
cd services/backend
pytest

# Frontend tests
cd services/frontend
npm test

# Integration tests
docker-compose up -d
# Run integration test suite
```

## 🔄 CI/CD Pipeline

### On Pull Request
1. Terraform format check
2. Terraform validation
3. Terraform plan
4. Post plan as PR comment
5. Run tests

### On Merge to Branch
1. Checkout code
2. Configure AWS credentials (OIDC)
3. Terraform init
4. Terraform apply
5. Deploy services
6. Post deployment summary

## 🤝 Contributing

1. Create feature branch from `develop`
2. Make changes
3. Run tests locally
4. Create Pull Request
5. Wait for CI checks
6. Get review and approval
7. Merge to `develop`

### Commit Message Format

```
feat: Add user authentication
fix: Resolve database connection issue
docs: Update deployment guide
chore: Update dependencies
```

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_ORG/YOUR_REPO/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_ORG/YOUR_REPO/discussions)
- **Documentation**: [docs/](docs/)

## 🛣️ Roadmap

- [ ] Add monitoring with CloudWatch dashboards
- [ ] Implement blue-green deployments
- [ ] Add automated backup verification
- [ ] Set up cost alerts and budgets
- [ ] Add performance testing pipeline
- [ ] Implement feature flags

## 📄 License

[Your License Here]

## 🙏 Acknowledgments

- Built with [Terraform](https://www.terraform.io/)
- Deployed on [AWS](https://aws.amazon.com/)
- CI/CD by [GitHub Actions](https://github.com/features/actions)

---

**Ready to get started?** → [Quick Start Guide](docs/QUICK_START.md) 🚀
