# Monitoring & Observability Module

**Version**: 2.0.0 **Status**: ✅ Complete **Last Updated**: 2025-10-19

---

## 📋 Overview

Comprehensive monitoring and observability module for HIPAA-compliant Cloud Run
services with:

- **Uptime monitoring** from multiple global regions
- **Advanced SLOs** with error budget tracking and burn rate alerts
- **Centralized logging** with BigQuery integration for analysis
- **Distributed tracing** with Cloud Trace
- **Error reporting** with automated alerting
- **Custom dashboards** for each microservice using Google's Golden Signals
- **Multi-channel notifications** (Email, SMS, Slack, PagerDuty)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     MONITORING & OBSERVABILITY                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Uptime Checks│  │ Cloud Trace  │  │Error Report  │             │
│  │  (Global)    │  │ (Distributed)│  │  (Auto)      │             │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │
│         │                  │                  │                     │
│  ┌──────▼──────────────────▼──────────────────▼─────────┐          │
│  │            Cloud Monitoring (Metrics)                 │          │
│  │  • Request Rate    • Latency Percentiles             │          │
│  │  • Error Rate      • Container Resources             │          │
│  │  • SLO Compliance  • Custom Metrics                  │          │
│  └──────────────────────┬────────────────────────────────┘          │
│                         │                                           │
│         ┌───────────────┼───────────────┐                          │
│         │               │               │                          │
│  ┌──────▼─────┐  ┌──────▼─────┐  ┌─────▼──────┐                   │
│  │  SLOs (3)  │  │  Alerts(7) │  │ Dashboards │                   │
│  │            │  │            │  │  (Dynamic) │                   │
│  │ •Avail 99.9│  │ • Down     │  │ • Main     │                   │
│  │ •Latency   │  │ • Error    │  │ • Per MS   │                   │
│  │ •Error Rate│  │ • SLO Burn │  │ • Golden   │                   │
│  └────────────┘  └──────┬─────┘  └────────────┘                   │
│                         │                                           │
│              ┌──────────▼─────────────┐                            │
│              │  Notification Channels │                            │
│              │  • Email  • SMS        │                            │
│              │  • Slack  • PagerDuty  │                            │
│              └────────────────────────┘                            │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │          Cloud Logging + BigQuery Sinks                   │     │
│  │  • Application Logs (90-day retention)                    │     │
│  │  • Error Logs (Severity >= ERROR)                         │     │
│  │  • Audit Logs (HIPAA-compliant PHI tracking)             │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Features

### 1. Uptime Monitoring

**Global Uptime Checks:**

- ✅ API Health Endpoint (`/health`) - Every 60 seconds
- ✅ Web Homepage (`/`) - Every 5 minutes
- ✅ Multi-region checking (USA, Europe, South America)
- ✅ SSL validation included

**Cost**: First 3 checks FREE, then $0.30/check/month

### 2. Service Level Objectives (SLOs)

**Three SLOs Configured:**

| SLO              | Target       | Rolling Period | Metric                         |
| ---------------- | ------------ | -------------- | ------------------------------ |
| **Availability** | 99.9%        | 30 days        | 2xx responses / total requests |
| **Latency**      | P95 < 1000ms | 30 days        | Request latencies              |
| **Error Rate**   | < 1%         | 30 days        | Non-2xx responses              |

**Error Budget Tracking:**

- Fast burn alert: >10x burn rate (2% budget in 1 hour)
- Slow burn alert: >3x burn rate (10% budget in 24 hours)

### 3. Alert Policies

**7 Alert Policies Configured:**

| Alert           | Threshold          | Duration  | Channels    |
| --------------- | ------------------ | --------- | ----------- |
| API Downtime    | Uptime check fails | 60s       | Email + SMS |
| High Error Rate | >1% errors         | 5 min     | Email       |
| High Latency    | P95 >1000ms        | 5 min     | Email       |
| Error Reporting | New error type     | 60s       | Email       |
| SLO Fast Burn   | 10x burn rate      | Immediate | Email + SMS |
| SLO Slow Burn   | 3x burn rate       | Immediate | Email       |
| Trace Latency   | P95 >2000ms        | 5 min     | Email       |

### 4. Centralized Logging

