# 🚀 Deployment Strategy - Adyela

## Overview

**Philosophy**: Optimize for developer velocity and cost while maintaining
production quality.

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│    DEV      │────▶│   STAGING    │────▶│  PRODUCTION  │
│   (Local)   │     │ (GCP Minimal)│     │  (GCP Full)  │
└─────────────┘     └──────────────┘     └──────────────┘
  Docker Compose      Cloud Run            Cloud Run
  Firebase Emu        256Mi, 0.5 CPU       512Mi, 1 CPU
  No Cost            ~$5-10/month         ~$50-100/month
```

---

## 🏠 Development Environment (Local)

### Infrastructure

**No cloud deployment** - Everything runs locally with Docker Compose.

**Stack:**

- API: FastAPI in Docker container
- Web: Vite dev server with HMR
- Database: Firestore Emulator
- Auth: Firebase Auth Emulator
- Storage: GCS Emulator (fake-gcs-server)
- Cache: Redis container

### Setup

```bash
# Start all services
docker-compose -f docker-compose.dev.yml up

# Services available at:
# - API: http://localhost:8000
# - Web: http://localhost:3000
# - Firestore UI: http://localhost:4000
# - Firebase Auth UI: http://localhost:9099
# - Redis: localhost:6379
```

### Development Workflow

1. **Make changes** to code locally
2. **Run tests** locally: `pnpm test`, `poetry run pytest`
3. **Create PR** → Triggers CI workflows
4. **Merge to main** → No automatic deployment (stays local)

### CI Only (No CD)

- ✅ Lint, format, type-check
- ✅ Unit tests with coverage
- ✅ Integration tests with emulators
- ✅ Security scans
- ✅ Contract tests
- ❌ No deployment to cloud

**File:** `docker-compose.dev.yml`

```yaml
version: '3.9'

services:
  api:
    build:
      context: ./apps/api
      target: development
    ports:
      - '8000:8000'
    environment:
      - ENVIRONMENT=development
      - FIREBASE_EMULATOR_HOST=firebase:9099
      - FIRESTORE_EMULATOR_HOST=firestore:8080
      - REDIS_URL=redis://redis:6379/0
    volumes:
      - ./apps/api:/app
    depends_on:
      - firestore
      - firebase
      - redis
    command: uvicorn adyela_api.main:app --reload --host 0.0.0.0 --port 8000

  web:
    build:
      context: ./apps/web
      target: development
    ports:
      - '3000:3000'
    environment:
      - VITE_API_URL=http://localhost:8000
      - VITE_FIREBASE_EMULATOR_HOST=localhost:9099
    volumes:
      - ./apps/web:/app
      - /app/node_modules
    command: pnpm dev --host 0.0.0.0 --port 3000

  firestore:
    image: google/cloud-sdk:latest
    command: >
      gcloud emulators firestore start
        --host-port=0.0.0.0:8080
        --project=adyela-dev
    ports:
      - '8080:8080'
    environment:
      - FIRESTORE_PROJECT_ID=adyela-dev

  firebase:
    image: andreysenov/firebase-tools:latest
    command: >
      firebase emulators:start
        --only auth
        --project adyela-dev
    ports:
      - '9099:9099'
      - '4000:4000' # Emulator UI
    volumes:
      - ./firebase.json:/home/node/firebase.json

  redis:
    image: redis:7-alpine
    ports:
      - '6379:6379'
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  redis_data:
```

---

## 🧪 Staging Environment (GCP Minimal)

### Infrastructure

**Purpose**: Test cloud integrations and pre-production validation.

**Deployment Strategy:**

- Manual trigger from GitHub Actions
- Or automatic on merge to `develop` branch

**GCP Resources:**

```hcl
# Minimal configuration
resource "google_cloud_run_service" "api_staging" {
  name     = "adyela-api-staging"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/adyela-staging/api:latest"

        resources {
          limits = {
            cpu    = "0.5"
            memory = "256Mi"
          }
        }
      }

      container_concurrency = 80
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "0"  # Scale to zero
        "autoscaling.knative.dev/maxScale" = "1"  # Max 1 instance
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}
```

**Cost Optimization:**

- ✅ Scale to zero when not used
- ✅ Max 1 instance (no auto-scaling)
- ✅ Minimal CPU/memory
- ✅ No CDN
- ✅ No backup automation
- ✅ No Cloud Armor
- ✅ Shared Firestore project with production (different collection prefix)

**Web Hosting:**

- Firebase Hosting (free tier) or GCS static hosting (~$0.01/month)

### Deployment Workflow

**Trigger:** Manual dispatch or push to `develop` branch

```yaml
# .github/workflows/cd-staging.yml
name: CD - Staging

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy'
        required: true
  push:
    branches:
      - develop # Optional: auto-deploy develop

