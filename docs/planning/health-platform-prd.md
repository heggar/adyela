# Product Requirements Document (PRD)

# Plataforma Integral de Salud Adyela

## 📊 Executive Summary

**Producto**: Plataforma multi-tenant de salud que conecta pacientes con
profesionales independientes

**Visión**: Ser la plataforma líder en Latinoamérica para profesionales de salud
independientes (medicina general, fisioterapia, psicología) que necesitan
gestionar sus consultas privadas.

**Modelo de Negocio**: Freemium (Free, Pro $X/mes, Enterprise custom)

**Mercado Objetivo**: Latinoamérica (Colombia, México, Chile, Argentina)

**Timeline MVP**: 8-12 meses (Fase 0-3)

**Equipo**: 6-8 desarrolladores especializados

---

## 🎯 Objetivos del Producto

### Objetivos de Negocio (Business Goals)

1. **Acquisition**: 500 profesionales registrados en 6 meses post-launch
2. **Activation**: 60% profesionales completan onboarding en <7 días
3. **Revenue**: 100 profesionales en tier Pro ($X/mes) en 12 meses
4. **Retention**: Churn < 15% mensual
5. **Referral**: NPS > 40 en primer año

### Objetivos de Usuario (User Goals)

**Pacientes**:

- Encontrar profesionales de salud cercanos en <3 minutos
- Reservar cita en <5 taps
- Recibir recordatorios automáticos (0 no-shows)

**Profesionales**:

- Gestionar agenda completa desde mobile
- Cobrar consultas online sin setup técnico
- Acceder a historial clínico de pacientes

**Admins Plataforma**:

- Aprobar profesionales en <24 horas
- Detectar fraud/abuse
- Analytics de negocio en tiempo real

---

## 👥 User Personas

### Persona 1: Paciente (María, 35 años)

**Demografía**: Profesional trabajando, vive en ciudad, clase media

**Necesidades**:

- Encontrar fisioterapeuta cerca de su oficina
- Reservar citas fuera de horario laboral (mobile)
- Recordatorios porque tiene agenda ocupada

**Frustraciones**:

- Llamar a clínicas durante horario laboral
- Esperas largas en sala de espera
- Pagar en efectivo (no tiene cambio)

**Quote**: "Necesito agendar mi cita rápido, entre reuniones"

### Persona 2: Profesional (Dr. Carlos, 42 años, Psicólogo)

**Demografía**: Profesional independiente, consultorio propio, 50-80
pacientes/mes

**Necesidades**:

- Gestionar agenda desde celular (está en consulta)
- Cobrar online (evitar efectivo/bancos)
- Recordar info de pacientes (notas clínicas)

**Frustraciones**:

- Agenda en papel/Excel (propenso a errores)
- Pacientes no pagan o cancelan último momento
- No tiene secretaria (hace todo solo)

**Quote**: "Necesito una solución simple que funcione desde mi celular"

### Persona 3: Admin Plataforma (Ana, 28 años)

**Demografía**: Staff Adyela, valida credenciales profesionales

**Necesidades**:

- Aprobar/rechazar solicitudes rápidamente
- Verificar documentos (títulos, licencias)
- Dashboard de métricas de plataforma

**Frustraciones**:

- Documentos ilegibles o incompletos
- Profesionales fraudulentos
- Falta de herramientas para moderar

**Quote**: "Necesito validar credenciales de forma eficiente y segura"

---

## 📱 User Stories - MVP

### Epic 1: Autenticación y Onboarding

#### US-001: Registro de Paciente ✅ IMPLEMENTADO (Flutter)

**Como** paciente nuevo **Quiero** registrarme con Google, Facebook o email
**Para** acceder a la plataforma rápidamente

**Criterios de Aceptación**:

- [x] Registro con Google OAuth en <10 segundos ✅
- [ ] Registro con Facebook OAuth en <10 segundos (Pendiente)
- [x] Registro con email/password (validación email) ✅
- [x] Onboarding de 3 pasos (info básica, foto perfil, preferencias) ✅
- [x] Completar onboarding en <2 minutos ✅

**Prioridad**: P0 (Blocker MVP) **Estimación**: 3 puntos (5-8 horas) **Estado**:
✅ Implementado en mobile-patient (Flutter)

#### US-002: Registro de Profesional 🔧 PARCIALMENTE IMPLEMENTADO

**Como** profesional de salud **Quiero** solicitar una cuenta con validación de
credenciales **Para** empezar a ofrecer mis servicios

**Criterios de Aceptación**:

- [x] Onboarding de 5 pasos (info básica, especialidad, credenciales, horarios,
      configuración) ✅
- [ ] Upload de documentos (título, licencia, cédula profesional) 🔧 En
      desarrollo
- [x] Selección de especialidad (medicina, fisioterapia, psicología, etc.) ✅
- [ ] Configuración de disponibilidad semanal 🔧 UI implementada, backend
      pendiente
- [ ] Estado inicial: "PENDING_APPROVAL" 🔧 Modelo definido, workflow pendiente
- [ ] Email de confirmación "Revisaremos tu solicitud en 24-48h" 🔧 Template
      creado, envío pendiente

**Prioridad**: P0 (Blocker MVP) **Estimación**: 5 puntos (13-21 horas)
**Estado**: 🔧 UI en mobile-professional, integración backend pendiente

#### US-003: Aprobación de Profesional (Admin)

**Como** admin de plataforma **Quiero** revisar y aprobar/rechazar solicitudes
de profesionales **Para** garantizar calidad y legitimidad

**Criterios de Aceptación**:

- [ ] Dashboard con lista de solicitudes pendientes
- [ ] Ver todos los documentos subidos por profesional
- [ ] Zoom/download de documentos
- [ ] Botón "Aprobar" → cambia estado a "ACTIVE" + email bienvenida
- [ ] Botón "Rechazar" → modal con razón → email explicando rechazo
- [ ] Log de todas las aprobaciones/rechazos (audit trail)

**Prioridad**: P0 (Blocker MVP) **Estimación**: 5 puntos (13-21 horas)

---

### Epic 2: Búsqueda y Reserva de Citas (Pacientes)

#### US-004: Búsqueda de Profesionales ✅ IMPLEMENTADO (Flutter)

**Como** paciente **Quiero** buscar profesionales por especialidad y ubicación
**Para** encontrar el más conveniente

**Criterios de Aceptación**:

- [x] Filtros: especialidad, ubicación (ciudad/barrio), disponibilidad ✅
- [x] Resultados muestran: foto, nombre, especialidad, rating, próxima
      disponibilidad ✅
- [x] Ordenar por: distancia, rating, precio ✅
- [ ] Vista lista y vista mapa (Google Maps) 🔧 Lista ✅, Mapa pendiente
- [x] Resultados en <2 segundos (caching) ✅

**Prioridad**: P0 (Blocker MVP) **Estimación**: 8 puntos (21-34 horas)
**Estado**: ✅ Implementado en mobile-patient con ProfessionalCard compartido

#### US-005: Ver Perfil de Profesional ✅ IMPLEMENTADO (Flutter)

**Como** paciente **Quiero** ver el perfil completo de un profesional **Para**
decidir si agendo con él/ella

**Criterios de Aceptación**:

- [x] Foto profesional, nombre completo, especialidad, credenciales ✅
- [x] Bio/descripción (200-500 chars) ✅
- [ ] Horarios disponibles (calendario interactivo) 🔧 UI lista, integración
      pendiente
- [ ] Ubicación (mapa + dirección) 🔧 Pendiente Google Maps integration
- [x] Precio por consulta (si aplica) ✅
- [x] Botón "Reservar Cita" (CTA prominente) ✅

