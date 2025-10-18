# Compliance y Regulaciones - Latinoamérica

## 📊 Resumen Ejecutivo

Este documento detalla los requisitos de compliance para la plataforma de salud
Adyela operando en Latinoamérica, con enfoque en protección de datos personales
y datos sensibles de salud.

**Mercado Objetivo**: Colombia, México, Chile, Argentina, Brasil **Enfoque
MVP**: Compliance básico operacional **Enfoque Post-MVP**: Escalable a HIPAA
(USA), GDPR (EU)

---

## 🌎 Regulaciones por País

### 🇨🇴 Colombia - Ley 1581 de 2012 (Protección de Datos Personales)

**Autoridad**: Superintendencia de Industria y Comercio (SIC)

**Requisitos Clave**:

1. **Consentimiento Informado**
   - Debe ser previo, expreso e informado
   - Para datos sensibles (salud): consentimiento explícito y por escrito
   - Debe informar finalidad, destinatarios, duración

   **Implementación**:

   ```javascript
   // Registro paciente - Checkbox obligatorio
   <Checkbox
     label="Acepto el tratamiento de mis datos personales según la Política de Privacidad"
     required
   />
   <Checkbox
     label="Autorizo el tratamiento de mis datos de salud (historial clínico, notas médicas) necesarios para la prestación del servicio"
     required
   />
   ```

2. **Derechos ARCO** (Acceso, Rectificación, Cancelación, Oposición)
   - **Acceso**: Usuario puede consultar sus datos
   - **Rectificación**: Corregir datos inexactos
   - **Cancelación**: Solicitar eliminación (derecho al olvido)
   - **Oposición**: Oponerse a ciertos tratamientos

   **Implementación**:
   - Panel "Mis Datos" en app paciente/profesional
   - Botón "Descargar mis datos" (exportar JSON/PDF)
   - Botón "Solicitar eliminación de cuenta"
   - Formulario de solicitud ARCO (respuesta en 15 días hábiles)

3. **Política de Privacidad**
   - Debe ser clara, accesible, comprensible
   - Incluir: responsable, finalidad, datos recolectados, derechos, contacto

4. **Transferencia Internacional**
   - Si datos salen de Colombia: consentimiento adicional
   - GCP us-central1 (USA) → requiere autorización
   - **Alternativa**: GCP southamerica-east1 (São Paulo) para data residency

5. **Registro de Bases de Datos**
   - Bases de datos con info personal deben registrarse ante SIC
   - **Deadline**: Antes de recolectar datos

**Sanciones**: Hasta USD $1M o 2% ingresos anuales

---

### 🇲🇽 México - LFPDPPP (Ley Federal de Protección de Datos Personales)

**Autoridad**: Instituto Nacional de Transparencia, Acceso a la Información y
Protección de Datos Personales (INAI)

**Requisitos Clave**:

1. **Aviso de Privacidad** (equivalente a Política de Privacidad)
   - Debe incluir: identidad del responsable, finalidad, datos a recolectar,
     opciones de limitar uso, medios para ejercer derechos ARCO
   - **Tipos**: Integral (documento completo), Simplificado (resumen), Corto
     (aviso breve)

2. **Consentimiento**
   - Datos sensibles (salud): consentimiento expreso
   - Puede ser tácito para datos no sensibles

3. **Derechos ARCO** (similar a Colombia)
   - Respuesta en 20 días hábiles
   - Medio para solicitar: formulario web, email

4. **Transferencia Internacional**
   - Requiere cláusulas contractuales estándar o BCR (Binding Corporate Rules)
   - GCP cumple con Privacy Shield successor

5. **Medidas de Seguridad**
   - Administrativas: políticas de seguridad, capacitación
   - Técnicas: encriptación, firewalls, control de acceso
   - Físicas: acceso controlado a servidores

**Implementación**:

- Aviso de Privacidad en 3 formatos (integral, simplificado, corto)
- Consentimiento checkbox en registro
- Portal ARCO en `/legal/arco`

**Sanciones**: Hasta USD $1.6M

---

### 🇨🇱 Chile - Ley 19.628 (Protección de Vida Privada)

**Autoridad**: Consejo para la Transparencia

**Requisitos Clave**:

1. **Consentimiento**
   - Debe ser por escrito para datos sensibles
   - Informar fuente, finalidad, destinatarios

2. **Derechos**
   - Información: conocer qué datos se tienen
   - Modificación: corregir datos
   - Eliminación: solicitar bloqueo o eliminación
   - Oposición: oponerse al tratamiento

3. **Registro de Bancos de Datos**
   - Bancos de datos personales deben registrarse
   - Banco de datos de salud: registro especial

4. **Seguridad**
   - Medidas técnicas y organizativas para proteger datos
   - Notificación de brechas de seguridad (best practice, no obligatorio)

**Implementación**: Similar a Colombia

**Sanciones**: Hasta USD $15K

---

### 🇦🇷 Argentina - Ley 25.326 (Protección de Datos Personales)

**Autoridad**: Agencia de Acceso a la Información Pública (AAIP)

**Requisitos Clave**:

1. **Consentimiento Libre, Expreso e Informado**
   - Para datos sensibles: consentimiento expreso y por escrito

2. **Derechos ARCO**
   - Acceso, Rectificación, Actualización, Supresión
   - Respuesta en 10 días hábiles

3. **Registro de Bases de Datos**
   - Todas las bases de datos deben registrarse ante AAIP
   - Incluye bases de datos de salud

4. **Transferencia Internacional**
   - Solo a países con nivel de protección adecuado
   - USA: requiere autorización o cláusulas contractuales

5. **Responsable de Seguridad**
   - Designar responsable de base de datos

**Implementación**:

- Registro de bases de datos ante AAIP antes de lanzamiento
- Designar Data Protection Officer (DPO)

**Sanciones**: Hasta USD $100K

---

### 🇧🇷 Brasil - LGPD (Lei Geral de Proteção de Dados)

**Autoridad**: Autoridade Nacional de Proteção de Dados (ANPD)

**Requisitos Clave** (similar a GDPR):

1. **Base Legal para Tratamiento**
   - Consentimiento, cumplimiento de contrato, obligación legal, protección de
     la vida, ejercicio de derechos, legítimo interés

2. **Consentimiento**
   - Debe ser específico, destacado, inequívoco
   - Para datos sensibles (salud): consentimiento específico y destacado

3. **Derechos del Titular**
   - Confirmación, acceso, corrección, anonimización, portabilidad, eliminación,
     información sobre compartir, revocación de consentimiento

4. **Data Protection Officer (DPO)**
   - **Obligatorio** para empresas que tratan datos sensibles
   - Contacto público para titulares y ANPD

5. **Privacy by Design & Default**
   - Diseñar sistemas con privacidad desde el inicio
   - Configuraciones por defecto deben proteger privacidad

6. **Notificación de Brechas**
   - Notificar ANPD y afectados en plazo razonable
   - Incluir medidas de mitigación

7. **Transferencia Internacional**
   - Solo a países con nivel adecuado de protección
   - Cláusulas contractuales estándar o BCR

**Implementación**:

- Designar DPO (email: dpo@adyela.com)
- Privacy impact assessment (PIA) para features nuevos
- Registro de actividades de tratamiento
- Plan de respuesta a brechas de seguridad

**Sanciones**: Hasta 2% ingresos anuales (max R$50M ~ USD $10M)

---

## 🔒 Datos Sensibles de Salud

### Clasificación de Datos

**Datos Personales Básicos**:

- Nombre, email, teléfono, fecha de nacimiento
- Ubicación (ciudad, barrio)
- Foto de perfil

**Datos Sensibles de Salud** (tratamiento especial):

- Historial clínico (notas de consultas)
- Diagnósticos, tratamientos, prescripciones
- Motivo de consulta
- Resultados de laboratorio
- Información de salud mental (psicología)

