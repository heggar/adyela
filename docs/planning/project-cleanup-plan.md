# Project Cleanup and Reorganization Plan

**Date:** October 11, 2025  
**Project:** Adyela Health System  
**Purpose:** Comprehensive audit and reorganization plan based on PRD
requirements

---

## 📊 Executive Summary

This document presents a complete audit of the Adyela project structure,
identifying organizational issues, redundancies, and misplaced files. The plan
prioritizes cleanup actions based on PRD requirements, development impact, and
HIPAA compliance needs.

**Key Findings:**

- 36+ markdown documentation files scattered across root and `/docs`
- 34 shell scripts in `/scripts` needing organization
- Empty placeholder directories (`packages/*`, `apps/ops`, `infra/envs/*`,
  `infra/modules`)
- Duplicate infrastructure configurations (`infra/environments` vs `infra/envs`)
- Build artifacts in source control (`apps/web/dist`, `apps/web/dev-dist`)
- Test reports in root (`lighthouse-reports/`, `schemathesis-reports/`)

---

## 🔍 Current State Analysis

### Directory Structure Overview

```
adyela/
├── 📁 apps/                    ✅ GOOD - Proper monorepo structure
│   ├── api/                    ✅ GOOD - FastAPI with hexagonal architecture
│   ├── web/                    ⚠️  NEEDS CLEANUP - Has build artifacts
│   └── ops/                    ❌ EMPTY - Placeholder directory
├── 📁 packages/                ❌ ALL EMPTY - Placeholder structure
│   ├── config/                 ❌ EMPTY
│   ├── core/                   ❌ EMPTY
│   └── ui/                     ❌ EMPTY
├── 📁 infra/                   ⚠️  DUPLICATED - Two configs exist
│   ├── environments/           ✅ POPULATED - Terraform files
│   ├── envs/                   ❌ EMPTY - Duplicate naming
│   └── modules/                ❌ EMPTY - No Terraform modules yet
├── 📁 docs/                    ⚠️  MIXED - Some docs here, many in root
│   ├── adrs/                   ✅ GOOD - Architecture decisions
│   ├── deployment/             ✅ GOOD - Deployment guides
│   └── rfcs/                   ✅ GOOD - RFCs structure
├── 📁 scripts/                 ⚠️  NEEDS ORGANIZATION - 34 shell scripts
├── 📁 tests/                   ⚠️  PARTIAL - Only E2E, missing integration
├── 📁 .github/                 ✅ GOOD - Well structured
├── 📁 .taskmaster/             ✅ GOOD - Task Master AI config
└── 📄 Root files               ❌ TOO MANY - 15+ MD files in root
```

---

## ❌ Problems Identified

### 1. **Documentation Chaos** (Priority: HIGH)

**Problem:** 36 markdown files scattered between root and `/docs`

**Root Level Documentation (Should be moved):**

```
❌ CLAUDE.md                        → docs/ai/
❌ CROSS_BROWSER_TESTING_REPORT.md  → docs/testing/
❌ DEPLOYMENT_PROGRESS.md           → docs/deployment/
❌ DEPLOYMENT_STRATEGY.md           → docs/deployment/
❌ DEPLOYMENT_SUCCESS.md            → docs/deployment/
❌ FINAL_QUALITY_REPORT.md          → docs/quality/
❌ FIXES_SUMMARY.md                 → docs/quality/
❌ GCP_SETUP_QUICKSTART.md          → docs/deployment/
❌ IMPROVEMENT_PLAN.md              → docs/quality/
❌ LOCAL_SETUP.md                   → docs/guides/
❌ MCP_GITHUB_SETUP.md              → docs/guides/
❌ NEXT_STEPS.md                    → docs/planning/
❌ QUALITY_EXECUTION_REPORT.md      → docs/quality/
❌ WORKFLOWS_VALIDATION.md          → docs/quality/

✅ Keep in root:
- README.md
- CONTRIBUTING.md
- SECURITY.md
- LICENSE (if exists)
```

**Impact:** Confusing documentation structure, hard to find information

**PRD Requirement:** Clear documentation structure for compliance and
maintenance

### 2. **Empty Placeholder Directories** (Priority: HIGH)

**Problem:** Multiple directories exist but contain no files

