# 🏗️ Arquitectura GCP Adyela - Vista Rápida

## 📊 Diagrama Simplificado (ASCII) - ACTUALIZADO 2024

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                          👥 USUARIOS & ACCESO                                     │
│  🔵 Pacientes  |  🟢 Doctores  |  🟠 Admins  |  🔴 Ops Team  |  🟣 Developers    │
└──────────────────────────────────────────────────────────────────────────────────┘
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                    🌐 CLOUDFLARE CDN + EDGE SECURITY (RECOMENDADO)               │
│  Cloudflare DNS  →  Cloudflare CDN  →  WAF  →  Page Rules  →  Workers           │
│  SSL/TLS 1.3  →  DDoS Protection  →  Bot Management  →  Rate Limiting           │
└──────────────────────────────────────────────────────────────────────────────────┘
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                          ⚖️ GOOGLE CLOUD LOAD BALANCER                           │
│  Global IP: 34.96.108.162  →  SSL Certificate  →  Backend Services              │
│  Health Checks  →  Session Affinity  →  Logging  →  Monitoring                  │
└──────────────────────────────────────────────────────────────────────────────────┘
                                      ▼
┌───────────────────────────────────┬──────────────────────────────────────────────┐
│    🟨 STAGING ENVIRONMENT         │    🟩 PRODUCTION ENVIRONMENT (HIPAA)         │
│    (Scale-to-zero | $33-51/mes)   │    (Always-on | $200-500/mes)                │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│  ⚙️ COMPUTE SERVICES              │  ⚙️ COMPUTE SERVICES (HA)                   │
│  • Cloud Run API (0-2) ✅         │  • Cloud Run API (1-10 instances)            │
│  • Cloud Run Web (0-2) ✅         │  • Cloud Run Web (2-10 instances)            │
│  • Cloud Functions Gen2 ⏳         │  • Cloud Functions Gen2 + HA                 │
│  • Cloud Scheduler ⏳              │  • Cloud Scheduler + Backup                  │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│  💾 DATA & STORAGE                │  💾 DATA & STORAGE (CMEK Encrypted)         │
│  • Firestore Multi-tenant ✅      │  • Firestore Multi-tenant + CMEK             │
│  • Cloud Storage CDN ✅           │  • Cloud Storage (7-year retention)          │
│  • Secret Manager ✅              │  • Secret Manager + Rotation + CMEK          │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│  🔄 ASYNC PROCESSING              │  🔄 ASYNC PROCESSING + DLQ                  │
│  • Pub/Sub Event Bus ⏳           │  • Pub/Sub + Dead Letter Queue               │
│  • Cloud Tasks Queue ⏳           │  • Cloud Tasks + Retry Logic                 │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│  📊 OBSERVABILITY                 │  📊 OBSERVABILITY + SLO                     │
│  • Cloud Logging (30 days) ✅     │  • Cloud Logging (7 years - HIPAA)           │
│  • Cloud Monitoring ✅            │  • Cloud Monitoring + SLO Alerts             │
│  • Cloud Trace (APM) ⏳           │  • Cloud Trace + Advanced APM                │
│  • Error Reporting ⏳             │  • Error Reporting + Uptime Checks           │
└───────────────────────────────────┴──────────────────────────────────────────────┘
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                    🟪 SHARED SERVICES & CI/CD                                     │
│  Cloud Build  |  Artifact Registry  |  Cloud KMS (CMEK)  |  VPC Network          │
│  Cloud IAM    |  Security Command Center  |  VPC Service Controls                │
│  GitHub Actions  |  Terraform (IaC)  |  Task Master AI                           │
└──────────────────────────────────────────────────────────────────────────────────┘

