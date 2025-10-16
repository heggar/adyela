# 🔧 Fase 1: Corrección DNS - Bypass Cloudflare Temporal

## 📋 Resumen

**Problema Identificado**: El DNS apunta a Cloudflare que está bloqueando las solicitudes (403 Forbidden), en lugar de apuntar al Load Balancer de GCP que está funcionando correctamente.

**Solución**: Cambiar temporalmente los registros DNS para apuntar directamente al Load Balancer de GCP, bypasseando Cloudflare.

---

## 🎯 Cambios DNS Requeridos

### Configuración Actual (INCORRECTO)

```
staging.adyela.care     → 172.67.215.203 (Cloudflare)  → 403 Forbidden
api.staging.adyela.care → 104.21.69.241 (Cloudflare)   → Sin respuesta
```

### Configuración Deseada (CORRECTO)

```
staging.adyela.care     → 34.96.108.162 (GCP Load Balancer) → ✅ Funcionando
api.staging.adyela.care → 34.96.108.162 (GCP Load Balancer) → ✅ Funcionando
```

---

## 🛠️ Procedimiento de Cambio DNS

### Opción 1: Si DNS está en Cloudflare

1. **Acceder a Cloudflare Dashboard**
   - URL: https://dash.cloudflare.com
   - Seleccionar dominio: `adyela.care`

2. **Navegar a DNS Records**
   - Menú lateral: "DNS" → "Records"

3. **Modificar/Crear Registros A**

   **Para staging.adyela.care:**

   ```
   Type: A
   Name: staging
   IPv4 address: 34.96.108.162
   Proxy status: DNS only (⚠️ IMPORTANTE: Click en la nube naranja para desactivar proxy)
   TTL: Auto
   ```

   **Para api.staging.adyela.care:**

   ```
   Type: A
   Name: api.staging
   IPv4 address: 34.96.108.162
   Proxy status: DNS only (⚠️ IMPORTANTE: Desactivar proxy)
   TTL: Auto
   ```

4. **Guardar Cambios**
   - Click en "Save"
   - Esperar propagación (1-5 minutos con Cloudflare)

### Opción 2: Si DNS está en GoDaddy

1. **Acceder a GoDaddy**
   - URL: https://dcc.godaddy.com
   - Ir a "My Products" → "DNS"

2. **Seleccionar dominio adyela.care**

3. **Modificar/Crear Registros A**

   **Para staging.adyela.care:**

   ```
   Type: A
   Host: staging
   Points to: 34.96.108.162
   TTL: 600 (10 minutos)
   ```

   **Para api.staging.adyela.care:**

   ```
   Type: A
   Host: api.staging
   Points to: 34.96.108.162
   TTL: 600 (10 minutos)
   ```

4. **Guardar Cambios**
   - Click en "Save"
   - Esperar propagación (10-30 minutos con GoDaddy)

---

## ✅ Validación Post-Cambio

### Script de Validación Automática

Ejecutar este script después de aplicar los cambios DNS:

```bash
#!/bin/bash

echo "🔍 Validando cambios DNS para Adyela Staging..."
echo ""

# Función para validar DNS
validate_dns() {
    local domain=$1
    local expected_ip="34.96.108.162"

    echo "📍 Verificando: $domain"
    actual_ip=$(dig +short $domain A | head -1)

    if [ "$actual_ip" = "$expected_ip" ]; then
        echo "   ✅ DNS correcto: $actual_ip"
        return 0
    else
        echo "   ❌ DNS incorrecto: $actual_ip (esperado: $expected_ip)"
        return 1
    fi
}

# Función para validar endpoint HTTP
validate_http() {
    local url=$1
    local endpoint=$2

    echo "🌐 Probando: $url$endpoint"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url$endpoint")

    if [ "$http_code" = "200" ]; then
        echo "   ✅ HTTP $http_code - Funcionando"
        return 0
    else
        echo "   ⚠️  HTTP $http_code - Verificar configuración"
        return 1
    fi
}

# Validar DNS
echo "=== VALIDACIÓN DNS ==="
validate_dns "staging.adyela.care"
dns1=$?
validate_dns "api.staging.adyela.care"
dns2=$?
echo ""

# Esperar si DNS aún no se propagó
if [ $dns1 -ne 0 ] || [ $dns2 -ne 0 ]; then
    echo "⏳ DNS aún no propagado. Esperando 30 segundos..."
    sleep 30
    echo ""
fi

# Validar endpoints HTTP
echo "=== VALIDACIÓN HTTP ==="
validate_http "https://staging.adyela.care" "/"
validate_http "https://api.staging.adyela.care" "/health"
echo ""

# Validar API endpoints específicos
echo "=== VALIDACIÓN API DETALLADA ==="
echo "🔧 Probando endpoint de salud..."
curl -s "https://api.staging.adyela.care/health" | jq .
echo ""

echo "🔧 Probando endpoint raíz del API..."
curl -s "https://api.staging.adyela.care/" | jq .
echo ""

# Resumen
echo "=== RESUMEN ==="
if [ $dns1 -eq 0 ] && [ $dns2 -eq 0 ]; then
    echo "✅ DNS propagado correctamente"
    echo "✅ Fase 1 completada exitosamente"
    echo ""
    echo "📋 Próximos pasos:"
    echo "   1. Validar frontend en https://staging.adyela.care"
    echo "   2. Validar API en https://api.staging.adyela.care"
    echo "   3. Proceder con Fase 2: Optimización de infraestructura"
else
    echo "⏳ DNS aún propagándose. Esperar 5-10 minutos adicionales."
    echo "   Comando para verificar: dig +short staging.adyela.care"
fi
```