jobs:
  deploy-staging:
    name: Deploy to Staging (GCP Minimal)
    runs-on: ubuntu-latest
    environment: staging

    steps:
      # ... build steps ...

      - name: Deploy API to Cloud Run
        run: |
          gcloud run deploy adyela-api-staging \
            --image gcr.io/${{ secrets.GCP_PROJECT_ID }}/api:${{ github.sha }} \
            --region us-central1 \
            --platform managed \
            --min-instances 0 \
            --max-instances 1 \
            --cpu 0.5 \
            --memory 256Mi \
            --timeout 60 \
            --no-traffic  # No canary, just deploy

      - name: Deploy Web to Firebase Hosting
        run: |
          firebase deploy \
            --only hosting:staging \
            --project ${{ secrets.FIREBASE_PROJECT_ID }}

      - name: Run Smoke Tests
        run: |
          curl -f https://api-staging.adyela.com/health
```

**Estimated Cost:** $5-10/month

- Cloud Run: $0-5/month (scale to zero)
- Firestore: Shared with dev/prod
- Firebase Hosting: Free tier
- Container Registry: $0.01/month

---

## 🏭 Production Environment (GCP Full)

### Infrastructure

**Purpose**: Serve real users with high availability and monitoring.

**Deployment Strategy:**

- Triggered by git tags `v*.*.*`
- Multi-stage approval required
- Canary deployment (10% → 100%)
- Automatic rollback on errors

**GCP Resources:**

```hcl
resource "google_cloud_run_service" "api_production" {
  name     = "adyela-api"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/adyela-prod/api:v1.0.0"

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }

      container_concurrency = 80
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "1"  # Always warm
        "autoscaling.knative.dev/maxScale" = "10"
        "run.googleapis.com/cpu-throttling" = "false"
      }
    }
  }

  traffic {
    # Canary deployment
    percent         = 90
    latest_revision = false
    revision_name   = "adyela-api-v1-0-0"
  }

  traffic {
    percent         = 10
    latest_revision = true  # New version gets 10%
  }
}
```

**Production Features:**

- ✅ Always-on (min 1 instance)
- ✅ Auto-scaling 1-10 instances
- ✅ Full CPU/memory
- ✅ Cloud CDN + Load Balancer
- ✅ Cloud Armor (WAF)
- ✅ Automated backups
- ✅ Cloud Monitoring + Alerting
- ✅ Error Reporting
- ✅ Cloud Trace
- ✅ Cloud Logging with retention

**Web Hosting:**

- GCS + Cloud CDN for maximum performance

### Deployment Workflow

**Trigger:** Git tag `v*.*.*` (e.g., `v1.0.0`)

```yaml
# .github/workflows/cd-production.yml
name: CD - Production

on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:

jobs:
  deploy-production:
    name: Deploy to Production (GCP Full)
    runs-on: ubuntu-latest
    environment: production # Requires approval

    steps:
      # ... build steps ...

      - name: Backup current version
        run: |
          # Tag current production image
          gcloud container images add-tag \
            gcr.io/${{ secrets.GCP_PROJECT_ID }}/api:latest \
            gcr.io/${{ secrets.GCP_PROJECT_ID }}/api:backup-$(date +%Y%m%d-%H%M%S)

      - name: Deploy with Canary (10%)
        run: |
          gcloud run deploy adyela-api \
            --image gcr.io/${{ secrets.GCP_PROJECT_ID }}/api:${{ github.ref_name }} \
            --region us-central1 \
            --platform managed \
            --min-instances 1 \
            --max-instances 10 \
            --cpu 1 \
            --memory 512Mi \
            --timeout 300 \
            --no-traffic  # Don't send traffic yet

          # Split traffic: 90% old, 10% new
          gcloud run services update-traffic adyela-api \
            --region us-central1 \
            --to-revisions LATEST=10

      - name: Monitor canary for 5 minutes
        run: |
          sleep 300
          # Check error rates, latency, etc.

      - name: Promote to 100% or rollback
        run: |
          if [ "$ERROR_RATE" -lt "1" ]; then
            # Promote to 100%
            gcloud run services update-traffic adyela-api \
              --region us-central1 \
              --to-latest
          else
            # Rollback
            gcloud run services update-traffic adyela-api \
              --region us-central1 \
              --to-revisions LATEST=0
            exit 1
          fi
