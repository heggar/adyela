# 📊 Google Analytics para Firebase - Implicaciones y Recomendaciones

## ⚠️ IMPORTANTE: Consideraciones HIPAA

**Adyela es una aplicación de salud que maneja PHI (Protected Health
Information).**

### 🚨 PROBLEMA: Google Analytics NO es HIPAA Compliant

Google Analytics **NO debe usarse** para rastrear datos que contengan PHI,
incluyendo:

❌ **NO rastrear:**

- Nombres de pacientes
- Fechas de nacimiento
- Diagnósticos o condiciones médicas
- Información de citas médicas con detalles
- Cualquier dato que identifique a un paciente

✅ **SÍ puedes rastrear:**

- Eventos de navegación genéricos ("page_view", "button_click")
- Performance de la aplicación
- Errores técnicos (sin datos de usuario)
- Métricas agregadas sin identificadores

---

## 💰 Costos

### Firebase Analytics (Gratis)

- ✅ **Eventos ilimitados**: GRATIS
- ✅ **Usuarios ilimitados**: GRATIS
- ✅ **Retención de datos**: 14 meses GRATIS

### Google Analytics 4 (GA4) - Integrado

- ✅ **Plan Gratuito**:
  - 10 millones de eventos/mes
  - Retención de datos: 14 meses
  - Reportes estándar

- 💰 **Analytics 360** (no necesario):
  - $50,000-150,000/año
  - Para empresas grandes

**Para Adyela: $0/mes** ✅

---

## 🔓 Qué se Activa al Habilitar Analytics

### 1. **Rastreo Automático**

Firebase Analytics rastrea automáticamente:

```javascript
// Eventos automáticos (sin código)
✅ first_open          // Primera vez que abren la app
✅ session_start       // Inicio de sesión
✅ screen_view         // Vistas de pantalla
✅ user_engagement     // Tiempo en app
✅ app_update          // Actualizaciones de app
```

### 2. **Datos Recolectados Automáticamente**

```javascript
// Información del dispositivo
- Modelo del dispositivo
- Sistema operativo
- Versión de la app
- País/idioma
- Resolución de pantalla

// Información de uso
- Duración de sesión
- Pantallas visitadas
- Frecuencia de uso
- Retención de usuarios
```

### 3. **Integración con Otros Servicios**

Al activar Analytics se habilitan:

- 📊 Firebase Performance Monitoring
- 📧 Firebase Cloud Messaging (targeting)
- 🔔 Firebase In-App Messaging
- 🧪 Firebase A/B Testing
- 🎯 Google Ads (remarketing)

---

## 🛡️ Privacidad y Cumplimiento

### HIPAA Compliance ⚠️

**Google Analytics NO es HIPAA compliant por defecto.**

#### Problemas:

1. **No hay BAA (Business Associate Agreement)**
   - Google NO firma BAA para Analytics
   - Violación de HIPAA si envías PHI

2. **Datos en servidores de Google**
   - No tienes control total de los datos
   - Pueden usarse para otros servicios de Google

3. **Compartición de datos**
   - Analytics puede compartir datos con Google Ads
   - No hay garantías de encriptación de PHI

#### Solución para Adyela:

**Opción A: Desactivar completamente** ✅ (Recomendado)

```typescript
// apps/web/src/main.tsx
import { initializeApp } from 'firebase/app';

const firebaseConfig = {
  // ... config
  measurementId: undefined, // ❌ NO inicializar Analytics
};

// NO importar ni usar firebase/analytics
```

**Opción B: Usar con extrema precaución** ⚠️

```typescript
// apps/web/src/services/analytics.ts
import { logEvent, setUserId } from 'firebase/analytics';

// ✅ CORRECTO: Eventos genéricos sin PHI
export function trackPageView(pageName: string) {
  logEvent(analytics, 'page_view', {
    page_name: pageName, // ✅ OK: Solo nombre de página
  });
}

// ❌ INCORRECTO: Incluye PHI
export function trackAppointmentCreated(appointment: Appointment) {
  logEvent(analytics, 'appointment_created', {
    patient_name: appointment.patientName, // ❌ PHI
    reason: appointment.reason, // ❌ PHI
  });
}

// ✅ CORRECTO: Sin PHI
export function trackAppointmentCreated() {
  logEvent(analytics, 'appointment_created', {
    // Solo métricas agregadas, sin identificadores
  });
}
```

