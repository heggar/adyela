# GitHub Actions Workflows

This directory contains all CI/CD workflows for the Adyela project.

## Status Badges

### CI Workflows

[![CI - API Backend](https://github.com/heggar/adyela/actions/workflows/ci-api.yml/badge.svg)](https://github.com/heggar/adyela/actions/workflows/ci-api.yml)
[![CI - Web Frontend](https://github.com/heggar/adyela/actions/workflows/ci-web.yml/badge.svg)](https://github.com/heggar/adyela/actions/workflows/ci-web.yml)
[![CI - Infrastructure](https://github.com/heggar/adyela/actions/workflows/ci-infra.yml/badge.svg)](https://github.com/heggar/adyela/actions/workflows/ci-infra.yml)

### CD Workflows

[![CD - Development](https://github.com/heggar/adyela/actions/workflows/cd-dev.yml/badge.svg)](https://github.com/heggar/adyela/actions/workflows/cd-dev.yml)
[![CD - Staging](https://github.com/heggar/adyela/actions/workflows/cd-staging.yml/badge.svg)](https://github.com/heggar/adyela/actions/workflows/cd-staging.yml)
[![CD - Production](https://github.com/heggar/adyela/actions/workflows/cd-production.yml/badge.svg)](https://github.com/heggar/adyela/actions/workflows/cd-production.yml)

## Workflows Overview

### CI Workflows

#### 1. `ci-api.yml` - API Backend CI

**Triggers:**

- Pull requests affecting `apps/api/**`
- Pushes to `main` and `develop` branches

**Jobs:**

- **Lint**: Black formatting check, Ruff linting
- **Type Check**: MyPy static type checking
- **Test**: pytest with 80% coverage requirement
- **Security**: Bandit security scanning
- **Docker Build**: Build and cache Docker image
- **Vulnerability Scan**: Trivy container scanning
- **Contract Tests**: Schemathesis API contract validation

**Requirements:**

- Python 3.12
- Poetry 1.8.5
- All tests must pass
- Coverage >= 80%
- No critical/high vulnerabilities

---

#### 2. `ci-web.yml` - Web Frontend CI

**Triggers:**

- Pull requests affecting `apps/web/**` or `pnpm-lock.yaml`
- Pushes to `main` and `develop` branches

**Jobs:**

- **Lint**: ESLint checking
- **Format Check**: Prettier validation
- **Type Check**: TypeScript compilation
- **Test**: Vitest with 70% coverage requirement
- **Build**: Production build validation
- **Bundle Analysis**: Bundle size limits enforcement
- **Lighthouse CI**: PWA metrics and performance
- **Accessibility**: axe-core accessibility testing

**Requirements:**

- Node.js 20
- pnpm 9
- Coverage >= 70%
- Main bundle < 500KB
- Vendor chunks < 200KB each
- PWA score >= 90

---

#### 3. `ci-infra.yml` - Infrastructure CI

**Triggers:**

- Pull requests affecting `infra/**`
- Pushes to `main` and `develop` branches

**Jobs:**

- **Validate**: Terraform fmt check, validation across all environments
- **Security Scan**: tfsec, Checkov, Terrascan
- **Plan**: Terraform plan for dev/staging/production (on PRs)
- **Cost Estimation**: Infracost analysis (optional)

**Requirements:**

- Terraform 1.9.0
- All security checks must pass
- Plans are posted as PR comments

---

### CD Workflows

#### 4. `cd-dev.yml` - Development Deployment

**Triggers:**

- Pushes to `main` branch
- Manual workflow dispatch

**Jobs:**

1. **Build API**: Docker image build and push to GCR
2. **Deploy API**: Cloud Run deployment (0-10 instances, 512Mi, 1 CPU)
3. **Build Web**: Production build with dev environment variables
4. **Deploy Web**: Upload to GCS bucket with CDN cache headers
5. **Smoke Tests**: Basic health checks and critical path validation
6. **Notify**: Slack notification with deployment status

**Environment:** `development`
**URLs:**

- API: Auto-generated Cloud Run URL
- Web: `https://dev.adyela.com`

**Features:**

- Automatic deployment on main branch
- CDN cache invalidation
- Newman API smoke tests
- GitHub deployment tracking

---

#### 5. `cd-staging.yml` - Staging Deployment

**Triggers:**

- Manual workflow dispatch with version input

**Jobs:**

1. **Approval**: Manual approval required
2. **Build API**: Docker image with SBOM and provenance
3. **Deploy API**: Cloud Run (1-20 instances, 1Gi, 2 CPU, VPC connector)
4. **Build Web**: Production build
5. **Deploy Web**: GCS with backup creation
6. **E2E Tests**: Full Playwright test suite (skippable)
7. **Performance Tests**: k6 load testing
8. **Security Scan**: OWASP ZAP full scan
9. **Notify**: Detailed Slack notification

**Environment:** `staging`
**URLs:**

- API: Auto-generated Cloud Run URL
- Web: `https://staging.adyela.com`

**Features:**

- Manual trigger with version selection
- Automatic backup before deployment
- Optional E2E test skip
- Container image signing with Cosign
- Comprehensive test suite
- Deployment rollback on failure

---

#### 6. `cd-production.yml` - Production Deployment

**Triggers:**

- Git tags matching `v*.*.*` (semantic versioning)
- Manual workflow dispatch

**Jobs:**

1. **Pre-flight Checks**: Version validation, changelog verification
2. **Primary Approval**: First approval gate (required)
3. **Secondary Approval**: Second approval gate (required)
4. **Build API**: Signed, scanned Docker image
5. **Deploy API (Canary)**: 10% traffic canary deployment
6. **Canary Validation**: Health checks and metrics monitoring
7. **Deploy API (Full)**: 100% traffic rollout on canary success
8. **Build Web**: Production build
9. **Deploy Web**: GCS with versioned backup
10. **Smoke Tests**: Production health validation
11. **Automatic Rollback**: On any failure
12. **Create Release**: GitHub release with notes
13. **Notify**: Success/failure Slack notification

**Environment:** `production`
**URLs:**

- API: `https://api.adyela.com`
- Web: `https://adyela.com`

**Features:**

- **Canary Deployment**: 10% traffic test before full rollout
- **Multi-stage Approval**: Two separate approval gates
- **Auto-rollback**: Immediate rollback on failure
- **Image Signing**: Cosign signature verification
- **Backup & Restore**: Automatic backup with version tagging
- **Release Automation**: GitHub release creation
- **Monitoring Integration**: Cloud Monitoring metrics validation

---

## Required Secrets

### GCP Authentication (OIDC)

- `GCP_WORKLOAD_IDENTITY_PROVIDER` - Workload Identity Provider
- `GCP_SERVICE_ACCOUNT` - Service account for dev
- `GCP_SERVICE_ACCOUNT_STAGING` - Service account for staging
- `GCP_SERVICE_ACCOUNT_PROD` - Service account for production
- `GCP_PROJECT_ID` / `GCP_PROJECT_ID_DEV`
- `GCP_PROJECT_ID_STAGING`
- `GCP_PROJECT_ID_PROD`

### Application Secrets

- `VITE_API_URL_DEV` / `VITE_API_URL_STAGING` / `VITE_API_URL_PROD`
- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`

### Security & Monitoring

- `CODECOV_TOKEN` - Code coverage reporting
- `COSIGN_PRIVATE_KEY` - Container image signing
- `SLACK_WEBHOOK_URL` - Deployment notifications (optional)
- `LHCI_GITHUB_APP_TOKEN` - Lighthouse CI (optional)
- `K6_CLOUD_TOKEN` - k6 performance testing (optional)
- `INFRACOST_API_KEY` - Cost estimation (optional)

---

## GitHub Environments

Configure the following environments in GitHub repository settings:

### `development`

- No protection rules required
- Auto-deploy on main branch

### `staging-approval`

- Required reviewers: 1
- For approval gate before staging deployment

### `staging`

- Required reviewers: 1
- Deployment branch: Any branch

### `production-approval-1`

- Required reviewers: 1 (e.g., Tech Lead)
- For first approval gate

### `production-approval-2`

- Required reviewers: 1 (e.g., Product Manager)
- For second approval gate

### `production`

- Required reviewers: 2
- Deployment branch: Tags only (`v*.*.*`)
- Wait timer: 5 minutes (optional)

---

## Caching Strategy

All workflows use GitHub Actions cache for:

### API

- Poetry dependencies: `~/.cache/pypoetry`
- Virtual environment: `.venv`
- Docker layers: BuildKit cache

### Web

- pnpm store: Managed by `pnpm/action-setup`
- Node modules: Automatic with `setup-node`
- Build artifacts: Temporary between jobs

### Infrastructure

- Terraform plugins: `~/.terraform.d/plugin-cache`
- Provider cache per environment

---

## Parallelization

Jobs run in parallel where possible:

### CI Workflows

- Lint, Type Check, Test, Security run in parallel
- Docker build waits for all CI checks
- Contract tests run after Docker build

### CD Workflows

- API and Web builds run in parallel
- Deployments are sequential with validation gates
- Post-deployment tests run in parallel

---

## Monitoring & Observability

### Artifacts

All workflows upload artifacts for debugging:

- Test results (7 days retention)
- Coverage reports (7 days)
- Security scan reports (30 days)
- Build artifacts (1-30 days based on environment)

### Notifications

Slack notifications include:

- Deployment status (success/failure)
- Environment and version info
- Direct links to services
- Test results summary

### GitHub Deployments

Production deployments create GitHub deployment records with:

- Environment tracking
- Deployment URLs
- Status updates
- Log access

---

## Rollback Procedures

### Development

Manual rollback required:

```bash
# Rollback API
gcloud run services update-traffic adyela-api-dev \
  --to-revisions=PREVIOUS_REVISION=100

# Rollback Web
gsutil -m rsync -r gs://adyela-web-dev-backups/BACKUP_DIR gs://adyela-web-dev/
```

### Staging

Automatic rollback on test failure, manual for issues:

```bash
# Re-run previous successful workflow
gh workflow run cd-staging.yml -f version=PREVIOUS_VERSION
```

### Production

**Automatic rollback on failure**, manual trigger:

```bash
# Deploy previous version
gh workflow run cd-production.yml -f version=PREVIOUS_VERSION -f skip_canary=true
```

---

## Best Practices

### Version Tagging

Use semantic versioning for production releases:

```bash
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3
```

### Changelog

Maintain `CHANGELOG.md` with each release:

```markdown
## [v1.2.3] - 2025-01-15

### Added

- New feature X

### Fixed

- Bug Y

### Changed

- Improved Z
```

### Testing

- Write tests before merging to main
- Maintain coverage thresholds
- Run E2E tests on staging before production
- Monitor canary deployments closely

### Security

- Never commit secrets
- Use GitHub Secrets for all sensitive data
- Rotate credentials regularly
- Review Dependabot alerts
- Keep dependencies updated

---

## Troubleshooting

### Common Issues

**1. Poetry cache invalidation**

```yaml
# Clear cache if dependencies change
- run: poetry cache clear --all pypi
```

**2. Docker build failures**

```bash
# Local debugging
docker build -t test -f apps/api/Dockerfile apps/api
```

**3. Terraform state lock**

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

**4. CDN cache not clearing**

```bash
# Manual invalidation
gcloud compute url-maps invalidate-cdn-cache adyela-web-lb --path "/*"
```

**5. Canary stuck in failed state**

```bash
# Manual traffic shift back
gcloud run services update-traffic adyela-api-prod --to-revisions=STABLE_REVISION=100
```

---

## Contributing

When adding new workflows:

1. Follow naming convention: `ci-*.yml` or `cd-*.yml`
2. Add comprehensive job descriptions
3. Include proper error handling
4. Upload relevant artifacts
5. Add status checks to branch protection
6. Update this README
7. Test in a feature branch first

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform in CI/CD](https://developer.hashicorp.com/terraform/tutorials/automation)
- [OIDC with GCP](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-providers)