📍 Region: us-central1 (Iowa, USA)
🌎 Multi-zone Availability + Cloudflare Global Edge
🔒 HIPAA Compliant + Cloudflare Security
💰 Costo Optimizado: $33-51/mes (20% reducción con Cloudflare)
```

---

## 🚀 Estado Actual de Despliegue - ACTUALIZADO 2024

### ✅ Staging Environment (85% COMPLETADO)

| Componente            | Estado       | Detalles                                                          | Costo/Mes |
| --------------------- | ------------ | ----------------------------------------------------------------- | --------- |
| **Cloud Run API**     | ✅ ACTIVO    | `adyela-api-staging` - Ingress: internal, Port: 8000              | $5-8      |
| **Cloud Run Web**     | ✅ ACTIVO    | `adyela-web-staging` - Ingress: internal-and-cloud-load-balancing | $3-5      |
| **VPC Network**       | ✅ ACTIVO    | `adyela-staging-vpc` (CUSTOM mode)                                | $0        |
| **VPC Connector**     | ✅ ACTIVO    | `adyela-staging-connector` (READY)                                | $3-5      |
| **Load Balancer**     | ✅ ACTIVO    | IP: `34.96.108.162` - SSL: ACTIVE                                 | $18-25    |
| **Cloud Storage CDN** | ✅ ACTIVO    | `adyela-staging-static-assets` - CDN habilitado                   | $2-5      |
| **SSL Certificate**   | ✅ ACTIVO    | `staging.adyela.care` - Google Managed                            | $0        |
| **Service Account**   | ✅ ACTIVO    | `adyela-staging-hipaa` - HIPAA roles                              | $0        |
| **Secret Manager**    | ✅ ACTIVO    | 8 secrets HIPAA configurados                                      | $1-2      |
| **Firebase Project**  | ✅ ACTIVO    | `adyela-staging` (717907307897)                                   | $2-3      |
| **Cloud Logging**     | ✅ ACTIVO    | Logs de Cloud Run visibles                                        | $2-3      |
| **Cloud Functions**   | ⏳ PENDIENTE | Gen2 serverless                                                   | $0        |
| **Cloud Scheduler**   | ⏳ PENDIENTE | Cron jobs                                                         | $0        |
| **Pub/Sub**           | ⏳ PENDIENTE | Event bus                                                         | $0        |
| **Cloud Tasks**       | ⏳ PENDIENTE | Cola de tareas                                                    | $0        |
| **Cloud Monitoring**  | ⏳ PENDIENTE | Métricas avanzadas                                                | $0        |
| **Cloud Trace**       | ⏳ PENDIENTE | APM avanzado                                                      | $0        |
| **Error Reporting**   | ⏳ PENDIENTE | Errores automáticos                                               | $0        |

**Costo Total Actual**: $34-53/mes  
**Cobertura Terraform**: 85% (Infraestructura) + 15% (Manual)

### 🔗 URLs Activas

- **Load Balancer**: `https://34.96.108.162` (HTTP/HTTPS)
- **Dominio Principal**: `https://staging.adyela.care` ✅ ACTIVO
- **API Subdomain**: `https://api.staging.adyela.care` ✅ ACTIVO
- **Cloud Run API**: `https://adyela-api-staging-717907307897.us-central1.run.app` (internal)
- **Cloud Run Web**: `https://adyela-web-staging-717907307897.us-central1.run.app` (internal)
- **CDN Assets**: `https://staging.adyela.care/assets/*` → Cloud Storage CDN

### 🔐 Configuración de Seguridad

- **Acceso Directo**: ❌ BLOQUEADO (ingress control)
- **VPC Egress**: `private-ranges-only`
- **Service Account**: HIPAA-compliant
- **Secrets**: 8 secrets encriptados
- **SSL/TLS**: 1.3 activo
- **Load Balancer**: Solo punto de entrada público

---

## 🎯 Componentes Principales

### 🌐 Capa de Entrada

| Servicio              | Función                  | Configuración            |
| --------------------- | ------------------------ | ------------------------ |
| **Cloud DNS**         | Resolución de dominios   | `adyela.care`            |
| **Cloud CDN**         | Cache global             | Edge locations worldwide |
| **Load Balancer**     | Distribución de tráfico  | HTTPS/TLS 1.3            |
| **Cloud Armor**       | Firewall de aplicaciones | WAF + DDoS protection    |
| **API Gateway**       | Gestión de APIs          | OpenAPI + JWT validation |
| **Identity Platform** | Autenticación            | JWT + MFA obligatorio    |

---

### 🟨 Staging Environment ✅ DESPLEGADO

#### ⚙️ Compute (ACTIVO)

- **Cloud Run API**: FastAPI, 0-1 instancias (scale-to-zero)
  - URL: `https://adyela-api-staging-717907307897.us-central1.run.app`
  - Ingress: `internal` (solo Load Balancer)
  - VPC Connector: `adyela-staging-connector`
- **Cloud Run Web**: React PWA, 0-2 instancias
  - URL: `https://adyela-web-staging-717907307897.us-central1.run.app`
  - Ingress: `internal-and-cloud-load-balancing`
  - VPC Connector: `adyela-staging-connector`
- **Cloud Functions**: Gen2, serverless (pendiente)
- **Cloud Scheduler**: Cron jobs, mantenimiento (pendiente)

#### 🌐 Networking (ACTIVO)

- **VPC Network**: `adyela-staging-vpc` (CUSTOM mode)
- **VPC Access Connector**: `adyela-staging-connector` (READY)
  - Subnet: `adyela-staging-connector-subnet`
  - Machine Type: f1-micro (2-3 instances)
