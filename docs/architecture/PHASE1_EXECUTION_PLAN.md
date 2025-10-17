# 🚀 FASE 1: DIAGNÓSTICO Y CORRECCIÓN CRÍTICA - Plan de Ejecución

## 📋 **Resumen de la Fase 1**

Esta fase se enfoca en resolver los problemas críticos identificados en el
diagnóstico, comenzando por el backend que no responde y siguiendo con la
verificación completa de todos los componentes.

---

## 🎯 **Objetivos Inmediatos**

1. **Resolver el problema crítico del API** que no responde a endpoints
2. **Verificar construcción correcta** de backend y frontend
3. **Validar configuración de secrets** y variables de entorno
4. **Sincronizar Terraform** con el estado real de GCP
5. **Preparar base sólida** para las siguientes fases

---

## ⏰ **Cronograma de Ejecución (2-3 horas)**

### **Hora 1: Diagnóstico Profundo del Backend**

- [ ] **0-15 min**: Verificar logs detallados del API
- [ ] **15-30 min**: Analizar configuración de FastAPI
- [ ] **30-45 min**: Verificar variables de entorno y secrets
- [ ] **45-60 min**: Probar construcción local del API

### **Hora 2: Corrección del Backend**

- [ ] **0-15 min**: Identificar y corregir problema raíz
- [ ] **15-30 min**: Actualizar configuración si es necesario
- [ ] **30-45 min**: Desplegar corrección
- [ ] **45-60 min**: Verificar funcionamiento

### **Hora 3: Verificación del Frontend y Sincronización**

- [ ] **0-15 min**: Verificar construcción del frontend
- [ ] **15-30 min**: Validar integración con API
- [ ] **30-45 min**: Sincronizar Terraform con estado real
- [ ] **45-60 min**: Verificar Load Balancer y routing

---

## 🔍 **PASO 1: DIAGNÓSTICO PROFUNDO DEL BACKEND**

### **1.1 Verificar Logs Detallados del API**

```bash
# Ver logs recientes del API con más detalle
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adyela-api-staging AND timestamp>=\"2025-10-12T20:00:00Z\"" --limit=20 --format="table(timestamp,severity,textPayload)"

# Ver logs de startup específicamente
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adyela-api-staging AND textPayload:\"startup\"" --limit=10 --format="value(timestamp,textPayload)"

# Ver logs de errores
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adyela-api-staging AND (severity=\"ERROR\" OR severity=\"CRITICAL\")" --limit=10 --format="value(timestamp,textPayload)"
```

### **1.2 Analizar Configuración de FastAPI**

```bash
# Verificar configuración actual del servicio
gcloud run services describe adyela-api-staging --region=us-central1 --format="export" > /tmp/api-config.yaml

# Verificar variables de entorno
gcloud run services describe adyela-api-staging --region=us-central1 --format="value(spec.template.spec.containers[0].env[].name,spec.template.spec.containers[0].env[].value)"

# Verificar secrets
gcloud run services describe adyela-api-staging --region=us-central1 --format="value(spec.template.spec.containers[0].env[].name,spec.template.spec.containers[0].env[].valueFrom.secretKeyRef.name,spec.template.spec.containers[0].env[].valueFrom.secretKeyRef.key)"
```

### **1.3 Verificar Variables de Entorno y Secrets**

```bash
# Listar todos los secrets disponibles
gcloud secrets list --format="table(name,createTime,labels)"

# Verificar contenido de secrets críticos (sin mostrar valores)
gcloud secrets describe api-secret-key --format="value(name,createTime,labels)"

# Verificar que los secrets tienen versiones
gcloud secrets versions list api-secret-key --format="table(name,state,createTime)"
```

### **1.4 Probar Construcción Local del API**

```bash
# Navegar al directorio del API
cd apps/api

# Verificar configuración de Poetry
poetry --version
poetry env info

# Instalar dependencias
poetry install

# Verificar que el API se puede ejecutar localmente
poetry run python -m adyela_api.main --help

# Probar ejecución local
poetry run python -m adyela_api.main &
API_PID=$!
sleep 5
curl -s http://localhost:8000/health
kill $API_PID
```

---

