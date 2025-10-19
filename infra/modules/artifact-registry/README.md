# Artifact Registry Terraform Module

This module creates and manages Google Cloud Artifact Registry repositories for
storing Docker containers, Maven packages, NPM packages, and other artifact
types.

## Features

- ✅ Support for multiple artifact formats (Docker, Maven, NPM, Python, etc.)
- ✅ Automated cleanup policies to manage storage costs
- ✅ IAM bindings for fine-grained access control
- ✅ Optional CI/CD service account creation
- ✅ Docker-specific configurations (immutable tags, vulnerability scanning)
- ✅ KMS encryption support
- ✅ Cost attribution via labels

## Usage

### Basic Docker Repository

```hcl
module "docker_registry" {
  source = "../../modules/artifact-registry"

  project_id    = "my-project"
  repository_id = "adyela-containers"
  location      = "us-central1"
  environment   = "staging"
  format        = "DOCKER"

  description = "Docker images for Adyela microservices"

  # IAM
  reader_members = [
    "serviceAccount:cloud-run@my-project.iam.gserviceaccount.com"
  ]

  writer_members = [
    "serviceAccount:github-actions@my-project.iam.gserviceaccount.com"
  ]
}
```

### With Cleanup Policies

```hcl
module "docker_registry_with_cleanup" {
  source = "../../modules/artifact-registry"

  project_id    = "my-project"
  repository_id = "adyela-containers"
  location      = "us-central1"
  environment   = "production"

  # Cleanup policies to manage costs
  cleanup_policies = [
    {
      id     = "delete-old-untagged-images"
      action = "DELETE"
      condition = {
        tag_state  = "UNTAGGED"
        older_than = "2592000s"  # 30 days
      }
    },
    {
      id     = "keep-recent-versions"
      action = "KEEP"
      most_recent_versions = {
        keep_count = 10
      }
    }
  ]

  # Immutable tags for production
  immutable_tags = true
}
```

### With CI/CD Service Account

```hcl
module "docker_registry_cicd" {
  source = "../../modules/artifact-registry"

  project_id    = "my-project"
  repository_id = "adyela-containers"
  location      = "us-central1"
  environment   = "staging"

  # Create service account for GitHub Actions
  create_cicd_service_account = true
  grant_storage_admin         = true

  labels = {
    team = "platform"
    tier = "critical"
  }
}

# Use in GitHub Actions workflow
output "cicd_sa_email" {
  value = module.docker_registry_cicd.cicd_service_account_email
}
```

## Cleanup Policy Examples

### Delete old untagged images (cost optimization)

```hcl
{
  id     = "delete-old-untagged"
  action = "DELETE"
  condition = {
    tag_state  = "UNTAGGED"
    older_than = "2592000s"  # 30 days
  }
}
```

### Keep only recent versions per package

```hcl
{
  id     = "keep-recent-10"
  action = "KEEP"
  most_recent_versions = {
    keep_count = 10
  }
}
```

### Delete old staging images

```hcl
{
  id     = "delete-old-staging"
  action = "DELETE"
  condition = {
    tag_prefixes = ["staging-"]
    older_than   = "604800s"  # 7 days
  }
}
```

## Inputs

| Name                        | Description                       | Type           | Default         | Required |
| --------------------------- | --------------------------------- | -------------- | --------------- | :------: |
| project_id                  | The GCP project ID                | `string`       | n/a             |   yes    |
| repository_id               | The ID of the repository          | `string`       | n/a             |   yes    |
| location                    | The location of the repository    | `string`       | `"us-central1"` |    no    |
| environment                 | Environment (staging, production) | `string`       | n/a             |   yes    |
| format                      | Repository format                 | `string`       | `"DOCKER"`      |    no    |
| cleanup_policies            | Cleanup policies                  | `list(object)` | `[]`            |    no    |
| immutable_tags              | Enable immutable tags             | `bool`         | `false`         |    no    |
| create_cicd_service_account | Create CI/CD service account      | `bool`         | `false`         |    no    |
| reader_members              | List of readers                   | `list(string)` | `[]`            |    no    |
| writer_members              | List of writers                   | `list(string)` | `[]`            |    no    |

## Outputs

| Name                       | Description                                 |
| -------------------------- | ------------------------------------------- |
| repository_id              | The ID of the created repository            |
| repository_url             | URL for pushing/pulling images              |
| cicd_service_account_email | Email of CI/CD service account (if created) |

## Cost Optimization

This module implements several cost optimization strategies:

1. **Cleanup Policies**: Automatically delete old/unused images
2. **Regional Repositories**: Lower egress costs when colocated with Cloud Run
3. **Immutable Tags**: Prevents accidental overwrites (production)
4. **IAM Controls**: Prevent unauthorized pushes that waste storage

## Security Best Practices

1. ✅ **Separate repositories per environment** (staging, production)
2. ✅ **Use immutable tags in production**
3. ✅ **Limit writer access to CI/CD service accounts**
4. ✅ **Enable KMS encryption for sensitive images**
5. ✅ **Implement least-privilege IAM bindings**

## Examples

See `examples/` directory for complete usage examples:

- `examples/basic-docker-registry/` - Simple Docker repository
- `examples/multi-environment/` - Staging + Production setup
- `examples/with-cleanup/` - Cost-optimized configuration

## Requirements

- Terraform >= 1.0
- Google Cloud Provider >= 6.0
- Artifact Registry API enabled in GCP project
