# Cloud KMS Module Outputs

output "key_rings" {
  description = "Map of created key rings"
  value = {
    for kr_key, kr in google_kms_key_ring.key_rings :
    kr_key => {
      id       = kr.id
      name     = kr.name
      location = kr.location
    }
  }
}

output "crypto_keys" {
  description = "Map of created crypto keys"
  value = {
    for key_id, key in google_kms_crypto_key.keys :
    key_id => {
      id              = key.id
      name            = key.name
      purpose         = key.purpose
      rotation_period = key.rotation_period
    }
  }
}

output "crypto_key_ids" {
  description = "Map of crypto key names to IDs"
  value       = { for key_id, key in google_kms_crypto_key.keys : key.name => key.id }
}

output "summary" {
  description = "Summary of KMS resources created"
  value = {
    key_rings_created   = length(google_kms_key_ring.key_rings)
    crypto_keys_created = length(google_kms_crypto_key.keys)
    iam_bindings        = length(google_kms_crypto_key_iam_member.key_bindings)
  }
}
