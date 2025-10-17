# 💰 Estimación de Costos Firebase - Adyela

## 📊 Proyección de Uso para Staging

### Escenario: Desarrollo/Staging (Uso bajo)

**Usuarios activos**: 5-10 usuarios/día (equipo de desarrollo + testing)

| Servicio              | Uso Mensual      | Límite Gratuito | Costo            |
| --------------------- | ---------------- | --------------- | ---------------- |
| **Authentication**    | 300 logins/mes   | Ilimitado       | **$0.00**        |
| **Firestore Reads**   | ~15,000 docs/mes | 1.5M/mes        | **$0.00**        |
| **Firestore Writes**  | ~5,000 docs/mes  | 600K/mes        | **$0.00**        |
| **Firestore Storage** | < 100 MB         | 1 GB            | **$0.00**        |
| **Cloud Storage**     | < 500 MB         | 5 GB            | **$0.00**        |
| **TOTAL STAGING**     | -                | -               | **$0.00/mes** ✅ |

---

### Escenario: Producción (Uso moderado)

**Usuarios activos**: 100 usuarios/día, 500 sesiones/día

#### Firestore (Estimación conservadora)

**Uso típico por sesión:**

- Login: 2 lecturas (user profile, settings)
- Navegación: 10 lecturas (appointments, patients)
- Acciones: 3 escrituras (crear/actualizar appointments)

**Cálculo mensual (30 días):**

| Operación  | Por Sesión | Total/Día (500 sesiones) | Total/Mes (30 días) |
| ---------- | ---------- | ------------------------ | ------------------- |
| Lecturas   | 12         | 6,000                    | 180,000             |
| Escrituras | 3          | 1,500                    | 45,000              |

**Costos:**

| Servicio              | Uso/Mes       | Límite Gratuito | Excedente | Costo             |
| --------------------- | ------------- | --------------- | --------- | ----------------- |
| **Authentication**    | 15,000 logins | Ilimitado       | 0         | **$0.00**         |
| **Firestore Reads**   | 180,000       | 1,500,000       | 0         | **$0.00** ✅      |
| **Firestore Writes**  | 45,000        | 600,000         | 0         | **$0.00** ✅      |
| **Firestore Storage** | 2 GB          | 1 GB            | 1 GB      | **$0.18**         |
| **Cloud Storage**     | 10 GB         | 5 GB            | 5 GB      | **$0.13**         |
| **Transferencia**     | 50 GB/mes     | 30 GB/mes       | 20 GB     | **$2.40**         |
| **TOTAL PRODUCCIÓN**  | -             | -               | -         | **~$2.71/mes** ✅ |

---

### Escenario: Producción (Uso alto)

**Usuarios activos**: 500 usuarios/día, 2,000 sesiones/día

| Servicio               | Uso/Mes       | Límite Gratuito | Excedente | Costo              |
| ---------------------- | ------------- | --------------- | --------- | ------------------ |
| **Authentication**     | 60,000 logins | Ilimitado       | 0         | **$0.00**          |
| **Firestore Reads**    | 720,000       | 1,500,000       | 0         | **$0.00** ✅       |
| **Firestore Writes**   | 180,000       | 600,000         | 0         | **$0.00** ✅       |
| **Firestore Storage**  | 10 GB         | 1 GB            | 9 GB      | **$1.62**          |
| **Cloud Storage**      | 50 GB         | 5 GB            | 45 GB     | **$1.17**          |
| **Transferencia**      | 200 GB/mes    | 30 GB/mes       | 170 GB    | **$20.40**         |
| **TOTAL ALTO TRÁFICO** | -             | -               | -         | **~$23.19/mes** ✅ |

---

## 🎯 Recomendaciones de Optimización

### 1. **Cacheo Agresivo**

```typescript
// apps/web/src/services/firebase.ts
const firestoreSettings = {
  cacheSizeBytes: CACHE_SIZE_UNLIMITED,
  persistence: true,
};
```

**Ahorro estimado:** 40-60% en lecturas

### 2. **Paginación**

```typescript
// Limitar consultas
const appointments = await getDocs(query(appointmentsRef, limit(20)));
```

**Ahorro estimado:** 50-70% en lecturas

### 3. **Índices Compuestos**

Crear índices para consultas complejas reduce lecturas redundantes.

**Ahorro estimado:** 30-40% en lecturas

### 4. **Listeners Selectivos**

```typescript
// En lugar de escuchar todos los documentos
onSnapshot(query(appointmentsRef, where('userId', '==', currentUserId)));
```

**Ahorro estimado:** 60-80% en lecturas

---

## 📊 Comparativa con Alternativas

| Servicio                       | Costo/Mes (500 usuarios/día) | Notas                            |
| ------------------------------ | ---------------------------- | -------------------------------- |
| **Firebase**                   | **$2-23**                    | Escalado automático, sin gestión |
| **MongoDB Atlas**              | $9-25                        | M10 cluster, gestión manual      |
| **Supabase**                   | $25                          | Incluye más features             |
| **AWS DynamoDB**               | $5-15                        | Requiere configuración compleja  |
| **PostgreSQL (GCP Cloud SQL)** | $25-50                       | Incluye base mínima              |

✅ **Firebase es la opción más económica para bajo-medio tráfico**

---

## 🔔 Configurar Alertas de Presupuesto

### 1. En Firebase Console

1. Ve a: https://console.firebase.google.com/project/adyela-staging/usage
2. Click en **"Details & settings"** > **"Set budget alert"**
3. Configura:
   - **Budget**: $10/mes (staging), $50/mes (production)
   - **Alert threshold**: 50%, 75%, 90%

### 2. Con gcloud CLI

```bash
# Crear alerta de presupuesto para Firebase
gcloud billing budgets create \
  --billing-account=0166AB-671459-CB9565 \
  --display-name="Firebase Budget - Staging" \
  --budget-amount=10USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=75 \
  --threshold-rule=percent=90 \
  --all-updates-rule-monitoring-notification-channels=CHANNEL_ID
```

---

## 💡 Plan Recomendado

### Para Staging

✅ **Spark Plan (GRATIS)** - Suficiente para desarrollo y testing

### Para Producción

✅ **Blaze Plan** con las siguientes medidas:

- Budget alert: $20/mes
- Implementar cacheo agresivo
- Monitorear uso semanalmente
- **Costo estimado:** $2-10/mes (primeros 6 meses)

---

## 📈 Proyección de Crecimiento

| Usuarios Activos/Día | Sesiones/Día | Costo/Mes Estimado |
| -------------------- | ------------ | ------------------ |
| 10 (staging)         | 50           | **$0**             |
| 100                  | 500          | **$2-5**           |
| 500                  | 2,000        | **$10-20**         |
| 1,000                | 4,000        | **$25-40**         |
| 5,000                | 20,000       | **$100-150**       |

---

## 🔗 Referencias Oficiales

- [Firebase Pricing](https://firebase.google.com/pricing)
- [Firestore Pricing Calculator](https://firebase.google.com/docs/firestore/pricing)
- [Firebase Usage Dashboard](https://console.firebase.google.com/project/_/usage)

---

**Generado:** 2025-10-07 **Proyecto:** Adyela **Billing Account:**
0166AB-671459-CB9565
