# Cloud Armor Security Policy Module
# Provides WAF protection, DDoS defense, and rate limiting

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Security Policy
resource "google_compute_security_policy" "policy" {
  project     = var.project_id
  name        = var.policy_name
  description = var.description

  # Adaptive Protection (DDoS)
  dynamic "adaptive_protection_config" {
    for_each = var.enable_adaptive_protection ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable          = true
        rule_visibility = var.adaptive_protection_rule_visibility
      }
    }
  }

  # Advanced Options
  dynamic "advanced_options_config" {
    for_each = var.enable_advanced_options ? [1] : []
    content {
      json_parsing = var.json_parsing
      log_level    = var.log_level

      dynamic "json_custom_config" {
        for_each = var.json_parsing == "STANDARD" ? [1] : []
        content {
          content_types = var.json_content_types
        }
      }
    }
  }

  # Default rule (last priority, deny by default for production)
  rule {
    action   = var.default_rule_action
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule: ${var.default_rule_action} all traffic"

    dynamic "rate_limit_options" {
      for_each = var.default_rule_action == "throttle" ? [1] : []
      content {
        conform_action = "allow"
        exceed_action  = "deny(429)"

        rate_limit_threshold {
          count        = var.default_rate_limit_threshold_count
          interval_sec = var.default_rate_limit_threshold_interval
        }

        enforce_on_key = var.default_rate_limit_enforce_on_key
      }
    }
  }

  # OWASP Top 10 Protection Rules
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? var.owasp_rules : []
    content {
      action   = "deny(403)"
      priority = rule.value.priority
      match {
        expr {
          expression = rule.value.expression
        }
      }
      description = rule.value.description

      dynamic "header_action" {
        for_each = var.enable_logging_headers ? [1] : []
        content {
          request_headers_to_adds {
            header_name  = "X-Cloud-Armor-Action"
            header_value = "blocked-${rule.value.rule_id}"
          }
        }
      }
    }
  }

  # Custom Rules
  dynamic "rule" {
    for_each = { for r in var.custom_rules : r.priority => r }
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      preview     = lookup(rule.value, "preview", false)
      description = rule.value.description

      match {
        dynamic "expr" {
          for_each = lookup(rule.value, "expression", null) != null ? [1] : []
          content {
            expression = rule.value.expression
          }
        }

        dynamic "config" {
          for_each = lookup(rule.value, "src_ip_ranges", null) != null ? [1] : []
          content {
            src_ip_ranges = rule.value.src_ip_ranges
          }
        }
      }

      # Rate Limiting
      dynamic "rate_limit_options" {
        for_each = rule.value.action == "throttle" ? [1] : []
        content {
          conform_action = lookup(rule.value.rate_limit_options, "conform_action", "allow")
          exceed_action  = lookup(rule.value.rate_limit_options, "exceed_action", "deny(429)")

          rate_limit_threshold {
            count        = rule.value.rate_limit_options.threshold_count
            interval_sec = rule.value.rate_limit_options.threshold_interval
          }

          enforce_on_key      = lookup(rule.value.rate_limit_options, "enforce_on_key", "IP")
          enforce_on_key_name = lookup(rule.value.rate_limit_options, "enforce_on_key_name", null)

          dynamic "ban_threshold" {
            for_each = lookup(rule.value.rate_limit_options, "ban_threshold_count", null) != null ? [1] : []
            content {
              count        = rule.value.rate_limit_options.ban_threshold_count
              interval_sec = rule.value.rate_limit_options.ban_threshold_interval
            }
          }

          ban_duration_sec = lookup(rule.value.rate_limit_options, "ban_duration_sec", null)
        }
      }

      # Header Actions
      dynamic "header_action" {
        for_each = lookup(rule.value, "header_action", null) != null ? [1] : []
        content {
          dynamic "request_headers_to_adds" {
            for_each = lookup(rule.value.header_action, "request_headers_to_adds", [])
            content {
              header_name  = request_headers_to_adds.value.header_name
              header_value = request_headers_to_adds.value.header_value
            }
          }
        }
      }

      # Redirect
      dynamic "redirect_options" {
        for_each = rule.value.action == "redirect" ? [1] : []
        content {
          type   = lookup(rule.value.redirect_options, "type", "EXTERNAL_302")
          target = rule.value.redirect_options.target
        }
      }
    }
  }

  # IP Allowlist Rules
  dynamic "rule" {
    for_each = length(var.ip_allowlist) > 0 ? [1] : []
    content {
      action      = "allow"
      priority    = var.ip_allowlist_priority
      description = "Allow traffic from trusted IP ranges"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.ip_allowlist
        }
      }
    }
  }

  # IP Denylist Rules
  dynamic "rule" {
    for_each = length(var.ip_denylist) > 0 ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.ip_denylist_priority
      description = "Block traffic from denied IP ranges"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.ip_denylist
        }
      }
    }
  }

  # Geographic Blocking
  dynamic "rule" {
    for_each = length(var.geo_denylist) > 0 ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.geo_denylist_priority
      description = "Block traffic from specific countries"
      match {
        expr {
          expression = "origin.region_code in [${join(",", formatlist("'%s'", var.geo_denylist))}]"
        }
      }
    }
  }

  # Geographic Allowlist (only allow specific countries)
  dynamic "rule" {
    for_each = length(var.geo_allowlist) > 0 ? [1] : []
    content {
      action      = "allow"
      priority    = var.geo_allowlist_priority
      description = "Only allow traffic from specific countries"
      match {
        expr {
          expression = "origin.region_code in [${join(",", formatlist("'%s'", var.geo_allowlist))}]"
        }
      }
    }
  }

  # SQL Injection Protection
  dynamic "rule" {
    for_each = var.enable_sqli_protection ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.sqli_protection_priority
      description = "Block SQL injection attempts"
      match {
        expr {
          expression = var.sqli_protection_expression
        }
      }
    }
  }

  # XSS Protection
  dynamic "rule" {
    for_each = var.enable_xss_protection ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.xss_protection_priority
      description = "Block XSS attempts"
      match {
        expr {
          expression = var.xss_protection_expression
        }
      }
    }
  }

  # LFI/RFI Protection (Local/Remote File Inclusion)
  dynamic "rule" {
    for_each = var.enable_lfi_protection ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.lfi_protection_priority
      description = "Block LFI/RFI attempts"
      match {
        expr {
          expression = var.lfi_protection_expression
        }
      }
    }
  }

  # RCE Protection (Remote Code Execution)
  dynamic "rule" {
    for_each = var.enable_rce_protection ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.rce_protection_priority
      description = "Block RCE attempts"
      match {
        expr {
          expression = var.rce_protection_expression
        }
      }
    }
  }

  # Scanner/Bot Detection
  dynamic "rule" {
    for_each = var.enable_scanner_detection ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.scanner_detection_priority
      description = "Block known vulnerability scanners and bots"
      match {
        expr {
          expression = var.scanner_detection_expression
        }
      }
    }
  }

  # Protocol Attack Protection
  dynamic "rule" {
    for_each = var.enable_protocol_attack_protection ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.protocol_attack_protection_priority
      description = "Block protocol attacks (HTTP Request Smuggling, etc.)"
      match {
        expr {
          expression = var.protocol_attack_protection_expression
        }
      }
    }
  }

  # Session Fixation Protection
  dynamic "rule" {
    for_each = var.enable_session_fixation_protection ? [1] : []
    content {
      action      = "deny(403)"
      priority    = var.session_fixation_protection_priority
      description = "Block session fixation attempts"
      match {
        expr {
          expression = var.session_fixation_protection_expression
        }
      }
    }
  }
}

