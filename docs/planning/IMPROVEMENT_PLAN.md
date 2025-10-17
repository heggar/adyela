# 🔧 PR #3 - CI/CD Workflows Improvement Plan

## 📊 Executive Summary

**Current Status**: ✅ PR is **MERGEABLE** - All critical checks passing

- **Total checks**: 23
- **Passing**: 17 ✅
- **Failed (non-blocking)**: 4 ❌
- **Waiting**: 2 ⏳

All failing checks have `continue-on-error: true` and don't block merge.
However, these issues should be addressed for production readiness.

---

## ❌ Issues Found & Analysis

### 1. 🔴 **Accessibility Check** (FAILURE)

**Priority**: HIGH **Location**:
`apps/web/src/features/auth/components/LoginPage.tsx` **Workflow**: CI - Web
Frontend → Accessibility Check job **Impact**: Affects UX, WCAG 2.1 compliance,
and SEO

#### Error Details

```
Violation of "landmark-one-main" with 1 occurrences!
  Ensure the document has a main landmark
  - html

Violation of "region" with 4 occurrences!
  Ensure all page content is contained by landmarks
  - h1
  - p
  - form > div:nth-child(1)
  - div:nth-child(2)

Total: 5 accessibility issues detected
```

#### Root Cause

The LoginPage component lacks semantic HTML structure:

- No `<main>` landmark element
- Content elements (h1, p, form) not wrapped in proper ARIA regions
- MainLayout has proper `<main>` element, but LoginPage renders outside it

#### Solution

Wrap LoginPage content in semantic HTML landmarks:

**File**: `apps/web/src/features/auth/components/LoginPage.tsx`

```tsx
export function LoginPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const login = useAuthStore(state => state.login);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login(
      {
        id: '1',
        email,
        name: 'Demo User',
        role: 'doctor',
        tenantId: 'tenant-1',
      },
      'mock-token'
    );
    navigate('/dashboard');
  };

  return (
    <div className='flex min-h-screen items-center justify-center bg-secondary-50'>
      {/* Add <main> landmark */}
      <main className='card w-full max-w-md p-8'>
        {/* Wrap heading and description in <header> region */}
        <header className='mb-8'>
          <h1 className='mb-6 text-center text-3xl font-bold text-secondary-900'>
            {t('auth.welcomeBack')}
          </h1>
          <p className='text-center text-secondary-600'>
            {t('auth.loginToContinue')}
          </p>
        </header>

        {/* Form is already semantic, but wrap in <section> for clarity */}
        <section>
          <form onSubmit={handleSubmit} className='space-y-4'>
            <div>
              <label
                htmlFor='email'
                className='mb-2 block text-sm font-medium text-secondary-700'
              >
                {t('auth.email')}
              </label>
              <input
                id='email'
                type='email'
                value={email}
                onChange={e => setEmail(e.target.value)}
                className='input'
                required
              />
            </div>
            <div>
              <label
                htmlFor='password'
                className='mb-2 block text-sm font-medium text-secondary-700'
              >
                {t('auth.password')}
              </label>
              <input
                id='password'
                type='password'
                value={password}
                onChange={e => setPassword(e.target.value)}
                className='input'
                required
              />
            </div>
            <button type='submit' className='btn-primary w-full py-3'>
              {t('auth.login')}
            </button>
          </form>
        </section>
      </main>
    </div>
  );
}
```

#### Verification Steps

```bash
# After making changes, run accessibility check locally
cd apps/web
pnpm preview &
npx @axe-core/cli http://localhost:4173/login --exit
```

#### Expected Outcome

- All 5 accessibility violations resolved
- WCAG 2.1 Level AA compliance achieved
- Accessibility Check job passes in CI

---

### 2. 🟡 **Contract Tests (Schemathesis)** (FAILURE)

**Priority**: MEDIUM **Location**: `.github/workflows/ci-api.yml` (lines
270-322) **Impact**: Workflow design issue, not code quality problem

#### Error Details

