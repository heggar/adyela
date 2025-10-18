# Diagramas Arquitectónicos - Adyela Health Platform

## 📊 Resumen

Este documento contiene todos los diagramas arquitectónicos de la plataforma
Adyela, siguiendo el modelo C4 (Context, Container, Component, Code).

**Herramienta**: Mermaid (renderizable en GitHub, VS Code, Markdown viewers)

---

## 🌍 1. C4 Model - Level 1: System Context

```mermaid
graph TB
    subgraph "Sistema Adyela"
        PLATFORM[Adyela Health Platform]
    end

    PATIENT[👤 Paciente<br/>Busca profesionales<br/>Reserva citas]
    PROFESSIONAL[👨‍⚕️ Profesional<br/>Gestiona agenda<br/>Atiende pacientes]
    ADMIN[👔 Admin Plataforma<br/>Aprueba profesionales<br/>Modera contenido]

    FIREBASE[🔐 Firebase Auth<br/>Autenticación]
    STRIPE[💳 Stripe<br/>Pagos]
    TWILIO[📧 Twilio<br/>Email/SMS]
    FCM[🔔 FCM<br/>Push Notifications]

    PATIENT -->|Busca, reserva citas| PLATFORM
    PROFESSIONAL -->|Gestiona agenda, pacientes| PLATFORM
    ADMIN -->|Aprueba, modera| PLATFORM

    PLATFORM -->|Autentica usuarios| FIREBASE
    PLATFORM -->|Procesa pagos| STRIPE
    PLATFORM -->|Envía emails/SMS| TWILIO
    PLATFORM -->|Envía push| FCM

    style PLATFORM fill:#4A90E2,stroke:#2C3E50,stroke-width:3px,color:#fff
    style PATIENT fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style PROFESSIONAL fill:#F5A623,stroke:#D68910,stroke-width:2px
    style ADMIN fill:#BD10E0,stroke:#9012FE,stroke-width:2px
```

---

## 📦 2. C4 Model - Level 2: Container Diagram

```mermaid
graph TB
    subgraph "Usuarios"
        PATIENT[📱 Mobile Patient<br/>Flutter iOS/Android]
        PROF[📱 Mobile Professional<br/>Flutter iOS/Android]
        ADMIN_WEB[💻 Web Admin<br/>React + shadcn/ui]
    end

    subgraph "GCP Load Balancer"
        LB[🌐 HTTPS Load Balancer<br/>Path-based routing]
    end

    subgraph "Backend Microservices"
        AUTH[🔐 api-auth<br/>Python/FastAPI<br/>Multi-tenant RBAC]
        APPT[📅 api-appointments<br/>Python/FastAPI<br/>Citas y calendario]
        PAY[💳 api-payments<br/>Node.js/Express<br/>Stripe integration]
        NOTIF[🔔 api-notifications<br/>Node.js/Express<br/>FCM, Email, SMS]
        ADMIN_API[👔 api-admin<br/>Python/FastAPI<br/>Aprobaciones]
        ANALYTICS[📊 api-analytics<br/>Python<br/>Reportes y BI]
    end

    subgraph "Data Layer"
        FIRESTORE[(🔥 Firestore<br/>Operacional<br/>Multi-tenant)]
        CLOUDSQL[(🗄️ Cloud SQL<br/>PostgreSQL<br/>Analytics)]
        STORAGE[📦 Cloud Storage<br/>Documentos, avatars]
    end

    subgraph "Event Bus"
        PUBSUB[📡 Cloud Pub/Sub<br/>Event-driven communication]
    end

    subgraph "External Services"
        FIREBASE_AUTH[🔐 Firebase Auth]
        STRIPE[💳 Stripe API]
        TWILIO[📧 Twilio]
        FCM_SERVICE[🔔 Firebase FCM]
    end

    PATIENT --> LB
    PROF --> LB
    ADMIN_WEB --> LB

    LB -->|/api/v2/auth/*| AUTH
    LB -->|/api/v2/appointments/*| APPT
    LB -->|/api/v2/payments/*| PAY
    LB -->|/api/v2/notifications/*| NOTIF
    LB -->|/api/v2/admin/*| ADMIN_API
    LB -->|/api/v2/analytics/*| ANALYTICS

    AUTH --> FIRESTORE
    AUTH --> FIREBASE_AUTH
    AUTH --> PUBSUB

    APPT --> FIRESTORE
    APPT -->|Validate permissions| AUTH
    APPT --> PUBSUB

    PAY --> FIRESTORE
    PAY --> STRIPE
    PAY --> PUBSUB

    NOTIF --> FIRESTORE
    NOTIF --> TWILIO
    NOTIF --> FCM_SERVICE
    NOTIF --> PUBSUB

    ADMIN_API --> FIRESTORE
    ADMIN_API --> STORAGE
    ADMIN_API -->|Call auth| AUTH
    ADMIN_API --> PUBSUB

    ANALYTICS --> CLOUDSQL
    ANALYTICS --> PUBSUB

    PUBSUB -.->|appointment.created| NOTIF
    PUBSUB -.->|appointment.created| ANALYTICS
    PUBSUB -.->|payment.completed| APPT
    PUBSUB -.->|professional.approved| AUTH
    PUBSUB -.->|professional.approved| NOTIF

    style LB fill:#4A90E2,stroke:#2C3E50,stroke-width:3px,color:#fff
    style AUTH fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style APPT fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style PAY fill:#F5A623,stroke:#D68910,stroke-width:2px
    style NOTIF fill:#F5A623,stroke:#D68910,stroke-width:2px
    style ADMIN_API fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style ANALYTICS fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style FIRESTORE fill:#BD10E0,stroke:#9012FE,stroke-width:2px,color:#fff
    style CLOUDSQL fill:#BD10E0,stroke:#9012FE,stroke-width:2px,color:#fff
    style PUBSUB fill:#FF6B6B,stroke:#EE5A52,stroke-width:2px
```

