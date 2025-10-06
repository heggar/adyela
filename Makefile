.PHONY: help setup start stop restart logs build test clean quality e2e lighthouse

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Adyela - Local Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC)"
	@echo "  make <target>"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

setup: ## Initial setup: copy env files and create volumes
	@echo "$(BLUE)Setting up Adyela local environment...$(NC)"
	@cp -n .env.example .env 2>/dev/null || echo ".env already exists"
	@cp -n apps/api/.env.example apps/api/.env 2>/dev/null || echo "apps/api/.env already exists"
	@cp -n apps/web/.env.example apps/web/.env 2>/dev/null || echo "apps/web/.env already exists"
	@mkdir -p firebase-data
	@echo "$(GREEN)✓ Setup complete!$(NC)"
	@echo "$(YELLOW)Run 'make start' to begin development$(NC)"

start: ## Start all services in background
	@echo "$(BLUE)Starting Adyela services...$(NC)"
	@docker-compose -f docker-compose.dev.yml up -d
	@echo "$(GREEN)✓ Services started!$(NC)"
	@echo ""
	@echo "$(YELLOW)Access the application:$(NC)"
	@echo "  • Web: http://localhost:3000"
	@echo "  • API Docs: http://localhost:8000/docs"
	@echo "  • Firebase UI: http://localhost:4000"
	@echo ""
	@echo "$(YELLOW)View logs: make logs$(NC)"

start-tools: ## Start all services including optional tools (Redis Commander, Mailhog)
	@echo "$(BLUE)Starting Adyela services with tools...$(NC)"
	@docker-compose --profile tools -f docker-compose.dev.yml up -d
	@echo "$(GREEN)✓ Services started!$(NC)"
	@echo ""
	@echo "$(YELLOW)Access the application:$(NC)"
	@echo "  • Web: http://localhost:3000"
	@echo "  • API Docs: http://localhost:8000/docs"
	@echo "  • Firebase UI: http://localhost:4000"
	@echo "  • Redis Commander: http://localhost:8081"
	@echo "  • Mailhog: http://localhost:8025"

start-fg: ## Start all services in foreground (see logs)
	@echo "$(BLUE)Starting Adyela services (foreground)...$(NC)"
	@docker-compose -f docker-compose.dev.yml up

stop: ## Stop all services
	@echo "$(BLUE)Stopping Adyela services...$(NC)"
	@docker-compose -f docker-compose.dev.yml down
	@echo "$(GREEN)✓ Services stopped!$(NC)"

restart: ## Restart all services
	@echo "$(BLUE)Restarting Adyela services...$(NC)"
	@docker-compose -f docker-compose.dev.yml restart
	@echo "$(GREEN)✓ Services restarted!$(NC)"

logs: ## Show logs from all services
	@docker-compose -f docker-compose.dev.yml logs -f

logs-api: ## Show logs from API service only
	@docker-compose -f docker-compose.dev.yml logs -f api

logs-web: ## Show logs from Web service only
	@docker-compose -f docker-compose.dev.yml logs -f web

logs-firebase: ## Show logs from Firebase emulators
	@docker-compose -f docker-compose.dev.yml logs -f firebase

build: ## Rebuild all services
	@echo "$(BLUE)Rebuilding Adyela services...$(NC)"
	@docker-compose -f docker-compose.dev.yml build
	@echo "$(GREEN)✓ Build complete!$(NC)"

build-api: ## Rebuild API service only
	@echo "$(BLUE)Rebuilding API service...$(NC)"
	@docker-compose -f docker-compose.dev.yml build api
	@echo "$(GREEN)✓ API rebuilt!$(NC)"

build-web: ## Rebuild Web service only
	@echo "$(BLUE)Rebuilding Web service...$(NC)"
	@docker-compose -f docker-compose.dev.yml build web
	@echo "$(GREEN)✓ Web rebuilt!$(NC)"

test: ## Run all tests
	@echo "$(BLUE)Running all tests...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec api poetry run pytest
	@docker-compose -f docker-compose.dev.yml exec web pnpm test --run
	@echo "$(GREEN)✓ All tests passed!$(NC)"