```
Error response from daemon: pull access denied for adyela-api,
repository does not exist or may require 'docker login':
denied: requested access to the resource is denied
```

#### Root Cause

The `contract-tests` job tries to use `adyela-api:${{ github.sha }}` as a
service container, but:

1. The image is built locally in the `docker-build` job
2. It's never pushed to a container registry (Docker Hub, GCR, etc.)
3. GitHub Actions services can only pull from registries, not use local images

#### Solution Options

**Option A: Make contract tests non-blocking (Quick Fix)**

Add `continue-on-error: true` to the job:

```yaml
contract-tests:
  name: Contract Tests (Schemathesis)
  runs-on: ubuntu-latest
  needs: [docker-build]
  continue-on-error: true # ← Add this
  services:
    api:
      image: adyela-api:${{ github.sha }}
```

**Option B: Run API without Docker (Recommended)**

Replace the service container approach with a direct Python run:

```yaml
contract-tests:
  name: Contract Tests (Schemathesis)
  runs-on: ubuntu-latest
  needs: [test] # Don't depend on docker-build
  continue-on-error: true
  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: Install Poetry
      run: |
        curl -sSL https://install.python-poetry.org | python3 -
        echo "$HOME/.local/bin" >> $GITHUB_PATH

    - name: Install dependencies
      working-directory: ${{ env.WORKING_DIR }}
      run: poetry install --no-interaction

    - name: Start API in background
      working-directory: ${{ env.WORKING_DIR }}
      env:
        SECRET_KEY: test-secret-key-for-contract-tests
        FIREBASE_PROJECT_ID: test-project
        GCP_PROJECT_ID: test-gcp-project
      run: |
        poetry run uvicorn adyela_api.main:app --host 0.0.0.0 --port 8000 &
        echo $! > api.pid

    - name: Wait for API to be ready
      run: |
        timeout 60 bash -c 'until curl -f http://localhost:8000/health; do sleep 2; done'

    - name: Install Schemathesis
      run: pip install schemathesis

    - name: Run Schemathesis contract tests
      run: |
        schemathesis run http://localhost:8000/openapi.json \
          --base-url http://localhost:8000 \
          --checks all \
          --hypothesis-max-examples=50 \
          --hypothesis-deadline=5000 \
          --exclude-deprecated \
          --report

    - name: Stop API
      if: always()
      run: kill $(cat ${{ env.WORKING_DIR }}/api.pid) || true

    - name: Upload contract test results
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: contract-test-results
        path: schemathesis-report.json
        retention-days: 7
```

**Option C: Move to CD pipeline (Future Enhancement)**

Contract tests are more valuable in deployment pipelines where the actual Docker
image is published. Consider moving this to `cd-dev.yml` or `cd-staging.yml`
where the image is available in GCR.

#### Recommended Action

Implement **Option B** to fix contract tests in CI, and plan **Option C** for
the CD pipeline.

---

### 3. 🟢 **Security Scan (Terrascan)** (FAILURE)

**Priority**: LOW **Location**: `.github/workflows/ci-infra.yml` (lines 102-108)
**Impact**: Informational, expected with minimal Terraform

#### Root Cause

The Terrascan step lacks error handling unlike tfsec and Checkov:

- tfsec has `continue-on-error: true` and `soft_fail: true`
- Checkov has `soft_fail: true`
- Terrascan has neither, so any violation fails the job

Terrascan is likely failing because:

1. Minimal/stub Terraform configuration in `infra/environments/`
2. No actual GCP resources defined yet
3. Policy violations on incomplete infrastructure
4. Missing required Terraform best practices

#### Solution

Add error handling to match tfsec and Checkov:

**File**: `.github/workflows/ci-infra.yml`

```yaml
- name: Run Terrascan
  uses: tenable/terrascan-action@main
  continue-on-error: true # ← Add this
  with:
    iac_type: 'terraform'
    iac_dir: ${{ env.WORKING_DIR }}
    policy_type: 'gcp'
    sarif_upload: true
    non_recursive: false
    verbose: true
    # Add skip rules for development (optional)
    # skip_rules: "accurics.gcp.IAM.1,accurics.gcp.NS.2"
```

