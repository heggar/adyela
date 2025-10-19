# Cloud KMS Module

Customer-Managed Encryption Keys (CMEK) for encrypting data at rest.

## Features

- ✅ Key rings management
- ✅ Crypto keys with automatic rotation
- ✅ IAM access control per key
- ✅ HSM support (hardware security modules)
- ✅ Multi-region keys

## Cost

- Software keys: $0.06/key/month
- HSM keys: $2.50/key/month
- Key operations: $0.03/10,000 operations
- **Typical**: $3-10/month for 50 keys

## Basic Usage

```hcl
module "kms" {
  source     = "../../modules/cloud-kms"
  project_id = "adyela-production"

  key_rings = [
    { name = "app-keys", location = "us-central1" }
  ]

  crypto_keys = [
    {
      name            = "database-encryption"
      key_ring        = "app-keys"
      rotation_period = "7776000s"  # 90 days

      iam_bindings = [
        {
          member = "serviceAccount:cloudsql@project.iam.gserviceaccount.com"
          role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
        }
      ]
    }
  ]
}
```

## HIPAA Compliance

```hcl
crypto_keys = [
  {
    name             = "phi-encryption"
    key_ring         = "hipaa-keys"
    rotation_period  = "2592000s"  # 30 days for PHI
    protection_level = "HSM"       # Hardware security module

    labels = {
      hipaa_scope = "yes"
      data_type   = "phi"
    }

    iam_bindings = [
      {
        member = "serviceAccount:phi-service@project.iam.gserviceaccount.com"
        role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
      }
    ]
  }
]
```

## Requirements

- Terraform >= 1.0
- Cloud KMS API enabled
- Required permissions: `roles/cloudkms.admin`

## References

- [Cloud KMS Documentation](https://cloud.google.com/kms/docs)
- [Key Rotation](https://cloud.google.com/kms/docs/key-rotation)
