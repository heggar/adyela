# Cloud Armor Security Policy Outputs

output "security_policy_id" {
  description = "ID of the security policy"
  value       = google_compute_security_policy.policy.id
}

output "security_policy_name" {
  description = "Name of the security policy"
  value       = google_compute_security_policy.policy.name
}

output "security_policy_self_link" {
  description = "Self link of the security policy"
  value       = google_compute_security_policy.policy.self_link
}

output "security_policy_fingerprint" {
  description = "Fingerprint of the security policy (for versioning)"
  value       = google_compute_security_policy.policy.fingerprint
}

output "preconfigured_waf_policy_id" {
  description = "ID of the preconfigured WAF policy (if enabled)"
  value       = var.enable_preconfigured_waf_rules ? google_compute_security_policy.preconfigured_waf[0].id : null
}

output "preconfigured_waf_policy_name" {
  description = "Name of the preconfigured WAF policy (if enabled)"
  value       = var.enable_preconfigured_waf_rules ? google_compute_security_policy.preconfigured_waf[0].name : null
}

output "preconfigured_waf_policy_self_link" {
  description = "Self link of the preconfigured WAF policy (if enabled)"
  value       = var.enable_preconfigured_waf_rules ? google_compute_security_policy.preconfigured_waf[0].self_link : null
}

output "adaptive_protection_enabled" {
  description = "Whether adaptive protection (DDoS defense) is enabled"
  value       = var.enable_adaptive_protection
}

output "owasp_protection_enabled" {
  description = "Whether OWASP Top 10 protection is enabled"
  value       = var.enable_owasp_rules
}

output "rule_count" {
  description = "Number of rules in the security policy"
  value       = length(google_compute_security_policy.policy.rule)
}

output "ip_allowlist_count" {
  description = "Number of IP ranges in the allowlist"
  value       = length(var.ip_allowlist)
}

output "ip_denylist_count" {
  description = "Number of IP ranges in the denylist"
  value       = length(var.ip_denylist)
}

output "geo_allowlist_countries" {
  description = "List of allowed countries"
  value       = var.geo_allowlist
}

output "geo_denylist_countries" {
  description = "List of denied countries"
  value       = var.geo_denylist
}

output "custom_rule_count" {
  description = "Number of custom rules configured"
  value       = length(var.custom_rules)
}

output "default_action" {
  description = "Default action for unmatched traffic"
  value       = var.default_rule_action
}

output "log_level" {
  description = "Logging level for the security policy"
  value       = var.log_level
}
