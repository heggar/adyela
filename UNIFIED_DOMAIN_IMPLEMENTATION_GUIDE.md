# Unified Domain Implementation Guide

**Version**: 1.0.0 **Date**: 2025-10-19 **Status**: ✅ Ready for Implementation
**Owner**: Infrastructure Team

---

## 🎯 Objetivo

Migrar todas las aplicaciones de Adyela (admin, paciente, profesional) a una
estructura de dominio unificada bajo `staging.adyela.care`, eliminando la
dependencia de Firebase Hosting para las apps Flutter web.

### Estructura Actual vs Nueva

**ANTES:**

```
https://staging.adyela.care                          → Admin (React)
https://adyela-staging.web.app                      → Paciente (Flutter - Firebase)
https://professional.adyela-staging.web.app         → Profesional (Flutter - Firebase)
https://api.staging.adyela.care                     → APIs
```

**DESPUÉS:**

```
https://staging.adyela.care                          → Admin (React)
https://patient.staging.adyela.care                 → Paciente (Flutter Web - Cloud Run)
https://professional.staging.adyela.care            → Profesional (Flutter Web - Cloud Run)
https://api.staging.adyela.care                     → APIs
```

---

## 📋 Resumen de Cambios

### 1. Infraestructura (Terraform)

#### ✅ Archivos Modificados

| Archivo                                       | Cambios                                                                                                                                                                                                                                    |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `infra/modules/load-balancer/variables.tf`    | + Agregadas variables para `patient_service_name` y `professional_service_name`                                                                                                                                                            |
| `infra/modules/load-balancer/main.tf`         | + Agregados NEGs para patient y professional<br>+ Agregados backend services<br>+ Actualizado URL map con subdomain routing<br>+ Actualizado SSL certificate para incluir nuevos subdominios<br>+ Actualizado CORS en static assets bucket |
| `infra/modules/cloud-run/main.tf`             | ✏️ Actualizado CORS para incluir `patient.staging` y `professional.staging`                                                                                                                                                                |
| `infra/environments/staging/main.tf`          | ✏️ Agregadas referencias a patient y professional services en load_balancer                                                                                                                                                                |
| `infra/environments/staging/microservices.tf` | ✏️ Actualizado CORS_ORIGINS con nuevos subdominios                                                                                                                                                                                         |

#### ✅ Archivos Creados

| Archivo                                     | Propósito                                                |
| ------------------------------------------- | -------------------------------------------------------- |
| `infra/environments/staging/flutter-web.tf` | Configuración Cloud Run para patient y professional apps |

**Recursos Terraform Nuevos:**

- 2 x Cloud Run services (patient-web, professional-web)
- 2 x Network Endpoint Groups (NEGs)
- 2 x Backend services
- Host rules y path matchers en URL map
- SSL certificate actualizado con 4 dominios

---

### 2. Aplicaciones Flutter Web

#### ✅ Dockerfiles Creados

| Archivo                                   | Descripción                                       |
| ----------------------------------------- | ------------------------------------------------- |
| `apps/mobile-patient/Dockerfile.web`      | Multi-stage build: Flutter builder + Nginx server |
| `apps/mobile-professional/Dockerfile.web` | Multi-stage build: Flutter builder + Nginx server |

**Características:**

- **Stage 1**: Build Flutter web con CanvasKit renderer
- **Stage 2**: Nginx optimizado para servir Flutter web
- Security headers (CSP, X-Frame-Options, etc.)
- Gzip compression
- Cache control para assets
- Health check endpoint (`/health`)
- Non-root user (nginx)
- Port 8080 (Cloud Run requirement)

---

### 3. CI/CD

#### ✅ GitHub Actions Workflow

| Archivo                                    | Propósito                                      |
| ------------------------------------------ | ---------------------------------------------- |
| `.github/workflows/deploy-flutter-web.yml` | Build y deploy de Flutter web apps a Cloud Run |

**Jobs:**

1. `determine-environment` - Detecta staging/production
2. `deploy-patient` - Build + push Docker image + deploy a Cloud Run
3. `deploy-professional` - Build + push Docker image + deploy a Cloud Run
4. `summary` - Resumen del deployment

**Triggers:**

- Push a `develop` → staging
- Push a `main` → production
- Manual dispatch con selección de environment

**Build Arguments:**

- `API_URL` - Configurado según environment
- `ENVIRONMENT` - staging/production

---

### 4. Documentación

#### ✅ Documentos Creados

| Archivo                                               | Contenido                                        |
| ----------------------------------------------------- | ------------------------------------------------ |
| `docs/deployment/dns-configuration-unified-domain.md` | Guía completa de configuración DNS en Cloudflare |
| `infra/environments/staging/README.md`                | ✏️ Actualizado con nuevas URLs                   |

---

## 🚀 Pasos de Implementación

### Fase 1: Terraform Infrastructure (30 minutos)

