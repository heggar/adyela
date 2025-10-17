# ⚡ Resumen Ejecutivo - Plan Staging

**Fecha**: 2025-10-15
**Tiempo**: 32 minutos
**Costo**: $0 adicional

---

## 🎯 Objetivo

Estabilizar staging con monitoring básico.
**NO** necesitamos HIPAA 100% (eso es para production).

---

## 📝 4 Pasos Simples

### 1️⃣ Cloudflare DNS-only para API (5 min)

**Archivo**: `infra/modules/cloudflare/main.tf`
**Línea 33**: Cambiar `proxied = true` a `proxied = false`

```hcl
resource "cloudflare_record" "api_staging" {
  proxied = false  # DNS-only
  ttl     = 300
}
```

**Aplicar**:

```bash
cd infra/environments/staging
export CLOUDFLARE_API_TOKEN="tu_token"
terraform apply -target=module.cloudflare
```

---

### 2️⃣ Deshabilitar IAP (2 min)

**Archivo**: `infra/environments/staging/main.tf`
**Línea 105**: Cambiar `iap_enabled = true` a `false`

```hcl
iap_enabled = false
```

**Aplicar**:

```bash
terraform apply -target=module.load_balancer
```

---

### 3️⃣ Deploy Monitoring (15 min)

**Archivo**: `infra/environments/staging/variables.tf`
Agregar:

```hcl
variable "alert_email" {
  description = "Email for monitoring alerts"
  type        = string
  default     = "tu-email@ejemplo.com"  # ⚠️ CAMBIAR
}
```

**Archivo**: `infra/environments/staging/main.tf`
Agregar al final:

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = local.environment
  domain       = "staging.adyela.care"

  alert_email       = var.alert_email
  enable_sms_alerts = false

  labels = local.labels
}

output "monitoring_dashboard_url" {
  value = module.monitoring.dashboard_url
}
```

**Aplicar**:

```bash
terraform init -upgrade
terraform apply -target=module.monitoring
```

---

### 4️⃣ Variables Min Instances (10 min)

**Archivo**: `infra/modules/cloud-run/variables.tf`
Agregar:

```hcl
variable "min_instances" {
  description = "Minimum instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum instances"
  type        = number
  default     = 10
}
```

**Archivo**: `infra/modules/cloud-run/main.tf`
Cambiar líneas 14-17 y 126-129:

```hcl
scaling {
  min_instance_count = var.min_instances
  max_instance_count = var.max_instances
}
```

**Archivo**: `infra/environments/staging/main.tf`
En módulo cloud_run agregar:

```hcl
min_instances = 0
max_instances = 2
```

**Aplicar**:

```bash
terraform apply
```

---

## ✅ Validación

```bash
# API funciona
curl https://api.staging.adyela.care/health

# Web funciona
curl https://staging.adyela.care

# Monitoring activo
gcloud monitoring uptime list
```

---

## 📊 Resultado

- ✅ API directo a GCP (mejor para debugging)
- ✅ Monitoring con alertas por email
- ✅ IAP deshabilitado (más simple)
- ✅ Configuración flexible (staging vs production)
- ✅ $0 costo adicional

---

## 📚 Documentación Completa

Ver: `docs/architecture/STAGING_PRAGMATIC_PLAN.md`

---

**¿Necesitas ayuda?** Revisa el plan completo para detalles y troubleshooting.
