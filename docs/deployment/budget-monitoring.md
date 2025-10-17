# Budget Monitoring & Auto-Shutdown

## 📊 Overview

El proyecto tiene configurado un sistema de monitoreo de presupuesto con alertas
automáticas y auto-shutdown para staging.

## 💰 Presupuestos Configurados

| Ambiente       | Presupuesto Mensual | Alertas                                                 |
| -------------- | ------------------- | ------------------------------------------------------- |
| **Staging**    | $10                 | 50% ($5), 80% ($8), 100% ($10), 120% ($12)              |
| **Production** | $103                | 50% ($51.50), 80% ($82.40), 100% ($103), 120% ($123.60) |

## 🔔 Notificaciones por Email

### Destinatarios

Las alertas se envían automáticamente a:

- ✅ Administradores de facturación del proyecto (IAM)
- ✅ Propietarios del proyecto

### Umbrales de Alerta

- **50%** - 🟢 **Informativo**: "Estás a mitad de tu presupuesto"
- **80%** - 🟡 **Advertencia**: "Te acercas al límite de presupuesto"
- **100%** - 🔴 **Crítico**: "Presupuesto excedido"
- **120%** - 🚨 **Emergencia**: "Sobrecosto del 20%"

## 🛑 Auto-Shutdown (Solo Staging)

### Configuración Actual

**Staging:**

- ✅ Auto-shutdown HABILITADO
- Se ejecuta cuando el presupuesto alcanza el 100%
- Escala todos los servicios Cloud Run a 0 instancias

**Production:**

- ❌ Auto-shutdown DESHABILITADO
- Requiere intervención manual por seguridad
- Solo se envían alertas críticas

### Ejecutar Auto-Shutdown Manualmente

Si necesitas apagar staging manualmente para ahorrar costos:

```bash
# Apagar staging
./scripts/simple-auto-shutdown.sh adyela-staging

# Restaurar staging
gcloud run services update adyela-api-staging \
  --region=us-central1 \
  --min-instances=0 \
  --max-instances=1
```

## 📈 Monitoreo Diario de Costos

Verificar costos actuales:

```bash
# Staging
./scripts/check-daily-costs.sh adyela-staging

# Production
./scripts/check-daily-costs.sh adyela-production
```

## 🔗 Recursos

### Ver Presupuestos

- **Console**:
  https://console.cloud.google.com/billing/0166AB-671459-CB9565/budgets
- **CLI**: `gcloud billing budgets list --billing-account=0166AB-671459-CB9565`

### Ver Costos Actuales

```bash
# Costos del mes actual
gcloud billing projects describe PROJECT_ID \
  --format="table(billingAccountName,billingEnabled)"
```

### Pub/Sub Topics Configurados

- **Staging**: `projects/adyela-staging/topics/budget-alerts`
- **Production**: `projects/adyela-production/topics/budget-alerts`
- **Auto-shutdown**: `projects/adyela-staging/topics/budget-auto-shutdown`

## 🚨 Respuesta a Alertas

### Alerta al 50% - Informativo

✅ **Acción**: Monitorear

- Revisar uso de recursos
- Verificar que el gasto esté dentro de lo esperado

### Alerta al 80% - Advertencia

⚠️ **Acción**: Optimizar

- Identificar servicios de alto consumo
- Considerar reducir recursos no críticos
- Revisar logs de errores (pueden estar consumiendo recursos)

### Alerta al 100% - Crítico

🔴 **Acción**: Intervenir

**Para Staging:**

- Auto-shutdown se ejecutará automáticamente
- O ejecutar manualmente: `./scripts/simple-auto-shutdown.sh adyela-staging`

**Para Production:**

- Revisar urgentemente qué está causando el sobrecosto
- Considerar escalar down servicios temporalmente
- Contactar al equipo de infraestructura

### Alerta al 120% - Emergencia

🚨 **Acción**: Apagar servicios no esenciales

```bash
# Escalar down servicio específico
gcloud run services update SERVICE_NAME \
  --region=us-central1 \
  --max-instances=1

# Escalar a cero (apagar)
gcloud run services update SERVICE_NAME \
  --region=us-central1 \
  --min-instances=0 \
  --max-instances=0
```

## 💡 Best Practices

### Optimización de Costos

1. **Staging debe escalar a cero**
   - `min-instances=0` cuando no está en uso
   - Usar `max-instances=1` para limitar costo
   - Apagar fuera de horario laboral

2. **Production debe ser eficiente**
   - `min-instances=1-2` para alta disponibilidad
   - `max-instances=100` para manejar picos
   - Monitorear métricas de uso

3. **Storage y Logs**
   - Configurar lifecycle policies para Cloud Storage
   - Retención de logs: 30 días (staging), 90 días (production)
   - Eliminar artifacts antiguos de Cloud Build

### Revisión Mensual

Al inicio de cada mes:

1. Revisar costos del mes anterior
2. Comparar con presupuesto
3. Ajustar recursos si es necesario
4. Actualizar presupuesto si cambian los requerimientos

## 📝 Scripts Disponibles

| Script                          | Descripción                   | Uso                                            |
| ------------------------------- | ----------------------------- | ---------------------------------------------- |
| `setup-budgets.sh`              | Crear/actualizar presupuestos | `./scripts/setup-budgets.sh PROJECT_ID AMOUNT` |
| `check-daily-costs.sh`          | Ver costos diarios            | `./scripts/check-daily-costs.sh PROJECT_ID`    |
| `simple-auto-shutdown.sh`       | Apagar servicios manualmente  | `./scripts/simple-auto-shutdown.sh PROJECT_ID` |
| `setup-budget-notifications.sh` | Configurar notificaciones     | (Opcional, ya configurado)                     |

## 🔧 Troubleshooting

### No recibo notificaciones por email

1. Verificar que eres admin de facturación:

   ```bash
   gcloud projects get-iam-policy PROJECT_ID \
     --flatten="bindings[].members" \
     --filter="bindings.role:roles/billing.admin"
   ```

2. Verificar configuración del presupuesto:
   ```bash
   gcloud billing budgets list --billing-account=0166AB-671459-CB9565
   ```

### Auto-shutdown no funciona

1. Verificar que los topics existen:

   ```bash
   gcloud pubsub topics list --project=adyela-staging
   ```

2. Ejecutar shutdown manual:
   ```bash
   ./scripts/simple-auto-shutdown.sh adyela-staging
   ```

### Costos inesperadamente altos

1. Identificar servicio con mayor costo:

   ```bash
   # Ver facturación en console
   open "https://console.cloud.google.com/billing/0166AB-671459-CB9565"
   ```

2. Ver métricas de Cloud Run:
   ```bash
   gcloud monitoring dashboards list
   ```

## 📞 Contacto

Para consultas sobre facturación:

- **Email**: hever_gonzalezg@adyela.care
- **GCP Support**:
  [Google Cloud Console](https://console.cloud.google.com/support)

---

**Última actualización**: 2025-10-05
