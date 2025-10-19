# Cloud Build Terraform Module

This module creates and manages Google Cloud Build triggers for automated CI/CD
pipelines. It supports GitHub integration, custom build steps, and seamless
deployment to Cloud Run and Artifact Registry.

## Features

- ✅ GitHub integration (push and pull request triggers)
- ✅ Custom build steps with dependencies
- ✅ Artifact Registry integration for container images
- ✅ Cloud Run deployment automation
- ✅ Secret Manager integration
- ✅ Dedicated service accounts with least-privilege IAM
- ✅ Build approval workflows
- ✅ Substitution variables for dynamic builds
- ✅ File inclusion/exclusion filters

## Usage

### Basic Docker Build and Push

```hcl
module "api_build" {
  source = "../../modules/cloud-build"

  project_id   = "my-project"
  trigger_name = "api-staging-deploy"
  environment  = "staging"
  location     = "global"

  # GitHub configuration
  github_config = {
    owner     = "adyela"
    repo_name = "adyela"
    push_config = {
      branch = "^main$"
    }
  }

  # Use cloudbuild.yaml from repository
  build_config_file = "apps/api/cloudbuild.yaml"

  # Substitutions (available as $_VARIABLE in build)
  substitutions = {
    _ENVIRONMENT    = "staging"
    _REGION         = "us-central1"
    _SERVICE_NAME   = "adyela-api-staging"
    _REPOSITORY_URL = "us-central1-docker.pkg.dev/my-project/adyela/api"
  }

  # Create dedicated service account with permissions
  create_service_account         = true
  grant_artifact_registry_access = true
  grant_cloud_run_access         = true
  grant_secret_access            = true
}
```

### Inline Build Configuration

```hcl
module "web_build" {
  source = "../../modules/cloud-build"

  project_id   = "my-project"
  trigger_name = "web-staging-deploy"
  environment  = "staging"

  github_config = {
    owner     = "adyela"
    repo_name = "adyela"
    push_config = {
      branch = "^main$"
    }
  }

  # Inline build steps
  inline_build_config = {
    steps = [
      {
        name = "gcr.io/cloud-builders/docker"
        args = [
          "build",
          "-t", "${var.artifact_registry_url}/adyela-web:$SHORT_SHA",
          "-t", "${var.artifact_registry_url}/adyela-web:latest",
          "-f", "apps/web/Dockerfile",
          "."
        ]
        id = "build-image"
      },
      {
        name     = "gcr.io/cloud-builders/docker"
        args     = ["push", "--all-tags", "${var.artifact_registry_url}/adyela-web"]
        id       = "push-image"
        wait_for = ["build-image"]
      },
      {
        name = "gcr.io/google.com/cloudsdktool/cloud-sdk"
        args = [
          "gcloud", "run", "deploy", "adyela-web-staging",
          "--image", "${var.artifact_registry_url}/adyela-web:$SHORT_SHA",
          "--region", "us-central1",
          "--platform", "managed"
        ]
        id       = "deploy-cloud-run"
        wait_for = ["push-image"]
      }
    ]

    images = [
      "${var.artifact_registry_url}/adyela-web:$SHORT_SHA",
      "${var.artifact_registry_url}/adyela-web:latest"
    ]

    timeout = "1200s"

    options = {
      machine_type = "E2_HIGHCPU_8"
      disk_size_gb = 100
    }
  }

  create_service_account         = true
  grant_artifact_registry_access = true
  grant_cloud_run_access         = true
}
```

### Pull Request Preview Environments

```hcl
module "pr_preview" {
  source = "../../modules/cloud-build"

  project_id   = "my-project"
  trigger_name = "pr-preview-deploy"
  environment  = "development"

  github_config = {
    owner     = "adyela"
    repo_name = "adyela"
    pull_request_config = {
      branch          = "^main$"
      comment_control = "COMMENTS_ENABLED"
    }
  }

  build_config_file = "cloudbuild.preview.yaml"

  substitutions = {
    _ENVIRONMENT = "preview-$PR_NUMBER"
    _BASE_URL    = "https://pr-$PR_NUMBER-staging.adyela.com"
  }

  # Only build when app code changes, not docs
  included_files = [
    "apps/**",
    "packages/**"
  ]

  ignored_files = [
    "docs/**",
    "*.md"
  ]

  create_service_account         = true
  grant_artifact_registry_access = true
  grant_cloud_run_access         = true
}
```

