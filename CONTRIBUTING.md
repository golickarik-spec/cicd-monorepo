# Contributing to CICD Platform

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Branch Strategy](#branch-strategy)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Code Style](#code-style)

## 🤝 Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Assume good intent

## 🚀 Getting Started

### Prerequisites

- Docker and Docker Compose
- Git
- Node.js 18+ (for frontend development)
- Python 3.11+ (for backend development)
- AWS CLI (for infrastructure changes)
- Terraform 1.5+ (for infrastructure changes)

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/YOUR_ORG/YOUR_REPO.git
cd YOUR_REPO

# Setup local environment
make setup

# Start services
make start

# Verify everything works
curl http://localhost:8000/api/health
curl http://localhost:5173
```

## 🔄 Development Workflow

1. **Create a feature branch** from `develop`
2. **Make your changes** with clear, focused commits
3. **Test locally** using `make test`
4. **Push your branch** to the repository
5. **Create a Pull Request** to `develop`
6. **Address review feedback**
7. **Merge** after approval and passing CI checks

## 🌳 Branch Strategy

### Branch Types

- `main` - Production-ready code only
- `staging` - Pre-production testing
- `develop` - Active development
- `feature/*` - New features
- `fix/*` - Bug fixes
- `hotfix/*` - Urgent production fixes
- `docs/*` - Documentation updates
- `chore/*` - Maintenance tasks

### Branch Flow

```
feature/xxx → develop → staging → main
    │            ↓         ↓        ↓
    │          Dev      Staging  Production
```

### Creating Branches

```bash
# Feature branch
git checkout develop
git pull origin develop
git checkout -b feature/add-user-auth

# Bug fix
git checkout -b fix/login-error

# Hotfix (from main)
git checkout main
git checkout -b hotfix/security-patch
```

## 📝 Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes

### Examples

```bash
# Good commit messages
feat(backend): add user authentication endpoint
fix(frontend): resolve login form validation issue
docs: update deployment guide with new steps
chore(deps): update terraform to 1.6.0
refactor(backend): simplify database connection logic

# Bad commit messages
update stuff
fix bug
changes
WIP
```

### Scope Guidelines

- `backend` - Backend service changes
- `frontend` - Frontend service changes
- `infra` - Infrastructure/Terraform changes
- `ci` - CI/CD pipeline changes
- `docs` - Documentation changes
- `deps` - Dependency updates

## 🔍 Pull Request Process

### Before Creating a PR

- [ ] All tests pass locally
- [ ] Code follows project style guidelines
- [ ] Documentation is updated if needed
- [ ] Commit messages follow conventions
- [ ] Branch is up to date with base branch

### Creating a Pull Request

1. **Push your branch** to GitHub
2. **Create PR** targeting `develop`
3. **Fill out PR template** completely
4. **Link related issues** using keywords (Fixes #123)
5. **Request reviewers**
6. **Add appropriate labels**

### PR Title Format

Follow the same format as commit messages:

```
feat(backend): add user authentication
fix(frontend): resolve mobile responsive issue
docs: update README with new instructions
```

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] Tested locally

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings generated
```

### Review Process

- PRs require at least 1 approval
- All CI checks must pass
- Address all review comments
- Keep PR scope focused and small
- Respond to feedback within 2 business days

### Merging

- Use **Squash and Merge** for feature branches
- Use **Rebase and Merge** for hotfixes
- Delete branch after merging

## 🧪 Testing

### Running Tests

```bash
# All tests
make test

# Backend tests only
cd services/backend
pytest

# Frontend tests only
cd services/frontend
npm test

# Integration tests
docker-compose up -d
# Run integration test suite
```

### Writing Tests

#### Backend Tests (Python/Pytest)

```python
# services/backend/tests/test_api.py
def test_health_endpoint():
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
```

#### Frontend Tests (Jest/Vitest)

```javascript
// services/frontend/src/components/Button.test.jsx
test('button renders correctly', () => {
  const { getByText } = render(<Button>Click me</Button>);
  expect(getByText('Click me')).toBeInTheDocument();
});
```

### Test Coverage

- Aim for > 80% code coverage
- All new features must include tests
- Critical paths must have integration tests

## 🎨 Code Style

### Python (Backend)

```bash
# Format with black
black services/backend/

# Lint with flake8
flake8 services/backend/

# Type check with mypy
mypy services/backend/
```

**Style Guide**: Follow [PEP 8](https://pep8.org/)

### JavaScript/React (Frontend)

```bash
# Format with prettier
npm run format

# Lint with eslint
npm run lint
```

**Style Guide**: [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)

### Terraform (Infrastructure)

```bash
# Format
terraform fmt -recursive

# Validate
terraform validate

# Lint with tflint
tflint
```

**Style Guide**: [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 📁 File Organization

### Adding New Services

```
services/
└── new-service/
    ├── Dockerfile
    ├── README.md
    ├── src/
    ├── tests/
    └── package.json or requirements.txt
```

### Adding New Infrastructure Modules

```
infrastructure/modules/
└── new-module/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

## 🐛 Reporting Bugs

### Before Reporting

- Check if the bug has already been reported
- Try to reproduce in a clean environment
- Gather relevant information (logs, screenshots)

### Bug Report Template

```markdown
**Description**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '....'
3. See error

**Expected Behavior**
What you expected to happen

**Screenshots**
If applicable

**Environment**
- OS: [e.g., Windows 10]
- Browser: [e.g., Chrome 91]
- Version: [e.g., 1.0.0]

**Additional Context**
Any other relevant information
```

## 💡 Feature Requests

### Feature Request Template

```markdown
**Problem Statement**
What problem does this solve?

**Proposed Solution**
Your proposed solution

**Alternatives Considered**
Other solutions you've thought about

**Additional Context**
Mockups, examples, etc.
```

## 📞 Getting Help

- **Documentation**: Check [docs/](docs/) first
- **Discussions**: Use GitHub Discussions for questions
- **Issues**: Create an issue for bugs
- **Slack/Discord**: [Your communication channel]

## 🏆 Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project README

## 📚 Additional Resources

- [Quick Start Guide](docs/QUICK_START.md)
- [AWS Setup Guide](docs/AWS_SETUP_GUIDE.md)
- [Deployment Workflow](docs/DEPLOYMENT_WORKFLOW.md)
- [Infrastructure README](infrastructure/README.md)

---

**Thank you for contributing!** 🎉

Your contributions make this project better for everyone.

