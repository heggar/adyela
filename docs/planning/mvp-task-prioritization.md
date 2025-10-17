# MVP Task Prioritization Strategy

**Fecha**: 11 de Enero, 2025 **Versión**: 1.0 **Proyecto**: Adyela Health System

---

## 📋 Resumen Ejecutivo

Basado en el análisis de costos de compliance HIPAA, este documento clasifica
todas las tareas del proyecto en **críticas para MVP** vs **opcionales para
post-MVP**.

**Conclusión clave**: Podemos implementar un MVP con infraestructura HIPAA-Ready
por solo **$1.20/mes adicionales**, postponiendo únicamente 2 componentes
costosos hasta tener usuarios reales procesando PHI.

---

## 🎯 Estrategia de MVP

### Principios Guía

1. ✅ **Implementar infraestructura HIPAA-Ready desde el inicio** (costo mínimo:
   $1.20/mes)
2. ⏸️ **Postponer solo 2 componentes**: CMEK y Cloud Armor WAF (costo:
   $5.29/mes)
3. 🚀 **Priorizar features core** sobre features avanzadas
4. 📊 **Validar product-market fit** antes de escalar
5. 💰 **Mantener costos bajo $5/mes** durante MVP

---

## 🏗️ Infraestructura: Crítico vs Opcional

### ✅ CRÍTICO - Implementar en MVP (Costo: $1.20/mes)

Estas 12 tareas de infraestructura deben implementarse para el MVP:

#### 1. **VPC y Networking** - $0.00/mes (FREE)

**Prioridad**: P0 - Bloqueante **Justificación**: Base de toda la seguridad y
aislamiento de red **Tiempo estimado**: 2-3 horas **Tareas**:

- Crear VPC dedicada para Adyela
- Configurar subnets privadas
- Establecer Cloud NAT para salida controlada
- Configurar Cloud DNS privado

#### 2. **Identity Platform (Firebase Auth)** - $0.00/mes (FREE hasta 50K MAU)

**Prioridad**: P0 - Bloqueante **Justificación**: Autenticación segura es
obligatoria para cualquier sistema con PHI **Tiempo estimado**: 4-6 horas
**Tareas**:

- Configurar Identity Platform
- Implementar MFA (Multi-Factor Authentication)
- Configurar políticas de password
- Implementar rate limiting

#### 3. **API Gateway** - $0.45/mes

**Prioridad**: P0 - Bloqueante **Justificación**: Control de acceso centralizado
y rate limiting **Tiempo estimado**: 3-4 horas **Tareas**:

- Configurar API Gateway
- Implementar rate limiting (10K requests/mes)
- Configurar CORS policies
- Establecer API versioning

#### 4. **Cloud Run (Backend API)** - Incluido en costo base

**Prioridad**: P0 - Bloqueante **Justificación**: Runtime de la aplicación
backend **Tiempo estimado**: Ya implementado, solo configuración HIPAA
**Tareas**:

- Configurar service account con permisos mínimos
- Habilitar Cloud Run VPC connector
- Configurar health checks
- Establecer autoscaling limits (1-10 instancias)

#### 5. **Firestore** - $0.18/mes

**Prioridad**: P0 - Bloqueante **Justificación**: Base de datos para la
aplicación **Tiempo estimado**: 2-3 horas **Tareas**:

- Configurar Firestore en modo privado (VPC)
- Implementar reglas de seguridad granulares
- Configurar índices optimizados
- Establecer backups automáticos

#### 6. **Cloud Storage** - $0.13/mes

**Prioridad**: P1 - Alta **Justificación**: Almacenamiento de archivos y
documentos **Tiempo estimado**: 2-3 horas **Tareas**:

- Configurar buckets con acceso privado
- Implementar signed URLs para acceso temporal
- Configurar lifecycle policies
- Establecer CORS si es necesario

#### 7. **VPC Service Controls** - $0.00/mes (FREE)

**Prioridad**: P0 - Bloqueante **Justificación**: Previene exfiltración de datos
(requisito HIPAA crítico) **Tiempo estimado**: 3-4 horas **Tareas**:

- Crear perimeter de seguridad
- Configurar políticas de ingress/egress
- Restringir acceso a servicios GCP desde dentro del perimeter
- Configurar access levels

#### 8. **Secret Manager** - $0.24/mes