- **Load Balancer**: HTTP(S) Global
  - IP: `34.96.108.162`
  - SSL Certificate: `adyela-staging-web-ssl-cert` (ACTIVE)
  - Domain: `staging.adyela.care` (configurado)

#### 💾 Data (ACTIVO)

- **Firebase Project**: `adyela-staging` (717907307897)
- **Firestore**: Multi-tenant, Native mode (configurado)
- **Cloud Storage**: Documentos, backups (pendiente)
- **Secret Manager**: 8 secrets HIPAA
  - `api-secret-key`, `jwt-secret-key`, `encryption-key`
  - `firebase-admin-key`, `database-connection-string`
  - `external-api-keys`, `smtp-credentials`

#### 🔐 Security (ACTIVO)

- **Service Account**: `adyela-staging-hipaa@adyela-staging.iam.gserviceaccount.com`
- **IAM Roles**: HIPAA-compliant roles asignados
- **VPC Egress**: `private-ranges-only`
- **Ingress Control**: Bloqueado acceso directo

#### 🔄 Async (PENDIENTE)

- **Pub/Sub**: Event bus (pendiente)
- **Cloud Tasks**: Cola de tareas (pendiente)

#### 📊 Monitoring (ACTIVO)

- **Cloud Logging**: Activo (logs de Cloud Run visibles)
- **Cloud Monitoring**: Métricas básicas (pendiente configuración avanzada)
- **Trace**: APM básico (pendiente)
- **Error Reporting**: Errores automáticos (pendiente)

**Estado**: ✅ 80% DESPLEGADO | **Costo Actual**: ~$15-25/mes

---

### 🟩 Production Environment (HIPAA Compliant)

#### ⚙️ Compute (High Availability)

- **Cloud Run API**: FastAPI, 1-10 instancias, always-on
- **Cloud Run Web**: React PWA, 2-10 instancias, always-on
- **Cloud Functions**: Gen2 + HA, auto-scaling
- **Cloud Scheduler**: Con backups automáticos

#### 💾 Data (CMEK Encrypted)

- **Firestore**: Multi-tenant + CMEK encryption
- **Cloud Storage**: Retención 7 años (HIPAA), CMEK
- **Secret Manager**: Con rotación automática + CMEK

#### 🔄 Async (Resilient)

- **Pub/Sub**: Con Dead Letter Queue (DLQ)
- **Cloud Tasks**: Con retry logic avanzado

#### 📊 Monitoring (SLO-based)

- **Logging**: Retención 7 años (HIPAA compliance)
- **Monitoring**: Alertas SLO + on-call
- **Trace**: APM avanzado
- **Error Reporting**: Con correlación
- **Uptime Checks**: Multi-region

#### 🔒 Security

- **VPC Service Controls**: Perímetro de datos
- **CMEK**: Todas las claves encriptadas
- **Audit Logs**: 7 años de retención
- **Access Controls**: IAM granular

**Costo Estimado**: $200-500/mes

---

### 🟪 Shared Services

#### 🚀 CI/CD

- **Cloud Build**: Pipelines automáticos
- **Artifact Registry**: Imágenes Docker
- **GitHub Actions**: Workflows de desarrollo

#### 🔐 Security

- **Cloud KMS**: Gestión de claves CMEK
- **Security Command Center**: Análisis de seguridad
- **VPC Service Controls**: Control de perímetro

#### 📡 Infrastructure

- **VPC Network**: Conectividad serverless
- **Cloud IAM**: Control de acceso
- **Terraform**: Infrastructure as Code
- **Task Master AI**: Gestión de tareas

---

## 📈 Características Clave

### ✅ Staging (80% DESPLEGADO)

- ✓ Scale-to-zero (ahorro de costos)
- ✓ Ambiente de pruebas completo
- ✓ Misma arquitectura que producción
- ✓ Retención corta de logs (30 días)
- ✓ VPC y networking configurado
- ✓ Load Balancer con SSL activo
- ✓ Service Account HIPAA configurado
- ✓ 8 secrets en Secret Manager
- ✓ Acceso directo bloqueado (seguridad)
- ✓ Costo actual ($15-25/mes)

### ✅ Production

- ✓ HIPAA Compliant al 100%
- ✓ Alta disponibilidad (99.95% SLA)
- ✓ Auto-scaling (1-10 instancias)
- ✓ CMEK encryption en todo
- ✓ Logs de auditoría (7 años)
- ✓ VPC Service Controls
- ✓ Backup automático
- ✓ Disaster Recovery