```

**Estimated Cost:** $50-100/month (light traffic)

- Cloud Run: $20-40/month
- Firestore: $10-20/month
- Cloud Storage + CDN: $5-10/month
- Load Balancer: $18/month
- Monitoring/Logging: $5-10/month

---

## 📊 Comparison Table

| Feature            | Dev (Local)             | Staging (GCP)                | Production (GCP)       |
| ------------------ | ----------------------- | ---------------------------- | ---------------------- |
| **Deployment**     | Manual (docker-compose) | Manual/Auto (develop branch) | Git tags only          |
| **Approval**       | None                    | Optional                     | Required (2 approvers) |
| **Infrastructure** | Docker Compose          | Cloud Run Minimal            | Cloud Run Full         |
| **CPU**            | Unlimited (local)       | 0.5 vCPU                     | 1 vCPU                 |
| **Memory**         | Unlimited (local)       | 256Mi                        | 512Mi                  |
| **Instances**      | 1 (local)               | 0-1 (scale to zero)          | 1-10 (auto-scale)      |
| **Database**       | Firestore Emulator      | Firestore (shared)           | Firestore (dedicated)  |
| **CDN**            | No                      | No                           | Yes (Cloud CDN)        |
| **Monitoring**     | Console logs            | Basic Cloud Logging          | Full Cloud Monitoring  |
| **Backups**        | Manual                  | None                         | Automated daily        |
| **Rollback**       | N/A                     | Manual                       | Automatic              |
| **Cost**           | $0                      | $5-10/month                  | $50-100/month          |

---

## 🔄 Recommended Workflow

### Developer Flow

```bash
# 1. Develop locally
git checkout -b feature/new-feature
docker-compose -f docker-compose.dev.yml up

# 2. Make changes, run tests
pnpm test
poetry run pytest

# 3. Create PR
git push origin feature/new-feature
# → CI runs automatically (no deployment)

# 4. Merge to main
# → Still no deployment, stays local
```

### Staging Deployment Flow

```bash
# Option A: Merge to develop branch (auto-deploy)
git checkout develop
git merge main
git push origin develop
# → Auto-deploys to staging

# Option B: Manual trigger
# Go to GitHub Actions → cd-staging.yml → Run workflow
```

### Production Deployment Flow

```bash
# 1. Create release tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 2. GitHub Actions triggers
# → Requires approval
# → Canary deployment (10%)
# → Monitor for 5 min
# → Promote to 100% or rollback
```

---

## 🚀 Migration Path

### Phase 1: Current State

- ✅ CI workflows working
- ❌ No CD workflows deployed yet

### Phase 2: Dev Local Setup (Week 1)

1. Create `docker-compose.dev.yml`
2. Set up Firebase emulators
3. Document local setup in README
4. Remove `cd-dev.yml` workflow (not needed)

### Phase 3: Staging Cloud Setup (Week 2)

1. Create GCP project `adyela-staging`
2. Deploy Terraform with minimal config
3. Set up `cd-staging.yml` workflow
4. Test manual deployment

### Phase 4: Production Cloud Setup (Week 3-4)

1. Create GCP project `adyela-production`
2. Deploy Terraform with full config
3. Set up `cd-production.yml` workflow
4. Configure monitoring & alerting
5. Test canary deployment

---

## 💡 Alternative Strategies

### Option 2: All Local (Dev + Staging)

**If you want to save even more:**

```
Dev (Local) + Staging (Local) → Production (GCP Only)
```

- Use different docker-compose files for staging simulation
- Only deploy to cloud for production
- **Savings:** ~$10/month more
- **Risk:** No cloud testing before production

### Option 3: Shared GCP Project

**If you want to minimize GCP complexity:**

```
Dev (Local) → Staging + Production (Same GCP Project, Different Resources)
```

- Single GCP project
- Different Cloud Run services: `adyela-api-staging`, `adyela-api-prod`
- Shared Firestore with collection prefixes: `staging_*`, `prod_*`
- **Savings:** Simpler setup
- **Risk:** Potential cross-contamination

---

## 🎯 Recommendation

**Go with Option 1: Dev Local + Staging GCP Minimal + Production GCP Full**

**Rationale:**

1. ✅ **Cost-effective**: $5-10/month for staging vs $50/month for both
2. ✅ **Developer velocity**: Instant local feedback
3. ✅ **Production safety**: Test cloud integrations in staging
4. ✅ **Scalable**: Easy to add more environments later
5. ✅ **Best practices**: Mirrors industry standard

**Next Steps:**

1. I can create the `docker-compose.dev.yml` file
2. Remove/modify `cd-dev.yml` workflow
3. Simplify `cd-staging.yml` for minimal GCP
4. Keep `cd-production.yml` as-is with full features

Would you like me to implement this strategy?