**Prioridad**: P0 (Blocker MVP) **Estimación**: 5 puntos **Estado**: ✅ UI
implementada, calendario pendiente de integración backend

#### US-006: Reservar Cita ✅ IMPLEMENTADO (Flutter)

**Como** paciente **Quiero** reservar una cita en 3 taps **Para** agendar
rápidamente

**Criterios de Aceptación**:

- [x] Step 1: Seleccionar fecha y hora del calendario ✅
- [x] Step 2: Agregar motivo de consulta (opcional, text area) ✅
- [x] Step 3: Confirmar (resumen: profesional, fecha/hora, precio) ✅
- [x] Cita creada con estado "CONFIRMED" (sin pago previo en MVP) ✅
- [ ] Email de confirmación a paciente y profesional 🔧 Backend pendiente
- [ ] Agregar a calendario (iCal/Google Calendar link) 🔧 Pendiente
- [x] Total time to book: <30 segundos ✅

**Prioridad**: P0 (Blocker MVP) **Estimación**: 8 puntos **Estado**: ✅ UI
completa, notificaciones por email pendientes

---

### Epic 3: Gestión de Citas (Profesionales)

#### US-007: Ver Agenda del Día

**Como** profesional **Quiero** ver mi agenda del día en un vistazo **Para**
saber qué citas tengo

**Criterios de Aceptación**:

- [ ] Vista lista con todas las citas del día
- [ ] Cada cita muestra: hora, paciente (nombre, foto), motivo, estado
- [ ] Estados: CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED
- [ ] Botón "Iniciar Consulta" (cambia estado a IN_PROGRESS)
- [ ] Botón "Completar" (cambia estado a COMPLETED + modal notas)
- [ ] Badge con # citas pendientes hoy

**Prioridad**: P0 (Blocker MVP) **Estimación**: 5 puntos

#### US-008: Gestionar Disponibilidad

**Como** profesional **Quiero** configurar mis horarios de atención **Para** que
pacientes solo reserven cuando estoy disponible

**Criterios de Aceptación**:

- [ ] Vista semanal (Lun-Dom)
- [ ] Por cada día: ON/OFF + horario inicio/fin + duración cita (15, 30, 45, 60
      min)
- [ ] Bloquear días específicos (vacaciones, feriados)
- [ ] Bloquear slots específicos (reunión, emergencia)
- [ ] Cambios se reflejan en calendario pacientes en <1 minuto

**Prioridad**: P0 (Blocker MVP) **Estimación**: 8 puntos

#### US-009: Cancelar Cita (Profesional)

**Como** profesional **Quiero** cancelar una cita si tengo una emergencia
**Para** liberar el slot

**Criterios de Aceptación**:

- [ ] Botón "Cancelar" en cita
- [ ] Modal: razón de cancelación (required) + mensaje opcional al paciente
- [ ] Estado → CANCELLED_BY_PROFESSIONAL
- [ ] Email automático a paciente
- [ ] Notificación push a paciente (si mobile app instalada)
- [ ] Slot liberado en calendario

**Prioridad**: P1 (Important) **Estimación**: 3 puntos

---

### Epic 4: Historial Clínico

#### US-010: Agregar Notas a Cita

**Como** profesional **Quiero** agregar notas clínicas después de la consulta
**Para** recordar detalles del paciente

**Criterios de Aceptación**:

- [ ] Al completar cita: modal "Notas de Consulta"
- [ ] Text area libre (markdown supported)
- [ ] Campos estructurados opcionales: diagnóstico, tratamiento, próxima cita
      sugerida
- [ ] Notas visibles solo para el profesional (privacidad)
- [ ] Editar notas hasta 24 horas después de la cita

**Prioridad**: P0 (Blocker MVP) **Estimación**: 5 puntos

#### US-011: Ver Historial de Paciente

**Como** profesional **Quiero** ver el historial completo de un paciente
**Para** tener contexto antes de la consulta

**Criterios de Aceptación**:

- [ ] Vista cronológica de todas las citas pasadas con este paciente
- [ ] Cada cita muestra: fecha, motivo, notas, diagnóstico, tratamiento
- [ ] Buscar en historial (por keyword)
- [ ] Exportar historial a PDF (futuro)

**Prioridad**: P1 (Important) **Estimación**: 5 puntos

---

### Epic 5: Notificaciones y Recordatorios

#### US-012: Recordatorios Automáticos

**Como** paciente **Quiero** recibir recordatorios de mi cita **Para** no
olvidarla

**Criterios de Aceptación**:

- [ ] Email 24 horas antes de la cita
- [ ] Email 2 horas antes de la cita
- [ ] Push notification 1 hora antes (si app instalada)
- [ ] SMS opcional (futuro, costo)
- [ ] Incluir botón "Cancelar cita" en email

**Prioridad**: P0 (Blocker MVP) **Estimación**: 5 puntos

#### US-013: Notificación de Cancelación

**Como** paciente o profesional **Quiero** ser notificado si la otra parte
cancela **Para** estar informado

**Criterios de Aceptación**:

- [ ] Email inmediato
- [ ] Push notification inmediata
- [ ] Incluir razón de cancelación (si proporcionada)
- [ ] Sugerir reagendar (botón CTA)

**Prioridad**: P1 (Important) **Estimación**: 3 puntos

---

### Epic 6: Pagos y Suscripciones (Post-MVP Fase 2)

#### US-014: Configurar Suscripción (Profesional)

**Como** profesional **Quiero** elegir un plan de suscripción **Para**
desbloquear features

**Criterios de Aceptación**:

- [ ] Ver comparativa de planes (Free, Pro, Enterprise)
- [ ] Límites por plan: # pacientes, # citas/mes, features
- [ ] Checkout con Stripe (tarjeta crédito/débito)
- [ ] Factura automática mensual
- [ ] Cambiar plan en cualquier momento (proration)

**Prioridad**: P2 (Fase 2) **Estimación**: 13 puntos

#### US-015: Cobrar Consulta (Futuro)

**Como** profesional **Quiero** cobrar la consulta online **Para** no depender
de efectivo

**Criterios de Aceptación**:

- [ ] Paciente paga al reservar o al completar cita (configurable)
- [ ] Payment intent con Stripe
- [ ] Profesional recibe pago - comisión plataforma (ej: 10%)
- [ ] Reembolso automático si profesional cancela <24h antes

**Prioridad**: P3 (Post-MVP) **Estimación**: 21 puntos

---

## 🔧 Requisitos Funcionales - Sistema

### Multi-Tenancy

**REQ-FUNC-001**: Aislamiento de Datos

- Cada profesional es un "tenant"
- Pacientes pueden pertenecer a múltiples tenants (reservar con múltiples
  profesionales)
- Firestore structure: `/tenants/{professionalId}/patients/{patientId}`
- Security rules: usuarios solo acceden a sus datos o datos compartidos con
  ellos

**REQ-FUNC-002**: Gestión de Tenants

- Admin puede ver todos los tenants
- Admin puede suspender/activar tenants
- Tenant Enterprise puede tener infraestructura dedicada (silo model)

### RBAC (Role-Based Access Control)

**REQ-FUNC-003**: Roles del Sistema

- `PATIENT`: Puede buscar profesionales, reservar citas, ver su historial
- `PROFESSIONAL`: Puede gestionar agenda, pacientes, notas clínicas
- `ASSISTANT`: (Futuro) Puede gestionar agenda en nombre del profesional
- `ADMIN_PLATFORM`: Puede aprobar profesionales, moderar, ver analytics
- `SUPER_ADMIN`: Acceso total al sistema

**REQ-FUNC-004**: Permisos Granulares

- Permisos por recurso: `appointments:read`, `appointments:create`,
  `appointments:update`, `appointments:delete`
