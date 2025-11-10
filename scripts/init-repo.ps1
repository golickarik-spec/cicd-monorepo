# Repository Initialization Script for Windows (PowerShell)

Write-Host "🚀 Initializing CICD Monorepo..." -ForegroundColor Green
Write-Host ""

# Step 1: Initialize Git
Write-Host "📦 Step 1: Initializing Git repository..." -ForegroundColor Cyan
if (!(Test-Path ".git")) {
    git init
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "⚠️  Git repository already exists" -ForegroundColor Yellow
}

# Step 2: Create initial commit
Write-Host ""
Write-Host "📝 Step 2: Creating initial commit..." -ForegroundColor Cyan
git add .
git commit -m "feat: initialize monorepo with modular infrastructure

- Restructure to services-based layout
- Add comprehensive Terraform modules
- Configure GitHub Actions workflows
- Add documentation and guides"
Write-Host "✅ Initial commit created" -ForegroundColor Green

# Step 3: Create branches
Write-Host ""
Write-Host "🌳 Step 3: Creating branches..." -ForegroundColor Cyan
git branch -M main
git checkout -b staging
git checkout -b develop
git checkout main
Write-Host "✅ Branches created: main, staging, develop" -ForegroundColor Green

# Step 4: Test local development
Write-Host ""
Write-Host "🧪 Step 4: Testing local development..." -ForegroundColor Cyan
Write-Host "   Starting Docker Compose..." -ForegroundColor Gray
docker-compose up -d

Start-Sleep -Seconds 5

# Check if services are running
$backendRunning = docker-compose ps backend | Select-String "Up"
$frontendRunning = docker-compose ps frontend | Select-String "Up"

if ($backendRunning -and $frontendRunning) {
    Write-Host "✅ Services started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Backend:  http://localhost:8000" -ForegroundColor Green
    Write-Host "   Frontend: http://localhost:5173" -ForegroundColor Green
    Write-Host "   Database: localhost:3306" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some services failed to start" -ForegroundColor Yellow
    Write-Host "   Check logs with: docker-compose logs" -ForegroundColor Gray
}

# Stop services
Write-Host ""
Write-Host "🛑 Stopping services..." -ForegroundColor Cyan
docker-compose down
Write-Host "✅ Services stopped" -ForegroundColor Green

# Final instructions
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 Repository initialized successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Create GitHub repository:" -ForegroundColor White
Write-Host "   gh repo create YOUR_ORG/YOUR_REPO --public" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Push to GitHub:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/YOUR_ORG/YOUR_REPO.git" -ForegroundColor Gray
Write-Host "   git push -u origin main" -ForegroundColor Gray
Write-Host "   git push origin staging" -ForegroundColor Gray
Write-Host "   git push origin develop" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Configure GitHub Secrets:" -ForegroundColor White
Write-Host "   - AWS_ROLE_ARN (IAM role for GitHub Actions)" -ForegroundColor Gray
Write-Host "   - MYSQL_PASSWORD (database password)" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Configure GitHub Variables:" -ForegroundColor White
Write-Host "   - AWS_REGION (e.g., us-east-1)" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Setup AWS (see docs/AWS_SETUP_GUIDE.md)" -ForegroundColor White
Write-Host "   - Create OIDC provider" -ForegroundColor Gray
Write-Host "   - Create IAM role" -ForegroundColor Gray
Write-Host "   - Attach permissions" -ForegroundColor Gray
Write-Host ""
Write-Host "6. Test deployment:" -ForegroundColor White
Write-Host "   git checkout develop" -ForegroundColor Gray
Write-Host "   git push origin develop" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "   - Quick Start:  docs/QUICK_START.md" -ForegroundColor Gray
Write-Host "   - AWS Setup:    docs/AWS_SETUP_GUIDE.md" -ForegroundColor Gray
Write-Host "   - Workflows:    docs/DEPLOYMENT_WORKFLOW.md" -ForegroundColor Gray
Write-Host "   - Contributing: CONTRIBUTING.md" -ForegroundColor Gray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Happy deploying! 🚀" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan

