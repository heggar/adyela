# 🚀 Plan Pragmático - Staging Environment

**Fecha**: 2025-10-15 **Enfoque**: Estabilidad y Testing (NO 100% HIPAA) **HIPAA
Estricto**: Solo para Production (futuro)

---

## 🎯 Filosofía

### Staging = Testing & Development

- ✅ Funcionalidad completa
- ✅ Arquitectura similar a production
- ✅ Costos optimizados
- ✅ Fácil debugging
- ⚠️ HIPAA básico (NO estricto)
- ⚠️ Datos de prueba (NO PHI real)

### Production = HIPAA 100%

- ✅ HIPAA compliance estricto
- ✅ Todos los servicios con BAA
- ✅ CMEK encryption
- ✅ VPC Service Controls
- ✅ 7 años audit logs
- ✅ Alta disponibilidad

---

## 🔧 Issues a Resolver en Staging

### Issue #1: Cloudflare (SIMPLIFICAR)

**Opción A: Mantener Cloudflare (Recomendado para staging)**

- ✅ Ya está configurado
- ✅ DNS ya apunta correctamente
- ✅ Free tier = $0 costo
- ✅ CDN funcional
- ⚠️ No HIPAA-compliant (OK para staging, NO PHI real)

**Acción**: MANTENER Cloudflare en staging, pero configurar DNS-only para API:

```hcl
# infra/modules/cloudflare/main.tf línea 33
resource "cloudflare_record" "api_staging" {
  proxied = false  # DNS-only, sin proxy
  ttl     = 300
}
```

**Opción B: Eliminar Cloudflare**

- Solo si causa problemas técnicos
- Usar Cloud CDN nativo (ya configurado como fallback)

**Para este plan**: Opción A (mantener con DNS-only en API)

---

### Issue #2: IAP (ELIMINAR)

**Problema**: IAP configurado pero no útil

- IAP es para apps internas (Google Workspace users)
- Pacientes usan Identity Platform OAuth
- Confusión innecesaria

**Solución Simple**:

```hcl
# infra/environments/staging/main.tf línea 105
iap_enabled = false
```

**Tiempo**: 2 minutos

---

### Issue #3: Monitoring (CRÍTICO)

**Problema**: NO hay alertas si el sistema falla

**Solución**: Deploy monitoring module (ya creado)

- Uptime checks cada 5 minutos
- Email alerts
- Dashboard básico

**Módulo**: `infra/modules/monitoring/` (listo para usar)

**Tiempo**: 15 minutos

---

### Issue #4: Min Instances (CONFIGURAR)

**Problema**: Hardcoded, no flexible

**Solución**: Variables para staging vs production

- Staging: min=0 (scale-to-zero = ahorro)
- Production: min=1 (always-on = performance)

**Tiempo**: 10 minutos

---

### Issue #5: Cloud Armor (OPCIONAL)

**Para Staging**: NO necesario

- Staging no tiene tráfico real
- Cloud Armor = +$7/mes
- Agregar solo si hay problemas de seguridad

**Para Production**: SÍ necesario

- OWASP Top 10 protection
- DDoS protection
- Rate limiting

**Decisión**: Posponer para production

---

## 📋 Plan de Implementación Pragmático

### PASO 1: Configurar Cloudflare DNS-only para API (5 min)

**Objetivo**: API directo a GCP, frontend puede usar CDN

```bash
cd infra/modules/cloudflare

# Editar main.tf línea 28-35
```

**Cambio**:

```hcl
resource "cloudflare_record" "api_staging" {
  zone_id = data.cloudflare_zone.adyela.id
  name    = "api.staging"
  content = var.load_balancer_ip
  type    = "A"
  proxied = false  # ✅ DNS-only (no proxy)
  ttl     = 300    # 5 minutos

  comment = "API staging - DNS only to GCP Load Balancer"
}

# Frontend puede seguir con proxy = true (CDN gratis)
resource "cloudflare_record" "staging" {
  zone_id = data.cloudflare_zone.adyela.id
  name    = "staging"
  content = var.load_balancer_ip
  type    = "A"
  proxied = true  # ✅ CDN activo para frontend
  ttl     = 1

  comment = "Frontend staging - Cloudflare CDN"
}
```

