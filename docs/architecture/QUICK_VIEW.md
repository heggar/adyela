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

### 🟨 Staging Environment

#### ⚙️ Compute

- **Cloud Run API**: FastAPI, 0-1 instancias (scale-to-zero)
- **Cloud Run Web**: React PWA, 0-2 instancias
- **Cloud Functions**: Gen2, serverless
- **Cloud Scheduler**: Cron jobs, mantenimiento

#### 💾 Data

- **Firestore**: Multi-tenant, Native mode
- **Cloud Storage**: Documentos, backups
- **Secret Manager**: API keys, credenciales

#### 🔄 Async

- **Pub/Sub**: Event bus
- **Cloud Tasks**: Cola de tareas

#### 📊 Monitoring

- **Logging**: Retención 30 días
- **Monitoring**: Métricas básicas
- **Trace**: APM básico
- **Error Reporting**: Errores automáticos

**Costo Estimado**: $5-10/mes

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

### ✅ Staging

- ✓ Scale-to-zero (ahorro de costos)
- ✓ Ambiente de pruebas completo
- ✓ Misma arquitectura que producción
- ✓ Retención corta de logs (30 días)
- ✓ Costo mínimo ($5-10/mes)

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

### Staging: $5-10/mes

- Cloud Run: $2-3 (scale-to-zero)
- Firestore: $1-2 (volumen bajo)
- Cloud Storage: $1-2 (backups)
- Logging: $1-2 (30 días)
- Otros: $1-2

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

## 🚀 Cómo Ver el Diagrama Visual Completo

### Opción 1: Draw.io Web (RECOMENDADO)

```bash
# Abre tu navegador en:
https://app.diagrams.net/

# Arrastra el archivo:
docs/architecture/adyela-gcp-architecture.drawio

# Verás el diagrama completo con todos los iconos de GCP
```

### Opción 2: VS Code Extension

```bash
# Instala la extensión:
code --install-extension hediet.vscode-drawio

# Abre el archivo:
code docs/architecture/adyela-gcp-architecture.drawio
```

### Opción 3: Desktop App (macOS)

```bash
# Instala Draw.io:
brew install --cask drawio

# Abre el archivo:
open docs/architecture/adyela-gcp-architecture.drawio
```

---

## 📚 Documentación Relacionada

- **[Guía Completa de Arquitectura](./GCP_ARCHITECTURE_GUIDE.md)** - 50+ páginas de detalles técnicos
- **[Instrucciones de Visualización](./VIEWING_INSTRUCTIONS.md)** - Solución de problemas
- **[Guía de Edición](./DIAGRAM_GUIDE.md)** - Cómo editar el diagrama
- **[README](./README.md)** - Índice general

---

## ⚠️ Nota Importante

Este diagrama ASCII es una **representación simplificada**. Para ver la arquitectura completa con:

- ✅ Iconos oficiales de GCP
- ✅ Colores y diseño profesional
- ✅ Conexiones entre servicios
- ✅ Etiquetas detalladas

**Abre el archivo `.drawio` en Draw.io** (web o desktop).

---

**Última Actualización**: 2025-10-11  
**Versión**: 3.0  
**Estado**: ✅ Arquitectura validada
