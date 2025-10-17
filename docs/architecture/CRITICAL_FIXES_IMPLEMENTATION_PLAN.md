# 🚨 Plan de Implementación - Correcciones Críticas

**Fecha**: 2025-10-12 **Prioridad**: 🔴 CRÍTICA **Tiempo Total Estimado**: 60-90
minutos **Impacto**: HIPAA Compliance + Patient Safety

---

## 📋 Resumen de Issues Críticos

| #   | Issue                                     | Impacto        | Tiempo | Prioridad |
| --- | ----------------------------------------- | -------------- | ------ | --------- |
| 1   | Cloudflare Proxy en API (HIPAA violation) | 🔴 BLOQUEANTE  | 15 min | CRÍTICA   |
| 2   | No hay Uptime Monitoring                  | 🔴 BLOQUEANTE  | 30 min | CRÍTICA   |
| 3   | IAP Configuration                         | ⚠️ Confusión   | 10 min | ALTA      |
| 4   | Production Settings                       | ⚠️ Performance | 5 min  | ALTA      |

---

## 🔴 ISSUE #1: Cloudflare Proxy en API (HIPAA Violation)

### Problema Detectado

**Archivo**: `infra/modules/cloudflare/main.tf` **Líneas 28-35**:

```hcl
resource "cloudflare_record" "api_staging" {
  zone_id = data.cloudflare_zone.adyela.id
  name    = "api.staging"
  content = var.load_balancer_ip
  type    = "A"
  proxied = true  # ❌ PROBLEMA: PHI pasando por Cloudflare (NO HIPAA)
  ttl     = 1
}
```

### ¿Por qué es Crítico?

1. **HIPAA Violation**: Cloudflare NO firma BAA (Business Associate Agreement)
2. **PHI Data Exposure**: Requests del API contienen Protected Health
   Information
3. **Compliance Risk**: Viola §164.308(b)(1) - Business Associate Requirements

### Solución

#### Opción A: DNS Only para API (Recomendada) ✅

**Modificar**: `infra/modules/cloudflare/main.tf`

```hcl
# DNS Records
resource "cloudflare_record" "staging" {
  zone_id = data.cloudflare_zone.adyela.id
  name    = "staging"
  content = var.load_balancer_ip
  type    = "A"
  proxied = true  # ✅ OK: Frontend (HTML/CSS/JS) no contiene PHI
  ttl     = 1

  comment = "Frontend application - Cloudflare CDN enabled (no PHI)"
}

resource "cloudflare_record" "api_staging" {
  zone_id = data.cloudflare_zone.adyela.id
  name    = "api.staging"
  content = var.load_balancer_ip
  type    = "A"
  proxied = false  # ✅ CORRECCIÓN: DNS only - tráfico directo a GCP (HIPAA-compliant)
  ttl     = 300    # 5 minutos (recomendado para DNS only)

  comment = "API endpoint - Direct to GCP (HIPAA-compliant, no Cloudflare proxy)"
}
```

**Justificación**:

- ✅ Frontend (staging.adyela.care) → Cloudflare OK (HTML/CSS/JS no es PHI)
- ✅ API (api.staging.adyela.care) → Directo a GCP (PHI protegido)
- ✅ HIPAA-compliant: PHI nunca pasa por Cloudflare
- ✅ Ahorro de costos: Cloudflare free tier sigue útil para frontend

#### Opción B: Eliminar Cloudflare Completamente (Más segura pero más cara)

**Si quieres máxima seguridad**:

```hcl
# Deshabilitar proxy para AMBOS dominios
resource "cloudflare_record" "staging" {
  proxied = false  # DNS only
  ttl     = 300
}

resource "cloudflare_record" "api_staging" {
  proxied = false  # DNS only
  ttl     = 300
}
```

**Luego habilitar Cloud CDN** (costo adicional):

```hcl
# En load-balancer/main.tf
resource "google_compute_backend_service" "web_backend" {
  enable_cdn = true  # +$8-12/mes pero HIPAA-compliant

  cdn_policy {
    cache_mode  = "CACHE_ALL_STATIC"
    default_ttl = 3600
  }
}
```