### Production Deployment with Approval

```hcl
module "production_deploy" {
  source = "../../modules/cloud-build"

  project_id   = "my-project"
  trigger_name = "production-deploy"
  environment  = "production"

  github_config = {
    owner     = "adyela"
    repo_name = "adyela"
    push_config = {
      tag = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"  # Match semver tags (v1.2.3)
    }
  }

  build_config_file = "cloudbuild.production.yaml"

  # Require manual approval before deploying
  require_approval = true

  substitutions = {
    _ENVIRONMENT = "production"
    _REGION      = "us-central1"
  }

  create_service_account         = true
  grant_artifact_registry_access = true
  grant_cloud_run_access         = true
  grant_secret_access            = true

  # Grant additional custom roles
  custom_roles = {
    "monitoring" = "roles/monitoring.metricWriter"
    "logging"    = "roles/logging.logWriter"
  }
}
```

## Typical cloudbuild.yaml Structure

```yaml
# apps/api/cloudbuild.yaml
steps:
  # 1. Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - '${_REPOSITORY_URL}:$SHORT_SHA'
      - '-t'
      - '${_REPOSITORY_URL}:latest'
      - '-f'
      - 'apps/api/Dockerfile'
      - '.'
    id: 'build-image'

  # 2. Run tests
  - name: '${_REPOSITORY_URL}:$SHORT_SHA'
    args: ['pytest', 'tests/']
    id: 'run-tests'
    waitFor: ['build-image']

  # 3. Push to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', '--all-tags', '${_REPOSITORY_URL}']
    id: 'push-image'
    waitFor: ['run-tests']

  # 4. Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - '${_SERVICE_NAME}'
      - '--image'
      - '${_REPOSITORY_URL}:$SHORT_SHA'
      - '--region'
      - '${_REGION}'
      - '--platform'
      - 'managed'
      - '--allow-unauthenticated'
    id: 'deploy-cloud-run'
    waitFor: ['push-image']

images:
  - '${_REPOSITORY_URL}:$SHORT_SHA'
  - '${_REPOSITORY_URL}:latest'

options:
  machineType: 'E2_HIGHCPU_8'
  diskSizeGb: 100
  logging: CLOUD_LOGGING_ONLY

timeout: '1200s'
```

## Built-in Substitutions

Cloud Build provides these automatic substitutions:

| Variable       | Description                           |
| -------------- | ------------------------------------- |
| `$PROJECT_ID`  | GCP project ID                        |
| `$BUILD_ID`    | Unique build ID                       |
| `$COMMIT_SHA`  | Full commit SHA                       |
| `$SHORT_SHA`   | First 7 characters of commit SHA      |
| `$BRANCH_NAME` | Branch name (for push triggers)       |
| `$TAG_NAME`    | Tag name (for tag triggers)           |
| `$REPO_NAME`   | Repository name                       |
| `$REVISION_ID` | Commit SHA or tag name                |
| `$PR_NUMBER`   | Pull request number (for PR triggers) |

Custom substitutions start with `_` (underscore).

## Inputs

| Name                           | Description                       | Type           | Default    | Required |
| ------------------------------ | --------------------------------- | -------------- | ---------- | :------: |
| project_id                     | The GCP project ID                | `string`       | n/a        |   yes    |
| trigger_name                   | Name of the Cloud Build trigger   | `string`       | n/a        |   yes    |
| environment                    | Environment (staging, production) | `string`       | n/a        |   yes    |
| location                       | Trigger location                  | `string`       | `"global"` |    no    |
| github_config                  | GitHub repository configuration   | `object`       | `null`     |  yes\*   |
| build_config_file              | Path to cloudbuild.yaml           | `string`       | `null`     |  yes\*   |
| inline_build_config            | Inline build configuration        | `object`       | `null`     |  yes\*   |
| substitutions                  | Custom variables                  | `map(string)`  | `{}`       |    no    |
| included_files                 | Files that trigger builds         | `list(string)` | `[]`       |    no    |
| ignored_files                  | Files that don't trigger builds   | `list(string)` | `[]`       |    no    |
| require_approval               | Require manual approval           | `bool`         | `false`    |    no    |
| create_service_account         | Create dedicated SA               | `bool`         | `false`    |    no    |
| grant_artifact_registry_access | Grant AR write access             | `bool`         | `true`     |    no    |
| grant_cloud_run_access         | Grant Cloud Run admin             | `bool`         | `false`    |    no    |
| grant_secret_access            | Grant Secret Manager access       | `bool`         | `false`    |    no    |