```
❌ packages/config/     - Empty (meant for shared ESLint/TS configs)
❌ packages/core/       - Empty (meant for shared SDK)
❌ packages/ui/         - Empty (meant for UI components)
❌ apps/ops/            - Empty (meant for observability)
❌ infra/modules/       - Empty (meant for Terraform modules)
❌ infra/envs/dev/      - Empty (duplicate of infra/environments/)
❌ infra/envs/prod/     - Empty
❌ infra/envs/stg/      - Empty
```

**Decision Required:**

- **Option A:** Remove empty directories (clean but removes structure)
- **Option B:** Add placeholder README files explaining future use
- **Option C:** Implement minimal structure per PRD

**Recommendation:** Option C - Implement per PRD Task #1 (Terraform modules)

**Impact:** Misleading project structure, confusion about what exists

**PRD Requirement:** Terraform modules for infrastructure (EP-NET, EP-IDP, etc.)

### 3. **Build Artifacts in Version Control** (Priority: CRITICAL)

**Problem:** Build outputs should not be in Git

```
❌ apps/web/dist/              - Production build (680KB+)
❌ apps/web/dev-dist/          - Development build
❌ apps/api/htmlcov/           - Test coverage HTML reports
❌ lighthouse-reports/         - Lighthouse audit reports
❌ schemathesis-reports/       - API contract test reports
```

**Actions:**

1. Add to `.gitignore`:

```gitignore
# Build outputs
apps/web/dist/
apps/web/dev-dist/
apps/api/htmlcov/

# Test reports
lighthouse-reports/
schemathesis-reports/
```

2. Move historical reports to archive or delete

**Impact:** Repository bloat, slower clones, potential security issues

**PRD Requirement:** Clean repository for CI/CD efficiency

### 4. **Duplicate Infrastructure Configurations** (Priority: MEDIUM)

**Problem:** Two directory structures for environments

```
✅ infra/environments/dev/       - Has Terraform files
✅ infra/environments/staging/   - Has Terraform files
✅ infra/environments/production/ - Has Terraform files

❌ infra/envs/dev/               - Empty
❌ infra/envs/prod/              - Empty
❌ infra/envs/stg/               - Empty
```

**Decision:** Remove `infra/envs/` entirely

**Rationale:**

- `infra/environments/` follows PRD naming convention
- Already has working Terraform configuration
- Matches GitHub Actions workflows expectations

**Impact:** Confusion about which config to use

**PRD Requirement:** Single source of truth for infrastructure

### 5. **Disorganized Scripts Directory** (Priority: MEDIUM)

**Problem:** 34 shell scripts in flat structure

```
scripts/
├── api-contract-tests.sh
├── check-daily-costs.sh
├── create-artifact-registry.sh
├── enable-gcp-apis.sh
├── gcp-setup-interactive.sh
├── lighthouse-audit.sh
├── quality-checks.sh
├── setup-auto-shutdown.sh
├── setup-budget-notifications.sh
├── setup-budgets.sh
├── setup-firebase-secrets.sh
├── setup-gcp-complete.sh
├── setup-gcp-oidc.sh
├── setup-gcp-secrets-manual.sh
├── setup-gcp-secrets.sh
├── setup-mcp-servers.sh
├── setup-staging-deployment.sh
├── setup-terraform-backend.sh
└── simple-auto-shutdown.sh
```

**Proposed Structure:**

```
scripts/
├── README.md                      - Script documentation
├── setup/                         - Initial setup scripts
│   ├── gcp-complete.sh
│   ├── gcp-interactive.sh
│   ├── gcp-oidc.sh
│   ├── terraform-backend.sh
│   ├── firebase-secrets.sh
│   ├── gcp-secrets.sh
│   ├── mcp-servers.sh
│   └── staging-deployment.sh
├── gcp/                           - GCP-specific scripts
│   ├── enable-apis.sh
│   ├── create-artifact-registry.sh
│   ├── setup-auto-shutdown.sh
│   ├── simple-auto-shutdown.sh
│   ├── setup-budgets.sh
│   ├── setup-budget-notifications.sh
│   └── check-daily-costs.sh
├── testing/                       - Testing scripts
│   ├── api-contract-tests.sh
│   ├── lighthouse-audit.sh
│   └── quality-checks.sh
└── utils/                         - Utility scripts
    └── (future utilities)
```

**Impact:** Hard to find and maintain scripts

**PRD Requirement:** Organized tooling for operational efficiency