**Comparación**:

| Opción                        | Costo/mes | HIPAA | Complejidad | Recomendación      |
| ----------------------------- | --------- | ----- | ----------- | ------------------ |
| A: DNS only API               | $0        | ✅ Sí | Baja        | ⭐ **RECOMENDADA** |
| B: Sin Cloudflare + Cloud CDN | +$8-12    | ✅ Sí | Media       | Si budget permite  |

### Pasos de Implementación (Opción A)

#### 1. Preparar información de Cloudflare

Necesitas tener configurado:

```bash
# Variable de entorno para Terraform
export CLOUDFLARE_API_TOKEN="tu_token_aqui"

# O crear archivo de secrets
cat > cloudflare.tfvars <<EOF
# No incluir en Git
cloudflare_api_token = "tu_token_cloudflare"
EOF
```

**¿Cómo obtener el API Token?**

1. Login en Cloudflare Dashboard: https://dash.cloudflare.com
2. My Profile → API Tokens → Create Token
3. Usar template "Edit zone DNS"
4. Zone Resources: Include → Specific zone → adyela.care
5. Copy token

#### 2. Modificar Terraform

```bash
cd /Users/hevergonzalezgarcia/TFM\ Agentes\ IA/CLAUDE/adyela/infra/modules/cloudflare

# Backup del archivo actual
cp main.tf main.tf.backup.$(date +%Y%m%d)

# Aplicar cambio
# Editar línea 33: cambiar proxied = true a proxied = false
```

#### 3. Aplicar cambios

```bash
cd /Users/hevergonzalezgarcia/TFM\ Agentes\ IA/CLAUDE/adyela/infra/environments/staging

# Verificar cambios
terraform plan -target=module.cloudflare

# Output esperado:
# ~ resource "cloudflare_record" "api_staging" {
#     ~ proxied = true -> false
#     ~ ttl     = 1 -> 300
#   }

# Aplicar cambio
terraform apply -target=module.cloudflare
```

#### 4. Validar DNS

```bash
# Esperar propagación (30-60 segundos)
sleep 60

# Verificar que ya no pasa por Cloudflare
dig +short api.staging.adyela.care
# Debe retornar: 34.96.108.162 (directo)

# Verificar que frontend sigue en Cloudflare
dig +short staging.adyela.care
# Debe retornar: 172.67.x.x o 104.21.x.x (Cloudflare)

# Probar API
curl -s https://api.staging.adyela.care/health | jq .
# Debe retornar: {"status":"healthy","version":"0.1.0"}
```

#### 5. Verificar Headers

```bash
# API - No debe tener headers de Cloudflare
curl -I https://api.staging.adyela.care/health | grep -i "cf-\|cloudflare"
# Debe estar VACÍO (sin headers de Cloudflare)

# Frontend - Debe tener headers de Cloudflare
curl -I https://staging.adyela.care | grep -i "cf-\|server"
# Debe mostrar: server: cloudflare
```

### Checklist de Validación

- [ ] ✅ API DNS apunta directo a GCP (34.96.108.162)
- [ ] ✅ API no tiene headers de Cloudflare
- [ ] ✅ API responde correctamente
- [ ] ✅ Frontend sigue en Cloudflare
- [ ] ✅ Frontend carga correctamente
- [ ] ✅ HIPAA compliance restaurado

---

## 🔴 ISSUE #2: Uptime Monitoring y Alertas

### Problema Detectado

**No existe** configuración de:

- Uptime checks externos
- Alertas de disponibilidad
- SLOs (Service Level Objectives)
- Dashboards de monitoreo

**Riesgo**: Si el sistema cae, nadie se entera → Patient safety risk

### Solución

#### Crear Módulo de Monitoring

**Nuevo archivo**: `infra/modules/monitoring/main.tf`

