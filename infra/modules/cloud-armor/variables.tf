# Cloud Armor Security Policy Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "policy_name" {
  description = "Name of the security policy"
  type        = string
}

variable "description" {
  description = "Description of the security policy"
  type        = string
  default     = ""
}

# Default Rule Configuration
variable "default_rule_action" {
  description = "Action for the default rule (allow, deny(403), deny(404), deny(502))"
  type        = string
  default     = "deny(403)"

  validation {
    condition     = can(regex("^(allow|deny\\([0-9]+\\)|throttle)$", var.default_rule_action))
    error_message = "Default rule action must be allow, deny(status_code), or throttle"
  }
}

variable "default_rate_limit_threshold_count" {
  description = "Request count threshold for default rate limiting"
  type        = number
  default     = 1000
}

variable "default_rate_limit_threshold_interval" {
  description = "Interval in seconds for default rate limiting"
  type        = number
  default     = 60
}

variable "default_rate_limit_enforce_on_key" {
  description = "Enforce rate limit on IP, ALL, HTTP-HEADER, XFF-IP, HTTP-COOKIE, HTTP-PATH"
  type        = string
  default     = "IP"

  validation {
    condition     = contains(["IP", "ALL", "HTTP-HEADER", "XFF-IP", "HTTP-COOKIE", "HTTP-PATH"], var.default_rate_limit_enforce_on_key)
    error_message = "Invalid enforce_on_key value"
  }
}

# Adaptive Protection (DDoS)
variable "enable_adaptive_protection" {
  description = "Enable Adaptive Protection for DDoS defense"
  type        = bool
  default     = false
}

variable "adaptive_protection_rule_visibility" {
  description = "Rule visibility for adaptive protection (STANDARD or PREMIUM)"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "PREMIUM"], var.adaptive_protection_rule_visibility)
    error_message = "Rule visibility must be STANDARD or PREMIUM"
  }
}

# Advanced Options
variable "enable_advanced_options" {
  description = "Enable advanced options configuration"
  type        = bool
  default     = true
}

variable "json_parsing" {
  description = "JSON parsing mode (DISABLED, STANDARD, STANDARD_WITH_GRAPHQL)"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["DISABLED", "STANDARD", "STANDARD_WITH_GRAPHQL"], var.json_parsing)
    error_message = "Invalid JSON parsing mode"
  }
}

variable "json_content_types" {
  description = "Content types to parse as JSON"
  type        = list(string)
  default     = ["application/json", "application/vnd.api+json"]
}

variable "log_level" {
  description = "Log level (NORMAL or VERBOSE)"
  type        = string
  default     = "NORMAL"

  validation {
    condition     = contains(["NORMAL", "VERBOSE"], var.log_level)
    error_message = "Log level must be NORMAL or VERBOSE"
  }
}

variable "enable_logging_headers" {
  description = "Add headers to requests indicating Cloud Armor actions"
  type        = bool
  default     = true
}

# IP Allowlist/Denylist
variable "ip_allowlist" {
  description = "List of IP ranges to allow (CIDR notation)"
  type        = list(string)
  default     = []
}

variable "ip_allowlist_priority" {
  description = "Priority for IP allowlist rule"
  type        = number
  default     = 100
}

variable "ip_denylist" {
  description = "List of IP ranges to deny (CIDR notation)"
  type        = list(string)
  default     = []
}

variable "ip_denylist_priority" {
  description = "Priority for IP denylist rule"
  type        = number
  default     = 200
}

# Geographic Restrictions
variable "geo_allowlist" {
  description = "List of country codes to allow (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
}

variable "geo_allowlist_priority" {
  description = "Priority for geo allowlist rule"
  type        = number
  default     = 300
}

variable "geo_denylist" {
  description = "List of country codes to deny (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
}

variable "geo_denylist_priority" {
  description = "Priority for geo denylist rule"
  type        = number
  default     = 400
}

# OWASP Top 10 Protection
variable "enable_owasp_rules" {
  description = "Enable OWASP Top 10 protection rules"
  type        = bool
  default     = true
}

variable "owasp_rules" {
  description = "List of OWASP protection rules to apply"
  type = list(object({
    rule_id     = string
    priority    = number
    description = string
    expression  = string
  }))
  default = [
    {
      rule_id     = "owasp-crs-v030301-id942100-sqli"
      priority    = 1000
      description = "SQL Injection: OWASP CRS v3.3.0 Rule 942100"
      expression  = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
    },
    {
      rule_id     = "owasp-crs-v030301-id941100-xss"
      priority    = 1001
      description = "Cross-site Scripting: OWASP CRS v3.3.0 Rule 941100"
      expression  = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
    },
    {
      rule_id     = "owasp-crs-v030301-id930100-lfi"
      priority    = 1002
      description = "Local File Inclusion: OWASP CRS v3.3.0 Rule 930100"
      expression  = "evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': 1})"
    },
    {
      rule_id     = "owasp-crs-v030301-id931100-rfi"
      priority    = 1003
      description = "Remote File Inclusion: OWASP CRS v3.3.0 Rule 931100"
      expression  = "evaluatePreconfiguredWaf('rfi-v33-stable', {'sensitivity': 1})"
    },
    {
      rule_id     = "owasp-crs-v030301-id932100-rce"
      priority    = 1004
      description = "Remote Code Execution: OWASP CRS v3.3.0 Rule 932100"
      expression  = "evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': 1})"
    },
    {
      rule_id     = "owasp-crs-v030301-id913100-scanner"
      priority    = 1005
      description = "Scanner Detection: OWASP CRS v3.3.0 Rule 913100"
      expression  = "evaluatePreconfiguredWaf('scannerdetection-v33-stable', {'sensitivity': 1})"
    },
    {
      rule_id     = "owasp-crs-v030301-id943100-session-fixation"
      priority    = 1006
      description = "Session Fixation: OWASP CRS v3.3.0 Rule 943100"
      expression  = "evaluatePreconfiguredWaf('sessionfixation-v33-stable', {'sensitivity': 1})"
    }
  ]
}