#### Paso 1.1: Revisar Cambios

```bash
cd infra/environments/staging

# Ver cambios
terraform plan

# Deberías ver:
# + 2 Cloud Run services
# + 2 NEGs
# + 2 Backend services
# ~ URL map actualizado
# ~ SSL certificate actualizado
```

#### Paso 1.2: Aplicar Infraestructura

```bash
# Aplicar cambios
terraform apply

# Confirmar con 'yes'
```

**Tiempo estimado**: 5-10 minutos

**Recursos creados:**

- `adyela-patient-web-staging` (Cloud Run)
- `adyela-professional-web-staging` (Cloud Run)
- NEGs, backends, URL map updates
- SSL certificate (estará en `PROVISIONING`)

---

### Fase 2: Build y Deploy Apps Flutter (45 minutos)

#### Paso 2.1: Verificar Artifact Registry

```bash
# Verificar que existe
gcloud artifacts repositories describe adyela \
  --project=adyela-staging \
  --location=us-central1
```

#### Paso 2.2: Opción A - Deployment Manual (Primera Vez)

```bash
# Autenticar Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build Patient App
cd /ruta/proyecto
docker build \
  -f apps/mobile-patient/Dockerfile.web \
  -t us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-patient-web-staging:latest \
  --build-arg API_URL=https://api.staging.adyela.care \
  --build-arg ENVIRONMENT=staging \
  .

# Push Patient App
docker push us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-patient-web-staging:latest

# Build Professional App
docker build \
  -f apps/mobile-professional/Dockerfile.web \
  -t us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-professional-web-staging:latest \
  --build-arg API_URL=https://api.staging.adyela.care \
  --build-arg ENVIRONMENT=staging \
  .

# Push Professional App
docker push us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-professional-web-staging:latest

# Deploy Patient
gcloud run deploy adyela-patient-web-staging \
  --image=us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-patient-web-staging:latest \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated

# Deploy Professional
gcloud run deploy adyela-professional-web-staging \
  --image=us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-professional-web-staging:latest \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated
```

**Tiempo estimado**: 30-40 minutos (builds son pesados)

#### Paso 2.2: Opción B - GitHub Actions (Recomendado)

```bash
# Commit y push de cambios
git add .
git commit -m "feat(infra): add Flutter web deployment to Cloud Run under unified domain"
git push origin develop

# GitHub Actions se ejecutará automáticamente
# Monitorear en: https://github.com/TU_REPO/actions
```

**Tiempo estimado**: 15-20 minutos (runners de GitHub)

---

### Fase 3: Configuración DNS (15 minutos)

#### Paso 3.1: Agregar Registros DNS en Cloudflare

**Opción A: Dashboard de Cloudflare**

1. Ir a https://dash.cloudflare.com/
2. Seleccionar `adyela.care`
3. DNS tab
4. Agregar registros:

**Patient App:**

- Type: `CNAME`
- Name: `patient.staging`
- Target: `staging.adyela.care`
- Proxy: ☁️ Proxied (orange cloud)
- TTL: Auto

**Professional App:**

- Type: `CNAME`
- Name: `professional.staging`
- Target: `staging.adyela.care`
- Proxy: ☁️ Proxied (orange cloud)
- TTL: Auto

**Opción B: Cloudflare API** (ver
`docs/deployment/dns-configuration-unified-domain.md`)

**Opción C: Terraform** (recomendado para production)

#### Paso 3.2: Verificar DNS

```bash
# Esperar 5-10 minutos
sleep 600

# Verificar patient
dig patient.staging.adyela.care +short

# Verificar professional
dig professional.staging.adyela.care +short
```

---

### Fase 4: Verificación SSL (15-30 minutos)

#### Paso 4.1: Monitorear Certificado

```bash
# Ver estado del certificado
gcloud compute ssl-certificates describe adyela-staging-web-ssl-cert \
  --project=adyela-staging \
  --format="table(name,managed.domains,managed.status)"

# Esperar a que todos sean ACTIVE
# PROVISIONING → ACTIVE (~15 minutos)
```

#### Paso 4.2: Verificar HTTPS

```bash
# Cuando el certificado esté ACTIVE
curl -I https://patient.staging.adyela.care
curl -I https://professional.staging.adyela.care

# Deberían retornar 200 OK
```

---

### Fase 5: Testing Completo (30 minutos)

#### ✅ Checklist de Verificación

**DNS:**

- [ ] `patient.staging.adyela.care` resuelve correctamente
- [ ] `professional.staging.adyela.care` resuelve correctamente

**SSL:**

- [ ] Certificado incluye 4 dominios
- [ ] Estado = `ACTIVE`
- [ ] HTTPS funciona sin warnings

**Aplicaciones:**

- [ ] Admin carga en `https://staging.adyela.care`
- [ ] Patient carga en `https://patient.staging.adyela.care`
- [ ] Professional carga en `https://professional.staging.adyela.care`
- [ ] API responde en `https://api.staging.adyela.care/health`