**BigQuery Log Sinks:**

- **Application Logs**: All Cloud Run service logs (DEFAULT+)
- **Error Logs**: Severity >= ERROR only
- **Audit Logs**: HIPAA-compliant PHI access tracking

**Features:**

- ✅ Partitioned tables for performance
- ✅ 90-day retention (configurable)
- ✅ Automatic IAM permissions for writers
- ✅ Queryable with SQL for analysis

**Cost**: BigQuery storage + analysis costs (~$0.02/GB/month storage, $5/TB
queried)

### 5. Dashboards

**Main Dashboard:**

- API Request Rate (requests/second)
- Error Rate by Response Code (%)
- Request Latency (P50, P95, P99)

**Microservice Dashboards** (Golden Signals):

- **Latency**: P50/P95/P99 with SLO threshold line
- **Traffic**: Request rate over time
- **Errors**: By response code class (stacked area)
- **Saturation**: CPU and Memory utilization

**Additional Metrics** (for API services):

- Active container instances
- Billable time (cost tracking)
- Cold start frequency

### 6. Distributed Tracing

**Cloud Trace Integration:**

- ✅ Automatic trace collection from Cloud Run
- ✅ Configurable sampling rate (100% for staging)
- ✅ Latency alerts (P95 >2 seconds)
- ✅ Correlation with logs and errors

### 7. Error Reporting

**Automatic Error Detection:**

- ✅ Stack trace collection
- ✅ Error grouping by signature
- ✅ Frequency and trend tracking
- ✅ Alerts on new error types

### 8. Notification Channels

**Supported Channels:**

- ✅ Email (always enabled)
- ✅ SMS (optional, requires verification)
- ✅ Slack (optional, webhook-based)
- ✅ PagerDuty (optional, for critical alerts)

---

## 🚀 Usage

### Basic Usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project_id   = "my-project"
  project_name = "adyela"
  environment  = "staging"
  region       = "us-central1"
  domain       = "staging.adyela.care"

  # Alert configuration
  alert_email = "alerts@adyela.com"

  # Enable log sinks
  enable_log_sinks = true

  labels = {
    environment = "staging"
    managed_by  = "terraform"
  }
}
```

### Advanced Usage with Microservices

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  # ... basic config ...

  # Custom SLO targets
  availability_slo_target = 0.995  # 99.5%
  latency_slo_target_ms   = 500    # 500ms
  error_rate_slo_target   = 0.005  # 0.5%
  slo_rolling_period_days = 30

  # Microservices dashboards
  enable_microservices_dashboards = true
  microservices = [
    {
      name         = "adyela-api-auth-staging"
      display_name = "Auth API"
      service_type = "api"
    },
    {
      name         = "adyela-api-appointments-staging"
      display_name = "Appointments API"
      service_type = "api"
    },
    {
      name         = "adyela-api-notifications-staging"
      display_name = "Notifications Service"
      service_type = "worker"
    }
  ]

  # SMS alerts for critical issues
  enable_sms_alerts    = true
  alert_phone_number   = "+15551234567"

  # Slack integration
  enable_slack_notifications = true
  slack_webhook_url          = var.slack_webhook_url  # From secret

  # PagerDuty for critical alerts
  enable_pagerduty_notifications = true
  pagerduty_integration_key      = var.pagerduty_key  # From secret

  # Trace configuration
  enable_trace_alerts  = true
  trace_sampling_rate  = 0.1  # 10% sampling for production

  # Error reporting
  enable_error_reporting_alerts = true
}
```

---

## 📝 Variables

### Required Variables

| Variable       | Type   | Description                            |
| -------------- | ------ | -------------------------------------- |
| `project_id`   | string | GCP Project ID                         |
| `project_name` | string | Project name for resource naming       |
| `environment`  | string | Environment name (staging, production) |
| `domain`       | string | Primary domain for uptime monitoring   |
| `alert_email`  | string | Email address for alerts               |

### Optional Variables