---

## 🔄 3. Diagrama de Secuencia: Reservar Cita

```mermaid
sequenceDiagram
    actor Patient as 📱 Paciente Mobile
    participant LB as 🌐 Load Balancer
    participant APPT as 📅 api-appointments
    participant AUTH as 🔐 api-auth
    participant FIRESTORE as 🔥 Firestore
    participant PUBSUB as 📡 Pub/Sub
    participant NOTIF as 🔔 api-notifications
    participant FCM as 🔔 FCM

    Patient->>+LB: POST /api/v2/appointments<br/>{professional_id, scheduled_at}<br/>Authorization: Bearer JWT

    LB->>+APPT: Forward request

    Note over APPT: Extract tenant_id<br/>from JWT

    APPT->>+AUTH: POST /api/v2/auth/validate<br/>{user_id, tenant_id,<br/>resource: "appointments",<br/>action: "create"}

    AUTH->>FIRESTORE: Check user permissions
    FIRESTORE-->>AUTH: Permissions data

    AUTH-->>-APPT: {allowed: true,<br/>roles: ["patient"]}

    Note over APPT: Permission granted

    APPT->>FIRESTORE: Check appointment conflict<br/>Query: professional_id,<br/>scheduled_at overlap

    FIRESTORE-->>APPT: No conflict

    APPT->>FIRESTORE: Save appointment<br/>/tenants/{tenant_id}/<br/>appointments/{appt_id}<br/>status: CONFIRMED

    FIRESTORE-->>APPT: Appointment saved

    APPT->>+PUBSUB: Publish event<br/>Topic: appointment.created<br/>{appt_id, patient_id,<br/>professional_id, ...}

    PUBSUB-->>-APPT: Event published

    APPT-->>-LB: 201 Created<br/>{appointment_id, status,<br/>scheduled_at, ...}

    LB-->>-Patient: 201 Created<br/>Appointment details

    Note over PUBSUB,NOTIF: Asynchronous processing

    PUBSUB->>+NOTIF: Event: appointment.created

    NOTIF->>FIRESTORE: Get patient & professional info

    FIRESTORE-->>NOTIF: User details

    NOTIF->>FCM: Send push notification<br/>To: patient & professional

    FCM-->>NOTIF: Notification sent

    NOTIF->>FIRESTORE: Log notification sent

    NOTIF-->>-PUBSUB: ACK

    Note over Patient: 🔔 Receives push:<br/>"Cita confirmada<br/>20 Oct, 10:00 AM"
```

---

## 💳 4. Diagrama de Secuencia: Saga Pattern (Reserva con Pago)