**Funcionalidad:**

- [ ] Patient app puede autenticarse (Firebase Auth)
- [ ] Patient app puede llamar a la API (CORS correcto)
- [ ] Professional app puede autenticarse
- [ ] Professional app puede llamar a la API
- [ ] No hay errores de mixed content en consola

**Performance:**

- [ ] Patient app carga en < 3 segundos
- [ ] Professional app carga en < 3 segundos
- [ ] Assets servidos con cache headers correctos

---

## 📊 Costos

### Nuevos Recursos

| Recurso                       | Cantidad      | Costo/mes     | Total |
| ----------------------------- | ------------- | ------------- | ----- |
| Cloud Run (Patient Web)       | Scale-to-zero | ~$0           | $0    |
| Cloud Run (Professional Web)  | Scale-to-zero | ~$0           | $0    |
| SSL Certificate (adicionales) | 2 dominios    | $0 (incluido) | $0    |
| NEGs                          | 2             | $0            | $0    |

**Total Incremento**: **$0/mes** (scale-to-zero en staging)

**Nota**: En production con tráfico real, estimar ~$10-20/mes adicionales.

---

## 🔄 Rollback Plan

Si algo falla, puedes hacer rollback rápidamente:

### Opción 1: Revertir Terraform

```bash
cd infra/environments/staging
git revert <commit-hash>
terraform apply
```

### Opción 2: Mantener URLs Antiguas

Las URLs de Firebase Hosting seguirán funcionando hasta que las elimines
manualmente. No hay prisa para migrar completamente.

### Opción 3: DNS Rollback

Simplemente elimina los registros DNS de `patient.staging` y
`professional.staging`. Las apps volverán a estar disponibles en Firebase URLs.

---

## 🐛 Troubleshooting

### Issue: DNS no resuelve

**Solución**: Esperar 15 minutos adicionales. Limpiar caché DNS local.

### Issue: SSL en PROVISIONING por >30 minutos

**Solución**:

1. Verificar DNS está correcto
2. Verificar Cloudflare proxy está habilitado
3. Ver logs de certificado SSL

### Issue: App muestra 404

**Solución**:

1. Verificar Cloud Run service está deployed
2. Verificar URL map tiene host rules correctos
3. Verificar backend service apunta al NEG correcto

### Issue: CORS errors

**Solución**:

1. Verificar `CORS_ORIGINS` en todas las APIs
2. Debería incluir `https://patient.staging.adyela.care` y
   `https://professional.staging.adyela.care`
3. Re-deploy APIs si es necesario

**Ver documentación completa**:
`docs/deployment/dns-configuration-unified-domain.md`

---

## 📚 Archivos Relevantes

### Terraform

- `infra/modules/load-balancer/main.tf`
- `infra/modules/load-balancer/variables.tf`
- `infra/modules/cloud-run/main.tf`
- `infra/environments/staging/main.tf`
- `infra/environments/staging/flutter-web.tf`
- `infra/environments/staging/microservices.tf`

### Docker

- `apps/mobile-patient/Dockerfile.web`
- `apps/mobile-professional/Dockerfile.web`

### CI/CD

- `.github/workflows/deploy-flutter-web.yml`

### Documentación

- `docs/deployment/dns-configuration-unified-domain.md`
- `docs/deployment/terraform-operations-runbook.md`
- `docs/deployment/gitops-workflow.md`
- `infra/environments/staging/README.md`

---

## ✅ Criterios de Éxito

Al completar esta implementación:

1. ✅ Todas las apps bajo dominio `staging.adyela.care`
2. ✅ Una sola IP de load balancer (34.96.108.162)
3. ✅ Un solo certificado SSL para 4 subdominios
4. ✅ CORS configurado correctamente
5. ✅ Apps Flutter web en Cloud Run (no Firebase Hosting)
6. ✅ URLs limpias y profesionales
7. ✅ Arquitectura consistente staging = production
8. ✅ Documentación completa
9. ✅ CI/CD automatizado

---

## 🎯 Próximos Pasos

Después de staging exitoso:

1. **Replicar en Production**
   - Seguir mismo proceso
   - Usar dominio `adyela.care`
   - Configurar min_instances > 0 para mejor performance

2. **Optimizaciones**
   - Habilitar Cloud CDN para Flutter web assets
   - Configurar Cloud Armor en production
   - Implementar rate limiting

3. **Monitoreo**
   - Configurar alertas de uptime
   - Dashboard de Grafana/Cloud Monitoring
   - Log analysis

---

**Implementado por**: Claude Code AI **Fecha de implementación**: 2025-10-19
**Versión de documentación**: 1.0.0 **Estado**: ✅ Listo para deployment

---

**¿Preguntas?** Consultar documentación en `docs/deployment/` o contactar al
equipo de infraestructura.
