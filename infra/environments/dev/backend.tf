terraform {
  backend "gcs" {
    bucket = "adyela-staging-terraform-state"
    prefix = "terraform/state/dev"
  }
}