```mermaid
sequenceDiagram
    actor Patient as 📱 Paciente
    participant APPT as 📅 api-appointments<br/>(Orchestrator)
    participant AUTH as 🔐 api-auth
    participant PAY as 💳 api-payments
    participant STRIPE as 💳 Stripe API
    participant FIRESTORE as 🔥 Firestore
    participant PUBSUB as 📡 Pub/Sub

    Patient->>+APPT: POST /appointments<br/>with_payment=true

    Note over APPT: Saga Start

    APPT->>+AUTH: Validate permissions
    AUTH-->>-APPT: ✅ Allowed

    Note over APPT: Saga Step 1<br/>Completed

    APPT->>FIRESTORE: Create appointment<br/>status: PENDING_PAYMENT
    FIRESTORE-->>APPT: ✅ Created

    Note over APPT: Saga Step 2<br/>Completed

    APPT->>+PAY: POST /payment-intents<br/>{amount, currency,<br/>appointment_id}

    PAY->>+STRIPE: Create PaymentIntent
    STRIPE-->>-PAY: {client_secret,<br/>intent_id}

    PAY-->>-APPT: {payment_intent_id,<br/>client_secret}

    Note over APPT: Saga Step 3<br/>Completed

    APPT-->>-Patient: 201 Created<br/>{appointment_id,<br/>payment_client_secret}

    Patient->>Patient: Complete payment<br/>in Stripe UI

    Patient->>STRIPE: Confirm payment
    STRIPE->>PAY: Webhook: payment_intent.succeeded

    PAY->>FIRESTORE: Update payment status
    PAY->>PUBSUB: Publish: payment.completed

    PUBSUB->>APPT: Event: payment.completed<br/>{appointment_id}

    APPT->>FIRESTORE: Update appointment<br/>status: CONFIRMED
    APPT->>PUBSUB: Publish: appointment.confirmed

    Note over Patient: ✅ Cita confirmada<br/>con pago

    rect rgb(255, 200, 200)
        Note over APPT,PUBSUB: ❌ Failure Scenario:<br/>Payment fails

        alt Payment Failed
            STRIPE->>PAY: Webhook: payment_intent.failed
            PAY->>PUBSUB: Publish: payment.failed
            PUBSUB->>APPT: Event: payment.failed
            APPT->>FIRESTORE: Update appointment<br/>status: CANCELLED<br/>reason: "Payment failed"
            APPT->>PUBSUB: Publish: appointment.cancelled

            Note over APPT: Compensating<br/>Transaction:<br/>Rollback appointment
        end
    end
```

---

## 🏗️ 5. Diagrama de Deployment (GCP)