### Medidas de Protección Adicionales

1. **Consentimiento Explícito**

   ```javascript
   // Al crear historial clínico
   const consent = await showDialog({
     title: 'Autorización de Datos de Salud',
     message:
       'El profesional guardará notas sobre tu consulta. Esta información es confidencial y solo será accesible por ti y el profesional.',
     buttons: ['Autorizar', 'Cancelar'],
   });
   ```

2. **Encriptación en Reposo** (futuro - Fase 2)
   - Firestore encryption at rest (default GCP)
   - **Adicional**: Encriptación a nivel de aplicación para notas clínicas
   - Customer-Managed Encryption Keys (CMEK) para compliance estricto

3. **Acceso Restringido**
   - Solo el profesional que creó la nota puede verla
   - Paciente puede ver sus propias notas (read-only)
   - Admin NO puede ver notas clínicas (solo metadata)

4. **Audit Logging**

   ```python
   # Cada acceso a historial clínico se registra
   await audit_log.log_access(
       user_id=current_user.id,
       resource_type="clinical_notes",
       resource_id=note_id,
       action="READ",
       patient_id=patient_id,
       professional_id=professional_id,
       timestamp=datetime.utcnow(),
       ip_address=request.client.host
   )
   ```

5. **Retención de Datos**
   - Datos de salud: 7 años (estándar médico)
   - Logs de acceso: 7 años (preparación HIPAA)
   - Datos personales básicos: mientras haya relación contractual + 2 años

---

## ⚖️ Implementación de Derechos ARCO

### Portal de Derechos ARCO

**Ubicación**: `/legal/arco` o sección en perfil de usuario

**Features**:

1. **Derecho de Acceso**

   ```javascript
   // Botón "Descargar mis datos"
   onClick = async () => {
     const userData = await api.get('/users/me/export');
     downloadJSON(userData, 'mis-datos-adyela.json');
   };
   ```

   **Contenido exportado**:
   - Datos personales (nombre, email, teléfono, etc.)
   - Historial de citas (fechas, profesionales, estados)
   - Notas clínicas (si paciente)
   - Configuraciones y preferencias
   - Log de accesos (últimos 6 meses)

2. **Derecho de Rectificación**
   - Editar perfil directamente en app
   - Para datos que no se pueden auto-editar: formulario de solicitud

3. **Derecho de Cancelación** (Eliminación)

   ```javascript
   // Botón "Eliminar mi cuenta"
   onClick = async () => {
     const confirm = await showDialog({
       title: 'Eliminar Cuenta',
       message:
         'Esta acción es irreversible. Tus datos serán eliminados permanentemente excepto aquellos que debamos conservar por obligación legal.',
       buttons: ['Confirmar Eliminación', 'Cancelar'],
     });

     if (confirm) {
       await api.post('/users/me/delete-request');
       // Soft delete inmediato, hard delete después de 30 días
     }
   };
   ```

   **Proceso de eliminación**:
   - Día 0: Cuenta marcada como "PENDING_DELETION", usuario no puede login
   - Día 1-30: Período de gracia (puede reactivar)
   - Día 30: Eliminación permanente de datos personales
   - Datos conservados por obligación legal: logs auditoria (anonimizados),
     transacciones (facturación)

4. **Derecho de Oposición**
   - Oponerse a ciertos tratamientos (ej: marketing)
   - Configuración en preferencias de usuario

5. **Derecho de Portabilidad** (LGPD Brasil)
   - Exportar datos en formato estructurado (JSON, CSV)
   - Transferir a otra plataforma (futuro: API de portabilidad)

### SLA de Respuesta

| País      | Plazo Legal     | SLA Adyela      |
| --------- | --------------- | --------------- |
| Colombia  | 15 días hábiles | 10 días hábiles |
| México    | 20 días hábiles | 15 días hábiles |
| Chile     | No especificado | 10 días hábiles |
| Argentina | 10 días hábiles | 7 días hábiles  |
| Brasil    | Plazo razonable | 10 días hábiles |