| Variable                          | Type         | Default       | Description                      |
| --------------------------------- | ------------ | ------------- | -------------------------------- |
| `region`                          | string       | `us-central1` | GCP region for resources         |
| `enable_log_sinks`                | bool         | `true`        | Enable BigQuery log sinks        |
| `log_retention_days`              | number       | `90`          | Log retention in BigQuery        |
| `enable_sms_alerts`               | bool         | `false`       | Enable SMS notifications         |
| `alert_phone_number`              | string       | `""`          | Phone for SMS (E.164 format)     |
| `availability_slo_target`         | number       | `0.999`       | Target availability (99.9%)      |
| `latency_slo_target_ms`           | number       | `1000`        | Target latency P95 (ms)          |
| `error_rate_slo_target`           | number       | `0.01`        | Max error rate (1%)              |
| `slo_rolling_period_days`         | number       | `30`          | SLO rolling window               |
| `enable_microservices_dashboards` | bool         | `true`        | Create per-service dashboards    |
| `microservices`                   | list(object) | `[]`          | List of microservices to monitor |
| `enable_slack_notifications`      | bool         | `false`       | Enable Slack alerts              |
| `slack_webhook_url`               | string       | `""`          | Slack webhook URL                |
| `enable_pagerduty_notifications`  | bool         | `false`       | Enable PagerDuty                 |
| `pagerduty_integration_key`       | string       | `""`          | PagerDuty integration key        |
| `enable_trace_alerts`             | bool         | `true`        | Enable trace latency alerts      |
| `trace_sampling_rate`             | number       | `1.0`         | Trace sampling (0.0-1.0)         |
| `enable_error_reporting_alerts`   | bool         | `true`        | Enable error alerts              |

---

## 📤 Outputs

### Dashboard URLs

```hcl
output "dashboard_url"                # Main dashboard URL
output "microservice_dashboard_urls"  # Map of microservice dashboards
```

### SLO IDs

```hcl
output "slo_availability_id"   # Availability SLO ID
output "slo_latency_id"        # Latency SLO ID
output "slo_error_rate_id"     # Error Rate SLO ID
```

### Alert Policies

```hcl
output "alert_policy_ids"      # Map of all alert policy IDs
```

### Log Sinks

```hcl
output "log_dataset_id"        # BigQuery dataset for logs
output "log_sink_names"        # Map of log sink names
```

### Quick Access URLs

```hcl
output "observability_urls"    # Map of all observability tool URLs
# - metrics_explorer
# - logs_explorer
# - trace_list
# - error_reporting
# - dashboards
# - uptime_checks
# - slos
# - alerts
```

---

## 💰 Cost Estimation

### Staging Environment

| Resource          | Quantity | Unit Cost    | Monthly Cost     |
| ----------------- | -------- | ------------ | ---------------- |
| Uptime Checks     | 2        | First 3 FREE | $0.00            |
| Alert Policies    | 7        | FREE         | $0.00            |
| SLOs              | 3        | FREE         | $0.00            |
| Dashboards        | 1+       | FREE         | $0.00            |
| Log Sinks         | 3        | FREE         | $0.00            |
| BigQuery Storage  | ~10 GB   | $0.02/GB     | ~$0.20           |
| BigQuery Analysis | ~1 GB    | $5/TB        | ~$0.01           |
| **Total**         |          |              | **~$0.21/month** |

### Production Environment

| Resource          | Quantity  | Unit Cost   | Monthly Cost     |
| ----------------- | --------- | ----------- | ---------------- |
| Uptime Checks     | 3         | $0.30/check | $0.90            |
| Log Sinks         | 3         | FREE        | $0.00            |
| BigQuery Storage  | ~100 GB   | $0.02/GB    | ~$2.00           |
| BigQuery Analysis | ~10 GB    | $5/TB       | ~$0.05           |
| SMS Alerts        | ~10/month | $0.03/SMS   | ~$0.30           |
| **Total**         |           |             | **~$3.25/month** |

---

## 🔍 Monitoring Best Practices

### 1. SLO Management

**Error Budget Policies:**

- **>50% budget remaining**: Deploy freely, experiment
- **25-50% budget**: Increase caution, reduce deploy frequency
- **<25% budget**: Freeze non-critical changes, focus on reliability
- **Budget exhausted**: Incident, halt all changes until recovery

**Burn Rate Response:**

- **Fast burn (10x)**: Page on-call immediately, potential outage
- **Slow burn (3x)**: Review trends, plan remediation
- **Normal burn**: Monitor, no action needed

