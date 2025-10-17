# 📜 Scripts Directory

This directory contains all automation scripts for the Adyela project, organized
by category for better maintainability.

## 📁 Directory Structure

```
scripts/
├── setup/          # Environment setup & configuration
├── gcp/            # Google Cloud Platform operations
├── testing/        # Quality checks & testing
├── utils/          # General utilities
└── README.md       # This file
```

---

## 🔧 Setup Scripts

Scripts for initial environment configuration and service setup.

### `setup/setup-mcp-servers.sh`

**Purpose**: Configure MCP (Model Context Protocol) servers for Claude Code
integration **Usage**: `./scripts/setup/setup-mcp-servers.sh` or
`make mcp-setup` **Prerequisites**: Claude Desktop installed **Description**:
Configures 5 MCP servers (Playwright, Filesystem, GitHub, Sequential Thinking,
Taskmaster AI) in Claude Desktop configuration file.

### `setup/dev-setup.sh`

**Purpose**: One-time developer environment setup **Usage**:
`./scripts/setup/dev-setup.sh` or `make dev-setup` **Prerequisites**: Docker,
pnpm, Python 3.12 **Description**: Initializes local development environment,
copies .env files, installs dependencies, and verifies service health.

### `setup/setup-firebase-secrets.sh`

**Purpose**: Configure Firebase credentials in GCP Secret Manager **Usage**:
`./scripts/setup/setup-firebase-secrets.sh` **Prerequisites**: Firebase project,
GCP authentication **Description**: Stores Firebase configuration securely in
Google Secret Manager for environment-specific access.

### `setup/setup-gcp-oidc.sh`

**Purpose**: Configure OpenID Connect for GitHub Actions authentication
**Usage**: `./scripts/setup/setup-gcp-oidc.sh` **Prerequisites**: GCP project,
GitHub repository **Description**: Sets up Workload Identity Federation for
secure CI/CD authentication without service account keys.

### `setup/setup-gcp-secrets.sh`

**Purpose**: Automated GCP secrets configuration **Usage**:
`./scripts/setup/setup-gcp-secrets.sh` **Prerequisites**: GCP authentication,
Secret Manager API enabled **Description**: Automated script to create and
configure all required secrets for the application.

### `setup/setup-gcp-secrets-manual.sh`

**Purpose**: Manual GCP secrets configuration with prompts **Usage**:
`./scripts/setup/setup-gcp-secrets-manual.sh` **Prerequisites**: GCP
authentication **Description**: Interactive script that prompts for each secret
value and stores them in Secret Manager.

---

## ☁️ GCP Scripts

Scripts for managing Google Cloud Platform resources and operations.

### `gcp/gcp-setup-interactive.sh`

**Purpose**: Interactive GCP project setup wizard **Usage**:
`./scripts/gcp/gcp-setup-interactive.sh` **Prerequisites**: gcloud CLI installed
**Description**: Step-by-step wizard for configuring a new GCP project with all
required APIs, IAM roles, and resources.

### `gcp/setup-gcp-complete.sh`

**Purpose**: Complete automated GCP environment setup **Usage**:
`./scripts/gcp/setup-gcp-complete.sh` **Prerequisites**: GCP authentication
**Description**: Automated script that configures entire GCP infrastructure
including VPC, Cloud Run, Firestore, etc.

### `gcp/enable-gcp-apis.sh`

**Purpose**: Enable required GCP APIs **Usage**:
`./scripts/gcp/enable-gcp-apis.sh` **Prerequisites**: GCP project with billing
enabled **Description**: Enables all necessary Google Cloud APIs (Cloud Run,
Firestore, Secret Manager, Artifact Registry, etc.).

### `gcp/setup-terraform-backend.sh`

**Purpose**: Configure Terraform remote state backend **Usage**:
`./scripts/gcp/setup-terraform-backend.sh` **Prerequisites**: Terraform
installed, GCP authentication **Description**: Creates GCS bucket for Terraform
state storage with versioning and state locking.

### `gcp/setup-staging-deployment.sh`

**Purpose**: Deploy application to staging environment **Usage**:
`./scripts/gcp/setup-staging-deployment.sh` **Prerequisites**: Docker images
built, GCP authentication **Description**: Deploys API and Web services to Cloud
Run staging environment with proper configuration.

