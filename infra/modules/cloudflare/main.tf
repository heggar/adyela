# Cloudflare CDN Module
# Provides CDN, WAF, and DNS management for Adyela

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare Zone
data "cloudflare_zone" "adyela" {
  name = var.domain
}

# DNS Records
resource "cloudflare_record" "staging" {
  zone_id = data.cloudflare_zone.adyela.id
  name    = "staging"
  content = var.load_balancer_ip
  type    = "A"
  proxied = true # Enable Cloudflare proxy (CDN)
  ttl     = 1    # Auto TTL when proxied
}

resource "cloudflare_record" "api_staging" {
  zone_id = data.cloudflare_zone.adyela.id
  name    = "api.staging"
  content = var.load_balancer_ip
  type    = "A"
  proxied = true # Enable Cloudflare proxy (CDN)
  ttl     = 1    # Auto TTL when proxied
}

# Page Rules for Cache Optimization
resource "cloudflare_page_rule" "static_assets" {
  zone_id  = data.cloudflare_zone.adyela.id
  target   = "staging.adyela.care/assets/*"
  priority = 1

  actions {
    cache_level                = "cache_everything"
    edge_cache_ttl            = 31536000 # 1 year
    browser_cache_ttl         = 31536000 # 1 year
    respect_strong_etag       = "on"
    browser_check             = "off"
    origin_error_page_pass_thru = "on"
  }
}

resource "cloudflare_page_rule" "api_cache_control" {
  zone_id  = data.cloudflare_zone.adyela.id
  target   = "api.staging.adyela.care/*"
  priority = 2

  actions {
    cache_level                = "bypass"
    browser_cache_ttl         = 0
    edge_cache_ttl            = 0
    origin_error_page_pass_thru = "on"
  }
}

resource "cloudflare_page_rule" "web_app_cache" {
  zone_id  = data.cloudflare_zone.adyela.id
  target   = "staging.adyela.care/*"
  priority = 3

  actions {
    cache_level                = "aggressive"
    edge_cache_ttl            = 3600     # 1 hour
    browser_cache_ttl         = 0        # No browser cache for SPA
    respect_strong_etag       = "on"
    browser_check             = "off"
    origin_error_page_pass_thru = "on"
  }
}

# WAF Rules
resource "cloudflare_ruleset" "waf_custom" {
  zone_id  = data.cloudflare_zone.adyela.id
  name     = "Adyela WAF Custom Rules"
  description = "Custom WAF rules for Adyela staging"
  kind     = "zone"
  phase    = "http_request_firewall_custom"

  rules {
    action = "block"
    expression = "(http.request.uri.path contains \"/.env\" or http.request.uri.path contains \"/wp-admin\" or http.request.uri.path contains \"/admin\")"
    description = "Block common attack paths"
    enabled = true
  }

  rules {
    action = "challenge"
    expression = "(cf.threat_score gt 14)"
    description = "Challenge high threat score requests"
    enabled = true
  }

  rules {
    action = "log"
    expression = "(http.request.method eq \"POST\" and http.request.uri.path contains \"/api/\")"
    description = "Log API POST requests"
    enabled = true
  }
}

# Rate Limiting (using ruleset instead of deprecated rate_limit)
resource "cloudflare_ruleset" "rate_limiting" {
  zone_id  = data.cloudflare_zone.adyela.id
  name     = "Adyela Rate Limiting"
  description = "Rate limiting for API endpoints"
  kind     = "zone"
  phase    = "http_ratelimit"

  rules {
    action = "log"
    expression = "(http.request.uri.path contains \"/api/\" and cf.rate_limit_key eq \"$http.cf.connecting_ip\")"
    description = "Rate limit API requests"
    enabled = true
    action_parameters {
      response {
        status_code = 429
        content = "Rate limit exceeded"
        content_type = "text/plain"
      }
    }
  }
}

# Security Headers
resource "cloudflare_ruleset" "security_headers" {
  zone_id  = data.cloudflare_zone.adyela.id
  name     = "Adyela Security Headers"
  description = "Security headers for Adyela"
  kind     = "zone"
  phase    = "http_response_headers_transform"

  rules {
    action = "rewrite"
    expression = "true"
    description = "Add security headers"
    enabled = true
    action_parameters {
      headers {
        name      = "X-Frame-Options"
        operation = "set"
        value     = "SAMEORIGIN"
      }
      headers {
        name      = "X-Content-Type-Options"
        operation = "set"
        value     = "nosniff"
      }
      headers {
        name      = "X-XSS-Protection"
        operation = "set"
        value     = "1; mode=block"
      }
      headers {
        name      = "Referrer-Policy"
        operation = "set"
        value     = "strict-origin-when-cross-origin"
      }
      headers {
        name      = "Permissions-Policy"
        operation = "set"
        value     = "geolocation=(), microphone=(), camera=()"
      }
    }
  }
}

# SSL/TLS Settings
resource "cloudflare_zone_settings_override" "ssl_settings" {
  zone_id = data.cloudflare_zone.adyela.id
  settings {
    ssl = "strict"
    min_tls_version = "1.2"
    tls_1_3 = "on"
    always_use_https = "on"
  }
}

# Performance Settings
resource "cloudflare_zone_settings_override" "performance_settings" {
  zone_id = data.cloudflare_zone.adyela.id
  settings {
    brotli = "on"
    minify {
      css  = "on"
      html = "on"
      js   = "on"
    }
    rocket_loader = "on"
    mirage = "on"
    polish = "lossless"
    webp = "on"
  }
}
