# 🚀 Adyela Project Commands Reference

**Project:** Adyela Medical Appointments Platform **Date:** October 5, 2025
**Version:** 1.0.0

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Development Commands](#development-commands)
3. [Testing Commands](#testing-commands)
4. [Quality & Security](#quality--security)
5. [Infrastructure & Deployment](#infrastructure--deployment)
6. [Database Operations](#database-operations)
7. [Git & Version Control](#git--version-control)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Quick Start

### First Time Setup

\`\`\`bash

# Clone repository

git clone https://github.com/adyela/adyela.git cd adyela

# Install dependencies

pnpm install

# Setup environment variables

cp .env.example .env.local

# Edit .env.local with your credentials

# Start development environment

make start

# Verify all services are running

make health \`\`\`

### Daily Development Workflow

\`\`\`bash

# Start development servers

make start # Start all services (API, Web, Firebase, Redis) make logs # View
combined logs make health # Check service health

# Run tests before committing

make test # Run all tests make lint # Lint code make type-check # TypeScript +
Python type checking

# Stop services when done

make stop \`\`\`

---

## 💻 Development Commands

### Service Management

#### Start Services

\`\`\`bash

# All services (recommended)

make start

# Equivalent to: docker-compose -f docker-compose.dev.yml up -d

# Individual services

make start-api # API only make start-web # Web only make start-db # Firebase
emulator only make start-cache # Redis only \`\`\`

#### Stop Services

\`\`\`bash

# All services

make stop

# Individual services

make stop-api make stop-web make stop-db make stop-cache

# Force stop and remove volumes

make clean \`\`\`

#### Monitor Services

\`\`\`bash

# View logs

make logs # All services make logs-api # API only make logs-web # Web only make
logs-follow # Follow logs in real-time

# Check service health

make health # Quick health check make ps # List running containers \`\`\`

### Development Servers

#### Backend (API)

\`\`\`bash

# Start API development server

cd apps/api poetry run dev # With hot reload

# API available at http://localhost:8000

# API documentation

open http://localhost:8000/docs # Swagger UI open http://localhost:8000/redoc #
ReDoc

# Direct Python execution

poetry run python -m uvicorn adyela_api.main:app --reload \`\`\`

#### Frontend (Web)

\`\`\`bash

# Start web development server

cd apps/web pnpm dev # With HMR

# App available at http://localhost:3000

# Preview production build

pnpm build pnpm preview \`\`\`

---

## 🧪 Testing Commands

### Unit Tests

#### Frontend (Vitest)

\`\`\`bash

# Run all unit tests

pnpm test

# Watch mode

pnpm test:watch

# With coverage

pnpm test:coverage

# Specific file

pnpm test src/features/auth/components/LoginPage.test.tsx

# UI mode (interactive)

pnpm test:ui \`\`\`

#### Backend (Pytest)

\`\`\`bash cd apps/api

# Run all tests

poetry run pytest

# With coverage

poetry run pytest --cov=adyela_api

# Specific test file

poetry run pytest tests/unit/domain/test_appointment.py

# Specific test function

poetry run pytest
tests/unit/domain/test_appointment.py::TestAppointment::test_create_appointment_success

# Run only unit tests

poetry run pytest -m unit

# Run only integration tests

poetry run pytest -m integration

# Generate HTML coverage report

poetry run pytest --cov=adyela_api --cov-report=html open htmlcov/index.html
\`\`\`

### E2E Tests (Playwright)

#### Basic E2E Commands

\`\`\`bash

# Run all E2E tests (Chromium only)

make e2e

# Equivalent to: pnpm playwright test

# Specific browser

pnpm playwright test --project=chromium pnpm playwright test --project=firefox
pnpm playwright test --project=webkit

# Headed mode (visible browser)

make e2e-headed

# Equivalent to: pnpm playwright test --headed

# Debug mode

make e2e-debug

# Equivalent to: pnpm playwright test --debug

# UI mode (interactive)

make e2e-ui

# Equivalent to: pnpm playwright test --ui

# Specific test file

pnpm playwright test tests/e2e/auth.spec.ts

# Update snapshots

pnpm playwright test --update-snapshots \`\`\`

#### Advanced E2E Options

\`\`\`bash

# Run tests matching pattern

pnpm playwright test -g "login"

# Run with specific reporter

pnpm playwright test --reporter=html pnpm playwright test --reporter=json

# Run on specific URL

BASE_URL=https://staging.adyela.com pnpm playwright test

# Run with retries

pnpm playwright test --retries=3

# Run specific number of workers

pnpm playwright test --workers=4

# View HTML report

pnpm playwright show-report \`\`\`

### API Contract Testing (Schemathesis)

\`\`\`bash

# Run API contract tests

make api-contract

# Manual execution

schemathesis run --url http://localhost:8000/openapi.json \\ --checks all \\
--hypothesis-max-examples=100 \\ --header "X-Tenant-ID: test-tenant"

# Generate test report

schemathesis run --url http://localhost:8000/openapi.json \\
--junit-xml=contract-report.xml \`\`\`

---

## 🔍 Quality & Security

### Code Quality

#### Linting

\`\`\`bash

# Lint all code

make lint

# Auto-fix linting issues

make lint-fix

# Frontend linting (ESLint)

pnpm lint # Check pnpm lint:fix # Auto-fix

# Backend linting (Ruff + Black)

cd apps/api poetry run ruff check . # Check poetry run ruff check --fix . #
Auto-fix poetry run black . # Format \`\`\`

#### Type Checking

\`\`\`bash

# Type check all code

make type-check

# Frontend (TypeScript)

pnpm type-check

# or

cd apps/web && tsc --noEmit

# Backend (MyPy)

cd apps/api poetry run mypy adyela_api \`\`\`

#### Code Formatting

\`\`\`bash

# Format all code

make format

# Check formatting (without fixing)

make format-check

# Frontend (Prettier)

pnpm format # Fix pnpm format:check # Check only

# Backend (Black)

cd apps/api poetry run black . # Fix poetry run black --check . # Check only
\`\`\`

### Security Scanning

#### Dependency Vulnerabilities

\`\`\`bash

# Security audit

make security-audit

# Frontend dependencies (npm audit)

pnpm audit pnpm audit --fix # Auto-fix

# Backend dependencies (pip-audit)

cd apps/api poetry run pip-audit poetry run safety check # Alternative \`\`\`

#### Container Security (Trivy)

\`\`\`bash

# Scan API container

trivy image adyela-api:latest

# Scan with severity filter

trivy image --severity CRITICAL,HIGH adyela-api:latest

# Scan web container

trivy image adyela-web:latest \`\`\`

#### Secret Detection

\`\`\`bash

# Scan for secrets in code

gitleaks detect --source . --verbose

# Scan specific commit

gitleaks detect --source . --commit SHA

# Protect pre-commit

gitleaks protect --staged \`\`\`

### Performance Auditing

#### Lighthouse

\`\`\`bash

# Run Lighthouse audit

make lighthouse

# Manual execution

cd apps/web pnpm build npx serve -s dist -p 3001 & lighthouse
http://localhost:3001 --output html --output-path ./lighthouse-report.html
\`\`\`

#### Bundle Analysis

\`\`\`bash

# Analyze frontend bundle

cd apps/web pnpm build pnpm vite-bundle-analyzer

# View bundle visualization

open dist/stats.html \`\`\`

### Comprehensive Quality Checks

\`\`\`bash

# Run all quality checks

make quality

# With auto-fix

make quality-fix

# Generate quality report

make reports \`\`\`

---

## ☁️ Infrastructure & Deployment

### Local Development

#### Docker Commands

\`\`\`bash

# Build containers

make build # Build all make build-api # API only make build-web # Web only

# Rebuild from scratch

make rebuild # Clean build all

# Remove all containers and volumes

make clean \`\`\`

#### Database (Firestore Emulator)

\`\`\`bash

# Start Firebase emulator

cd apps/api firebase emulators:start

# With specific ports

firebase emulators:start --only firestore,auth

# Import data

firebase emulators:start --import=./firebase-data

# Export data

firebase emulators:export ./firebase-data \`\`\`

### Terraform (Infrastructure as Code)

#### Plan & Apply

\`\`\`bash

# Initialize Terraform

cd infra/environments/staging terraform init

# Plan changes

terraform plan -out=tfplan

# Apply changes

terraform apply tfplan

# Destroy resources

terraform destroy \`\`\`

#### Workspace Management

\`\`\`bash

# List workspaces

terraform workspace list

# Create workspace

terraform workspace new production

# Switch workspace

terraform workspace select staging

# Delete workspace

terraform workspace delete dev \`\`\`

### Deployment

#### Staging Deployment

\`\`\`bash

# Deploy to staging (via GitHub Actions)

git tag staging-$(date +%Y%m%d-%H%M%S) git push origin --tags

# Manual deployment

make deploy-staging

# Verify deployment

make verify-staging \`\`\`

#### Production Deployment

\`\`\`bash

# Create release tag

git tag v1.2.0 git push origin v1.2.0

# GitHub Actions automatically deploys to production

# Manual rollback

make rollback-production --to=v1.1.0 \`\`\`

---

## 💾 Database Operations

### Firestore (Local Development)

#### Using Firebase CLI

\`\`\`bash

# Start emulator

firebase emulators:start

# Access Firestore Emulator UI

open http://localhost:4000 \`\`\`

#### Using Python (Script)

\`\`\`python

# apps/api/scripts/db_seed.py

from google.cloud import firestore from adyela_api.domain import Appointment,
Patient

db = firestore.Client()

# Create test data

patient = Patient( id="patient-123", first_name="John", last_name="Doe",
email="john@example.com" )

db.collection("patients").document(patient.id).set(patient.to_dict()) \`\`\`

### Database Migrations

#### Create Migration

\`\`\`bash cd apps/api/migrations

# Create new migration file

cat > 001_add_prescription_collection.py << EOF """Add prescription
collection"""

async def up(db): # Migration logic pass

async def down(db): # Rollback logic pass EOF \`\`\`

#### Run Migrations

\`\`\`bash

# Run pending migrations

python -m scripts.run_migrations up

# Rollback last migration

python -m scripts.run_migrations down \`\`\`

### Backup & Restore

#### Firestore Backup (Production)

\`\`\`bash

# Export Firestore data

gcloud firestore export gs://adyela-backups/$(date +%Y%m%d)

# Import Firestore data

gcloud firestore import gs://adyela-backups/20251005 \`\`\`

---

## 🔄 Git & Version Control

### Branch Management

#### Create Feature Branch

\`\`\`bash

# Create and switch to feature branch

git checkout -b feature/prescription-management

# Push to remote

git push -u origin feature/prescription-management \`\`\`

#### Work on Branch

\`\`\`bash

# Make changes

git add . git commit -m "feat: add prescription model"

# Push changes

git push

# Sync with main

git fetch origin git rebase origin/main \`\`\`

### Commit Messages

#### Conventional Commits Format

\`\`\`bash

# Feature

git commit -m "feat: add prescription management"

# Bug fix

git commit -m "fix: resolve login validation error"

# Documentation

git commit -m "docs: update API documentation"

# Refactoring

git commit -m "refactor: restructure appointment repository"

# Tests

git commit -m "test: add E2E tests for prescriptions"

# Chore

git commit -m "chore: update dependencies" \`\`\`

#### Using Commitizen

\`\`\`bash

# Interactive commit (recommended)

pnpm commit

# Commitizen will prompt for:

# - Type (feat, fix, docs, etc.)

# - Scope (auth, appointments, api, etc.)

# - Subject (short description)

# - Body (detailed description)

# - Breaking changes

# - Issues closed

\`\`\`

### Pull Requests

#### Create PR

\`\`\`bash

# Using GitHub CLI

gh pr create \\ --title "feat: Add prescription management" \\ --body "$(cat
<<EOF

## Summary

Added prescription management feature

## Changes

- Created Prescription entity
- Implemented prescription repository
- Added prescription API endpoints
- Created prescription UI components

## Test Plan

- [x] Unit tests pass
- [x] E2E tests pass
- [x] Manual testing completed

🤖 Generated with [Claude Code](https://claude.com/claude-code) EOF )"

# Using Git + Browser

git push -u origin feature/prescription-management

# Then create PR on GitHub web interface

\`\`\`

#### Review PR

\`\`\`bash

# Checkout PR locally

gh pr checkout 123

# View PR details

gh pr view 123

# View PR diff

gh pr diff 123

# Review PR

gh pr review 123 --approve gh pr review 123 --request-changes --body "Please fix
linting errors"

# Merge PR

gh pr merge 123 --squash --delete-branch \`\`\`

---

## 🐛 Troubleshooting

### Common Issues

#### Port Already in Use

\`\`\`bash

# Find process using port

lsof -i :3000 # Web lsof -i :8000 # API

# Kill process

kill -9 <PID>

# Or use different port

PORT=3001 pnpm dev \`\`\`

#### Docker Issues

\`\`\`bash

# Remove all containers

docker rm -f $(docker ps -aq)

# Remove all volumes

docker volume prune -f

# Clean rebuild

make clean make build make start \`\`\`

#### Node Modules Issues

\`\`\`bash

# Clear pnpm cache

pnpm store prune

# Reinstall dependencies

rm -rf node_modules pnpm-lock.yaml pnpm install \`\`\`

#### Python Environment Issues

\`\`\`bash cd apps/api

# Remove virtual environment

poetry env remove --all

# Reinstall dependencies

poetry install

# Verify environment

poetry run python --version \`\`\`

### Debugging

#### API Debugging

\`\`\`bash

# Run with debugger

cd apps/api poetry run python -m debugpy --listen 5678 -m uvicorn
adyela_api.main:app --reload

# View logs

docker-compose logs -f api

# Execute inside container

docker-compose exec api bash \`\`\`

#### Frontend Debugging

\`\`\`bash

# Run with source maps

cd apps/web pnpm dev --sourcemap

# View detailed logs

DEBUG=\* pnpm dev

# Clear cache

rm -rf node_modules/.vite \`\`\`

### Performance Issues

#### Check Resource Usage

\`\`\`bash

# Docker stats

docker stats

# System resources

htop

# Disk space

df -h docker system df \`\`\`

#### Optimize Performance

\`\`\`bash

# Prune Docker

docker system prune -a --volumes

# Clear build cache

pnpm store prune rm -rf apps/web/.next apps/web/dist

# Restart services

make restart \`\`\`

---

## 📚 Additional Resources

### Documentation

- [Project Structure Analysis](./PROJECT_STRUCTURE_ANALYSIS.md)
- [Token Optimization Strategy](./TOKEN_OPTIMIZATION_STRATEGY.md)
- [MCP Integration Matrix](./MCP_INTEGRATION_MATRIX.md)
- [Quality Automation Guide](./QUALITY_AUTOMATION.md)
- [MCP Servers Guide](./MCP_SERVERS_GUIDE.md)

### Agent Specifications

- [Cloud Architect Agent](../.claude/agents/cloud-architect-agent.md)
- [Cybersecurity Agent](../.claude/agents/cybersecurity-agent.md)
- [QA Automation Agent](../.claude/agents/qa-automation-agent.md)
- [Healthcare Compliance Agent](../.claude/agents/healthcare-compliance-agent.md)

### External Links

- [Adyela GitHub Repository](https://github.com/adyela/adyela)
- [Adyela Documentation](https://docs.adyela.com)
- [API Documentation (Swagger)](http://localhost:8000/docs)

---

## 🎯 Quick Reference Card

\`\`\`bash

# Essential Daily Commands

make start # Start all services make logs # View logs make test # Run all tests
make lint # Lint code make e2e # Run E2E tests make stop # Stop all services

# Quality Checks (Before Commit)

make lint # Linting make type-check # Type checking make test # Unit tests make
e2e # E2E tests make quality # All quality checks

# CI/CD

git push # Push code (triggers CI) git tag v1.2.0 # Create release gh pr
create # Create pull request \`\`\`

---

**Version History:**

- v1.0.0 (2025-10-05): Initial commands reference

**Status:** ✅ Complete Reference Guide