### ✅ Seguridad Multi-capa

1. **Edge**: Cloud Armor (WAF + DDoS)
2. **API**: API Gateway (rate limiting, JWT)
3. **Auth**: Identity Platform (MFA obligatorio)
4. **Network**: VPC Service Controls
5. **Data**: CMEK encryption at rest
6. **Transport**: TLS 1.3 everywhere
7. **Audit**: Comprehensive logging (7 years)

---

## 🌍 Networking & Data Flow

```
Usuario → Cloud DNS → Cloud CDN → Load Balancer → Cloud Armor
    ↓
API Gateway (rate limit, JWT validation)
    ↓
Identity Platform (MFA check)
    ↓
VPC Service Controls (perimeter check)
    ↓
┌─────────────┬──────────────┐
│  Staging    │  Production  │
│  (testing)  │  (live PHI)  │
└─────────────┴──────────────┘
    ↓               ↓
Cloud Run → Firestore (CMEK)
         → Cloud Storage (CMEK)
         → Pub/Sub → Cloud Functions
                  → Cloud Tasks
```

---

## 💰 Costos Mensuales Estimados - ACTUALIZADO 2024

### Staging: $34-53/mes (ACTUAL) → $33-51/mes (CON CLOUDFLARE)

#### Costo Actual (Google Cloud CDN)

- Cloud Run API: $5-8 (0-2 instances, VPC connector)
- Cloud Run Web: $3-5 (0-2 instances, VPC connector)
- Load Balancer: $18-25 (HTTP(S) global, SSL)
- VPC Access Connector: $3-5 (f1-micro instances)
- Cloud Storage CDN: $2-5 (static assets, CORS)
- Firestore: $2-3 (volumen bajo)
- Secret Manager: $1-2 (8 secrets)
- Cloud Logging: $2-3 (30 días)
- **Total Actual**: $34-53/mes

#### Costo Proyectado (Cloudflare CDN)

- Cloud Run API: $5-8 (sin cambios)
- Cloud Run Web: $3-5 (sin cambios)
- Load Balancer: $18-25 (sin cambios)
- VPC Access Connector: $3-5 (sin cambios)
- Cloudflare CDN: $5-8 (vs $8-12 GCP CDN) **-40%**
- Cloudflare WAF: $0 (vs $5.17 Cloud Armor) **-100%**
- Firestore: $2-3 (sin cambios)
- Secret Manager: $1-2 (sin cambios)
- Cloud Logging: $2-3 (sin cambios)
- **Total Proyectado**: $33-51/mes
- **Ahorro**: $8-9/mes (20% reducción)

### Production: $200-500/mes (HIPAA Compliant)

- Cloud Run: $80-150 (always-on, HA)
- Firestore: $30-60 (CMEK, alto volumen)
- Cloud Storage: $20-40 (7 años retención)
- Logging: $30-50 (7 años retención HIPAA)
- Monitoring: $10-20 (SLO, alertas)
- KMS (CMEK): $5-10
- VPC-SC: $10-20
- Load Balancer: $20-30
- Cloudflare CDN: $10-20 (vs $15-30 Cloud Armor + CDN)
- Otros: $20-30

### Shared: $20-40/mes

- Cloud Build: $10-15
- Artifact Registry: $5-10
- GitHub Actions: $0-10 (minutos incluidos)
- Terraform Cloud: $0 (free tier)

**Total Estimado**: $240-580/mes (con Cloudflare optimización)

---

## 🚀 **Recomendaciones Prioritarias**

### **1. Implementar Cloudflare CDN (Prioridad Alta)**

- **Beneficio**: 20% reducción de costos + mejor performance
- **Tiempo**: 1-2 semanas
- **ROI**: $96-108 ahorro anual

### **2. Completar Terraform Coverage (Prioridad Media)**

- **Beneficio**: 100% Infrastructure as Code
- **Tiempo**: 1 semana
- **Impacto**: Mejor mantenibilidad y versionado

### **3. Resolver Issues Actuales (Prioridad Alta)**

- **Assets desincronizados**: Sincronizar CDN con deployments
- **Cache headers**: Optimizar TTL y cache policies
- **Health checks**: Implementar monitoring completo

### **4. Implementar Monitoring Avanzado (Prioridad Media)**

- **Cloud Monitoring**: SLOs y alertas
- **Cloud Trace**: APM y performance
- **Error Reporting**: Detección automática de errores

---

**Última Actualización**: 2025-10-12  
**Versión**: 4.0  
**Estado**: ✅ Staging 85% desplegado | ✅ Arquitectura analizada | 🔄 Cloudflare CDN recomendado