**Prioridad**: P0 - Bloqueante **Justificación**: Manejo seguro de credenciales
(ya en uso parcialmente) **Tiempo estimado**: 1-2 horas (configuración
adicional) **Tareas**:

- Migrar todas las secrets a Secret Manager
- Configurar versionamiento automático
- Implementar rotation policies
- Configurar acceso basado en service accounts

#### 9. **Cloud Monitoring + Logging** - $0.00/mes (FREE hasta 50GB/mes)

**Prioridad**: P0 - Bloqueante **Justificación**: Audit logging es requisito
obligatorio HIPAA **Tiempo estimado**: 3-4 horas **Tareas**:

- Configurar Data Access Audit Logs
- Implementar log sinks para retención >7 años
- Crear dashboards de monitoreo
- Configurar alertas críticas

#### 10. **Audit Logging específico para PHI** - $0.00/mes (FREE)

**Prioridad**: P0 - Bloqueante **Justificación**: Obligatorio por HIPAA Security
Rule **Tiempo estimado**: 4-6 horas **Tareas**:

- Implementar logging de todos los accesos a PHI
- Capturar: user_id, patient_id, action, timestamp, reason
- Configurar tamper-proof storage (Cloud Storage Bucket locked)
- Implementar retention de 7 años mínimo

#### 11. **IAM Policies (Least Privilege)** - $0.00/mes (FREE)

**Prioridad**: P0 - Bloqueante **Justificación**: Principio de mínimo privilegio
(HIPAA Security Rule) **Tiempo estimado**: 3-4 horas **Tareas**:

- Crear service accounts por servicio
- Implementar RBAC granular
- Eliminar permisos de Owner/Editor
- Documentar matriz de permisos

#### 12. **TLS 1.3 en todas las comunicaciones** - $0.00/mes (FREE)

**Prioridad**: P0 - Bloqueante **Justificación**: Encriptación en tránsito
(HIPAA Security Rule) **Tiempo estimado**: 1-2 horas **Tareas**:

- Configurar Cloud Run con TLS 1.3 mínimo
- Implementar HTTPS-only en API Gateway
- Configurar certificados SSL/TLS automáticos
- Verificar cipher suites seguras

**Total Costo MVP Infraestructura Crítica: $1.00/mes** **Tiempo Total Estimado:
28-41 horas**

---

### ⏸️ OPCIONAL - Postponer hasta Post-MVP (Costo: $5.29/mes)

Estas 2 tareas se activan cuando hay usuarios reales procesando PHI:

#### 13. **CMEK (Customer-Managed Encryption Keys)** - $0.12/mes

**Prioridad**: P2 - Media (activar con primeros 100 usuarios) **Justificación**:
Google-managed encryption es suficiente para MVP **Cuándo activar**: Al tener
primeros 100 usuarios activos o primeros contratos enterprise **Tiempo de
activación**: 2-3 horas **Tareas**:

- Crear key ring en Cloud KMS
- Configurar rotation automática (90 días)
- Aplicar CMEK a Firestore y Cloud Storage
- Actualizar service accounts con permisos de encryptDecrypt

#### 14. **Cloud Armor WAF** - $5.17/mes

**Prioridad**: P2 - Media (activar con tráfico real) **Justificación**: Rate
limiting en API Gateway es suficiente para MVP **Cuándo activar**: Al superar
10K requests/día o detectar primeros ataques **Tiempo de activación**: 3-4 horas
**Tareas**:

- Configurar Cloud Armor en API Gateway
- Implementar reglas OWASP Top 10
- Configurar rate limiting avanzado
- Establecer geo-blocking si es necesario

**Total Costo Infraestructura Opcional: $5.29/mes** **Tiempo Total Activación:
5-7 horas**

---

## 🚀 Features de Aplicación: Crítico vs Opcional

### ✅ CRÍTICO - MVP Core Features

#### **Core Feature 1: Autenticación y Registro**

**Prioridad**: P0 - Bloqueante **User Stories**:

- ✅ Como paciente, quiero registrarme con email/password
- ✅ Como paciente, quiero hacer login con MFA
- ✅ Como doctor, quiero acceder con credenciales organizacionales
- ✅ Como usuario, quiero recuperar mi contraseña

**Estado actual**: ✅ Implementado (E2E tests: 16/16 passing)

#### **Core Feature 2: Gestión de Citas**