### Validación Manual

**1. Verificar resolución DNS:**

```bash
# Debe retornar: 34.96.108.162
dig +short staging.adyela.care
dig +short api.staging.adyela.care

# O con nslookup
nslookup staging.adyela.care
nslookup api.staging.adyela.care
```

**2. Probar frontend:**

```bash
# Debe retornar HTTP 200
curl -I https://staging.adyela.care

# Debe mostrar la aplicación React
curl -s https://staging.adyela.care | grep -o "<title>.*</title>"
```

**3. Probar API:**

```bash
# Debe retornar: {"status":"healthy","version":"0.1.0"}
curl -s https://api.staging.adyela.care/health | jq .

# Debe retornar información del API
curl -s https://api.staging.adyela.care/ | jq .
```

**4. Verificar SSL:**

```bash
# Debe mostrar certificado válido de Google
openssl s_client -connect staging.adyela.care:443 -servername staging.adyela.care < /dev/null 2>/dev/null | openssl x509 -noout -issuer -subject -dates
```

---

## 🔍 Troubleshooting

### Problema: DNS no se propaga

**Síntomas:**

- `dig` sigue mostrando IPs de Cloudflare (172.67.x.x o 104.21.x.x)

**Soluciones:**

```bash
# 1. Verificar nameservers del dominio
dig NS adyela.care

# 2. Flush DNS cache local (macOS)
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# 3. Probar con DNS público de Google
dig @8.8.8.8 staging.adyela.care

# 4. Esperar más tiempo (hasta 24h en casos extremos)
```

### Problema: HTTP 403 persiste

**Síntomas:**

- DNS apunta correctamente a 34.96.108.162
- Pero sigue retornando 403

**Soluciones:**

```bash
# 1. Verificar que el dominio no esté en caché de Cloudflare
# Purgar caché en Cloudflare Dashboard: Caching → Configuration → Purge Everything

# 2. Probar con IP directa
curl -k https://34.96.108.162/health -H "Host: api.staging.adyela.care"

# 3. Verificar Cloud Armor no está bloqueando
gcloud compute security-policies list
```

### Problema: SSL Certificate Error

**Síntomas:**

- "Certificate not valid for domain"

**Causa:**

- El certificado SSL de GCP está configurado para el dominio pero puede tomar tiempo

**Solución:**

```bash
# 1. Verificar certificado en GCP
gcloud compute ssl-certificates describe adyela-staging-web-ssl-cert --global

# 2. Esperar hasta 24h para provisión completa del certificado
# 3. Mientras tanto, usar --insecure para testing
curl --insecure https://staging.adyela.care
```

---

## 📊 Métricas de Éxito

### Criterios de Aceptación Fase 1

- [ ] ✅ DNS staging.adyela.care apunta a 34.96.108.162
- [ ] ✅ DNS api.staging.adyela.care apunta a 34.96.108.162
- [ ] ✅ Frontend responde HTTP 200 en https://staging.adyela.care
- [ ] ✅ API /health responde HTTP 200 en https://api.staging.adyela.care/health
- [ ] ✅ API / responde HTTP 200 en https://api.staging.adyela.care/
- [ ] ✅ SSL certificate válido en ambos dominios
- [ ] ✅ No hay errores en Cloud Run logs
- [ ] ✅ Load Balancer routing funciona correctamente

### Tiempo Estimado

- **Aplicar cambios DNS**: 5 minutos
- **Propagación DNS**: 5-30 minutos (Cloudflare) o 10-60 minutos (GoDaddy)
- **Validación completa**: 10 minutos
- **Total**: 20-100 minutos

---

## 📝 Notas Importantes

### ⚠️ Importante sobre Cloudflare

Si estás usando Cloudflare, **debes desactivar el proxy (nube naranja)** para bypasearlo temporalmente:

- **Proxy ACTIVADO** (nube naranja) = Tráfico pasa por Cloudflare → ❌ No funciona
- **DNS only** (nube gris) = Tráfico va directo a GCP → ✅ Funciona

**Imagen de referencia:**

```
[Cloudflare DNS Record]
Name: staging
Type: A
Content: 34.96.108.162
☁️ → 🔘  (Click para cambiar de naranja a gris)
```

### 🎯 Fase 2: Reintegrar Cloudflare (Opcional)

Una vez que el sistema esté funcionando directamente con GCP, en la **Fase 2** podemos:

1. Reactivar el proxy de Cloudflare (nube naranja)
2. Configurar correctamente:
   - SSL/TLS: Full (strict)
   - Page Rules: Bypass cache para API
   - WAF Rules: Permitir tráfico de GCP
   - Origin Server: 34.96.108.162

**Beneficios de reintegrar Cloudflare:**

- 20% reducción de costos ($8-9/mes de ahorro)
- CDN global edge locations
- DDoS protection incluido
- WAF incluido (vs $5.17/mes Cloud Armor)
- Cache inteligente de assets

---

## 🚀 Siguientes Pasos

Una vez completada esta corrección DNS:

1. ✅ **Validar acceso completo** a frontend y API
2. ✅ **Probar OAuth login** end-to-end
3. ✅ **Verificar integración** frontend-backend
4. ✅ **Documentar configuración actual** en Terraform
5. 🔄 **Proceder con Fase 2**: Optimización de infraestructura

---

**Estado**: 🚀 Listo para aplicar
**Prioridad**: 🔴 CRÍTICA
**Tiempo Estimado**: 20-100 minutos (dependiendo de propagación DNS)
**Última actualización**: 2025-10-12