**Proceso interno**:

1. Solicitud ARCO recibida → Ticket automático
2. Validación de identidad (email, documento)
3. Procesamiento por equipo legal/compliance
4. Respuesta enviada al usuario
5. Log de solicitud ARCO guardado (audit trail)

---

## 📜 Documentos Legales Requeridos

### 1. Política de Privacidad

**Debe incluir**:

- Identidad del responsable (Adyela SpA/SAS)
- Finalidad del tratamiento de datos
- Datos recolectados (categorías)
- Base legal para tratamiento
- Destinatarios de datos (terceros: GCP, Stripe, etc.)
- Transferencias internacionales
- Derechos ARCO y cómo ejercerlos
- Medidas de seguridad
- Retención de datos
- Cookies y tecnologías similares
- Contacto DPO/responsable

**Ubicación**: `/legal/privacy` **Versión**: Multiidioma (ES), adaptada por país

### 2. Términos y Condiciones

**Debe incluir**:

- Descripción del servicio
- Condiciones de uso
- Responsabilidades de usuarios (pacientes, profesionales)
- Prohibiciones (uso fraudulento, datos falsos)
- Propiedad intelectual
- Limitación de responsabilidad
- Ley aplicable y jurisdicción
- Modificaciones a T&C

**Ubicación**: `/legal/terms`

### 3. Consentimiento Informado (Datos de Salud)

**Separado de T&C**, específico para datos sensibles:

```
CONSENTIMIENTO PARA TRATAMIENTO DE DATOS DE SALUD

Autorizo a Adyela y a los profesionales de salud que utilizan la plataforma a:

1. Recolectar, almacenar y procesar mis datos de salud (historial clínico, diagnósticos, tratamientos) necesarios para la prestación del servicio.

2. Compartir esta información únicamente con los profesionales de salud que yo elija para mis consultas.

3. Utilizar mis datos de salud de forma anonimizada para investigación y mejora del servicio, siempre protegiendo mi identidad.

Entiendo que:
- Puedo revocar este consentimiento en cualquier momento contactando a dpo@adyela.com
- La revocación no afecta el tratamiento previo basado en este consentimiento
- Mis datos de salud serán conservados por 7 años según normativa médica

Fecha: ___________
Firma/Aceptación electrónica: ___________
```

### 4. Aviso de Cookies

**Debe incluir**:

- Tipos de cookies utilizadas (esenciales, analíticas, marketing)
- Finalidad de cada cookie
- Terceros que colocan cookies (Google Analytics, etc.)
- Cómo deshabilitar cookies

**Ubicación**: Banner en primera visita + `/legal/cookies`

---

## 🔐 Medidas de Seguridad Técnicas

### Obligatorias para Compliance

1. **Encriptación en Tránsito**
   - ✅ TLS 1.3 en todos los endpoints
   - ✅ HTTPS obligatorio (redirect HTTP → HTTPS)

2. **Encriptación en Reposo**
   - ✅ Firestore encryption at rest (default GCP)
   - ⏳ CMEK para datos sensibles (Fase 2)

3. **Autenticación y Autorización**
   - ✅ Multi-factor authentication (MFA) opcional → obligatorio para
     profesionales (Fase 2)
   - ✅ RBAC granular
   - ✅ Session timeout: 30 días inactividad

4. **Firewalls y WAF**
   - ✅ Cloud Armor (WAF) en Load Balancer
   - ✅ VPC con firewall rules restrictivas

5. **Monitoring y Detección**
   - ✅ Cloud Logging con alertas de anomalías
   - ✅ Detección de accesos no autorizados
   - ✅ Rate limiting (prevenir ataques)

6. **Backup y Recuperación**
   - ✅ Backups automáticos diarios (Firestore, Cloud SQL)
   - ✅ Point-in-time recovery (PITR)
   - ✅ Disaster recovery plan (RTO <15 min)