```hcl
# Monitoring Module - Uptime Checks & Alerts
# Cost: $0.30/check/month (primeros 3 uptime checks FREE)

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ================================================================================
# UPTIME CHECKS
# ================================================================================

# Uptime Check - API Health Endpoint
resource "google_monitoring_uptime_check_config" "api_health" {
  display_name = "${var.project_name}-${var.environment}-api-uptime"
  timeout      = "10s"
  period       = "60s" # Check every 1 minute

  http_check {
    path           = "/health"
    port           = "443"
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = "api.${var.domain}"
    }
  }

  # Check from multiple regions for redundancy
  selected_regions = [
    "USA",
    "EUROPE",
    "SOUTH_AMERICA"
  ]

  # Alert policy attachment
  checker_type = "STATIC_IP_CHECKERS"
}

# Uptime Check - Frontend Homepage
resource "google_monitoring_uptime_check_config" "web_homepage" {
  display_name = "${var.project_name}-${var.environment}-web-uptime"
  timeout      = "10s"
  period       = "300s" # Check every 5 minutes (less critical than API)

  http_check {
    path           = "/"
    port           = "443"
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.domain
    }
  }

  selected_regions = [
    "USA",
    "EUROPE"
  ]

  checker_type = "STATIC_IP_CHECKERS"
}

# ================================================================================
# NOTIFICATION CHANNELS
# ================================================================================

# Email Notification Channel
resource "google_monitoring_notification_channel" "email_alerts" {
  display_name = "${var.project_name}-${var.environment}-email-alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }

  enabled = true
}

# SMS Notification Channel (optional - requires verification)
resource "google_monitoring_notification_channel" "sms_critical" {
  count = var.enable_sms_alerts ? 1 : 0

  display_name = "${var.project_name}-${var.environment}-sms-critical"
  type         = "sms"

  labels = {
    number = var.alert_phone_number
  }

  enabled = true
}

# ================================================================================
# ALERT POLICIES
# ================================================================================

# Alert Policy - API Downtime
resource "google_monitoring_alert_policy" "api_downtime" {
  display_name = "${var.project_name}-${var.environment}-api-downtime"
  combiner     = "OR"

  conditions {
    display_name = "API Health Check Failure"

    condition_threshold {
      filter          = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.labels.host=\"api.${var.domain}\""
      duration        = "60s" # Alert after 1 minute of failures
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_alerts.id],
    var.enable_sms_alerts ? [google_monitoring_notification_channel.sms_critical[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s" # Auto-close after 30 minutes of recovery
  }

  documentation {
    content   = <<-EOT
      ## API Health Check Failure

      **Service**: ${var.project_name} API (${var.environment})
      **Endpoint**: https://api.${var.domain}/health

      ### Immediate Actions:
      1. Check API logs: `gcloud logging read "resource.labels.service_name=adyela-api-${var.environment}" --limit=50`
      2. Check Cloud Run status: `gcloud run services describe adyela-api-${var.environment} --region=us-central1`
      3. Verify Load Balancer health: GCP Console → Network Services → Load Balancing

      ### Escalation:
      - If downtime >5 minutes: Page on-call engineer
      - If downtime >15 minutes: Notify leadership

      ### Recovery:
      - Check recent deployments: `gcloud run revisions list --service=adyela-api-${var.environment}`
      - Rollback if needed: `gcloud run services update-traffic adyela-api-${var.environment} --to-revisions=PREVIOUS_REVISION=100`
    EOT
    mime_type = "text/markdown"
  }

  enabled = true
}

# Alert Policy - High Error Rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "${var.project_name}-${var.environment}-high-error-rate"
  combiner     = "OR"

  conditions {
    display_name = "API Error Rate >1%"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_count\"",
        "metric.labels.response_code_class!=\"2xx\""
      ])

      duration        = "300s" # 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = 0.01 # 1% error rate

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.service_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  documentation {
    content   = <<-EOT
      ## High API Error Rate Detected

      The API is returning >1% errors in the last 5 minutes.

      ### Check:
      1. Recent error logs: `gcloud logging read "resource.labels.service_name=adyela-api-${var.environment} AND severity>=ERROR" --limit=20`
      2. Error distribution by endpoint
      3. Recent code deployments
    EOT
    mime_type = "text/markdown"
  }

  enabled = true
}

# Alert Policy - High Latency
resource "google_monitoring_alert_policy" "high_latency" {
  display_name = "${var.project_name}-${var.environment}-high-latency"
  combiner     = "OR"

  conditions {
    display_name = "API Latency P95 >1000ms"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_latencies\""
      ])

      duration        = "300s" # 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = 1000 # 1000ms = 1 second

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.service_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  documentation {
    content   = "API latency P95 is above 1 second. Check Cloud Run metrics and database performance."
    mime_type = "text/plain"
  }

  enabled = true
}

# ================================================================================
# SLO (Service Level Objectives)
# ================================================================================

# SLO - 99.9% Availability
resource "google_monitoring_slo" "api_availability" {
  service      = google_monitoring_custom_service.api_service.service_id
  slo_id       = "api-availability-slo"
  display_name = "API Availability SLO (99.9%)"

  goal                = 0.999 # 99.9%
  rolling_period_days = 30    # 30-day rolling window

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_count\""
      ])

      good_service_filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_count\"",
        "metric.labels.response_code_class=\"2xx\""
      ])
    }
  }
}

# Custom Service Definition
resource "google_monitoring_custom_service" "api_service" {
  service_id   = "adyela-api-${var.environment}"
  display_name = "Adyela API (${var.environment})"

  telemetry {
    resource_name = "//run.googleapis.com/projects/${var.project_id}/locations/us-central1/services/adyela-api-${var.environment}"
  }
}

# ================================================================================
# DASHBOARD
# ================================================================================

resource "google_monitoring_dashboard" "main_dashboard" {
  dashboard_json = jsonencode({
    displayName = "${var.project_name} ${var.environment} - Main Dashboard"

    mosaicLayout = {
      columns = 12

      tiles = [
        # Tile 1: API Request Rate
        {
          width  = 6
          height = 4
          widget = {
            title = "API Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },

        # Tile 2: Error Rate
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "Error Rate (%)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class!=\"2xx\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },

        # Tile 3: Latency Percentiles
        {
          width  = 12
          height = 4
          yPos   = 4
          widget = {
            title = "Request Latency (P50, P95, P99)"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_50"
                      }
                    }
                  }
                  plotType = "LINE"
                  targetAxis = "Y1"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_95"
                      }
                    }
                  }
                  plotType = "LINE"
                  targetAxis = "Y1"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_99"
                      }
                    }
                  }
                  plotType = "LINE"
                  targetAxis = "Y1"
                }
              ]
            }
          }
        }
      ]
    }
  })
}
```