### 6. **Test Organization Issues** (Priority: MEDIUM)

**Problem:** Tests scattered, incomplete structure

**Current:**

```
tests/                  - Root level, only E2E
├── e2e/
│   ├── api-health.spec.ts
│   └── auth.spec.ts

apps/api/tests/         - API unit/integration tests
├── unit/
├── integration/
└── contract/

apps/web/tests/         - Web unit/integration tests
├── unit/
└── integration/
```

**Issues:**

- Root `/tests` duplicates workspace tests
- Missing comprehensive test coverage
- No clear test strategy documentation

**Recommendation:** Keep tests with their respective apps, remove root `/tests`

**Impact:** Confusion about where to add tests

**PRD Requirement:** Clear test organization for quality assurance

### 7. **Firebase Configuration Inconsistency** (Priority: LOW)

**Problem:** Firebase files in root for project moving to GCP/Identity Platform

```
⚠️  firebase.json             - Firebase hosting config
⚠️  firestore.indexes.json    - Firestore indexes
⚠️  firestore.rules          - Firestore security rules
⚠️  storage.rules            - Storage security rules
⚠️  firebase-data/           - Firebase emulator data
```

**Status:** Keep for now (Firestore still used), but organize better

**Recommendation:** Move to `infra/firebase/` when fully migrated

**PRD Note:** PRD uses Firestore (GCP native) + Identity Platform, not Firebase
SDK

### 8. **Missing .gitignore Entries** (Priority: HIGH)

**Problem:** Sensitive and build files not ignored

**Required additions:**

```gitignore
# Build artifacts
apps/web/dist/
apps/web/dev-dist/
apps/api/htmlcov/

# Test reports
lighthouse-reports/
schemathesis-reports/

# Task Master AI
.taskmaster/reports/*.json
.taskmaster/tasks/*.txt
.taskmaster/docs/research/

# Environment files
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/settings.json
.vscode/launch.json
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
```

---

## ✅ Recommended Directory Structure (Per PRD)

### Target Structure