7. **Control de Acceso**
   - ✅ Least privilege principle (IAM roles mínimos)
   - ✅ Service accounts por microservicio
   - ✅ Audit logging de accesos administrativos

---

## 🚨 Plan de Respuesta a Brechas de Seguridad

### Definición de Brecha

**Brecha de seguridad**: Acceso no autorizado, pérdida, alteración o divulgación
de datos personales

**Ejemplos**:

- Hackeo de base de datos
- Acceso no autorizado a historiales clínicos
- Fuga de datos por empleado
- Pérdida de laptop con datos no encriptados

### Proceso de Respuesta (Playbook)

**Fase 1: Detección y Contención (0-6 horas)**

1. **Detección**: Alerta automática o reporte manual
2. **Activación**: Notificar al Incident Response Team (IRT)
   - Tech Lead
   - Security Engineer
   - DPO
   - Legal Counsel
3. **Contención**: Detener la brecha
   - Cerrar acceso comprometido
   - Aislar sistemas afectados
   - Preservar evidencia (logs)

**Fase 2: Evaluación (6-24 horas)**

4. **Análisis de impacto**:
   - ¿Qué datos fueron afectados? (personales, sensibles de salud)
   - ¿Cuántos usuarios afectados?
   - ¿Qué países? (determina autoridades a notificar)
   - ¿Nivel de riesgo para usuarios? (bajo, medio, alto)

5. **Determinar obligación de notificación**:
   - Brasil (LGPD): Notificar ANPD si riesgo para derechos y libertades
   - Argentina: Notificar AAIP si datos sensibles
   - México: Notificar INAI si datos sensibles y riesgo patrimonial/moral
   - Colombia, Chile: Best practice notificar SIC/Consejo

**Fase 3: Notificación (24-72 horas)**

6. **Notificar Autoridades** (según país y regulación):
   - **Brasil**: ANPD (en plazo razonable, generalmente 72h)
   - **Argentina**: AAIP (inmediatamente si datos sensibles)
   - **México**: INAI (inmediatamente)

   **Contenido notificación**:
   - Naturaleza de la brecha
   - Datos afectados (categorías, cantidad)
   - Usuarios afectados (estimado)
   - Medidas de contención tomadas
   - Medidas para mitigar impacto
   - Contacto DPO

7. **Notificar Usuarios Afectados**:
   - Email a cada usuario afectado
   - Explicación clara y simple
   - Pasos que deben tomar (cambiar contraseña, monitorear cuenta)
   - Contacto para consultas

   **Plantilla email**:

   ```
   Asunto: Importante: Notificación de Seguridad de Adyela

   Estimado/a [Nombre],

   Le escribimos para informarle sobre un incidente de seguridad que afectó su cuenta de Adyela.

   ¿Qué pasó?
   [Descripción clara del incidente]

   ¿Qué datos fueron afectados?
   [Lista específica: email, nombre, historial clínico, etc.]

   ¿Qué hemos hecho?
   [Medidas de contención y mitigación]

   ¿Qué debe hacer?
   1. Cambiar su contraseña inmediatamente
   2. Habilitar autenticación de dos factores
   3. Monitorear su cuenta por actividad sospechosa

   Para consultas: seguridad@adyela.com

   Atentamente,
   Equipo de Seguridad de Adyela
   ```

**Fase 4: Remediación y Mejora (1-4 semanas)**

8. **Root Cause Analysis (RCA)**:
   - ¿Cómo ocurrió la brecha?
   - ¿Qué controles fallaron?
   - ¿Cómo prevenirla en el futuro?

9. **Implementar mejoras**:
   - Parchear vulnerabilidades
   - Reforzar controles de seguridad
   - Capacitación adicional del equipo

10. **Post-mortem público** (opcional, si afecta a muchos usuarios):
    - Blog post explicando incidente
    - Transparencia sobre medidas tomadas

---

## 🌍 Preparación para Expansión Internacional

### HIPAA (USA) - Preparación Fase 2