\* Either `build_config_file` or `inline_build_config` must be provided

## Outputs

| Name                  | Description                        |
| --------------------- | ---------------------------------- |
| trigger_id            | The ID of the Cloud Build trigger  |
| trigger_name          | The name of the trigger            |
| service_account_email | Email of the build service account |

## IAM Permissions

The created service account (if `create_service_account = true`) receives:

- **Always**: None (explicitly granted via flags)
- **If `grant_artifact_registry_access = true`**:
  `roles/artifactregistry.writer`
- **If `grant_cloud_run_access = true`**: `roles/run.admin`
- **If `grant_secret_access = true`**: `roles/secretmanager.secretAccessor`
- **If `cloud_run_service_account` set**: `roles/iam.serviceAccountUser` on that
  SA
- **Custom roles**: Any roles in `custom_roles` map

## Cost Optimization

Cloud Build pricing:

- **First 120 build-minutes/day**: FREE
- **Additional build-minutes**: $0.003/minute (E2_HIGHCPU_8)
- **Disk**: Included in machine type

**Optimization strategies:**

1. **Use smaller machine types** for simple builds (E2_MEDIUM)
2. **Cache Docker layers** with `kaniko` or `--cache-from`
3. **Ignore documentation changes** with `ignored_files`
4. **Use build artifacts** instead of rebuilding dependencies
5. **Set appropriate timeouts** (default: 10 minutes)

## Security Best Practices

1. ✅ **Use dedicated service accounts** per environment
2. ✅ **Enable manual approval for production** (`require_approval = true`)
3. ✅ **Store secrets in Secret Manager**, not build config
4. ✅ **Use immutable image tags** (`$SHORT_SHA`, not `latest`)
5. ✅ **Limit service account permissions** (least privilege)
6. ✅ **Validate GitHub webhook signatures**
7. ✅ **Use private pools** for sensitive builds (not covered by this module)

## Integration with Other Modules

### With Artifact Registry

```hcl
module "artifact_registry" {
  source        = "../artifact-registry"
  project_id    = "my-project"
  repository_id = "adyela"
  environment   = "staging"
}

module "cloud_build" {
  source       = "../cloud-build"
  trigger_name = "api-deploy"

  substitutions = {
    _REPOSITORY_URL = module.artifact_registry.repository_url
  }

  create_service_account         = true
  grant_artifact_registry_access = true
}
```

### With Cloud Run

```hcl
module "cloud_run_api" {
  source       = "../cloud-run-service"
  service_name = "adyela-api-staging"
  # ... other config
}

module "cloud_build_api" {
  source       = "../cloud-build"
  trigger_name = "api-deploy"

  create_service_account     = true
  grant_cloud_run_access     = true
  cloud_run_service_account  = module.cloud_run_api.service_account_id
}
```

## Examples

See `examples/` directory:

- `examples/basic-docker-build/` - Simple Docker build and push
- `examples/multi-stage-pipeline/` - Build, test, deploy pipeline
- `examples/pr-preview-environments/` - Ephemeral preview environments

## Requirements

- Terraform >= 1.0
- Google Cloud Provider >= 6.0
- Cloud Build API enabled in GCP project
- GitHub App installed (for GitHub triggers)

## Troubleshooting

### "Repository not found" error

- Ensure GitHub App is installed on the repository
- Verify `owner` and `repo_name` are correct
- Check that Cloud Build has access to the repository

### Build fails with permission errors

- Verify service account has required IAM roles
- Check that `grant_*_access` flags are set correctly
- Ensure Cloud Run service account is specified if needed

### Builds not triggering

- Check `included_files` and `ignored_files` patterns
- Verify branch/tag regex patterns are correct
- Ensure trigger is not `disabled = true`
