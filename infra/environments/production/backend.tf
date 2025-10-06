terraform {
  backend "gcs" {
    bucket = "adyela-production-terraform-state"
    prefix = "terraform/state"
  }
}
