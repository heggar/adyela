# Feature Development Workflow

## Quick Start

1. **Find a task**: `make task-next`
2. **Start the task**: `make task-start ID=5`
3. **Develop**: Write code, commit often
4. **Validate**: `make quality-local`
5. **Complete**: `make task-complete ID=5`
6. **Create PR**: Push branch and create PR to staging

## Detailed Workflow

### Phase 1: Task Selection (30 seconds)

```bash
make task-next
# Shows next available task with all dependencies met
```

### Phase 2: Feature Branch Creation (10 seconds)

```bash
make task-start ID=5
# Example task: "Implement User Authentication"
# Creates: feature/implement-user-authentication
# Updates: Task status to in-progress
# Generates: Checklist at .task-context/task-5/checklist.md
```

**Branch Naming**: The branch name is derived from the task title, using descriptive names instead of task numbers. This makes branches more readable and meaningful in Git history.

### Phase 3: Development (varies)

Write code following TDD:

1. Write test first
2. Implement feature
3. Commit frequently (hooks enforce quality)

**Pre-commit hooks automatically run**:

- Format code (Prettier/Black)
- Lint changed files
- Type check
- Scan for secrets

**Commit message format**:

```
feat(api): add user authentication endpoint

Implements JWT-based authentication with refresh tokens.
Includes rate limiting and session management.

Task #5
```

### Phase 4: Quality Validation (2-3 minutes)

```bash
make quality-local
# Runs complete CI/CD validation suite locally:
# - Format check
# - Linting (ESLint, Ruff)
# - Type checking (TypeScript, MyPy)
# - Unit tests (≥65% coverage)
# - Integration tests
# - Build validation
# - Security audit (Bandit, npm audit)
# - License compliance
# - Secret scanning
```

### Phase 5: Task Completion (10 seconds)

```bash
make task-complete ID=5
# Runs final quality checks
# Updates task status to done
# Logs completion notes in Task Master
```

### Phase 6: Pull Request (1 minute)

```bash
git push origin feature/implement-user-authentication
# Create PR via GitHub UI
# PR template auto-fills with task reference
```

**PR must have**:

- Conventional commit messages
- Task #X reference
- All CI checks passing (10-15 min)
- 2 approvals
- Up to date with staging

### Phase 7: Merge to Staging (automatic)

- Squash merge to staging
- Automatic deployment to staging environment
- E2E tests run in staging
- Performance tests execute
- Security scan (OWASP ZAP)

### Phase 8: Staging Validation (manual)

- Verify feature works in staging
- Test integration with other features
- Check performance metrics
- Review security scan results

### Phase 9: Release to Production (manual)

- Create release PR from staging to main
- Final review and approval
- Tag with version (v1.2.3)
- Deploy to production
- Monitor metrics and logs

## Quality Gates

### Local (Pre-commit)

- **Speed**: < 30 seconds
- **Scope**: Changed files only
- **Blocks**: Secrets, build artifacts, basic lint errors

### Local (Pre-push) - Optional

Can add `.husky/pre-push` for:

- Full test suite
- More comprehensive checks
- **Speed**: 2-3 minutes

### CI/CD (PR)

- **Speed**: 10-15 minutes
- **Scope**: Full validation
- **Blocks**: Any check failure
- **Requirements**:
  - All tests passing
  - Coverage ≥ 65%
  - No security vulnerabilities
  - License compliance
  - Docker build successful
  - Container scan clean

### Staging (Post-merge)

- **Speed**: 15-20 minutes
- **Scope**: E2E, performance, security
- **Monitors**: Deployment health, metrics
- **E2E Tests**: Critical user flows
- **Performance**: Load tests, response times
- **Security**: OWASP ZAP full scan

## HIPAA Compliance

Every stage logs audit trails:

- **Git commits**: Who, what, when
- **CI/CD logs**: All check results (7-year retention)
- **Deployment logs**: Version, approver, timestamp
- **Access logs**: GCP audit logs for all PHI access

## Troubleshooting

### Pre-commit hook fails

```bash
# Fix automatically
pnpm lint:fix
pnpm format

# Or skip (ONLY if emergency)
git commit --no-verify
```

### Quality checks fail locally

```bash
# Run individual checks
pnpm lint
pnpm type-check
pnpm test

# Fix and re-run
make quality-local
```

### CI checks fail

1. Pull latest CI logs from GitHub Actions
2. Reproduce locally: `make quality-local`
3. Fix issues
4. Push updates (CI re-runs automatically)

### Can't find task

```bash
# List all tasks
make task-list

# Show specific task
npx task-master-ai show 5

# Expand task into subtasks
npx task-master-ai expand --id=5 --research
```

## Best Practices

1. **Small commits**: Atomic, focused changes
2. **Test first**: Write tests before implementation (TDD)
3. **Run locally**: Use `make quality-local` before pushing
4. **Update docs**: Keep documentation in sync
5. **Link tasks**: Always reference Task #X in commits/PRs
6. **Review checklist**: Complete .task-context/task-X/checklist.md
7. **Clean workspace**: No build artifacts, logs, or secrets

## Commands Cheat Sheet

```bash
# Task Management
make task-list              # List all tasks
make task-next              # Show next task
make task-start ID=5        # Start task #5
make task-complete ID=5     # Complete task #5

# Development
make start                  # Start local environment
make logs                   # View logs
make test                   # Run tests

# Quality
make quality-local          # Full validation (matches CI)
make lint                   # Lint only
make format                 # Format code

# Shortcuts
pnpm dev                    # Start dev servers
pnpm test                   # Run tests
pnpm build                  # Build all
```

## Success Metrics

- **Time to start feature**: < 30 seconds
- **Pre-commit validation**: < 30 seconds
- **Full quality check**: < 3 minutes
- **CI/CD pipeline**: < 15 minutes
- **Zero secrets in commits**: gitleaks prevents
- **Code coverage**: Maintained ≥ 65%
- **Security vulnerabilities**: Caught before merge
- **HIPAA compliance**: 100% audit trail
- **Developer satisfaction**: Faster, clearer workflow