### `gcp/create-artifact-registry.sh`

**Purpose**: Create Artifact Registry repository for Docker images **Usage**:
`./scripts/gcp/create-artifact-registry.sh` **Prerequisites**: GCP
authentication **Description**: Sets up Docker repository in Artifact Registry
for storing container images.

### `gcp/check-daily-costs.sh`

**Purpose**: Monitor daily GCP spending **Usage**:
`./scripts/gcp/check-daily-costs.sh` **Prerequisites**: Cloud Billing API
enabled **Description**: Retrieves and reports current day's GCP costs with
breakdown by service.

### `gcp/setup-budgets.sh`

**Purpose**: Configure GCP budget alerts **Usage**:
`./scripts/gcp/setup-budgets.sh` **Prerequisites**: Cloud Billing API enabled
**Description**: Creates budget alerts for cost monitoring with email
notifications at 50%, 80%, and 100% thresholds.

### `gcp/setup-budget-notifications.sh`

**Purpose**: Configure budget alert notification channels **Usage**:
`./scripts/gcp/setup-budget-notifications.sh` **Prerequisites**: Budgets created
**Description**: Sets up email and Pub/Sub notification channels for budget
alerts.

### `gcp/setup-auto-shutdown.sh`

**Purpose**: Schedule automatic resource shutdown **Usage**:
`./scripts/gcp/setup-auto-shutdown.sh` **Prerequisites**: Cloud Scheduler API
enabled **Description**: Creates Cloud Scheduler jobs to automatically shut down
development resources during off-hours to save costs.

### `gcp/simple-auto-shutdown.sh`

**Purpose**: Simple resource shutdown script **Usage**:
`./scripts/gcp/simple-auto-shutdown.sh` **Prerequisites**: GCP authentication
**Description**: Manual script to quickly shut down all non-production Cloud Run
services and development resources.

---

## 🧪 Testing Scripts

Scripts for quality assurance, testing, and validation.

### `testing/quality-checks.sh`

**Purpose**: Run comprehensive quality checks **Usage**:
`./scripts/testing/quality-checks.sh` or `make quality` **Prerequisites**:
Services running **Description**: Executes linting, type checking, tests, and
security audits for both API and Web. Used in CI/CD pipeline. **Checks
Performed**:

- ✓ Code formatting (Black, Prettier)
- ✓ Linting (Ruff, ESLint)
- ✓ Type checking (MyPy, TypeScript)
- ✓ Unit tests (Pytest, Vitest)
- ✓ Security scanning (Bandit, npm audit)

### `testing/lighthouse-audit.sh`

**Purpose**: Run Lighthouse performance and accessibility audit **Usage**:
`./scripts/testing/lighthouse-audit.sh [URL]` or `make lighthouse`
**Prerequisites**: Chrome/Chromium installed **Description**: Performs
Lighthouse audit for performance, accessibility, best practices, and SEO.
Generates HTML report. **Metrics**:

- Performance (>= 90 target)
- Accessibility (>= 100 target)
- Best Practices (>= 90 target)
- SEO (>= 90 target)

### `testing/api-contract-tests.sh`

**Purpose**: Run API contract tests with Schemathesis **Usage**:
`./scripts/testing/api-contract-tests.sh` or `make api-contract`
**Prerequisites**: API running, Schemathesis installed **Description**:
Validates API against OpenAPI specification, tests all endpoints for contract
compliance and generates coverage report.

---

## 🛠️ Utility Scripts

General-purpose utility scripts for development workflow.

### `utils/task-start.sh`

**Purpose**: Start working on a Task Master task **Usage**:
`./scripts/utils/task-start.sh <TASK_ID>` or `make task-start ID=5`
**Prerequisites**: Taskmaster AI configured **Description**: Sets task status to
"in-progress", creates feature branch, and displays task details.

### `utils/task-complete.sh`

**Purpose**: Mark Task Master task as complete **Usage**:
`./scripts/utils/task-complete.sh <TASK_ID>` or `make task-complete ID=5`
**Prerequisites**: Taskmaster AI configured **Description**: Sets task status to
"done", generates completion summary, and suggests next task.