**Prioridad**: P0 - Bloqueante **User Stories**:

- ✅ Como paciente, quiero ver citas disponibles
- ✅ Como paciente, quiero agendar una cita
- ✅ Como paciente, quiero cancelar una cita
- ✅ Como doctor, quiero ver mi agenda del día
- ✅ Como doctor, quiero confirmar/rechazar citas

**Estado actual**: ✅ Implementado parcialmente (core funcionalidad lista)

#### **Core Feature 3: Videoconsultas**

**Prioridad**: P0 - Bloqueante (diferenciador clave) **User Stories**:

- ✅ Como paciente, quiero unirme a videollamada a la hora de mi cita
- ✅ Como doctor, quiero iniciar videoconsulta con paciente
- ⚠️ Como usuario, quiero que la llamada sea segura y encriptada

**Estado actual**: ⚠️ Jitsi integrado, falta validación HIPAA de la
implementación

**Tareas pendientes**:

- Verificar que Jitsi esté en modo self-hosted (no usar servidores públicos)
- Implementar end-to-end encryption (E2EE)
- Configurar recording HIPAA-compliant si es necesario
- Agregar audit logging de sesiones de video

**Tiempo estimado**: 6-8 horas

#### **Core Feature 4: Perfil de Paciente (Mínimo)**

**Prioridad**: P0 - Bloqueante **User Stories**:

- ✅ Como paciente, quiero ver mis datos personales
- ✅ Como paciente, quiero editar mi información de contacto
- ⚠️ Como paciente, quiero ver el historial de mis citas

**Estado actual**: ✅ Implementado básico

#### **Core Feature 5: Dashboard de Doctor**

**Prioridad**: P0 - Bloqueante **User Stories**:

- ✅ Como doctor, quiero ver lista de pacientes del día
- ✅ Como doctor, quiero acceder rápidamente a citas próximas
- ⚠️ Como doctor, quiero ver alertas de citas pendientes de confirmar

**Estado actual**: ✅ Implementado básico

---

### ⏸️ OPCIONAL - Post-MVP Features

#### **Feature Avanzada 1: Recetas Médicas (Prescriptions)**

**Prioridad**: P1 - Alta (post-MVP) **Justificación**: Aumenta complejidad legal
y requiere integración con farmacias **Cuándo implementar**: Después de validar
PMF con features core **User Stories**:

- Como doctor, quiero generar receta digital
- Como paciente, quiero ver mis recetas activas
- Como farmacia, quiero validar recetas

**Tiempo estimado**: 20-30 horas **Dependencias**: Integración con sistema de
farmacias, validación legal

#### **Feature Avanzada 2: Historial Médico Completo (EMR)**

**Prioridad**: P1 - Alta (post-MVP) **Justificación**: Requiere compliance
adicional y estructura de datos compleja **Cuándo implementar**: Después de 6
meses con MVP en producción **User Stories**:

- Como doctor, quiero registrar notas de consulta estructuradas
- Como paciente, quiero ver mi historial médico completo
- Como especialista, quiero importar historial de otros proveedores

**Tiempo estimado**: 40-60 horas **Dependencias**: FHIR compliance,
interoperabilidad HL7

#### **Feature Avanzada 3: Laboratorios e Imágenes**

**Prioridad**: P2 - Media (futuro) **Justificación**: Requiere integraciones
externas y storage costoso **Cuándo implementar**: Fase 2 (año 2) **User
Stories**:

- Como doctor, quiero solicitar exámenes de laboratorio
- Como paciente, quiero ver resultados de mis exámenes
- Como doctor, quiero visualizar imágenes médicas (DICOM)

**Tiempo estimado**: 60-80 horas **Costo adicional**: Storage de imágenes DICOM
(~$2-5/mes adicionales)

#### **Feature Avanzada 4: Pagos y Facturación**

**Prioridad**: P1 - Alta (post-MVP) **Justificación**: Requiere integración con
payment gateway y complejidad fiscal **Cuándo implementar**: Después de validar
modelo de negocio **User Stories**:

- Como paciente, quiero pagar consultas con tarjeta
- Como clínica, quiero generar facturas automáticas
- Como administrador, quiero reportes financieros

**Tiempo estimado**: 30-40 horas **Costo adicional**: Payment gateway fees
(Stripe ~2.9% + $0.30)

#### **Feature Avanzada 5: Multi-idioma Completo**