```
adyela/
├── 📁 .github/                    - GitHub configuration
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
├── 📁 .taskmaster/                - Task Master AI
│   ├── config.json
│   ├── tasks/
│   ├── docs/
│   └── reports/
├── 📁 apps/                       - Application workspaces
│   ├── api/                       - FastAPI backend
│   │   ├── adyela_api/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   ├── pyproject.toml
│   │   └── README.md
│   ├── web/                       - React PWA frontend
│   │   ├── src/
│   │   ├── tests/
│   │   ├── public/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── README.md
│   └── ops/                       - Observability (FUTURE)
│       └── README.md (placeholder)
├── 📁 packages/                   - Shared packages
│   ├── config/                    - Shared configs (FUTURE - Task #17)
│   │   └── README.md
│   ├── core/                      - Client SDK (FUTURE)
│   │   └── README.md
│   └── ui/                        - UI components (FUTURE)
│       └── README.md
├── 📁 infra/                      - Infrastructure as Code
│   ├── modules/                   - Terraform modules (Tasks #1-20)
│   │   ├── network/               - EP-NET (Task #1)
│   │   ├── identity_platform/     - EP-IDP (Task #2)
│   │   ├── api_gateway/           - EP-API (Task #3)
│   │   ├── firestore/             - EP-DATA (Task #4)
│   │   ├── storage/               - EP-DATA (Task #5)
│   │   ├── cloud_armor/           - EP-SEC (Task #6)
│   │   ├── vpc_sc/                - EP-SEC (Task #7)
│   │   ├── secret_manager/        - EP-SEC (Task #8)
│   │   ├── pubsub/                - EP-ASYNC (Task #9)
│   │   ├── cloud_tasks/           - EP-ASYNC (Task #10)
│   │   ├── cloud_run/             - EP-RUN (Task #11)
│   │   ├── cloud_scheduler/       - EP-ASYNC (Task #12)
│   │   ├── monitoring/            - EP-OBS (Task #13)
│   │   ├── budgets/               - EP-COST (Task #14)
│   │   └── cicd/                  - EP-IAC (Task #15)
│   ├── environments/              - Environment configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── production/
│   └── firebase/                  - Firebase configs
│       ├── firestore.indexes.json
│       ├── firestore.rules
│       └── storage.rules
├── 📁 docs/                       - Documentation
│   ├── README.md                  - Documentation index
│   ├── adrs/                      - Architecture decisions
│   ├── rfcs/                      - Request for comments
│   ├── guides/                    - Setup & usage guides
│   │   ├── local-setup.md
│   │   ├── mcp-setup.md
│   │   └── gcp-quickstart.md
│   ├── deployment/                - Deployment documentation
│   │   ├── architecture-validation.md
│   │   ├── gcp-setup.md
│   │   ├── staging-guide.md
│   │   ├── deployment-strategy.md
│   │   ├── deployment-progress.md
│   │   └── deployment-success.md
│   ├── quality/                   - Quality & testing
│   │   ├── quality-automation.md
│   │   ├── quality-execution.md
│   │   ├── final-quality-report.md
│   │   ├── fixes-summary.md
│   │   └── improvement-plan.md
│   ├── testing/                   - Testing documentation
│   │   ├── cross-browser-testing.md
│   │   └── workflows-validation.md
│   ├── cost/                      - Cost management
│   │   ├── budget-monitoring.md
│   │   ├── firebase-cost-estimate.md
│   │   └── token-optimization.md
│   ├── compliance/                - HIPAA & Security
│   │   ├── hipaa-compliance.md
│   │   └── security-audit.md
│   ├── ai/                        - AI integration docs
│   │   ├── claude-integration.md
│   │   ├── taskmaster-guide.md
│   │   ├── mcp-integration-matrix.md
│   │   └── mcp-servers-guide.md
│   ├── analytics/                 - Analytics & monitoring
│   │   └── google-analytics-implications.md
│   └── planning/                  - Planning documents
│       ├── next-steps.md
│       ├── comprehensive-optimization.md
│       └── project-cleanup-plan.md (this file)
├── 📁 scripts/                    - Operational scripts
│   ├── README.md
│   ├── setup/                     - Setup scripts
│   ├── gcp/                       - GCP management
│   ├── testing/                   - Test scripts
│   └── utils/                     - Utilities
├── 📄 .gitignore                  - Git ignore rules
├── 📄 .env.example                - Environment template
├── 📄 README.md                   - Project overview
├── 📄 CONTRIBUTING.md             - Contribution guide
├── 📄 SECURITY.md                 - Security policy
├── 📄 CHANGELOG.md                - Change log (to create)
├── 📄 LICENSE                     - License (to create)
├── 📄 package.json                - Root package config
├── 📄 pnpm-workspace.yaml         - Workspace config
├── 📄 turbo.json                  - Turbo config
├── 📄 docker-compose.dev.yml      - Local dev environment
├── 📄 Makefile                    - Common commands
└── 📄 commitlint.config.js        - Commit linting
```

---

## 🎯 Cleanup Plan (Prioritized)

### Phase 1: Critical Cleanup (Day 1)

**Goal:** Remove potential security issues and repository bloat

1. **Add .gitignore entries for build artifacts**

   ```bash
   # Add entries to .gitignore
   echo "\n# Build artifacts\napps/web/dist/\napps/web/dev-dist/\napps/api/htmlcov/\n" >> .gitignore
   echo "# Test reports\nlighthouse-reports/\nschemathesis-reports/\n" >> .gitignore
   ```

2. **Remove build artifacts from Git**

   ```bash
   git rm -r --cached apps/web/dist apps/web/dev-dist apps/api/htmlcov
   git rm -r --cached lighthouse-reports schemathesis-reports
   git commit -m "chore: remove build artifacts from version control"
   ```

3. **Archive or delete old test reports**

   ```bash
   # Option A: Archive
   mkdir -p docs/archives/test-reports
   mv lighthouse-reports/* docs/archives/test-reports/ 2>/dev/null
   mv schemathesis-reports/* docs/archives/test-reports/ 2>/dev/null

   # Option B: Delete
   rm -rf lighthouse-reports schemathesis-reports
   ```

**Estimated Time:** 1 hour  
**Risk:** Low  
**Impact:** High (security, repo size)

### Phase 2: Documentation Organization (Days 2-3)

**Goal:** Create clean documentation structure

1. **Create new documentation directories**

   ```bash
   mkdir -p docs/{guides,quality,testing,cost,compliance,ai,analytics,planning}
   ```

