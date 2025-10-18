# Análisis de Costos y Presupuestos FinOps

## Resumen Ejecutivo

Este documento centraliza el análisis de costos de la arquitectura de
microservicios propuesta para Adyela.

**🔗 Ver análisis completo en**:
`docs/planning/health-platform-strategy.plan.md` - Sección 4.1 (líneas 384-630)

---

## Presupuesto Mensual Resumido

### Staging Environment

**Total**: **$100-150/mes**

- Backend microservicios (6 servicios): $25-45
- Frontend apps (3 servicios): $10-15
- Data layer (Firestore + Cloud SQL): $30-45
- Networking (LB + CDN + WAF): $25-32
- Observabilidad: $10-22

**Comparación**: $70-103/mes objetivo actual → **+30-45% por microservicios**

### Producción Environment

**Total Inicial**: **$700-900/mes** **Total Escalado** (10k+ usuarios):
**$1,200-1,800/mes**

---

## Estrategias de Optimización Clave

### Staging ($150/mes target)

1. **Scale-to-Zero Agresivo**
   - Ahorro: 40-50% vs min-instances=1
   - Implementación: Terraform `--min-instances=0`

2. **Cloud SQL Scheduling**
   - Detener fuera de horario (20:00-8:00, weekends)
   - Ahorro: ~$12-17/mes (50%)

3. **Budget Alerts**
   ```bash
   # Alert al 50%, 80%, 100% de $150/mes
   # Ver Terraform code en plan principal línea 482-510
   ```

### Producción (Optimización Continua)

1. **Cost Allocation Tags**
   - Tags: `service`, `tier`, `tenant_id`, `environment`
   - Permite identificar servicios costosos

2. **Firestore Optimization**
   - Denormalización estratégica
   - Redis caching (hot paths)
   - Estimated savings: 30-40% reads

3. **CDN Hit Ratio > 80%**
   - Reduce egress costs significativamente

4. **Committed Use Discounts (CUD)** (Mes 12+)
   - Descuento: 37-57% cuando usage es estable

---

## Métricas FinOps

| Métrica                     | Target Staging | Target Producción        |
| --------------------------- | -------------- | ------------------------ |
| **Cost per Active User**    | N/A (dev only) | <$0.50/usuario/mes       |
| **Cost per API Request**    | N/A            | <$0.0001/request         |
| **Infra Cost as % Revenue** | N/A            | <30% Fase 1, <20% Fase 2 |
| **Egress Cost Ratio**       | <20%           | <15% (CDN optimizado)    |

---

## Riesgos de Costos

| Riesgo                  | Prob  | Impacto | Mitigación                    |
| ----------------------- | ----- | ------- | ----------------------------- |
| Staging excede $150/mes | Media | Bajo    | Budget alerts + auto-shutdown |
| Firestore runaway costs | Alta  | Alto    | Query analysis CI/CD + alerts |
| CDN mal configurado     | Media | Medio   | Hit ratio monitoring          |

---

## Roadmap de Optimización

- **Mes 1-3**: Setup budget alerts, cost allocation tags
- **Mes 4-6**: Análisis de costo por servicio, optimize Firestore
- **Mes 7-9**: Caching (Redis), CDN optimization, right-sizing
- **Mes 10-12**: Cost attribution por tenant, CUD evaluation

---

## Terraform Budget Alerts

```hcl
# Ver implementación completa en:
# docs/planning/health-platform-strategy.plan.md líneas 482-510

resource "google_billing_budget" "staging_budget" {
  billing_account = var.billing_account
  display_name    = "Adyela Staging Budget"

  amount {
    specified_amount {
      units = "150"  # $150/mes
    }
  }

  threshold_rules {
    threshold_percent = 0.5  # 50%
  }
  # ... ver documento principal para código completo
}
```

---

## Cost Attribution Multi-Tenancy

### Pool Model (Tier Free/Pro)

- Todos los tenants comparten infraestructura
- Costo prorrateado por: # usuarios activos, API calls, storage
- `tenant_id` label en todas las operaciones Firestore

### Silo Model (Tier Enterprise)

- Infraestructura dedicada
- Cloud Run service dedicado por tenant
- Billing directo con `tenant_id` tags

**Ver código Terraform**: Plan principal líneas 567-594

---

## Dashboards Recomendados

1. **Cost by Service** (Looker Studio)
   - api-auth: $X/mes
   - api-appointments: $Y/mes
   - etc.

2. **Cost by Tenant** (Enterprise tiers)
   - Tenant ABC: $Z/mes
   - Tenant XYZ: $W/mes

3. **Cost Anomaly Detection**
   - Alert si costo diario > 20% normal

---

## Contactos y Responsabilidades

- **FinOps Lead**: [TBD]
- **Budget Approvals**: [TBD]
- **Monthly Cost Reviews**: Primer viernes de cada mes
- **Escalation**: CTO si budget excede 120% ($180/mes staging, $1080/mes
  producción)

---

**Documento**: `docs/finops/cost-analysis-and-budgets.md` **Version**: 1.0
**Última actualización**: 2025-10-18 **Review Schedule**: Mensual