- Matrix de permisos por rol (ver tabla en plan estratégico)

### API Versioning

**REQ-FUNC-005**: Versionado Semántico

- API v1: Monolito legacy (deprecate en Mes 10)
- API v2: Microservicios (auth, appointments, etc.)
- Backward compatibility mantenida 6 meses después de deprecation notice

---

## 🛡️ Requisitos No Funcionales

### Performance

**REQ-PERF-001**: Latency

- API p95 latency < 200ms (backend)
- API p99 latency < 500ms (backend)
- Mobile app startup time < 3 segundos
- Web admin first contentful paint < 1.5 segundos

**REQ-PERF-002**: Throughput

- Staging: 100 requests/segundo (suficiente)
- Producción: 1,000 requests/segundo (escalable a 10k)

**REQ-PERF-003**: Availability

- Staging: 95% uptime (best effort)
- Producción: 99.9% uptime (SLA: <43 min downtime/mes)

### Security

**REQ-SEC-001**: Autenticación

- Multi-factor authentication (MFA) opcional para profesionales
- Session timeout: 30 días inactivity
- JWT tokens con refresh token rotation

**REQ-SEC-002**: Autorización

- Todos los endpoints requieren autenticación (excepto health checks)
- RBAC enforced en API layer
- Firestore security rules como segunda capa

**REQ-SEC-003**: Encryption

- TLS 1.3 en tránsito (obligatorio)
- Firestore encryption at rest (default GCP)
- Secrets en Secret Manager (nunca en código)

**REQ-SEC-004**: Audit Logging

- Log todas las operaciones de profesionales en datos de pacientes
- Log todas las aprobaciones/rechazos de admin
- Retention: 7 años (preparación HIPAA futuro)

### Scalability

**REQ-SCALE-001**: Horizontal Scaling

- Cloud Run autoscaling (0 a 100 instancias)
- Firestore autoscaling nativo
- Cloud SQL read replicas si necesario

**REQ-SCALE-002**: Caching

- Redis para hot paths (user permissions, tenant config)
- CDN para assets estáticos (avatars, images)
- TTL configurables por tipo de data

### Compliance (Latinoamérica)

**REQ-COMP-001**: Protección de Datos Personales

- Cumplir con leyes locales (Colombia: Ley 1581, México: LFPDPPP, etc.)
- Consentimiento explícito para uso de datos
- Derechos ARCO implementados (Acceso, Rectificación, Cancelación, Oposición)

**REQ-COMP-002**: Datos Sensibles

- Historial clínico es dato sensible (requiere consentimiento especial)
- Encriptación adicional para notas clínicas (futuro)
- Acceso audit logged

**REQ-COMP-003**: Preparación HIPAA (diseño futuro)

- Arquitectura debe permitir HIPAA compliance si se expande a USA
- BAA-compliant GCP services (Firestore, Cloud Run)
- Audit logs 7 años

### Testing

**REQ-TEST-001**: Coverage

- Unit tests: 80% backend, 80% frontend web, 70% mobile
- Integration tests: Critical paths
- E2E tests: 100% critical user journeys

**REQ-TEST-002**: Quality Gates (CI/CD)

- Linting pass (ruff, eslint, dart analyze)
- Type checking pass (mypy, tsc)
- Security scan pass (Trivy, Snyk, Gitleaks)
- All tests pass
- Coverage thresholds met

### Observability

**REQ-OBS-001**: Logging

- Structured logging (JSON) con correlation IDs
- Log levels: DEBUG (local), INFO (staging), WARNING (prod)
- Retention: 7 días staging, 30 días producción

**REQ-OBS-002**: Metrics

- Latency percentiles (p50, p90, p95, p99)
- Error rates por endpoint
- Custom business metrics (citas creadas/día, MAU, etc.)

**REQ-OBS-003**: Tracing

- Distributed tracing con Cloud Trace
- Correlation IDs propagados entre todos los servicios