## 🔧 **PASO 2: CORRECCIÓN DEL BACKEND**

### **2.1 Identificar Problema Raíz**

Basado en el diagnóstico, identificar si el problema es:

- [ ] **Configuración de FastAPI**: Endpoints no configurados correctamente
- [ ] **Variables de entorno**: Secrets no se inyectan correctamente
- [ ] **Docker image**: Imagen no contiene el código correcto
- [ ] **Cloud Run configuration**: Configuración incorrecta del servicio
- [ ] **Network/VPC**: Problemas de conectividad

### **2.2 Aplicar Corrección**

Dependiendo del problema identificado:

#### **Si es configuración de FastAPI:**

```bash
# Verificar archivo main.py
cat apps/api/adyela_api/main.py

# Verificar configuración de routers
cat apps/api/adyela_api/presentation/api/v1/__init__.py

# Verificar endpoints de health
cat apps/api/adyela_api/presentation/api/v1/endpoints/health.py
```

#### **Si es variables de entorno:**

```bash
# Verificar configuración en Terraform
cat infra/modules/cloud-run/main.tf | grep -A 20 "env {"

# Aplicar configuración correcta
cd infra/environments/staging
terraform apply -target=module.cloud_run.google_cloud_run_v2_service.api
```

#### **Si es Docker image:**

```bash
# Reconstruir y desplegar imagen
cd apps/api
docker build -t us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-api-staging:debug .

# Desplegar nueva imagen
gcloud run deploy adyela-api-staging \
  --image=us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-api-staging:debug \
  --region=us-central1
```

### **2.3 Desplegar Corrección**

```bash
# Aplicar cambios via Terraform
cd infra/environments/staging
terraform plan -target=module.cloud_run.google_cloud_run_v2_service.api
terraform apply -target=module.cloud_run.google_cloud_run_v2_service.api

# O desplegar manualmente si es necesario
gcloud run services update adyela-api-staging --region=us-central1 --image=us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-api-staging:latest
```

### **2.4 Verificar Funcionamiento**

```bash
# Esperar que el servicio se actualice
sleep 30

# Probar endpoint de health
curl -v "https://adyela-api-staging-vrqu3jr6aa-uc.a.run.app/health"

# Probar endpoint de docs
curl -s "https://adyela-api-staging-vrqu3jr6aa-uc.a.run.app/docs"

# Probar a través del Load Balancer
curl -s "https://api.staging.adyela.care/health"

# Verificar logs después del despliegue
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adyela-api-staging AND timestamp>=\"$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)\"" --limit=10 --format="value(timestamp,textPayload)"
```

---

## 🎨 **PASO 3: VERIFICACIÓN DEL FRONTEND**

### **3.1 Verificar Construcción del Frontend**

```bash
# Navegar al directorio del frontend
cd apps/web

# Verificar configuración de Vite
cat vite.config.ts

# Verificar variables de entorno
cat .env.example

# Instalar dependencias
pnpm install

# Construir aplicación
pnpm build

# Verificar que se generaron los assets
ls -la dist/
```

### **3.2 Validar Integración con API**

```bash
# Verificar configuración de API URL
grep -r "VITE_API" apps/web/src/

# Verificar configuración de Firebase
cat apps/web/src/config/firebase.ts

# Probar construcción con variables de entorno
VITE_API_BASE_URL=https://api.staging.adyela.care pnpm build
```

### **3.3 Probar Docker Build del Frontend**

```bash
# Construir imagen Docker
cd apps/web
docker build -t us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-web-staging:debug .

# Probar imagen localmente
docker run -p 3000:8080 us-central1-docker.pkg.dev/adyela-staging/adyela/adyela-web-staging:debug

# En otra terminal, probar
curl -s http://localhost:3000
```

---

## 🔄 **PASO 4: SINCRONIZACIÓN TERRAFORM**

### **4.1 Verificar Estado de Terraform**

```bash
# Navegar al directorio de staging
cd infra/environments/staging

# Verificar estado actual
terraform plan

# Identificar recursos que no están en Terraform
terraform state list
```

### **4.2 Importar Recursos Faltantes**