test-api: ## Run API tests only
	@echo "$(BLUE)Running API tests...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec api poetry run pytest
	@echo "$(GREEN)✓ API tests passed!$(NC)"

test-api-cov: ## Run API tests with coverage
	@echo "$(BLUE)Running API tests with coverage...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec api poetry run pytest --cov=adyela_api --cov-report=html
	@echo "$(GREEN)✓ Coverage report generated at apps/api/htmlcov/index.html$(NC)"

test-web: ## Run Web tests only
	@echo "$(BLUE)Running Web tests...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec web pnpm test --run
	@echo "$(GREEN)✓ Web tests passed!$(NC)"

test-web-cov: ## Run Web tests with coverage
	@echo "$(BLUE)Running Web tests with coverage...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec web pnpm test:coverage --run
	@echo "$(GREEN)✓ Coverage report generated at apps/web/coverage/index.html$(NC)"

lint: ## Run linters on all code
	@echo "$(BLUE)Running linters...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec api poetry run ruff check .
	@docker-compose -f docker-compose.dev.yml exec api poetry run black --check .
	@docker-compose -f docker-compose.dev.yml exec web pnpm lint
	@echo "$(GREEN)✓ Linting complete!$(NC)"

format: ## Auto-format all code
	@echo "$(BLUE)Formatting code...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec api poetry run black .
	@docker-compose -f docker-compose.dev.yml exec api poetry run ruff check --fix .
	@docker-compose -f docker-compose.dev.yml exec web pnpm exec prettier --write "src/**/*.{ts,tsx,js,jsx,json,css}"
	@echo "$(GREEN)✓ Formatting complete!$(NC)"

shell-api: ## Open shell in API container
	@docker-compose -f docker-compose.dev.yml exec api /bin/bash

shell-web: ## Open shell in Web container
	@docker-compose -f docker-compose.dev.yml exec web /bin/sh

redis-cli: ## Connect to Redis CLI
	@docker-compose -f docker-compose.dev.yml exec redis redis-cli -a dev-redis-password

ps: ## Show running services
	@docker-compose -f docker-compose.dev.yml ps

clean: ## Stop services and remove volumes (CAUTION: deletes data)
	@echo "$(RED)⚠️  WARNING: This will delete all local data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(BLUE)Cleaning up...$(NC)"; \
		docker-compose -f docker-compose.dev.yml down -v; \
		rm -rf firebase-data; \
		echo "$(GREEN)✓ Cleanup complete!$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

clean-docker: ## Remove all Docker resources (images, containers, volumes)
	@echo "$(RED)⚠️  WARNING: This will remove all Docker resources!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(BLUE)Deep cleaning Docker...$(NC)"; \
		docker-compose -f docker-compose.dev.yml down -v; \
		docker system prune -af; \
		docker volume prune -f; \
		rm -rf firebase-data; \
		echo "$(GREEN)✓ Deep clean complete!$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

health: ## Check health of all services
	@echo "$(BLUE)Checking service health...$(NC)"
	@echo ""
	@echo "$(YELLOW)API:$(NC)"
	@curl -sf http://localhost:8000/health | jq . || echo "$(RED)✗ API not responding$(NC)"
	@echo ""
	@echo "$(YELLOW)Web:$(NC)"
	@curl -sf http://localhost:3000 > /dev/null && echo "$(GREEN)✓ Web is up$(NC)" || echo "$(RED)✗ Web not responding$(NC)"
	@echo ""
	@echo "$(YELLOW)Firebase Emulator UI:$(NC)"
	@curl -sf http://localhost:4000 > /dev/null && echo "$(GREEN)✓ Firebase UI is up$(NC)" || echo "$(RED)✗ Firebase not responding$(NC)"
	@echo ""
	@echo "$(YELLOW)Redis:$(NC)"
	@docker-compose -f docker-compose.dev.yml exec redis redis-cli -a dev-redis-password ping | grep -q PONG && echo "$(GREEN)✓ Redis is up$(NC)" || echo "$(RED)✗ Redis not responding$(NC)"