**Nuevo archivo**: `infra/modules/monitoring/variables.tf`

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "domain" {
  description = "Primary domain for monitoring"
  type        = string
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "enable_sms_alerts" {
  description = "Enable SMS alerts for critical issues"
  type        = bool
  default     = false
}

variable "alert_phone_number" {
  description = "Phone number for SMS alerts (E.164 format: +1234567890)"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
```

**Nuevo archivo**: `infra/modules/monitoring/outputs.tf`

```hcl
output "api_uptime_check_id" {
  description = "ID of the API uptime check"
  value       = google_monitoring_uptime_check_config.api_health.id
}

output "web_uptime_check_id" {
  description = "ID of the web uptime check"
  value       = google_monitoring_uptime_check_config.web_homepage.id
}

output "dashboard_url" {
  description = "URL to the monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.main_dashboard.id}?project=${var.project_id}"
}

output "slo_name" {
  description = "Name of the SLO"
  value       = google_monitoring_slo.api_availability.name
}
```

#### Integrar Módulo en Staging

**Modificar**: `infra/environments/staging/main.tf`

Agregar al final del archivo:

```hcl
# ================================================================================
# Monitoring Module - Uptime Checks & Alerts
# Cost: $0/month (primeros 3 uptime checks FREE)
# ================================================================================

module "monitoring" {
  source = "../../modules/monitoring"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = local.environment
  domain       = "staging.adyela.care"

  # Alert configuration
  alert_email   = "ops@adyela.com" # ⚠️ CAMBIAR por email real
  enable_sms_alerts = false        # Cambiar a true para SMS (requiere verificación)
  # alert_phone_number = "+1234567890" # Solo si enable_sms_alerts = true

  labels = local.labels
}

# Output URLs útiles
output "monitoring_dashboard_url" {
  description = "URL del dashboard de monitoring"
  value       = module.monitoring.dashboard_url
}
```

#### Pasos de Implementación

```bash
cd /Users/hevergonzalezgarcia/TFM\ Agentes\ IA/CLAUDE/adyela

# 1. Crear directorio del módulo
mkdir -p infra/modules/monitoring

# 2. Crear archivos del módulo (copiar contenido de arriba)
# main.tf, variables.tf, outputs.tf

# 3. Modificar staging/main.tf para incluir módulo

# 4. Aplicar cambios
cd infra/environments/staging

terraform init -upgrade  # Para registrar nuevo módulo
terraform plan -target=module.monitoring
terraform apply -target=module.monitoring

# 5. Verificar en GCP Console
# https://console.cloud.google.com/monitoring/uptime
```

### Información Necesaria

Para configurar el monitoring, necesito que proporciones:

```bash
# Email para alertas
ALERT_EMAIL="ops@adyela.com"  # ⚠️ CAMBIAR

# (Opcional) Teléfono para SMS críticos
ALERT_PHONE="+1234567890"  # Formato E.164
```

### Checklist de Validación

- [ ] ✅ Uptime check para API (cada 1 minuto)
- [ ] ✅ Uptime check para Frontend (cada 5 minutos)
- [ ] ✅ Email notification channel configurado
- [ ] ✅ Alert policy para downtime (<1 min)
- [ ] ✅ Alert policy para error rate (>1%)
- [ ] ✅ Alert policy para latency (>1s)
- [ ] ✅ SLO de 99.9% availability
- [ ] ✅ Dashboard con métricas clave
- [ ] ✅ Recibir email de test

---

## ⚠️ ISSUE #3: IAP Configuration

### Problema Detectado

**Archivo**: `infra/modules/load-balancer/main.tf` **Línea 265**: "IAP
configuration will be done manually"

**Análisis**: IAP parece estar mencionado pero NO habilitado en Terraform

### Decisión

**NO habilitar IAP** porque:

1. IAP es para aplicaciones **internas** (Google Workspace)
2. Los **pacientes** no tienen cuentas de Google
3. Ya tienes **OAuth** (Google/Microsoft) en Identity Platform
4. **Confusión arquitectural** tener dos sistemas de auth

### Solución

**Confirmar que IAP está deshabilitado** y documentarlo:

**Modificar**: `infra/environments/staging/main.tf`

```hcl
module "load_balancer" {
  source = "../../modules/load-balancer"

  # ...

  # IAP configuration
  iap_enabled = false  # ✅ Correcto: OAuth via Identity Platform, no IAP

  # ⚠️ NOTA: NO habilitar IAP para usuarios finales (pacientes)
  # IAP está diseñado para aplicaciones internas con cuentas Google Workspace
  # La autenticación de usuarios se hace via Identity Platform OAuth
}
```

**Tiempo**: 5 minutos (solo documentación)

---

## ⚠️ ISSUE #4: Production Settings (Min Instances)

### Problema

Cloud Run con `min_instances = 0` causa cold starts de 2-5 segundos

### Solución

**Modificar**: `infra/modules/cloud-run/main.tf`

Agregar soporte para min_instances:

```hcl
resource "google_cloud_run_v2_service" "api" {
  # ...

  template {
    scaling {
      min_instance_count = var.min_instances  # ⚠️ Nuevo parámetro
      max_instance_count = var.max_instances
    }
  }
}
```

**Modificar**: `infra/modules/cloud-run/variables.tf`

```hcl
variable "min_instances" {
  description = "Minimum number of instances (0 for scale-to-zero, 1+ for always-on)"
  type        = number
  default     = 0  # Default: scale-to-zero para staging
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}
```

**Modificar**: `infra/environments/staging/main.tf`

```hcl
module "cloud_run" {
  source = "../../modules/cloud-run"

  # Staging: scale-to-zero para ahorro
  min_instances = 0
  max_instances = 2

  # ...
}
```

**Crear**: `infra/environments/production/main.tf` (para futuro)

```hcl
module "cloud_run" {
  source = "../../modules/cloud-run"

  # Production: always-on para evitar cold starts
  min_instances = 1  # ✅ Siempre 1 instancia mínimo
  max_instances = 10

  # ...
}
```

**Tiempo**: 5 minutos

---

## 📋 Resumen de Archivos a Modificar/Crear

### Archivos a Modificar

1. `infra/modules/cloudflare/main.tf`
   - Línea 33: `proxied = true` → `proxied = false`
   - Línea 34: `ttl = 1` → `ttl = 300`

2. `infra/modules/cloud-run/main.tf`
   - Agregar soporte para `min_instances`

3. `infra/modules/cloud-run/variables.tf`
   - Agregar variables `min_instances` y `max_instances`

4. `infra/environments/staging/main.tf`
   - Agregar módulo `monitoring`
   - Configurar `min_instances` en cloud_run
   - Documentar `iap_enabled = false`

### Archivos a Crear

5. `infra/modules/monitoring/main.tf` (nuevo)
6. `infra/modules/monitoring/variables.tf` (nuevo)
7. `infra/modules/monitoring/outputs.tf` (nuevo)

### Scripts de Validación

8. `scripts/validate-critical-fixes.sh` (nuevo)

---

## ⏱️ Timeline de Implementación

```
Hora 1 (0-60 min): HIPAA Fix
├─ 0-15 min: Modificar Cloudflare Terraform
├─ 15-30 min: Aplicar cambios y validar DNS
├─ 30-45 min: Verificar headers y compliance
└─ 45-60 min: Documentar y commit

Hora 2 (60-120 min): Monitoring
├─ 60-75 min: Crear módulo monitoring
├─ 75-90 min: Integrar en staging
├─ 90-105 min: Aplicar Terraform
└─ 105-120 min: Configurar email y validar alertas

Completar (120-150 min): Ajustes finales
├─ 120-125 min: Documentar IAP disabled
├─ 125-130 min: Configurar min_instances
├─ 130-140 min: Testing completo
└─ 140-150 min: Commit y documentación final
```

**Total**: 2-2.5 horas

---

## 📞 Información que Necesito de Ti

### 1. Cloudflare API Token

```bash
# Cómo obtener:
# 1. https://dash.cloudflare.com/profile/api-tokens
# 2. Create Token → Edit zone DNS
# 3. Zone: adyela.care
# 4. Copy token

export CLOUDFLARE_API_TOKEN="tu_token_aqui"
```

### 2. Email para Alertas

```bash
# Email donde quieres recibir alertas
ALERT_EMAIL="ops@adyela.com"  # ⚠️ Proporcionar
```

### 3. (Opcional) Teléfono para SMS

```bash
# Solo si quieres SMS para alertas críticas
ALERT_PHONE="+1234567890"  # Formato E.164
```

---

## ✅ Criterios de Éxito Final

### HIPAA Compliance

- [ ] ✅ API DNS apunta directo a GCP (no Cloudflare)
- [ ] ✅ No headers de Cloudflare en API
- [ ] ✅ PHI nunca pasa por Cloudflare
- [ ] ✅ Documentado en arquitectura

### Monitoring Operacional

- [ ] ✅ Uptime checks funcionando
- [ ] ✅ Alertas de email funcionando
- [ ] ✅ Dashboard visible en GCP Console
- [ ] ✅ SLO de 99.9% configurado

### Configuration Correcta

- [ ] ✅ IAP documentado como disabled
- [ ] ✅ Min instances configurado
- [ ] ✅ Terraform state limpio
- [ ] ✅ Documentación actualizada

---

**Última Actualización**: 2025-10-12 **Estado**: 📋 Plan Completo | ⏳ Esperando
Información **Próximo Paso**: Proporcionar Cloudflare API Token + Email para
alertas