```mermaid
graph TB
    subgraph "Internet"
        USER[👤 Users<br/>Web + Mobile]
    end

    subgraph "GCP - us-central1"
        subgraph "CDN Layer"
            CDN[☁️ Cloud CDN<br/>Static assets<br/>Cache hit ratio >80%]
        end

        subgraph "Security Layer"
            ARMOR[🛡️ Cloud Armor<br/>WAF + DDoS<br/>Rate limiting]
        end

        subgraph "Load Balancing"
            LB[⚖️ HTTPS Load Balancer<br/>SSL termination<br/>Path-based routing]
        end

        subgraph "Compute - Cloud Run (Serverless)"
            subgraph "Backend Services"
                AUTH_POD[🔐 api-auth<br/>Min: 0, Max: 10<br/>512MB, 1vCPU]
                APPT_POD[📅 api-appointments<br/>Min: 0, Max: 20<br/>1GB, 1vCPU]
                PAY_POD[💳 api-payments<br/>Min: 0, Max: 10<br/>512MB, 1vCPU]
                NOTIF_POD[🔔 api-notifications<br/>Min: 0, Max: 15<br/>256MB, 1vCPU]
                ADMIN_POD[👔 api-admin<br/>Min: 0, Max: 5<br/>512MB, 1vCPU]
                ANALYTICS_POD[📊 api-analytics<br/>Min: 0, Max: 5<br/>512MB, 1vCPU]
            end

            subgraph "Frontend Services"
                WEB_ADMIN[💻 web-admin<br/>React SSR<br/>Min: 0, Max: 5]
            end
        end

        subgraph "Data Layer"
            FIRESTORE[(🔥 Firestore<br/>Multi-region<br/>Auto-scaling)]
            CLOUDSQL[(🗄️ Cloud SQL<br/>PostgreSQL<br/>db-f1-micro)]
            STORAGE[📦 Cloud Storage<br/>Standard class<br/>5GB staging)]
        end

        subgraph "Messaging"
            PUBSUB[📡 Cloud Pub/Sub<br/>6 topics<br/>10 subscriptions]
        end

        subgraph "Observability"
            LOGGING[📝 Cloud Logging<br/>7d retention staging<br/>30d production]
            MONITORING[📊 Cloud Monitoring<br/>Dashboards + Alerts]
            TRACE[🔍 Cloud Trace<br/>Distributed tracing]
        end

        subgraph "Security & Secrets"
            SECRET_MGR[🔐 Secret Manager<br/>30 secrets<br/>API keys, tokens]
            IAM[🔑 IAM<br/>Service accounts<br/>Least privilege]
        end
    end

    subgraph "External Services"
        FIREBASE_AUTH[🔐 Firebase Auth]
        STRIPE_API[💳 Stripe API]
        TWILIO_API[📧 Twilio API]
        FCM_API[🔔 FCM API]
    end

    USER --> CDN
    CDN --> ARMOR
    ARMOR --> LB

    LB --> AUTH_POD
    LB --> APPT_POD
    LB --> PAY_POD
    LB --> NOTIF_POD
    LB --> ADMIN_POD
    LB --> ANALYTICS_POD
    LB --> WEB_ADMIN

    AUTH_POD --> FIRESTORE
    AUTH_POD --> FIREBASE_AUTH
    AUTH_POD --> PUBSUB

    APPT_POD --> FIRESTORE
    APPT_POD --> PUBSUB
    APPT_POD -.->|HTTP| AUTH_POD

    PAY_POD --> FIRESTORE
    PAY_POD --> STRIPE_API
    PAY_POD --> PUBSUB

    NOTIF_POD --> FIRESTORE
    NOTIF_POD --> TWILIO_API
    NOTIF_POD --> FCM_API
    NOTIF_POD --> PUBSUB

    ADMIN_POD --> FIRESTORE
    ADMIN_POD --> STORAGE
    ADMIN_POD --> PUBSUB

    ANALYTICS_POD --> CLOUDSQL
    ANALYTICS_POD --> PUBSUB

    AUTH_POD --> SECRET_MGR
    PAY_POD --> SECRET_MGR
    NOTIF_POD --> SECRET_MGR

    AUTH_POD --> LOGGING
    APPT_POD --> LOGGING
    AUTH_POD --> MONITORING
    APPT_POD --> TRACE

    style LB fill:#4A90E2,stroke:#2C3E50,stroke-width:3px,color:#fff
    style CDN fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style ARMOR fill:#FF6B6B,stroke:#EE5A52,stroke-width:2px,color:#fff
    style FIRESTORE fill:#BD10E0,stroke:#9012FE,stroke-width:2px,color:#fff
    style CLOUDSQL fill:#BD10E0,stroke:#9012FE,stroke-width:2px,color:#fff
    style PUBSUB fill:#F5A623,stroke:#D68910,stroke-width:2px
```

---

## 🔀 6. Diagrama de Multi-Tenancy (Firestore Structure)

```mermaid
graph TB
    subgraph "Firestore Database"
        ROOT[📂 Root]

        subgraph "Global Collections"
            USERS[👥 /users<br/>Global user accounts]
        end

        subgraph "Tenant 1: Dr. Carlos García"
            T1[🏥 /tenants/tenant_carlos_123]
            T1_APPTS[📅 /appointments<br/>Citas de este profesional]
            T1_PATIENTS[👤 /patients<br/>Metadata de pacientes]
            T1_SETTINGS[⚙️ /settings/config<br/>Configuración del tenant]
        end

        subgraph "Tenant 2: Dra. Ana Pérez"
            T2[🏥 /tenants/tenant_ana_456]
            T2_APPTS[📅 /appointments]
            T2_PATIENTS[👤 /patients]
            T2_SETTINGS[⚙️ /settings/config]
        end

        subgraph "User María (Patient)"
            U1[👤 /users/user_maria_789]
            U1_T1[📌 /tenants/tenant_carlos_123<br/>Ha visitado a Dr. Carlos]
            U1_T2[📌 /tenants/tenant_ana_456<br/>Ha visitado a Dra. Ana]
        end
    end

    ROOT --> USERS
    ROOT --> T1
    ROOT --> T2

    T1 --> T1_APPTS
    T1 --> T1_PATIENTS
    T1 --> T1_SETTINGS

    T2 --> T2_APPTS
    T2 --> T2_PATIENTS
    T2 --> T2_SETTINGS

    USERS --> U1
    U1 --> U1_T1
    U1 --> U1_T2

    T1_APPTS -.->|References| U1
    T2_APPTS -.->|References| U1

    style T1 fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style T2 fill:#F5A623,stroke:#D68910,stroke-width:2px
    style U1 fill:#4A90E2,stroke:#2C3E50,stroke-width:2px,color:#fff
    style T1_APPTS fill:#FFE5E5,stroke:#FF6B6B,stroke-width:1px
    style T2_APPTS fill:#FFF5E5,stroke:#F5A623,stroke-width:1px
```

