# Cloud Storage Module Outputs

output "bucket_name" {
  description = "Name of the created bucket"
  value       = google_storage_bucket.bucket.name
}

output "bucket_url" {
  description = "URL of the bucket"
  value       = google_storage_bucket.bucket.url
}

output "bucket_self_link" {
  description = "Self link of the bucket"
  value       = google_storage_bucket.bucket.self_link
}

output "bucket_location" {
  description = "Location of the bucket"
  value       = google_storage_bucket.bucket.location
}

output "bucket_storage_class" {
  description = "Storage class of the bucket"
  value       = google_storage_bucket.bucket.storage_class
}

output "bucket_id" {
  description = "ID of the bucket"
  value       = google_storage_bucket.bucket.id
}

output "public_url" {
  description = "Public URL for accessing objects (if bucket is public)"
  value       = "https://storage.googleapis.com/${google_storage_bucket.bucket.name}"
}

output "website_url" {
  description = "Website URL (if website configuration is enabled)"
  value       = var.website_config != null ? "https://${google_storage_bucket.bucket.name}" : null
}