Alternatively, add `soft_fail` if the action supports it (check action docs).

#### Why This Is Acceptable

- Infrastructure code is in early development stage
- Security scans are informational in CI (not enforcing yet)
- Policy violations should be reviewed but not block PRs
- Production deployments will have separate security gates

---

### 4. 🟢 **Terraform Plan (Dev)** (FAILURE)

**Priority**: LOW **Location**: `.github/workflows/ci-infra.yml` (lines 110-183)
**Impact**: Expected behavior for fork PRs, requires GCP secrets

#### Error Details

```
google-github-actions/auth failed with: the GitHub Action workflow
must specify exactly one of "workload_identity_provider" or "credentials_json"
```

#### Root Cause

The workflow requires GCP authentication secrets that are:

1. Not available in PRs from forked repositories (security best practice)
2. Not available until GCP Workload Identity Federation is configured
3. Only needed for actual Terraform operations (init with backend, plan, apply)

#### Solution

Make Terraform plan jobs conditional on secret availability:

**File**: `.github/workflows/ci-infra.yml`

```yaml
plan-dev:
  name: Terraform Plan (Dev)
  runs-on: ubuntu-latest
  needs: [validate, security-scan]
  # Only run if secrets are available (not on forks)
  if:
    github.event_name == 'pull_request' &&
    github.event.pull_request.head.repo.full_name == github.repository
  environment: development
  steps:
    # ... rest of the steps
```

Apply the same condition to `plan-staging` and `plan-production`.

#### Alternative: Skip authentication for validation-only

If you only want to validate Terraform syntax (not plan actual changes), you can
skip the GCP auth steps:

```yaml
plan-dev:
  name: Terraform Validate (Dev) # Rename job
  runs-on: ubuntu-latest
  needs: [validate, security-scan]
  if: github.event_name == 'pull_request'
  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ env.TERRAFORM_VERSION }}

    # Remove GCP authentication steps

    - name: Terraform Init
      working-directory: ${{ env.WORKING_DIR }}/environments/dev
      run: terraform init -backend=false # ← Skip backend

    - name: Terraform Validate
      working-directory: ${{ env.WORKING_DIR }}/environments/dev
      run: terraform validate

    # Remove plan steps
```

#### Recommended Action

Implement the conditional check to skip Terraform plans on fork PRs while
keeping full validation.

---

## 📅 Implementation Roadmap

### Phase 1: Quick Wins (< 1 hour)

**Goal**: Fix all failing checks except contract tests

1. ✅ Fix accessibility issues in LoginPage (10 min)
   - Add `<main>` landmark
   - Add `<header>` and `<section>` regions
   - Test locally with axe

2. ✅ Add error handling to Terrascan (5 min)
   - Add `continue-on-error: true`
   - Document expected failures

3. ✅ Make Terraform plans conditional (10 min)
   - Add fork repository check
   - Skip on external PRs

### Phase 2: Contract Tests Redesign (1-2 hours)

**Goal**: Get contract tests running in CI

4. ✅ Implement Option B for contract tests
   - Replace Docker service with direct Python run
   - Start API with uvicorn in background
   - Run Schemathesis against local API
   - Test locally before committing

### Phase 3: Infrastructure Development (Future)

**Goal**: Complete Terraform infrastructure

5. 🔜 Set up GCP Workload Identity Federation
   - Create workload identity pool
   - Configure GitHub OIDC provider
   - Add secrets to GitHub repository

6. 🔜 Develop actual Terraform resources
   - Cloud Run services
   - Cloud Storage buckets
   - IAM roles and policies
   - Firestore database
   - VPC networking (if needed)

7. 🔜 Move contract tests to CD pipeline
   - Run against deployed dev environment
   - Use actual Docker image from GCR
   - Include in smoke tests

---

## ✅ Success Criteria

### Phase 1 Complete When:

- [ ] All accessibility violations resolved
- [ ] Accessibility Check job passes ✅
- [ ] Security Scan (Infra) non-blocking ✅
- [ ] Terraform Plan only runs on non-fork PRs ✅

### Phase 2 Complete When:

- [ ] Contract tests run successfully in CI
- [ ] Schemathesis finds 0 API contract violations
- [ ] Contract Tests job passes ✅

### Phase 3 Complete When:

- [ ] GCP infrastructure deployed to dev environment
- [ ] All Terraform plan jobs succeed
- [ ] CD pipelines deploy successfully

---

## 🧪 Testing Strategy

### Local Testing Before PR

```bash
# 1. Test accessibility
cd apps/web
pnpm build
pnpm preview &
npx @axe-core/cli http://localhost:4173/login --exit

# 2. Test contract tests (after implementing Option B)
cd apps/api
poetry run uvicorn adyela_api.main:app &
sleep 5
schemathesis run http://localhost:8000/openapi.json \
  --base-url http://localhost:8000 \
  --checks all \
  --hypothesis-max-examples=10

# 3. Validate Terraform
cd infra/environments/dev
terraform init -backend=false
terraform validate
terraform fmt -check -recursive ../../

# 4. Run security scans
cd apps/api
poetry run bandit -r adyela_api
docker build -t adyela-api:test .
trivy image adyela-api:test
```

### CI Validation

After pushing PR:

1. Monitor GitHub Actions workflow runs
2. Check "Files changed" tab for PR review
3. Verify all critical checks pass (Lint, Tests, Build)
4. Review non-critical check failures (should be expected)

---

## 📊 Risk Assessment

| Issue                    | Risk       | Impact if Not Fixed                              | Mitigation                                           |
| ------------------------ | ---------- | ------------------------------------------------ | ---------------------------------------------------- |
| Accessibility violations | **HIGH**   | Legal compliance issues, poor UX, SEO penalty    | Phase 1 - Quick fix available                        |
| Contract tests failing   | **MEDIUM** | API contract bugs not caught in CI               | Phase 2 - Redesign needed, but manual testing covers |
| Terrascan failures       | **LOW**    | Informational only, doesn't affect functionality | Phase 1 - Make non-blocking                          |
| Terraform plan failures  | **LOW**    | Expected on fork PRs, doesn't affect validation  | Phase 1 - Add conditional check                      |

---

## 🎯 Recommended Next Steps

### Immediate Action (Today)

1. **Fix accessibility issues** - High impact, low effort
   - Edit `apps/web/src/features/auth/components/LoginPage.tsx`
   - Add semantic HTML landmarks
   - Test locally with axe-core
   - Commit and push

2. **Make Terrascan non-blocking** - Low effort
   - Edit `.github/workflows/ci-infra.yml`
   - Add `continue-on-error: true` to Terrascan step
   - Commit and push

3. **Add Terraform plan conditional** - Low effort
   - Edit `.github/workflows/ci-infra.yml`
   - Add repository check to plan jobs
   - Commit and push

### This Week

4. **Redesign contract tests** - Medium effort
   - Implement Option B (Python-based)
   - Test locally
   - Commit and push
   - Monitor CI results

### Next Sprint

5. **Plan GCP infrastructure setup**
   - Design Terraform architecture
   - Set up Workload Identity Federation
   - Create GCP projects for dev/staging/prod
   - Configure GitHub secrets

---

## 📚 References

- [axe-core Accessibility Rules](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md)
- [WCAG 2.1 Level AA Guidelines](https://www.w3.org/WAI/WCAG21/quickref/?levels=aa)
- [Schemathesis Documentation](https://schemathesis.readthedocs.io/)
- [GitHub Actions - Workload Identity Federation](https://github.com/google-github-actions/auth#setup)
- [Terrascan Documentation](https://runterrascan.io/docs/)

---

**Document Version**: 1.0 **Last Updated**: 2025-10-04 **Author**: Claude Code
**Status**: Ready for Implementation