# Individual Protection Toggles with Customizable Expressions
variable "enable_sqli_protection" {
  description = "Enable SQL Injection protection"
  type        = bool
  default     = true
}

variable "sqli_protection_priority" {
  description = "Priority for SQL Injection protection rule"
  type        = number
  default     = 1000
}

variable "sqli_protection_expression" {
  description = "CEL expression for SQL Injection detection"
  type        = string
  default     = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
}

variable "enable_xss_protection" {
  description = "Enable XSS protection"
  type        = bool
  default     = true
}

variable "xss_protection_priority" {
  description = "Priority for XSS protection rule"
  type        = number
  default     = 1001
}

variable "xss_protection_expression" {
  description = "CEL expression for XSS detection"
  type        = string
  default     = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
}

variable "enable_lfi_protection" {
  description = "Enable LFI/RFI protection"
  type        = bool
  default     = true
}

variable "lfi_protection_priority" {
  description = "Priority for LFI protection rule"
  type        = number
  default     = 1002
}

variable "lfi_protection_expression" {
  description = "CEL expression for LFI/RFI detection"
  type        = string
  default     = "evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': 1})"
}

variable "enable_rce_protection" {
  description = "Enable RCE protection"
  type        = bool
  default     = true
}

variable "rce_protection_priority" {
  description = "Priority for RCE protection rule"
  type        = number
  default     = 1003
}

variable "rce_protection_expression" {
  description = "CEL expression for RCE detection"
  type        = string
  default     = "evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': 1})"
}

variable "enable_scanner_detection" {
  description = "Enable scanner/bot detection"
  type        = bool
  default     = true
}

variable "scanner_detection_priority" {
  description = "Priority for scanner detection rule"
  type        = number
  default     = 1004
}

variable "scanner_detection_expression" {
  description = "CEL expression for scanner detection"
  type        = string
  default     = "evaluatePreconfiguredWaf('scannerdetection-v33-stable', {'sensitivity': 1})"
}

variable "enable_protocol_attack_protection" {
  description = "Enable protocol attack protection"
  type        = bool
  default     = true
}

variable "protocol_attack_protection_priority" {
  description = "Priority for protocol attack protection rule"
  type        = number
  default     = 1005
}

variable "protocol_attack_protection_expression" {
  description = "CEL expression for protocol attack detection"
  type        = string
  default     = "evaluatePreconfiguredWaf('protocolattack-v33-stable', {'sensitivity': 1})"
}

variable "enable_session_fixation_protection" {
  description = "Enable session fixation protection"
  type        = bool
  default     = true
}

variable "session_fixation_protection_priority" {
  description = "Priority for session fixation protection rule"
  type        = number
  default     = 1006
}

variable "session_fixation_protection_expression" {
  description = "CEL expression for session fixation detection"
  type        = string
  default     = "evaluatePreconfiguredWaf('sessionfixation-v33-stable', {'sensitivity': 1})"
}

# Preconfigured WAF Rules
variable "enable_preconfigured_waf_rules" {
  description = "Enable Google-managed preconfigured WAF rules"
  type        = bool
  default     = false
}

variable "preconfigured_waf_config_exclusions" {
  description = "Configuration for preconfigured WAF rules with exclusions"
  type = list(object({
    target_rule_set   = string
    sensitivity_level = number
    exclusions = optional(list(object({
      target_rule_set = string
      target_rule_ids = optional(list(string))
      request_headers = optional(list(object({
        operator = string
        value    = string
      })))
      request_uris = optional(list(object({
        operator = string
        value    = string
      })))
      request_query_params = optional(list(object({
        operator = string
        value    = string
      })))
    })))
  }))
  default = []
}

# Custom Rules
variable "custom_rules" {
  description = "List of custom security rules"
  type = list(object({
    priority      = number
    description   = string
    action        = string
    expression    = optional(string)
    src_ip_ranges = optional(list(string))
    preview       = optional(bool)

    rate_limit_options = optional(object({
      threshold_count        = number
      threshold_interval     = number
      conform_action         = optional(string)
      exceed_action          = optional(string)
      enforce_on_key         = optional(string)
      enforce_on_key_name    = optional(string)
      ban_threshold_count    = optional(number)
      ban_threshold_interval = optional(number)
      ban_duration_sec       = optional(number)
    }))

    header_action = optional(object({
      request_headers_to_adds = list(object({
        header_name  = string
        header_value = string
      }))
    }))

    redirect_options = optional(object({
      type   = string
      target = string
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.custom_rules :
      can(regex("^(allow|deny\\([0-9]+\\)|throttle|redirect)$", rule.action))
    ])
    error_message = "Rule action must be allow, deny(status_code), throttle, or redirect"
  }
}
