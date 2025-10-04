# Política de Seguridad

## 🔒 Reportar una Vulnerabilidad

La seguridad de Adyela es una prioridad. Agradecemos los esfuerzos de la comunidad de seguridad para divulgar responsablemente las vulnerabilidades.

### 📧 Cómo Reportar

**NO** crees un issue público para vulnerabilidades de seguridad.

En su lugar:

1. **Email**: Envía un correo a security@adyela.com
2. **Asunto**: `[SECURITY] Descripción breve`
3. **Contenido**: Incluye:
   - Descripción detallada de la vulnerabilidad
   - Pasos para reproducir
   - Impacto potencial
   - Posible solución (si tienes una)

### ⏱️ Tiempo de Respuesta

- **Confirmación inicial**: 48 horas
- **Evaluación inicial**: 7 días
- **Actualización de estado**: Cada 14 días
- **Resolución target**: 90 días (dependiendo de severidad)

### 🎯 Severidad y SLA

#### Crítica (CVSS 9.0-10.0)

- **Impacto**: Compromiso completo del sistema
- **SLA**: Parche en 7 días
- **Ejemplos**: RCE, SQL Injection directa

#### Alta (CVSS 7.0-8.9)

- **Impacto**: Compromiso significativo
- **SLA**: Parche en 30 días
- **Ejemplos**: XSS, Autenticación bypass

#### Media (CVSS 4.0-6.9)

- **Impacto**: Exposición limitada de datos
- **SLA**: Parche en 90 días
- **Ejemplos**: CSRF, Información disclosure

#### Baja (CVSS 0.1-3.9)

- **Impacto**: Impacto mínimo
- **SLA**: Próximo release
- **Ejemplos**: Problemas de configuración

## 🛡️ Versiones Soportadas

| Versión | Soporte              |
| ------- | -------------------- |
| 0.x.x   | ✅ Desarrollo activo |

_Nota: Una vez en producción, se soportarán las últimas 2 versiones major._

## 🏆 Programa de Reconocimiento

Actualmente no tenemos un programa de bug bounty formal, pero reconocemos públicamente (con permiso) a los investigadores que reportan vulnerabilidades válidas.

### Hall of Fame

_Pendiente de implementar_

## 🔐 Mejores Prácticas de Seguridad

### Para Desarrolladores

#### 1. Autenticación y Autorización

```typescript
// ✅ Bien - Verificar permisos explícitamente
async function getPatientData(userId: string, patientId: string) {
  const patient = await db.patient.findUnique({ id: patientId });

  if (!canAccessPatient(userId, patient)) {
    throw new ForbiddenError("Access denied");
  }

  return patient;
}

// ❌ Mal - Confiar en datos del cliente
async function getPatientData(patientId: string) {
  // Sin verificación de permisos
  return await db.patient.findUnique({ id: patientId });
}
```

#### 2. Validación de Entrada

```python
# ✅ Bien - Validar con Pydantic
from pydantic import BaseModel, validator

class AppointmentCreate(BaseModel):
    patient_id: str
    scheduled_at: datetime

    @validator('scheduled_at')
    def scheduled_in_future(cls, v):
        if v < datetime.now():
            raise ValueError('Must be in future')
        return v

# ❌ Mal - Usar datos sin validar
def create_appointment(data: dict):
    # Sin validación
    return db.appointments.insert(data)
```

#### 3. Secrets Management

```typescript
// ✅ Bien - Usar variables de entorno
const apiKey = process.env.SENDGRID_API_KEY;

// ❌ Mal - Hardcodear secrets
const apiKey = "SG.abc123xyz";
```

#### 4. SQL Injection Prevention

```python
# ✅ Bien - Usar ORM o parameterized queries
patient = await db.patients.filter(id=patient_id).first()

# ❌ Mal - Concatenación de strings
query = f"SELECT * FROM patients WHERE id = '{patient_id}'"
```

#### 5. XSS Prevention

```typescript
// ✅ Bien - Sanitizar y escapar
import DOMPurify from "dompurify";

const clean = DOMPurify.sanitize(userInput);
element.innerHTML = clean;

// ❌ Mal - Renderizar directamente
element.innerHTML = userInput;
```

### Para Operaciones

#### 1. Variables de Entorno

- ✅ Usar Google Secret Manager en producción
- ✅ Rotar secrets regularmente
- ❌ NUNCA commitear `.env` al repo
- ❌ NUNCA loguear secrets

#### 2. Comunicación

- ✅ HTTPS obligatorio en producción
- ✅ TLS 1.3+ únicamente
- ✅ Certificate pinning en apps móviles
- ❌ HTTP en producción

#### 3. Base de Datos

- ✅ Encriptación at-rest
- ✅ Encriptación in-transit
- ✅ Backups encriptados
- ✅ Principle of least privilege

#### 4. Logging y Monitoreo

```python
# ✅ Bien - Sin datos sensibles
logger.info(f"User {user_id} logged in")

# ❌ Mal - Loguear datos sensibles
logger.info(f"User {email} logged in with password {password}")
```

## 🔍 Security Scanning

### Automático (CI/CD)

- **Dependencias**: Snyk, Dependabot
- **SAST**: SonarQube
- **Container Scanning**: Trivy
- **Secret Detection**: GitGuardian

### Manual

```bash
# Scan de dependencias
pnpm audit

# Lint de seguridad
pnpm lint:security

# Tests de seguridad
pnpm test:security
```

## 📋 Checklist de Seguridad

### Pre-Deployment

- [ ] Todas las dependencias actualizadas
- [ ] Sin vulnerabilidades conocidas
- [ ] Secrets en Secret Manager
- [ ] HTTPS configurado
- [ ] Rate limiting activo
- [ ] Logging configurado
- [ ] Backups automáticos
- [ ] Disaster recovery plan
- [ ] Security headers configurados
- [ ] CORS configurado correctamente

### Security Headers

```
Content-Security-Policy: default-src 'self'
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

## 🚨 Incidentes de Seguridad

### En Caso de Incidente

1. **Contener**: Aislar el sistema afectado
2. **Evaluar**: Determinar el alcance
3. **Notificar**: Informar al equipo de seguridad
4. **Remediar**: Aplicar el fix
5. **Documentar**: Post-mortem completo
6. **Comunicar**: Notificar a usuarios afectados si aplica

### Post-Mortem

Documentar en `docs/security/incidents/`:

- Timeline del incidente
- Causa raíz
- Acciones tomadas
- Lecciones aprendidas
- Acciones preventivas

## 🔄 Actualizaciones

Esta política se revisa y actualiza:

- Cada 6 meses
- Después de incidentes significativos
- Cuando hay cambios regulatorios

**Última actualización**: 2025-10-04
**Próxima revisión**: 2026-04-04

## 📞 Contacto

- **Email de Seguridad**: security@adyela.com
- **PGP Key**: [Pendiente]
- **Emergency**: [Pendiente]

---

Gracias por ayudarnos a mantener Adyela seguro 🔒
