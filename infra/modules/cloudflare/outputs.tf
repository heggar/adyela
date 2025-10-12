# Cloudflare Module Outputs

output "zone_id" {
  description = "Cloudflare Zone ID"
  value       = data.cloudflare_zone.adyela.id
}

output "zone_name" {
  description = "Cloudflare Zone Name"
  value       = data.cloudflare_zone.adyela.name
}

output "staging_record_id" {
  description = "Staging DNS record ID"
  value       = cloudflare_record.staging.id
}

output "api_staging_record_id" {
  description = "API staging DNS record ID"
  value       = cloudflare_record.api_staging.id
}

output "waf_ruleset_id" {
  description = "WAF ruleset ID"
  value       = cloudflare_ruleset.waf_custom.id
}

output "security_headers_ruleset_id" {
  description = "Security headers ruleset ID"
  value       = cloudflare_ruleset.security_headers.id
}

output "rate_limiting_ruleset_id" {
  description = "Rate limiting ruleset ID"
  value       = cloudflare_ruleset.rate_limiting.id
}