---

## 🌊 7. Event Flow Diagram (Event-Driven Architecture)

```mermaid
graph LR
    subgraph "Publishers"
        APPT[📅 api-appointments]
        PAY[💳 api-payments]
        ADMIN[👔 api-admin]
        AUTH[🔐 api-auth]
    end

    subgraph "Cloud Pub/Sub Topics"
        T1[📡 appointment.created]
        T2[📡 appointment.cancelled]
        T3[📡 payment.completed]
        T4[📡 payment.failed]
        T5[📡 professional.approved]
        T6[📡 user.registered]
    end

    subgraph "Subscribers"
        NOTIF[🔔 api-notifications]
        ANALYTICS[📊 api-analytics]
        APPT_SUB[📅 api-appointments]
        AUTH_SUB[🔐 api-auth]
    end

    APPT -->|Publish| T1
    APPT -->|Publish| T2
    PAY -->|Publish| T3
    PAY -->|Publish| T4
    ADMIN -->|Publish| T5
    AUTH -->|Publish| T6

    T1 -->|Subscribe| NOTIF
    T1 -->|Subscribe| ANALYTICS

    T2 -->|Subscribe| NOTIF
    T2 -->|Subscribe| ANALYTICS

    T3 -->|Subscribe| APPT_SUB
    T3 -->|Subscribe| ANALYTICS

    T4 -->|Subscribe| APPT_SUB
    T4 -->|Subscribe| ANALYTICS

    T5 -->|Subscribe| AUTH_SUB
    T5 -->|Subscribe| NOTIF

    T6 -->|Subscribe| NOTIF
    T6 -->|Subscribe| ANALYTICS

    style T1 fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style T2 fill:#F5A623,stroke:#D68910,stroke-width:2px
    style T3 fill:#4A90E2,stroke:#2C3E50,stroke-width:2px,color:#fff
    style T4 fill:#FF6B6B,stroke:#EE5A52,stroke-width:2px,color:#fff
    style T5 fill:#BD10E0,stroke:#9012FE,stroke-width:2px,color:#fff
    style T6 fill:#50E3C2,stroke:#3AC9A8,stroke-width:2px
```

---

## 🔐 8. Security Architecture Diagram

```mermaid
graph TB
    USER[👤 User<br/>Web/Mobile]

    subgraph "Security Perimeter"
        subgraph "Layer 1: Network Security"
            CLOUDFLARE[☁️ Cloudflare<br/>DDoS protection<br/>DNS management]
            ARMOR[🛡️ Cloud Armor<br/>WAF rules<br/>IP allowlist/blocklist<br/>Rate limiting]
        end

        subgraph "Layer 2: Application Security"
            LB[⚖️ Load Balancer<br/>TLS 1.3 termination<br/>SSL certificates]

            subgraph "Authentication"
                FIREBASE_AUTH[🔐 Firebase Auth<br/>Multi-provider<br/>MFA optional]
                API_AUTH[🔐 api-auth<br/>JWT generation<br/>RBAC enforcement]
            end
        end

        subgraph "Layer 3: Data Security"
            FIRESTORE[(🔥 Firestore<br/>Encryption at rest<br/>Security rules)]
            CLOUDSQL[(🗄️ Cloud SQL<br/>Encryption at rest<br/>SSL connections)]
            SECRET_MGR[🔐 Secret Manager<br/>Secrets rotation<br/>Access logging]
        end

        subgraph "Layer 4: Observability & Audit"
            AUDIT_LOG[📝 Audit Logs<br/>PHI access logs<br/>7 years retention]
            MONITORING[📊 Monitoring<br/>Security alerts<br/>Anomaly detection]
        end
    end

    USER --> CLOUDFLARE
    CLOUDFLARE --> ARMOR
    ARMOR --> LB

    LB --> FIREBASE_AUTH
    FIREBASE_AUTH --> API_AUTH

    API_AUTH --> FIRESTORE
    API_AUTH --> CLOUDSQL
    API_AUTH --> SECRET_MGR

    API_AUTH --> AUDIT_LOG
    ARMOR --> MONITORING

    style CLOUDFLARE fill:#F5A623,stroke:#D68910,stroke-width:2px
    style ARMOR fill:#FF6B6B,stroke:#EE5A52,stroke-width:2px,color:#fff
    style LB fill:#4A90E2,stroke:#2C3E50,stroke-width:2px,color:#fff
    style API_AUTH fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style FIRESTORE fill:#BD10E0,stroke:#9012FE,stroke-width:2px,color:#fff
    style SECRET_MGR fill:#50E3C2,stroke:#3AC9A8,stroke-width:2px
```