**Aplicar**:

```bash
cd ../../environments/staging
export CLOUDFLARE_API_TOKEN="tu_token"  # Solo si necesitas aplicar
terraform plan -target=module.cloudflare
terraform apply -target=module.cloudflare
```

**Validar**:

```bash
# API debe apuntar directo a GCP
dig +short api.staging.adyela.care
# Debe mostrar: 34.96.108.162

# Frontend puede estar en Cloudflare
dig +short staging.adyela.care
# Puede mostrar: 172.67.x.x o 104.21.x.x (OK)

# Verificar que API responde
curl -s https://api.staging.adyela.care/health | jq .
```

---

### PASO 2: Deshabilitar IAP (2 min)

```bash
cd infra/environments/staging

# Editar main.tf línea 105
```

**Cambio**:

```hcl
module "load_balancer" {
  source = "../../modules/load-balancer"

  # ...

  # IAP disabled - Auth via Identity Platform OAuth
  iap_enabled = false

  labels = local.labels
}
```

**Aplicar**:

```bash
terraform plan -target=module.load_balancer
terraform apply -target=module.load_balancer
```

---

### PASO 3: Deploy Monitoring (15 min)

#### 3.1 Crear variable para email

**Editar**: `infra/environments/staging/variables.tf`

Agregar al final:

```hcl
variable "alert_email" {
  description = "Email for monitoring alerts"
  type        = string
  default     = "dev@adyela.com"  # ⚠️ CAMBIAR por tu email
}
```

#### 3.2 Agregar módulo de monitoring

**Editar**: `infra/environments/staging/main.tf`

Agregar al final (antes de outputs):

```hcl
# ================================================================================
# Monitoring Module - Uptime Checks & Basic Alerts
# Cost: $0/month (first 3 uptime checks FREE)
# ================================================================================

module "monitoring" {
  source = "../../modules/monitoring"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = local.environment
  domain       = "staging.adyela.care"

  # Email alerts (cambiar en variables.tf)
  alert_email       = var.alert_email
  enable_sms_alerts = false

  labels = local.labels
}

# Output útil
output "monitoring_dashboard_url" {
  description = "Monitoring Dashboard"
  value       = module.monitoring.dashboard_url
}
```

#### 3.3 Aplicar

```bash
cd infra/environments/staging

terraform init -upgrade  # Registrar nuevo módulo
terraform plan -target=module.monitoring
terraform apply -target=module.monitoring

# Ver dashboard
terraform output monitoring_dashboard_url
```

**Resultado esperado**:

- 2 uptime checks (API: 1 min, Web: 5 min)
- 3 alert policies (downtime, errors, latency)
- Email alerts configurados
- Dashboard en GCP Console

---

### PASO 4: Variables para Min Instances (10 min)

#### 4.1 Agregar variables al módulo

**Editar**: `infra/modules/cloud-run/variables.tf`

Agregar:

```hcl
variable "min_instances" {
  description = "Minimum instances (0=scale-to-zero, 1+=always-on)"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum instances"
  type        = number
  default     = 10
}
```

#### 4.2 Usar variables en el módulo

**Editar**: `infra/modules/cloud-run/main.tf`

Cambiar líneas 14-17 (API):

```hcl
scaling {
  min_instance_count = var.min_instances
  max_instance_count = var.max_instances
}
```

Cambiar líneas 126-129 (Web):

```hcl
scaling {
  min_instance_count = var.min_instances
  max_instance_count = var.max_instances
}
```

#### 4.3 Configurar en staging

**Editar**: `infra/environments/staging/main.tf`

En módulo cloud_run, agregar:

```hcl
module "cloud_run" {
  source = "../../modules/cloud-run"

  # ... configuración existente ...

  # Staging: scale-to-zero para ahorro
  min_instances = 0
  max_instances = 2

  # ... resto ...
}
```

#### 4.4 Aplicar

```bash
cd infra/environments/staging

terraform plan
terraform apply
```

---

## ✅ Validación Rápida

### Script Simple

Crear: `scripts/validate-staging.sh`

```bash
#!/bin/bash

echo "🔍 Validación Staging Environment"
echo "=================================="
echo ""

# Test 1: API responde
echo -n "1. API health check... "
API_STATUS=$(curl -s https://api.staging.adyela.care/health | jq -r '.status' 2>/dev/null)
if [ "$API_STATUS" = "healthy" ]; then
  echo "✅ OK"
else
  echo "❌ FAIL (respuesta: $API_STATUS)"
fi

# Test 2: Web responde
echo -n "2. Web frontend... "
WEB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://staging.adyela.care)
if [ "$WEB_STATUS" = "200" ]; then
  echo "✅ OK"
else
  echo "❌ FAIL (HTTP $WEB_STATUS)"
fi

# Test 3: Monitoring configurado
echo -n "3. Uptime checks... "
UPTIME_COUNT=$(gcloud monitoring uptime list --format="value(displayName)" 2>/dev/null | wc -l)
if [ "$UPTIME_COUNT" -ge 2 ]; then
  echo "✅ OK ($UPTIME_COUNT checks)"
else
  echo "⚠️  WARN (solo $UPTIME_COUNT checks, esperado: 2)"
fi

# Test 4: IAP deshabilitado
echo -n "4. IAP disabled... "
if grep -q "iap_enabled = false" infra/environments/staging/main.tf 2>/dev/null; then
  echo "✅ OK"
else
  echo "⚠️  WARN (IAP aún habilitado)"
fi

echo ""
echo "✅ Validación completada"
echo ""
```

Hacer ejecutable y correr:

```bash
chmod +x scripts/validate-staging.sh
bash scripts/validate-staging.sh
```

---

## 💰 Costos Staging (Optimizado)

```
Cloud Run API:         $5-8/mes    (scale-to-zero)
Cloud Run Web:         $3-5/mes    (scale-to-zero)
Load Balancer:         $18-25/mes  (HTTP(S) + SSL)
VPC Connector:         $3-5/mes    (f1-micro)
Cloudflare:            $0/mes      (free tier)
Cloud Storage:         $2-5/mes    (static assets)
Firestore:             $2-3/mes    (volumen bajo)
Secret Manager:        $1-2/mes    (8 secrets)
Cloud Logging:         $2-3/mes    (30 días)
Monitoring:            $0/mes      (first 3 checks free)
Cloud Armor:           $0/mes      (no configurado)
--------------------------------
TOTAL:                 $36-56/mes
```

**Sin aumento de costo** vs actual ($34-53/mes)

---

## 🔄 Diferencias Staging vs Production (Futuro)

| Aspecto           | Staging              | Production             |
| ----------------- | -------------------- | ---------------------- |
| **DNS/CDN**       | Cloudflare (free) ✅ | Cloud CDN nativo ✅    |
| **WAF**           | Sin Cloud Armor ⚠️   | Cloud Armor (OWASP) ✅ |
| **IAP**           | Disabled ✅          | Disabled ✅            |
| **Monitoring**    | Básico (free) ✅     | Avanzado + SLO ✅      |
| **Min Instances** | 0 (scale-to-zero)    | 1 (always-on)          |
| **Max Instances** | 2                    | 10                     |
| **Encryption**    | Default              | CMEK ✅                |
| **VPC SC**        | No                   | Sí ✅                  |
| **Log Retention** | 30 días              | 7 años ✅              |
| **Backup**        | Manual               | Automático ✅          |
| **HIPAA**         | Básico ⚠️            | 100% ✅                |
| **Costo/mes**     | $36-56               | $200-500               |

---

## 📝 Checklist de Implementación

### Pre-requisitos