**Prioridad**: P2 - Media (futuro) **Justificación**: MVP funciona con ES/EN
**Cuándo implementar**: Al expandir a nuevos mercados **Tiempo estimado**: 15-20
horas

---

## 📊 Resumen de Priorización

### MVP Scope (Fase 0: Meses 1-3)

**Infraestructura**:

- ✅ 12 componentes HIPAA-Ready (costo: $1.20/mes)
- ⏸️ 2 componentes postponer (CMEK, Cloud Armor)

**Features**:

- ✅ Autenticación + MFA
- ✅ Gestión de citas
- ⚠️ Videoconsultas (requiere validación HIPAA)
- ✅ Perfil básico de paciente
- ✅ Dashboard básico de doctor

**Tiempo total estimado MVP**: 35-50 horas **Costo mensual MVP**: $3.20/mes
($2.00 base + $1.20 HIPAA)

### Post-MVP Scope (Fase 1: Meses 4-9)

**Infraestructura**:

- Activar CMEK cuando se alcancen 100 usuarios (+$0.12/mes)
- Activar Cloud Armor WAF cuando se superen 10K req/día (+$5.17/mes)

**Features**:

- Recetas médicas
- Pagos y facturación
- Historial médico expandido

**Tiempo estimado Fase 1**: 50-70 horas **Costo mensual Fase 1**: $8.49/mes

---

## 🎯 Plan de Implementación MVP

### Sprint 1: Infraestructura HIPAA-Ready (Semana 1-2)

**Objetivos**:

- Implementar 12 componentes de infraestructura críticos
- Costo objetivo: $1.20/mes adicionales

**Tasks**:

1. ✅ VPC + Networking (2-3h)
2. ✅ Identity Platform configuración avanzada (4-6h)
3. ✅ API Gateway (3-4h)
4. ✅ Cloud Run con VPC connector (2-3h)
5. ✅ Firestore en modo privado (2-3h)
6. ✅ Cloud Storage seguro (2-3h)
7. ✅ VPC Service Controls (3-4h)
8. ✅ Secret Manager completo (1-2h)
9. ✅ Cloud Monitoring + Logging (3-4h)
10. ✅ Audit Logging PHI (4-6h)
11. ✅ IAM Policies (3-4h)
12. ✅ TLS 1.3 enforcement (1-2h)

**Deliverables**:

- Infraestructura desplegada en staging
- Documentación de configuración
- Tests de seguridad pasando
- Costo verificado ≤ $5/mes

### Sprint 2: Validación HIPAA de Features (Semana 3)

**Objetivos**:

- Validar que features core cumplan HIPAA
- Completar audit logging en toda la aplicación

**Tasks**:

1. Validar Jitsi self-hosted con E2EE (6-8h)
2. Implementar audit logging en todos los endpoints que acceden PHI (8-10h)
3. Agregar tests de seguridad para PHI access (4-6h)
4. Documentar flujos de datos sensibles (3-4h)

**Deliverables**:

- Videoconsultas HIPAA-compliant
- 100% de accesos a PHI loggeados
- Documentación de compliance actualizada

### Sprint 3: Testing y Deployment (Semana 4)

**Objetivos**:

- Ejecutar full testing suite
- Desplegar a staging con infraestructura HIPAA-Ready

**Tasks**:

1. E2E tests completos (verificar 16/16 passing)
2. Security audit con Bandit + npm audit
3. Lighthouse audit (target: Performance 90+)
4. Deployment a staging
5. Smoke tests en staging

**Deliverables**:

- MVP desplegado en staging
- Todos los tests en verde
- Costo real medido

---

## 💰 Análisis de Costos por Fase

### Fase 0: MVP (Mes 1-3)

```
Base Infrastructure:      $2.00/mes
HIPAA-Ready Components:   $1.20/mes
─────────────────────────────────
Total:                    $3.20/mes
```

### Fase 1: Early Growth (Mes 4-9, 100-1000 usuarios)

```
Base Infrastructure:      $2.00/mes
HIPAA-Ready Components:   $1.20/mes
CMEK (activado):          $0.12/mes
Cloud Armor (activado):   $5.17/mes
─────────────────────────────────
Total:                    $8.49/mes
```

### Fase 2: Scale (Mes 10-18, 1K-10K usuarios)