**REQ-OBS-004**: Alerting

- Error rate > 5% → Page on-call
- Latency p95 > 500ms → Warning
- Service down → Page immediately

---

## 🎨 Diseño UX/UI

### Principios de Diseño

1. **Mobile-First**: 70% usuarios en mobile, diseñar para mobile primero
2. **Accesibilidad**: WCAG 2.1 AA compliance (mantener 100/100 actual)
3. **Simplicidad**: Cada pantalla debe tener 1 objetivo claro
4. **Feedback**: Siempre mostrar estado de carga, éxito, error
5. **Confianza**: Diseño profesional, evitar parecer "app genérica"

### Paleta de Colores

**Paciente App**:

- Primary: Azul suave (#4A90E2) - Confianza, salud
- Secondary: Verde (#7ED321) - Éxito, confirmación
- Accent: Naranja suave (#F5A623) - Urgencia moderada

**Profesional App**:

- Primary: Azul oscuro (#2C3E50) - Profesionalismo
- Secondary: Gris (#95A5A6) - Neutral
- Accent: Verde corporativo (#27AE60) - Acción

**Admin Web**:

- Neutrales (shadcn/ui default) - Funcionalidad > estética

### Componentes Clave (Flutter - Mobile) ✅ IMPLEMENTADOS

**Shared Components (flutter-shared package):**

- **AppointmentCard**: Cita en lista (foto, nombre, hora, botones acción) ✅
  Reutilizado en patient y professional
- **ProfessionalCard**: Profesional en búsqueda (foto, especialidad, rating,
  precio, CTA) ✅
- **EmptyState**: Cuando no hay datos (icono, título, mensaje) ✅ Usado en
  múltiples pantallas

**Domain Models (flutter-core package):**

- **Professional**: Entidad con 20+ campos (id, userId, specialty, rating,
  isVerified, etc.) ✅
- **Appointment**: Entidad con estados (pending, confirmed, inProgress,
  completed, cancelled, noShow) ✅
- **Specialty**: Enum con 8 especialidades médicas ✅
- **AppointmentStatus**: Enum con lógica de negocio (isActive, canCancel,
  isFinished) ✅

**Feature-Specific:**

- CalendarPicker: Pendiente implementación con calendar package
- StatusBadge: Implementado en AppointmentCard con color coding

### Componentes Clave (React - Admin Web)

- **ApprovalQueue**: Lista de solicitudes pendientes (shadcn/ui Table)
- **DocumentViewer**: Visor de PDFs/imágenes (zoom, download)
- **MetricsDashboard**: KPIs del negocio (recharts)
- **ActionDialog**: Confirmación de acciones críticas (shadcn/ui Dialog)

---

## 🚀 Criterios de Éxito MVP

### Métricas de Producto

1. **Onboarding Completion Rate**: >60% (profesionales completan registro)
2. **Time to First Appointment**: <7 días (profesional aprobado → primera cita)
3. **Appointment Booking Success**: >90% (pacientes completan reserva)
4. **No-Show Rate**: <20% (con recordatorios automáticos)
5. **Daily Active Professionals**: >50 en primer mes post-launch

### Métricas Técnicas

1. **API Uptime**: >99% (staging), >99.9% (producción)
2. **API Latency p95**: <200ms
3. **Mobile App Crash Rate**: <1%
4. **Test Coverage**: >80% backend, >70% mobile
5. **Security**: 0 vulnerabilities críticas (Snyk/Trivy)

### Criterios de Lanzamiento (Go/No-Go)

Antes de lanzar a producción, MUST have:

- ✅ Todos los User Stories P0 completados
- ✅ E2E tests passing (100% critical paths)
- ✅ Penetration test passed (externo)
- ✅ Performance benchmarks met (latency, throughput)
- ✅ Disaster recovery tested
- ✅ Runbooks documentados
- ✅ On-call rotation definida
- ✅ Budget alerts configurados

---

## 📈 Roadmap Post-MVP

### Fase 2 (Mes 13-18): Monetización

- Suscripciones freemium
- Pagos online (Stripe)
- Facturación automática
- Reportes financieros profesionales

### Fase 3 (Mes 19-24): Features Avanzados

- Telemedicina (videollamadas Jitsi/Twilio)
- Recetas electrónicas
- Laboratorios y farmacias integrations
- Marketplace de servicios

### Fase 4 (Mes 25+): Expansión

- Multi-región (Brazil, USA)
- HIPAA compliance completo (USA)
- AI features (chatbot, recomendaciones)
- Multi-idioma (português, inglés)

---

## ✅ Definition of Done (DoD)

Una User Story está "Done" cuando:

1. **Code Complete**:
   - [ ] Código escrito y peer-reviewed
   - [ ] Linting y type checking passing
   - [ ] No warnings críticos

2. **Tested**:
   - [ ] Unit tests escritos (coverage >80%)
   - [ ] Integration tests si aplica
   - [ ] E2E test si critical path
   - [ ] Manual QA passed

3. **Secure**:
   - [ ] Security scan passed (Snyk, Trivy)
   - [ ] No hardcoded secrets
   - [ ] Auth/authz implemented

4. **Deployed**:
   - [ ] Desplegado en staging
   - [ ] Smoke tests passing
   - [ ] Validated por Product Owner

5. **Documented**:
   - [ ] API docs actualizados (OpenAPI)
   - [ ] Runbook actualizado si nuevo servicio
   - [ ] User-facing docs si feature visible

---

## 🔗 Referencias

- **Plan Estratégico**: `docs/planning/health-platform-strategy.plan.md`
- **Arquitectura Microservicios**:
  `docs/architecture/microservices-migration-strategy.md`
- **FinOps**: `docs/finops/cost-analysis-and-budgets.md`
- **Testing Strategy**: `docs/quality/testing-strategy-microservices.md`

---

**Documento**: `docs/planning/health-platform-prd.md` **Version**: 1.1 **Última
actualización**: 2025-10-18 **Owner**: Product Team **Stakeholders**:
Engineering, Design, Business **Next Review**: Mes 3 (tras Fase 0 completa)

---

## 📱 Estado de Implementación Actual (Actualizado 2025-10-18)

### ✅ Completado

**Flutter Mobile Apps:**

- mobile-patient (iOS/Android/Web): Autenticación, búsqueda profesionales,
  reserva citas
- mobile-professional (iOS/Android/Web): Dashboard, gestión citas, gestión
  pacientes
- Shared packages (flutter-core, flutter-shared): 85%+ code reuse

**Microservicios (En Desarrollo):**

- api-auth, api-appointments, api-admin, api-analytics (Python/FastAPI)
- api-payments, api-notifications (Node.js/Express)

**React Admin Panel:**

- Autenticación, gestión profesionales, 100% accesibilidad (WCAG 2.1 AA)

### 🔧 En Desarrollo

- Integración completa de microservicios
- Multi-tenancy Firestore (actualmente single-tenant)
- Terraform IaC
- Cloud SQL para analytics

### ⚠️ Pendiente

- Videoconsultas (Jitsi)
- Pagos online (Stripe integration completa)
- Notificaciones push en producción

---

## 🤖 Para Task Master AI

Este PRD está optimizado para `task-master parse-prd`. Las User Stories tienen
formato consistente:

```
#### US-XXX: Título
**Como** [rol]
**Quiero** [acción]
**Para** [beneficio]

**Criterios de Aceptación**:
- [ ] Criterio 1
- [ ] Criterio 2

**Prioridad**: P0/P1/P2
**Estimación**: X puntos
```

Para generar tareas:

```bash
npx task-master-ai parse-prd \
  --input docs/planning/health-platform-prd.md \
  --output .taskmaster/tasks.json \
  --tag mvp
```