# Preconfigured WAF Rules (Google-managed)
resource "google_compute_security_policy" "preconfigured_waf" {
  count = var.enable_preconfigured_waf_rules ? 1 : 0

  project     = var.project_id
  name        = "${var.policy_name}-preconfigured"
  description = "Preconfigured WAF rules for ${var.policy_name}"

  # Default allow
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule: allow all"
  }

  # OWASP ModSecurity Core Rule Set
  dynamic "rule" {
    for_each = var.preconfigured_waf_config_exclusions
    content {
      action   = "deny(403)"
      priority = 1000 + rule.key
      match {
        expr {
          expression = "evaluatePreconfiguredWaf('${rule.value.target_rule_set}', {'sensitivity': ${rule.value.sensitivity_level}})"
        }
      }
      description = "Preconfigured WAF: ${rule.value.target_rule_set}"

      dynamic "preconfigured_waf_config" {
        for_each = [rule.value]
        content {
          dynamic "exclusion" {
            for_each = lookup(preconfigured_waf_config.value, "exclusions", [])
            content {
              target_rule_set = exclusion.value.target_rule_set

              dynamic "target_rule_ids" {
                for_each = lookup(exclusion.value, "target_rule_ids", [])
                content {
                  target_rule_id = target_rule_ids.value
                }
              }

              dynamic "request_header" {
                for_each = lookup(exclusion.value, "request_headers", [])
                content {
                  operator = request_header.value.operator
                  value    = request_header.value.value
                }
              }

              dynamic "request_uri" {
                for_each = lookup(exclusion.value, "request_uris", [])
                content {
                  operator = request_uri.value.operator
                  value    = request_uri.value.value
                }
              }

              dynamic "request_query_param" {
                for_each = lookup(exclusion.value, "request_query_params", [])
                content {
                  operator = request_query_param.value.operator
                  value    = request_query_param.value.value
                }
              }
            }
          }
        }
      }
    }
  }
}