2. **Move root-level documentation**

   ```bash
   # Deployment docs
   mv DEPLOYMENT_*.md docs/deployment/
   mv GCP_SETUP_QUICKSTART.md docs/guides/gcp-quickstart.md

   # Quality docs
   mv *QUALITY*.md FIXES_SUMMARY.md IMPROVEMENT_PLAN.md docs/quality/

   # Testing docs
   mv CROSS_BROWSER_TESTING_REPORT.md docs/testing/
   mv WORKFLOWS_VALIDATION.md docs/testing/

   # AI/MCP docs
   mv CLAUDE.md docs/ai/claude-integration.md
   mv MCP_GITHUB_SETUP.md docs/guides/mcp-setup.md

   # Setup docs
   mv LOCAL_SETUP.md docs/guides/local-setup.md

   # Planning docs
   mv NEXT_STEPS.md docs/planning/
   ```

3. **Update internal documentation links**
   - Update README.md to link to new locations
   - Update CONTRIBUTING.md if it references moved docs
   - Create docs/README.md with documentation index

**Estimated Time:** 4-6 hours  
**Risk:** Medium (broken links)  
**Impact:** High (developer experience)

### Phase 3: Directory Structure Cleanup (Day 4)

**Goal:** Remove empty directories and duplicates

1. **Remove duplicate infrastructure directory**

   ```bash
   rm -rf infra/envs/
   ```

2. **Handle empty package directories**

   **Option A: Remove all empty dirs**

   ```bash
   rm -rf packages/config packages/core packages/ui apps/ops
   ```

   **Option B: Add placeholder READMEs**

   ```bash
   # For each empty directory
   cat > packages/config/README.md << 'EOF'
   # Shared Configuration Package

   **Status:** Not yet implemented

   This package will contain shared ESLint, Prettier, and TypeScript configurations for the monorepo.

   **Planned for:** Task #17 (Create Multi-Environment Terraform Workspaces)

   ## Future Structure
   ```

   packages/config/ ├── eslint/ ├── prettier/ ├── typescript/ └── package.json

   ```
   EOF
   ```

3. **Remove root /tests directory**
   ```bash
   # Tests should stay with their apps
   rm -rf tests/
   ```

**Estimated Time:** 2 hours  
**Risk:** Low  
**Impact:** Medium (clarity)

### Phase 4: Scripts Organization (Day 5)

**Goal:** Organize scripts into logical categories

1. **Create script subdirectories**

   ```bash
   mkdir -p scripts/{setup,gcp,testing,utils}
   ```

2. **Move scripts to categories**

   ```bash
   # Setup scripts
   mv scripts/setup-*.sh scripts/setup/

   # GCP scripts
   mv scripts/*gcp*.sh scripts/gcp/
   mv scripts/*budget*.sh scripts/gcp/
   mv scripts/*cost*.sh scripts/gcp/
   mv scripts/create-artifact-registry.sh scripts/gcp/
   mv scripts/enable-gcp-apis.sh scripts/gcp/
   mv scripts/*shutdown*.sh scripts/gcp/

   # Testing scripts
   mv scripts/*test*.sh scripts/testing/
   mv scripts/*quality*.sh scripts/testing/
   mv scripts/lighthouse-audit.sh scripts/testing/
   ```

3. **Create scripts/README.md** with usage documentation

**Estimated Time:** 2-3 hours  
**Risk:** Medium (break existing workflows)  
**Impact:** High (maintainability)

### Phase 5: Firebase File Organization (Day 6)

**Goal:** Organize Firebase configuration files

1. **Create infra/firebase directory**

   ```bash
   mkdir -p infra/firebase
   ```

2. **Move Firebase files**

   ```bash
   mv firebase.json firestore.*.json storage.rules infra/firebase/
   ```

3. **Update firebase.json paths** if needed

4. **Update GitHub Actions workflows** to reference new paths

**Estimated Time:** 2 hours  
**Risk:** High (may break Firebase deployments)  
**Impact:** Medium (organization)

### Phase 6: Create Missing Documentation (Day 7)

**Goal:** Fill documentation gaps

1. **Create CHANGELOG.md**

   ```bash
   # Use conventional-changelog or changesets
   npx conventional-changelog -p angular -i CHANGELOG.md -s
   ```

2. **Create LICENSE file** (if not exists)

   ```bash
   # Choose appropriate license (consult legal for healthcare)
   ```

3. **Create .env.example** with all required variables

4. **Update README.md** with new structure

5. **Create docs/README.md** as documentation index