### 2. Alert Fatigue Prevention

**Guidelines:**

- ✅ DO alert on SLO violations (user impact)
- ✅ DO alert on fast error budget burn
- ❌ DON'T alert on individual request failures
- ❌ DON'T alert on expected transient errors

**Alert Tuning:**

- Review alert frequency monthly
- Disable low-value alerts
- Consolidate similar alerts
- Adjust thresholds based on actual patterns

### 3. Dashboard Usage

**Daily Operations:**

1. Check main dashboard for overview
2. Review SLO compliance and error budget
3. Investigate any anomalies

**Incident Response:**

1. Main dashboard → Identify affected service
2. Microservice dashboard → Find root cause (Golden Signals)
3. Logs Explorer → Review error messages
4. Trace List → Analyze slow requests
5. Error Reporting → Group related errors

### 4. Log Analysis Queries

**Top Errors (Last 24 Hours):**

```sql
SELECT
  jsonPayload.message,
  COUNT(*) as error_count
FROM
  `project.dataset.application_logs*`
WHERE
  severity >= 'ERROR'
  AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10
```

**PHI Access Audit (HIPAA):**

```sql
SELECT
  jsonPayload.user_id,
  jsonPayload.patient_id,
  jsonPayload.action,
  jsonPayload.reason,
  timestamp
FROM
  `project.dataset.audit_logs*`
WHERE
  jsonPayload.phi_access = true
  AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
ORDER BY timestamp DESC
```

**Latency P95 by Endpoint:**

```sql
SELECT
  httpRequest.requestUrl,
  APPROX_QUANTILES(httpRequest.latency, 100)[OFFSET(95)] / 1000000 as p95_latency_ms,
  COUNT(*) as request_count
FROM
  `project.dataset.application_logs*`
WHERE
  timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
GROUP BY 1
ORDER BY 2 DESC
```

---

## 🛠️ Troubleshooting

### Common Issues

**1. SLO showing "No Data"**

```bash
# Check if service exists
gcloud run services describe SERVICE_NAME --region=us-central1

# Verify service is receiving traffic
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="SERVICE_NAME"' --limit=10
```

**2. Alerts not firing**

```bash
# Check notification channels
gcloud alpha monitoring channels list

# Verify alert policy is enabled
gcloud alpha monitoring policies list

# Test notification channel
gcloud alpha monitoring channels describe CHANNEL_ID
```

**3. Log sinks not working**

```bash
# Check sink configuration
gcloud logging sinks describe SINK_NAME

# Verify IAM permissions
gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:WRITER_IDENTITY"

# Grant missing permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=WRITER_IDENTITY \
  --role=roles/bigquery.dataEditor
```

**4. Dashboard metrics missing**

Metrics may take 2-5 minutes to appear. If still missing after 10 minutes:

```bash
# Check if metric exists
gcloud monitoring metric-descriptors list --filter="metric.type=run.googleapis.com/request_count"

# Verify service labels
gcloud run services describe SERVICE_NAME --format="value(metadata.labels)"
```

---

## 📚 References

- [Cloud Monitoring Documentation](https://cloud.google.com/monitoring/docs)
- [SLO Best Practices](https://cloud.google.com/blog/products/devops-sre/sre-fundamentals-slis-slas-and-slos)
- [Error Budget Policy](https://sre.google/workbook/error-budget-policy/)
- [Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals)
- [Cloud Trace Documentation](https://cloud.google.com/trace/docs)
- [Cloud Logging Query Language](https://cloud.google.com/logging/docs/view/logging-query-language)

---

## ✅ Health Checklist

- [ ] All uptime checks are passing
- [ ] SLO compliance > 99%
- [ ] Error budget > 50% remaining
- [ ] No fast burn alerts in last 7 days
- [ ] Alert fatigue < 5 alerts/week
- [ ] Log sinks flowing to BigQuery
- [ ] Dashboards showing recent data (<5 min old)
- [ ] Notification channels tested and working
- [ ] Weekly log analysis performed
- [ ] Monthly alert tuning completed

---

**Maintained By**: DevOps Team **Support**: alerts@adyela.com **Last Review**:
2025-10-19