### GDPR Compliance 🇪🇺

Si tienes usuarios en Europa:

**Requisitos:**

1. **Consentimiento explícito**

   ```typescript
   // Pedir permiso antes de activar Analytics
   if (userConsent.analytics) {
     initializeAnalytics();
   }
   ```

2. **Anonimización de IP**

   ```typescript
   // En firebase config
   import { getAnalytics } from 'firebase/analytics';
   const analytics = getAnalytics(app);

   // GA4 anonimiza IP por defecto ✅
   ```

3. **Cookie banner**
   - Informar sobre uso de cookies
   - Permitir opt-out

---

## 📈 Alternativas HIPAA Compliant

### 1. **Self-hosted Analytics** (Recomendado)

**Matomo** (Open Source)

```bash
# Desplegar en Cloud Run
docker run -d \
  --name=matomo \
  -p 8080:80 \
  matomo/matomo
```

**Ventajas:**

- ✅ HIPAA compliant (datos en tu servidor)
- ✅ Control total de datos
- ✅ No compartición con terceros
- ✅ Open source

**Costo:** ~$10-20/mes (hosting)

### 2. **Firebase Performance Monitoring** ✅

Firebase Performance NO recolecta PHI:

```typescript
// apps/web/src/services/performance.ts
import { getPerformance } from 'firebase/performance';

const perf = getPerformance();

// ✅ HIPAA OK: Solo métricas técnicas
trace.putMetric('api_response_time', 250);
```

**Ventajas:**

- ✅ GRATIS
- ✅ No recolecta PHI
- ✅ Métricas técnicas útiles

### 3. **Custom Logging en Firestore**

```typescript
// apps/web/src/services/audit-log.ts
interface AuditLog {
  timestamp: Date;
  action: 'page_view' | 'appointment_created' | 'login';
  userId: string; // ✅ OK: Referencia, no PHI directamente
  metadata: {
    // ✅ Solo datos no-PHI
    page?: string;
    duration?: number;
  };
}

// Almacenar logs en Firestore (HIPAA compliant)
await addDoc(collection(db, 'audit_logs'), auditLog);
```

**Ventajas:**

- ✅ HIPAA compliant (con Firestore HIPAA config)
- ✅ Control total
- ✅ Auditoría completa

**Costo:** Incluido en Firestore

---

## 🎯 Recomendación para Adyela

### Staging Environment

```typescript
// .env.staging
VITE_ENABLE_ANALYTICS = false; // ❌ Desactivado
VITE_ENABLE_PERFORMANCE = true; // ✅ Activado (HIPAA OK)
```

### Production Environment

**Opción 1: Sin Analytics (Más seguro)** ✅

```typescript
// .env.production
VITE_ENABLE_ANALYTICS = false;
VITE_ENABLE_PERFORMANCE = true;
VITE_ENABLE_CUSTOM_LOGGING = true; // Logging propio en Firestore
```

**Opción 2: Con Analytics (Con precauciones extremas)** ⚠️

```typescript
// .env.production
VITE_ENABLE_ANALYTICS = true;
VITE_ANALYTICS_MODE = strict; // Solo eventos genéricos

// apps/web/src/services/analytics.ts
const ALLOWED_EVENTS = [
  'page_view',
  'button_click',
  'error_occurred',
  'session_start',
];

// Validar que NO se envíe PHI
function sanitizeEventData(data: any) {
  const PHI_PATTERNS = [
    /name/i,
    /email/i,
    /phone/i,
    /patient/i,
    /diagnosis/i,
    /reason/i,
  ];

  // Bloquear si detecta PHI
  for (const [key, value] of Object.entries(data)) {
    if (PHI_PATTERNS.some(pattern => pattern.test(key))) {
      throw new Error('PHI detected in analytics data');
    }
  }
}
```

---

## 📋 Checklist de Activación

Si decides activar Analytics:

- [ ] **Firmar BAA con Google** (Imposible para Analytics)
- [ ] **Implementar sanitización de datos**
- [ ] **Configurar cookie banner (GDPR)**
- [ ] **Documentar en Privacy Policy**
- [ ] **Configurar IP anonymization**
- [ ] **Limitar eventos a lista blanca**
- [ ] **Entrenar equipo en compliance**
- [ ] **Auditoría mensual de datos enviados**

---

## 🔧 Implementación Segura (Si decides usarlo)

### 1. Configuración Condicional

```typescript
// apps/web/src/config/firebase.ts
import { getAnalytics, isSupported } from 'firebase/analytics';

export async function initializeAnalytics() {
  // Solo si el usuario da consentimiento
  const consent = await getUserConsent();

  if (!consent.analytics) {
    return null;
  }

  // Verificar soporte
  const supported = await isSupported();
  if (!supported) {
    return null;
  }

  return getAnalytics(app);
}
```

### 2. Wrapper Seguro

```typescript
// apps/web/src/services/analytics-safe.ts
const BLOCKED_PROPERTIES = [
  'name',
  'email',
  'phone',
  'patient',
  'diagnosis',
  'reason',
  'notes',
  'ssn',
  'dob',
  'address',
];

export function safeLogEvent(eventName: string, params?: Record<string, any>) {
  // Validar nombre del evento
  if (!ALLOWED_EVENTS.includes(eventName)) {
    console.error('Event not allowed:', eventName);
    return;
  }

  // Sanitizar parámetros
  if (params) {
    for (const key of Object.keys(params)) {
      if (BLOCKED_PROPERTIES.some(prop => key.toLowerCase().includes(prop))) {
        throw new Error(`Blocked property in analytics: ${key}`);
      }
    }
  }

  // Enviar evento
  if (analytics) {
    logEvent(analytics, eventName, params);
  }
}
```

---

## 📊 Métricas Alternativas HIPAA-Compliant

Puedes rastrear estas métricas sin violar HIPAA:

### Performance Monitoring ✅

```typescript
import { trace } from 'firebase/performance';

// Rendimiento de API
const t = trace(perf, 'api_call');
t.start();
await fetch('/api/appointments');
t.stop();
```

### Custom Events en Firestore ✅

```typescript
// Eventos agregados sin PHI
interface AppMetric {
  date: Date;
  metric: 'appointments_created' | 'logins' | 'errors';
  count: number;
  // Sin identificadores de pacientes
}
```

### Server-side Logging ✅

```python
# apps/api/adyela_api/infrastructure/logging/metrics.py
import logging
from datetime import datetime

def log_metric(metric_name: str, value: float):
    """Log metrics sin PHI."""
    logging.info(f"METRIC: {metric_name}={value}")
```

---

## 🚦 Resumen: ¿Activar o No?

### ❌ NO Activar Si:

- Manejas PHI (tu caso con Adyela)
- Necesitas cumplir HIPAA estrictamente
- No tienes recursos para auditoría constante
- No puedes garantizar sanitización 100%

### ✅ Activar Si:

- Es una app sin datos sensibles
- Solo rastrearás métricas técnicas
- Tienes consentimiento explícito de usuarios
- Implementas sanitización robusta

---

## 🎯 Recomendación Final para Adyela

**NO activar Google Analytics** por las siguientes razones:

1. ❌ No es HIPAA compliant
2. ❌ Riesgo de enviar PHI accidentalmente
3. ❌ No puedes firmar BAA con Google
4. ✅ Tienes alternativas mejores (Matomo, custom logging)

**En su lugar, usa:**

1. ✅ Firebase Performance Monitoring (métricas técnicas)
2. ✅ Custom logging en Firestore (auditoría HIPAA compliant)
3. ✅ Matomo self-hosted (si necesitas analytics avanzado)

---

## 📚 Referencias

- [HIPAA and Google Analytics](https://support.google.com/analytics/answer/7686480)
- [Firebase Analytics GDPR](https://firebase.google.com/support/privacy)
- [Matomo Healthcare](https://matomo.org/healthcare/)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html)

---

**Última actualización:** 2025-10-18 **Proyecto:** Adyela (Healthcare
Application) **Compliance:** HIPAA, GDPR
