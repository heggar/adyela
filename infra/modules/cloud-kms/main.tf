# Cloud KMS Module
# Manages encryption keys and key rings for CMEK

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Key Rings
resource "google_kms_key_ring" "key_rings" {
  for_each = { for kr in var.key_rings : kr.name => kr }

  project  = var.project_id
  name     = each.value.name
  location = each.value.location
}

# Crypto Keys
resource "google_kms_crypto_key" "keys" {
  for_each = { for key in var.crypto_keys : "${key.key_ring}-${key.name}" => key }

  name            = each.value.name
  key_ring        = google_kms_key_ring.key_rings[each.value.key_ring].id
  purpose         = lookup(each.value, "purpose", "ENCRYPT_DECRYPT")
  rotation_period = lookup(each.value, "rotation_period", "7776000s") # 90 days

  labels = merge(var.labels, lookup(each.value, "labels", {}))

  lifecycle {
    prevent_destroy = lookup(each.value, "prevent_destroy", true)
  }

  version_template {
    algorithm        = lookup(each.value, "algorithm", "GOOGLE_SYMMETRIC_ENCRYPTION")
    protection_level = lookup(each.value, "protection_level", "SOFTWARE")
  }
}

# IAM Bindings for Crypto Keys
resource "google_kms_crypto_key_iam_member" "key_bindings" {
  for_each = {
    for binding in local.key_iam_bindings :
    "${binding.key_ring}-${binding.key_name}-${binding.member}-${binding.role}" => binding
  }

  crypto_key_id = google_kms_crypto_key.keys["${each.value.key_ring}-${each.value.key_name}"].id
  role          = each.value.role
  member        = each.value.member
}

locals {
  key_iam_bindings = flatten([
    for key in var.crypto_keys : [
      for binding in lookup(key, "iam_bindings", []) : {
        key_ring = key.key_ring
        key_name = key.name
        member   = binding.member
        role     = binding.role
      }
    ]
  ])
}