---

## 🚀 Common Usage Patterns

### Initial Project Setup

```bash
# 1. Setup GCP environment
./scripts/gcp/enable-gcp-apis.sh
./scripts/gcp/gcp-setup-interactive.sh

# 2. Configure secrets
./scripts/setup/setup-gcp-secrets.sh
./scripts/setup/setup-firebase-secrets.sh

# 3. Setup local development
./scripts/setup/dev-setup.sh
```

### Development Workflow

```bash
# Start a task
make task-start ID=15

# Run quality checks before committing
make quality

# Complete the task
make task-complete ID=15
```

### Testing & Validation

```bash
# Run all quality checks
make quality

# Run E2E tests
make e2e

# Run performance audit
make lighthouse

# Run API contract tests
make api-contract
```

### GCP Operations

```bash
# Check daily costs
./scripts/gcp/check-daily-costs.sh

# Deploy to staging
./scripts/gcp/setup-staging-deployment.sh

# Shutdown dev resources
./scripts/gcp/simple-auto-shutdown.sh
```

---

## 🔧 Makefile Integration

All scripts are integrated with the project Makefile for easier execution:

| Makefile Command          | Script Path                     | Description            |
| ------------------------- | ------------------------------- | ---------------------- |
| `make quality`            | `testing/quality-checks.sh`     | Run all quality checks |
| `make lighthouse`         | `testing/lighthouse-audit.sh`   | Performance audit      |
| `make api-contract`       | `testing/api-contract-tests.sh` | API contract tests     |
| `make mcp-setup`          | `setup/setup-mcp-servers.sh`    | Configure MCP servers  |
| `make task-start ID=X`    | `utils/task-start.sh`           | Start task X           |
| `make task-complete ID=X` | `utils/task-complete.sh`        | Complete task X        |
| `make dev-setup`          | `setup/dev-setup.sh`            | Developer setup        |

See `make help` for complete list of available commands.

---

## 📋 Prerequisites Summary

### Required Tools

- **Docker & Docker Compose**: Container runtime
- **pnpm**: Package manager (frontend)
- **Python 3.12**: Backend runtime
- **Poetry**: Python dependency manager
- **gcloud CLI**: Google Cloud operations
- **Terraform**: Infrastructure as Code (for IaC scripts)

### Required Access

- **GCP Project**: With billing enabled
- **Firebase Project**: For authentication
- **GitHub Repository**: For CI/CD integration
- **Taskmaster AI**: For task management scripts

---

## 🐛 Troubleshooting

### Script Permission Issues

```bash
# Make all scripts executable
find scripts/ -name "*.sh" -exec chmod +x {} \;
```

### GCP Authentication

```bash
# Login to GCP
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### Script Execution Errors

- Ensure you're running scripts from project root
- Check prerequisites are installed
- Verify GCP authentication and project configuration
- Review script output for specific error messages

---

## 📚 Additional Resources

- **Project Documentation**: `/docs`
- **Makefile Reference**: Run `make help`
- **Taskmaster AI Guide**: `/docs/TASKMASTER_AI_GUIDE.md`
- **MCP Integration**: `/docs/MCP_INTEGRATION_MATRIX.md`
- **CI/CD Workflows**: `/.github/workflows`

---

## 🤝 Contributing

When adding new scripts:

1. **Choose appropriate category** (setup, gcp, testing, utils)
2. **Add shebang**: `#!/usr/bin/env bash`
3. **Include header comment**: Purpose, usage, prerequisites
4. **Make executable**: `chmod +x script.sh`
5. **Update this README**: Add documentation in appropriate section
6. **Update Makefile**: Add convenience target if appropriate
7. **Test thoroughly**: Verify script works in clean environment

---

## 📝 Script Maintenance

- All scripts use bash for consistency
- Scripts should be idempotent when possible
- Include proper error handling and exit codes
- Use descriptive variable names and comments
- Validate prerequisites before execution
- Provide helpful error messages

---

**Last Updated**: 2025-01-10 **Total Scripts**: 22 (Setup: 6, GCP: 11, Testing:
3, Utils: 2)