**Adyela NO está sujeto a HIPAA en MVP** (solo Latinoamérica), pero diseñamos
con HIPAA en mente:

**Preparación arquitectónica**:

- ✅ Audit logging (7 años retención)
- ✅ Encryption at rest y in transit
- ✅ RBAC granular
- ✅ BAA-compliant GCP services (Firestore, Cloud Run)
- ⏳ CMEK encryption (Fase 2)
- ⏳ VPC Service Controls (Fase 2)
- ⏳ HIPAA training para equipo (Fase 2)

**Timeline HIPAA**:

- Fase 2 (Mes 13-18): Implementar controles adicionales
- Fase 3 (Mes 19-24): Auditoría HIPAA externa
- Fase 4 (Mes 25+): Lanzamiento USA con HIPAA compliance

### GDPR (EU) - Preparación Fase 3

**Similaridades con LGPD Brasil**:

- Consentimiento, derechos del titular, DPO, privacy by design, notificación de
  brechas

**Diferencias clave**:

- GDPR más estricto en transferencias internacionales
- Data residency en EU (GCP europe-west1)
- Representative in EU requerido

**Timeline GDPR**:

- Fase 4 (Mes 25+): Evaluación de expansión a EU

---

## ✅ Checklist de Compliance MVP

### Pre-Lanzamiento (Must Have)

- [ ] **Política de Privacidad** publicada (`/legal/privacy`)
- [ ] **Términos y Condiciones** publicados (`/legal/terms`)
- [ ] **Consentimiento de datos sensibles** implementado (checkbox registro)
- [ ] **Portal ARCO** implementado (descargar datos, solicitar eliminación)
- [ ] **Aviso de Cookies** (banner + página)
- [ ] **DPO designado** (email: dpo@adyela.com)
- [ ] **Registro de bases de datos** (Colombia SIC, Argentina AAIP)
- [ ] **Audit logging** activado (accesos a datos sensibles)
- [ ] **Encriptación TLS 1.3** habilitada
- [ ] **Plan de respuesta a brechas** documentado
- [ ] **Capacitación del equipo** en manejo de datos sensibles

### Post-Lanzamiento (Nice to Have - Fase 2)

- [ ] **MFA obligatorio** para profesionales
- [ ] **CMEK encryption** para datos sensibles
- [ ] **Privacy impact assessments** (PIA) para features nuevos
- [ ] **Registro de actividades de tratamiento** (LGPD/GDPR)
- [ ] **Data residency** en LATAM (GCP southamerica-east1)
- [ ] **Certificación ISO 27001** (seguridad de la información)
- [ ] **Auditoría externa** de compliance

---

## 📞 Contactos y Responsabilidades

| Rol                               | Responsable | Email               | Responsabilidad                            |
| --------------------------------- | ----------- | ------------------- | ------------------------------------------ |
| **DPO (Data Protection Officer)** | [TBD]       | dpo@adyela.com      | Compliance general, ARCO, brechas          |
| **Security Engineer**             | [TBD]       | security@adyela.com | Seguridad técnica, respuesta a incidentes  |
| **Legal Counsel**                 | [TBD]       | legal@adyela.com    | Documentos legales, consultas regulatorias |
| **Tech Lead**                     | [TBD]       | tech@adyela.com     | Implementación técnica de compliance       |

---

## 📚 Referencias

- [Ley 1581 Colombia](https://www.sic.gov.co/tema/proteccion-de-datos-personales)
- [LFPDPPP México](https://www.inai.org.mx/)
- [Ley 19.628 Chile](https://www.bcn.cl/leychile/navegar?idNorma=141599)
- [Ley 25.326 Argentina](https://www.argentina.gob.ar/aaip)
- [LGPD Brasil](https://www.gov.br/anpd/pt-br)

---

**Documento**: `docs/planning/health-platform-compliance-latam.md` **Version**:
1.0 **Última actualización**: 2025-10-18 **Review**: Antes de cada lanzamiento
en nuevo país **Owner**: Legal + DPO