```bash
# Si hay recursos que no están en Terraform, importarlos
# Ejemplo para Cloud Run services:
terraform import module.cloud_run.google_cloud_run_v2_service.api projects/adyela-staging/locations/us-central1/services/adyela-api-staging
terraform import module.cloud_run.google_cloud_run_v2_service.web projects/adyela-staging/locations/us-central1/services/adyela-web-staging

# Verificar que el plan está limpio
terraform plan
```

### **4.3 Aplicar Configuración Correcta**

```bash
# Aplicar configuración completa
terraform apply

# Verificar que no hay drift
terraform plan
```

---

## 🔗 **PASO 5: VERIFICACIÓN DEL LOAD BALANCER**

### **5.1 Verificar Configuración del Load Balancer**

```bash
# Verificar backend services
gcloud compute backend-services list --global

# Verificar URL map
gcloud compute url-maps describe adyela-staging-web-url-map --global

# Verificar health checks
gcloud compute health-checks list
```

### **5.2 Verificar Routing**

```bash
# Probar routing a través del Load Balancer
curl -v "https://staging.adyela.care/health"
curl -v "https://api.staging.adyela.care/health"

# Verificar SSL certificate
openssl s_client -connect staging.adyela.care:443 -servername staging.adyela.care < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

### **5.3 Verificar DNS**

```bash
# Verificar resolución DNS
nslookup staging.adyela.care
nslookup api.staging.adyela.care

# Verificar que apuntan al Load Balancer
dig +short staging.adyela.care
dig +short api.staging.adyela.care
```

---

## ✅ **CRITERIOS DE ÉXITO PARA FASE 1**

### **Backend (API)**

- [ ] ✅ API responde correctamente a `/health`
- [ ] ✅ API responde correctamente a `/docs`
- [ ] ✅ API responde correctamente a `/api/v1/auth/sync`
- [ ] ✅ Logs muestran aplicación iniciando correctamente
- [ ] ✅ Variables de entorno se inyectan correctamente

### **Frontend (Web)**

- [ ] ✅ Aplicación web se construye sin errores
- [ ] ✅ Docker image se construye correctamente
- [ ] ✅ Aplicación web responde en staging
- [ ] ✅ Integración con API funciona correctamente
- [ ] ✅ PWA y service workers funcionan

### **Infraestructura**

- [ ] ✅ Terraform plan está limpio (no hay cambios pendientes)
- [ ] ✅ Load Balancer routing funciona correctamente
- [ ] ✅ SSL certificates están activos
- [ ] ✅ DNS resolution funciona correctamente
- [ ] ✅ Health checks pasan correctamente

### **Integración**

- [ ] ✅ Frontend puede comunicarse con API
- [ ] ✅ OAuth login funciona end-to-end
- [ ] ✅ CORS está configurado correctamente
- [ ] ✅ Secrets se inyectan correctamente
- [ ] ✅ Logging funciona en todos los componentes

---

## 🚨 **PLAN DE CONTINGENCIA**

### **Si el API sigue sin responder:**

1. **Rollback a imagen anterior** que funcionaba
2. **Verificar configuración de secrets** manualmente
3. **Revisar logs de Cloud Run** para errores específicos
4. **Probar con configuración mínima** (sin secrets)

### **Si hay problemas de DNS:**

1. **Verificar configuración en GoDaddy**
2. **Esperar propagación DNS** (hasta 24 horas)
3. **Usar IP directa del Load Balancer** temporalmente

### **Si hay problemas de SSL:**

1. **Verificar certificado en GCP**
2. **Regenerar certificado** si es necesario
3. **Verificar configuración de dominio**

---

## 📊 **MÉTRICAS DE PROGRESO**

### **Progreso General**

- [ ] **0-25%**: Diagnóstico completado
- [ ] **25-50%**: Problema raíz identificado
- [ ] **50-75%**: Corrección aplicada
- [ ] **75-100%**: Verificación exitosa

### **Tiempo Estimado por Tarea**

- **Diagnóstico**: 30-45 minutos
- **Corrección**: 30-45 minutos
- **Verificación**: 30-45 minutos
- **Sincronización**: 15-30 minutos

---

**Última Actualización**: 2025-10-12  
**Versión**: 1.0  
**Estado**: 🚀 Listo para Ejecución