---

## 📱 9. Mobile Architecture (Flutter)

```mermaid
graph TB
    subgraph "Flutter Mobile Apps"
        subgraph "mobile-patient (iOS/Android)"
            P_UI[📱 UI Layer<br/>Widgets, Screens]
            P_BL[💼 BLoC Layer<br/>State management]
            P_REPO[📦 Repository Layer<br/>Data access]
        end

        subgraph "mobile-professional (iOS/Android)"
            PR_UI[📱 UI Layer<br/>Widgets, Screens]
            PR_BL[💼 BLoC Layer<br/>State management]
            PR_REPO[📦 Repository Layer<br/>Data access]
        end

        subgraph "Shared Packages"
            FLUTTER_AUTH[🔐 flutter-auth<br/>Auth logic<br/>90% shared]
            FLUTTER_CORE[⚙️ flutter-core<br/>Models, DTOs, Utils<br/>95% shared]
            FLUTTER_SHARED[🎨 flutter-shared<br/>Widgets, Theme<br/>85% shared]
        end
    end

    subgraph "Backend APIs"
        API[🌐 Adyela API<br/>REST + JWT]
    end

    subgraph "Firebase Services"
        FCM[🔔 Firebase FCM<br/>Push notifications]
        ANALYTICS[📊 Firebase Analytics<br/>User behavior]
        CRASHLYTICS[🐛 Firebase Crashlytics<br/>Error tracking]
    end

    P_UI --> P_BL
    P_BL --> P_REPO

    PR_UI --> PR_BL
    PR_BL --> PR_REPO

    P_REPO --> FLUTTER_AUTH
    P_REPO --> FLUTTER_CORE

    PR_REPO --> FLUTTER_AUTH
    PR_REPO --> FLUTTER_CORE

    P_UI --> FLUTTER_SHARED
    PR_UI --> FLUTTER_SHARED

    FLUTTER_AUTH --> API
    FLUTTER_CORE --> API

    P_REPO --> FCM
    P_REPO --> ANALYTICS
    P_REPO --> CRASHLYTICS

    PR_REPO --> FCM
    PR_REPO --> ANALYTICS
    PR_REPO --> CRASHLYTICS

    style P_UI fill:#7ED321,stroke:#5FA019,stroke-width:2px
    style PR_UI fill:#F5A623,stroke:#D68910,stroke-width:2px
    style FLUTTER_AUTH fill:#4A90E2,stroke:#2C3E50,stroke-width:2px,color:#fff
    style FLUTTER_CORE fill:#4A90E2,stroke:#2C3E50,stroke-width:2px,color:#fff
    style FLUTTER_SHARED fill:#4A90E2,stroke:#2C3E50,stroke-width:2px,color:#fff
```

---

## ✅ Uso de Diagramas

### Render en GitHub

Los diagramas Mermaid se renderizan automáticamente en GitHub, Gitlab, y la
mayoría de visualizadores Markdown modernos.

### Render en VS Code

Instalar extensión: **Markdown Preview Mermaid Support**

### Exportar a Imágenes

```bash
# Usar mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Export diagrams
mmdc -i docs/architecture/diagrams.md -o output/diagrams.pdf
```

### Editar Diagramas

**Online Editor**: https://mermaid.live/

---

**Documento**: `docs/architecture/diagrams.md` **Version**: 1.0 **Última
actualización**: 2025-10-18 **Herramienta**: Mermaid **Formato**: Markdown +
Mermaid