```
Base Infrastructure:      $5.00/mes (scaled)
HIPAA-Ready Components:   $2.50/mes (scaled)
CMEK:                     $0.24/mes (scaled)
Cloud Armor:             $12.00/mes (scaled)
Image Storage:            $5.00/mes (new)
─────────────────────────────────
Total:                   $24.74/mes
```

---

## ✅ Recomendación Final

### Decisión: **Implementar MVP con Infraestructura HIPAA-Ready**

**Razones**:

1. ✅ **Costo mínimo**: Solo $1.20/mes adicionales (incremental cost de 60%)
2. ✅ **Evita migración futura**: Implementar HIPAA después es 10x más costoso
   en tiempo
3. ✅ **Compliance desde día 1**: Podemos aceptar clientes healthcare
   inmediatamente
4. ✅ **Diferenciador competitivo**: La mayoría de MVPs no son HIPAA-compliant
5. ✅ **Tiempo de activación rápido**: Solo 35-50 horas de implementación
6. ✅ **Escalabilidad**: Solo activar CMEK y Cloud Armor cuando sea necesario

**Componentes a postponer**:

- ⏸️ CMEK (Customer-Managed Encryption Keys): $0.12/mes
- ⏸️ Cloud Armor WAF: $5.17/mes

**Features a postponer**:

- ⏸️ Recetas médicas
- ⏸️ EMR completo
- ⏸️ Laboratorios e imágenes
- ⏸️ Pagos y facturación
- ⏸️ Multi-idioma avanzado

---

## 📋 Checklist de Aceptación MVP

### Infraestructura (12/14 componentes)

- [ ] VPC configurada con subnets privadas
- [ ] Identity Platform con MFA activo
- [ ] API Gateway con rate limiting
- [ ] Cloud Run con VPC connector
- [ ] Firestore en modo privado
- [ ] Cloud Storage con acceso restringido
- [ ] VPC Service Controls activo
- [ ] Secret Manager con todas las secrets
- [ ] Cloud Monitoring configurado
- [ ] Audit Logging PHI implementado
- [ ] IAM Policies con least privilege
- [ ] TLS 1.3 enforced
- ⏸️ CMEK (postponer)
- ⏸️ Cloud Armor (postponer)

### Features Core

- [ ] Autenticación con MFA funcional
- [ ] Gestión de citas completa
- [ ] Videoconsultas HIPAA-compliant
- [ ] Perfil de paciente básico
- [ ] Dashboard de doctor funcional

### Quality Gates

- [ ] E2E tests: 16/16 passing
- [ ] Unit test coverage: ≥65%
- [ ] Security scan: 0 high/critical vulnerabilities
- [ ] Lighthouse Performance: ≥90
- [ ] Lighthouse Accessibility: 100
- [ ] Costo mensual: ≤$5/mes

### Documentation

- [ ] Architecture diagrams actualizados
- [ ] HIPAA compliance checklist completo
- [ ] API documentation completa
- [ ] Deployment guide actualizado

---

## 🎯 Métricas de Éxito del MVP

### Métricas Técnicas

- ✅ Costo mensual: $3.20/mes (target: <$5/mes)
- ✅ Uptime: 99.5% (target: >99%)
- ✅ Response time P95: <500ms (target: <1s)
- ✅ Tests passing: 100% (target: 100%)

### Métricas de Negocio (3 meses)

- 🎯 Usuarios registrados: 50-100
- 🎯 Citas agendadas: 200-500
- 🎯 Videoconsultas realizadas: 100-300
- 🎯 Net Promoter Score: >40

### Triggers para Fase 1

- ✅ 100+ usuarios activos mensuales → Activar CMEK
- ✅ 10K+ requests/día → Activar Cloud Armor
- ✅ Primeros 10 clientes pagos → Implementar facturación
- ✅ Solicitudes de recetas → Implementar prescriptions
- ✅ NPS >50 → Expandir features

---

## 📚 Referencias

- [HIPAA Compliance Cost Analysis](./hipaa-compliance-cost-analysis.md)
- [GCP Architecture Validation](../deployment/architecture-validation.md)
- [Final Quality Report](../../FINAL_QUALITY_REPORT.md)
- [Deployment Strategy](../../DEPLOYMENT_STRATEGY.md)

---

**Última actualización**: 11 de Enero, 2025 **Próxima revisión**: Al completar
Sprint 1 **Owner**: DevOps Team + Product Owner
