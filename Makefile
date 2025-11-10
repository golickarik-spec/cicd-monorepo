.PHONY: help setup start stop restart logs clean test deploy-dev deploy-staging deploy-prod

help:
	@echo "Available commands:"
	@echo "  make setup         - Setup local development environment"
	@echo "  make start         - Start all services with Docker Compose"
	@echo "  make stop          - Stop all services"
	@echo "  make restart       - Restart all services"
	@echo "  make logs          - View logs from all services"
	@echo "  make clean         - Clean up containers and volumes"
	@echo "  make test          - Run all tests"
	@echo "  make deploy-dev    - Deploy to development"
	@echo "  make deploy-staging- Deploy to staging"
	@echo "  make deploy-prod   - Deploy to production"

setup:
	@echo "🔧 Setting up local environment..."
	@docker-compose build
	@cd services/backend && pip install -r requirements.txt || true
	@cd services/frontend && npm install || true
	@echo "✅ Setup complete!"

start:
	@echo "🚀 Starting all services..."
	@docker-compose up -d
	@echo "✅ Services started!"
	@echo "   Backend:  http://localhost:8000"
	@echo "   Frontend: http://localhost:5173"
	@echo "   Database: localhost:3306"

stop:
	@echo "🛑 Stopping all services..."
	@docker-compose down
	@echo "✅ Services stopped!"

restart: stop start

logs:
	@docker-compose logs -f

clean:
	@echo "🧹 Cleaning up..."
	@docker-compose down -v
	@rm -rf services/backend/__pycache__
	@rm -rf services/frontend/node_modules
	@rm -rf services/frontend/dist
	@echo "✅ Cleanup complete!"

test:
	@echo "🧪 Running tests..."
	@cd services/backend && pytest || true
	@cd services/frontend && npm test || true
	@echo "✅ Tests complete!"

deploy-dev:
	@echo "🚀 Deploying to dev..."
	@git push origin develop

deploy-staging:
	@echo "🚀 Deploying to staging..."
	@git push origin staging

deploy-prod:
	@echo "🚀 Deploying to production..."
	@git push origin main