- [ ] Token de Cloudflare (si vas a aplicar cambios)
- [ ] Email para alertas configurado en `variables.tf`
- [ ] Terraform >= 1.5.0
- [ ] gcloud CLI autenticado

### Implementación

- [ ] **PASO 1**: Cloudflare DNS-only para API (5 min)
- [ ] **PASO 2**: Deshabilitar IAP (2 min)
- [ ] **PASO 3**: Deploy monitoring (15 min)
- [ ] **PASO 4**: Variables min_instances (10 min)

### Validación

- [ ] API responde en `https://api.staging.adyela.care/health`
- [ ] Web responde en `https://staging.adyela.care`
- [ ] Uptime checks activos (ver GCP Console)
- [ ] Email de test recibido
- [ ] Dashboard visible
- [ ] `terraform plan` sin cambios pendientes

### Post-Implementación

- [ ] Documentar cambios en git
- [ ] Commit con conventional commits
- [ ] Actualizar QUICK_VIEW.md
- [ ] Notificar al equipo

---

## 🎯 Próximos Pasos

### Corto Plazo (Esta Semana)

1. [x] Crear plan pragmático para staging ✅
2. [ ] Implementar los 4 pasos (32 minutos total)
3. [ ] Validar que todo funciona
4. [ ] Commit de cambios

### Medio Plazo (1-2 Semanas)

1. [ ] Testing completo en staging
2. [ ] Performance tuning
3. [ ] Documentar issues encontrados
4. [ ] Estabilizar staging

### Largo Plazo (1-3 Meses)

1. [ ] Planear ambiente de production
2. [ ] Diseñar arquitectura HIPAA 100%
3. [ ] Configurar CMEK, VPC-SC
4. [ ] Deploy production con compliance estricto

---

## 💡 Notas Importantes

### ✅ Para Staging

- **No necesitas** HIPAA 100% compliance
- **No uses** datos reales de pacientes (PHI)
- **Enfócate en** funcionalidad y estabilidad
- **Optimiza** costos (scale-to-zero)
- **Mantén** Cloudflare si funciona

### 🏥 Para Production (Futuro)

- **SÍ necesitas** HIPAA 100% compliance
- **Eliminar** Cloudflare (usar Cloud CDN nativo)
- **Agregar** Cloud Armor ($7/mes)
- **Habilitar** CMEK encryption
- **Configurar** VPC Service Controls
- **7 años** log retention
- **Always-on** instances (min=1)

---

## 🆘 Troubleshooting

### Si Cloudflare causa problemas

```bash
# Opción 1: Comentar módulo temporalmente
cd infra/environments/staging
# Comentar líneas 116-125 (module cloudflare)

# Opción 2: DNS directo en registrar
# Actualizar en GoDaddy (o registrar):
# staging.adyela.care → A → 34.96.108.162
# api.staging.adyela.care → A → 34.96.108.162
```

### Si monitoring falla

```bash
# Verificar módulo existe
ls -la infra/modules/monitoring/

# Verificar APIs habilitadas
gcloud services list --enabled | grep monitoring

# Habilitar si necesario
gcloud services enable monitoring.googleapis.com
```

### Si terraform falla

```bash
# Limpiar cache
rm -rf .terraform .terraform.lock.hcl

# Re-inicializar
terraform init -upgrade

# Ver estado
terraform state list
```

---

## 📚 Referencias

- **Monitoring Module**: `infra/modules/monitoring/`
- **Cloud Run Module**: `infra/modules/cloud-run/`
- **Load Balancer Module**: `infra/modules/load-balancer/`
- **Staging Config**: `infra/environments/staging/main.tf`

---

**Estado**: 🟢 LISTO PARA IMPLEMENTAR **Tiempo Total**: 32 minutos **Costo
Adicional**: $0/mes **Complejidad**: Baja ⭐⭐☆☆☆

**Última Actualización**: 2025-10-15 **Versión**: 1.0 - Pragmatic Staging Plan