update-deps: ## Update dependencies for API and Web
	@echo "$(BLUE)Updating dependencies...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec api poetry update
	@docker-compose -f docker-compose.dev.yml exec web pnpm update
	@echo "$(GREEN)✓ Dependencies updated!$(NC)"
	@echo "$(YELLOW)Consider rebuilding: make build$(NC)"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Quality & Testing Commands
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

quality: ## Run all quality checks (lint, type-check, tests, security)
	@./scripts/quality-checks.sh

quality-fix: ## Run quality checks and auto-fix issues
	@echo "$(BLUE)Running auto-fixes...$(NC)"
	@make format
	@./scripts/quality-checks.sh

# E2E Testing
e2e: ## Run Playwright E2E tests
	@echo "$(BLUE)Running E2E tests...$(NC)"
	@pnpm playwright test
	@echo "$(GREEN)✓ E2E tests complete!$(NC)"

e2e-ui: ## Run E2E tests with Playwright UI
	@echo "$(BLUE)Opening Playwright UI...$(NC)"
	@pnpm playwright test --ui

e2e-debug: ## Run E2E tests in debug mode
	@echo "$(BLUE)Running E2E tests in debug mode...$(NC)"
	@pnpm playwright test --debug

e2e-headed: ## Run E2E tests in headed mode (see browser)
	@echo "$(BLUE)Running E2E tests in headed mode...$(NC)"
	@pnpm playwright test --headed

e2e-report: ## Open E2E test report
	@pnpm playwright show-report

# Performance & Accessibility Audits
lighthouse: ## Run Lighthouse performance audit
	@./scripts/lighthouse-audit.sh

lighthouse-ci: ## Run Lighthouse with CI thresholds
	@./scripts/lighthouse-audit.sh http://localhost:3000

# API Testing
api-contract: ## Run API contract tests with Schemathesis
	@./scripts/api-contract-tests.sh

api-load: ## Run API load tests (requires k6)
	@echo "$(YELLOW)Load testing not yet implemented$(NC)"
	@echo "Install k6: https://k6.io/docs/getting-started/installation/"

# Code Analysis
type-check: ## Run TypeScript type checking
	@echo "$(BLUE)Type checking...$(NC)"
	@docker-compose -f docker-compose.dev.yml exec web pnpm type-check
	@docker-compose -f docker-compose.dev.yml exec api poetry run mypy adyela_api
	@echo "$(GREEN)✓ Type checking complete!$(NC)"

security-audit: ## Run security audit
	@echo "$(BLUE)Running security audit...$(NC)"
	@pnpm audit --audit-level=moderate
	@docker-compose -f docker-compose.dev.yml exec api poetry run pip-audit
	@echo "$(GREEN)✓ Security audit complete!$(NC)"

# MCP Servers
mcp-setup: ## Setup MCP servers for Claude Code
	@./scripts/setup-mcp-servers.sh

mcp-test: ## Test MCP server integration
	@echo "$(BLUE)Testing MCP servers...$(NC)"
	@echo "$(YELLOW)Available MCP servers:$(NC)"
	@echo "  • Playwright - Browser automation"
	@echo "  • Filesystem - File operations"
	@echo "  • GitHub - Repository management"
	@echo "  • Sequential Thinking - Problem solving"
	@echo ""
	@echo "$(GREEN)✓ Check Claude Code for available MCP tools$(NC)"

# CI/CD Simulation
ci-local: ## Simulate CI pipeline locally
	@echo "$(BLUE)Running local CI simulation...$(NC)"
	@make quality
	@make e2e
	@make lighthouse
	@make api-contract
	@echo "$(GREEN)✓ CI simulation complete!$(NC)"

# Reports
reports: ## Generate all reports (coverage, lighthouse, etc.)
	@echo "$(BLUE)Generating reports...$(NC)"
	@make test-api-cov
	@make test-web-cov
	@make lighthouse
	@echo "$(GREEN)✓ Reports generated!$(NC)"
	@echo ""
	@echo "$(YELLOW)Available reports:$(NC)"
	@echo "  • API Coverage: apps/api/htmlcov/index.html"
	@echo "  • Web Coverage: apps/web/coverage/index.html"
	@echo "  • Lighthouse: lighthouse-reports/"
	@echo "  • E2E: playwright-report/"