**Estimated Time:** 3-4 hours  
**Risk:** Low  
**Impact:** High (completeness)

---

## 📋 Task Master AI Tasks to Create

### Task 31: Project Documentation Reorganization

- Move 15+ root MD files to appropriate `/docs` subdirectories
- Create documentation index
- Update internal links
- Priority: HIGH
- Dependencies: None

### Task 32: Remove Build Artifacts from Git

- Update .gitignore
- Remove dist/, htmlcov/, reports from version control
- Clean up Git history (optional)
- Priority: CRITICAL
- Dependencies: None

### Task 33: Infrastructure Directory Cleanup

- Remove duplicate `infra/envs/` directory
- Organize Terraform modules per PRD
- Create module structure for Tasks #1-20
- Priority: HIGH
- Dependencies: Task #1 (Terraform modules)

### Task 34: Scripts Organization and Documentation

- Reorganize 34 scripts into categories
- Create scripts README
- Update CI/CD workflows if needed
- Priority: MEDIUM
- Dependencies: None

### Task 35: Package Directories Setup

- Decide on placeholder vs implementation
- Add README files explaining future use
- Align with monorepo strategy
- Priority: LOW
- Dependencies: Task #17

### Task 36: Firebase Configuration Migration

- Move Firebase files to infra/firebase/
- Update workflows and configs
- Test Firebase deployments
- Priority: LOW
- Dependencies: Tasks #2, #4

### Task 37: Test Organization Cleanup

- Remove root /tests directory
- Ensure tests stay with apps
- Document test strategy
- Priority: MEDIUM
- Dependencies: None

### Task 38: Create Missing Documentation

- CHANGELOG.md
- LICENSE file
- .env.example
- Documentation index
- Priority: MEDIUM
- Dependencies: Task #31

---

## ⚠️ Risks and Mitigation

### Risk 1: Breaking Changes

**Risk:** Moving files breaks imports, workflows, or configs

**Mitigation:**

1. Test in feature branch first
2. Update all references before committing
3. Run full CI/CD pipeline
4. Grep for references: `grep -r "old/path" .`

### Risk 2: Lost Information

**Risk:** Deleting files loses important context

**Mitigation:**

1. Archive before deleting
2. Create comprehensive commit messages
3. Tag important commits for easy recovery

### Risk 3: Merge Conflicts

**Risk:** Other developers working on same files

**Mitigation:**

1. Coordinate with team
2. Do cleanup in small, focused PRs
3. Communicate changes in advance

### Risk 4: CI/CD Failures

**Risk:** Workflows reference old paths

**Mitigation:**

1. Update workflows first
2. Test in staging
3. Have rollback plan ready

---

## ✅ Success Criteria

- [ ] Zero build artifacts in Git
- [ ] All documentation in `/docs` with clear organization
- [ ] No duplicate directories
- [ ] Scripts organized by category
- [ ] Updated .gitignore preventing future issues
- [ ] All empty directories either implemented or removed
- [ ] Documentation index created
- [ ] CHANGELOG.md exists
- [ ] .env.example complete
- [ ] All CI/CD workflows still pass
- [ ] No broken links in documentation

---

## 📊 Metrics

**Current State:**

- 36 documentation files (15 in root)
- 4 empty package directories
- 2 duplicate infrastructure configs
- 680KB+ build artifacts in Git
- 34 unorganized scripts

**Target State:**

- 0 documentation files in root (except required)
- 0 empty directories (or with READMEs)
- 1 infrastructure configuration
- 0 build artifacts in Git
- Scripts organized in 4 categories

**Estimated Effort:** 7 days (1 developer)

**Priority Distribution:**

- Critical: 1 task (build artifacts)
- High: 3 tasks (docs, infra, gitignore)
- Medium: 3 tasks (scripts, tests, docs)
- Low: 2 tasks (packages, firebase)

---

## 🎯 Next Steps

1. **Review this plan with team**
2. **Get approval for file deletions/moves**
3. **Create feature branch: `chore/project-cleanup`**
4. **Execute Phase 1 (Critical) immediately**
5. **Execute Phases 2-6 in order**
6. **Create PR for each phase**
7. **Update Task Master AI with new tasks**

---

**Document Status:** DRAFT - Awaiting Review  
**Created:** October 11, 2025  
**Author:** Task Master AI  
**Next Review:** After team approval
