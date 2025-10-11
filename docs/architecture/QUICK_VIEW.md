# 🏗️ Arquitectura GCP Adyela - Vista Rápida

## 📊 Diagrama Simplificado (ASCII)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                          👥 USUARIOS & ACCESO                                     │
│  🔵 Pacientes  |  🟢 Doctores  |  🟠 Admins  |  🔴 Ops Team  |  🟣 Developers    │
└──────────────────────────────────────────────────────────────────────────────────┘
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                          🌐 DNS & EDGE SECURITY                                   │
│  Cloud DNS  →  Cloud CDN  →  Load Balancer  →  Cloud Armor (WAF)                │
│  API Gateway  →  Identity Platform (JWT+MFA)  →  VPC Service Controls            │
└──────────────────────────────────────────────────────────────────────────────────┘
                                      ▼
┌───────────────────────────────────┬──────────────────────────────────────────────┐
│    🟨 STAGING ENVIRONMENT         │    🟩 PRODUCTION ENVIRONMENT (HIPAA)         │
│    (Scale-to-zero | $5-10/mes)    │    (Always-on | $200-500/mes)                │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│  ⚙️ COMPUTE SERVICES              │  ⚙️ COMPUTE SERVICES (HA)                   │
│  • Cloud Run API (0-1)            │  • Cloud Run API (1-10 instances)            │
│  • Cloud Run Web (0-2)            │  • Cloud Run Web (2-10 instances)            │
│  • Cloud Functions Gen2           │  • Cloud Functions Gen2 + HA                 │
│  • Cloud Scheduler                │  • Cloud Scheduler + Backup                  │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│  💾 DATA & STORAGE                │  💾 DATA & STORAGE (CMEK Encrypted)         │
│  • Firestore Multi-tenant         │  • Firestore Multi-tenant + CMEK             │
│  • Cloud Storage                  │  • Cloud Storage (7-year retention)          │
│  • Secret Manager                 │  • Secret Manager + Rotation + CMEK          │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│  🔄 ASYNC PROCESSING              │  🔄 ASYNC PROCESSING + DLQ                  │
│  • Pub/Sub Event Bus              │  • Pub/Sub + Dead Letter Queue               │
│  • Cloud Tasks Queue              │  • Cloud Tasks + Retry Logic                 │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│  📊 OBSERVABILITY                 │  📊 OBSERVABILITY + SLO                     │
│  • Cloud Logging (30 days)        │  • Cloud Logging (7 years - HIPAA)           │
│  • Cloud Monitoring               │  • Cloud Monitoring + SLO Alerts             │
│  • Cloud Trace (APM)              │  • Cloud Trace + Advanced APM                │
│  • Error Reporting                │  • Error Reporting + Uptime Checks           │
└───────────────────────────────────┴──────────────────────────────────────────────┘
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                    🟪 SHARED SERVICES & CI/CD                                     │
│  Cloud Build  |  Artifact Registry  |  Cloud KMS (CMEK)  |  VPC Network          │
│  Cloud IAM    |  Security Command Center  |  VPC Service Controls                │
│  GitHub Actions  |  Terraform (IaC)  |  Task Master AI                           │
└──────────────────────────────────────────────────────────────────────────────────┘

📍 Region: us-central1 (Iowa, USA)
🌎 Multi-zone Availability
🔒 HIPAA Compliant
```

---

## 🚀 Estado Actual de Despliegue

### ✅ Staging Environment (80% COMPLETADO)

| Componente           | Estado       | Detalles                                                          |
| -------------------- | ------------ | ----------------------------------------------------------------- |
| **Cloud Run API**    | ✅ ACTIVO    | `adyela-api-staging` - Ingress: internal                          |
| **Cloud Run Web**    | ✅ ACTIVO    | `adyela-web-staging` - Ingress: internal-and-cloud-load-balancing |
| **VPC Network**      | ✅ ACTIVO    | `adyela-staging-vpc` (CUSTOM mode)                                |
| **VPC Connector**    | ✅ ACTIVO    | `adyela-staging-connector` (READY)                                |
| **Load Balancer**    | ✅ ACTIVO    | IP: `34.96.108.162` - SSL: ACTIVE                                 |
| **SSL Certificate**  | ✅ ACTIVO    | `staging.adyela.care` - Google Managed                            |
| **Service Account**  | ✅ ACTIVO    | `adyela-staging-hipaa` - HIPAA roles                              |
| **Secret Manager**   | ✅ ACTIVO    | 8 secrets HIPAA configurados                                      |
| **Firebase Project** | ✅ ACTIVO    | `adyela-staging` (717907307897)                                   |
| **Cloud Logging**    | ✅ ACTIVO    | Logs de Cloud Run visibles                                        |
| **Cloud Functions**  | ⏳ PENDIENTE | Gen2 serverless                                                   |
| **Cloud Scheduler**  | ⏳ PENDIENTE | Cron jobs                                                         |
| **Pub/Sub**          | ⏳ PENDIENTE | Event bus                                                         |
| **Cloud Tasks**      | ⏳ PENDIENTE | Cola de tareas                                                    |
| **Cloud Storage**    | ⏳ PENDIENTE | Documentos y backups                                              |
| **Cloud Monitoring** | ⏳ PENDIENTE | Métricas avanzadas                                                |
| **Cloud Trace**      | ⏳ PENDIENTE | APM avanzado                                                      |
| **Error Reporting**  | ⏳ PENDIENTE | Errores automáticos                                               |

### 🔗 URLs Activas

- **Load Balancer**: `https://34.96.108.162` (HTTP/HTTPS)
- **Dominio**: `staging.adyela.care` (configurado, pendiente DNS)
- **API Directa**: ❌ Bloqueada (seguridad HIPAA)
- **Web Directa**: ❌ Bloqueada (seguridad HIPAA)

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

## 💰 Costos Mensuales Estimados

### Staging: $15-25/mes (ACTUAL)

- Cloud Run: $5-8 (con VPC connector, always-on mínimo)
- Load Balancer: $5-8 (HTTP(S) global)
- VPC Access Connector: $3-5 (f1-micro instances)
- Firestore: $2-3 (volumen bajo)
- Secret Manager: $1-2 (8 secrets)
- SSL Certificate: $0 (Google managed)
- Logging: $2-3 (30 días)
- Otros: $2-3

### Production: $200-500/mes

- Cloud Run: $80-150 (always-on, HA)
- Firestore: $30-60 (CMEK, alto volumen)
- Cloud Storage: $20-40 (7 años retención)
- Logging: $30-50 (7 años retención HIPAA)
- Monitoring: $10-20 (SLO, alertas)
- KMS (CMEK): $5-10
- VPC-SC: $10-20
- Load Balancer: $20-30
- Cloud Armor: $10-20
- CDN: $5-15
- Otros: $20-30

### Shared: $20-40/mes

- Cloud Build: $10-15
- Artifact Registry: $5-10
- GitHub Actions: $0-10 (minutos incluidos)
- Terraform Cloud: $0 (free tier)

**Total Estimado**: $225-550/mes

---

**Última Actualización**: 2025-10-11  
**Versión**: 3.1  
**Estado**: ✅ Staging 80% desplegado | ✅ Arquitectura validada
