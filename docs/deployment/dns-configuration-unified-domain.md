# DNS Configuration for Unified Domain Structure

**Version**: 1.0.0 **Last Updated**: 2025-10-19 **Owner**: Infrastructure Team
**Classification**: DEPLOYMENT GUIDE

---

## 📋 Overview

This document provides instructions for configuring DNS records in Cloudflare to
support the unified domain structure where all applications (admin, patient,
professional) are hosted under the same base domain with subdomain routing.

### Architecture

```
staging.adyela.care                    → Admin Web App (React)
patient.staging.adyela.care           → Patient App (Flutter Web)
professional.staging.adyela.care      → Professional App (Flutter Web)
api.staging.adyela.care               → Backend APIs
```

---

## 🎯 DNS Requirements

### Staging Environment

| Subdomain              | Type  | Target                | TTL  | Proxy Status | Purpose              |
| ---------------------- | ----- | --------------------- | ---- | ------------ | -------------------- |
| `staging`              | A     | `34.96.108.162`       | Auto | ☁️ Proxied   | Admin web app        |
| `patient.staging`      | CNAME | `staging.adyela.care` | Auto | ☁️ Proxied   | Patient web app      |
| `professional.staging` | CNAME | `staging.adyela.care` | Auto | ☁️ Proxied   | Professional web app |
| `api.staging`          | CNAME | `staging.adyela.care` | Auto | ☁️ Proxied   | Backend APIs         |

**Load Balancer IP**: `34.96.108.162` (already configured in GCP)

---

## 🚀 Step-by-Step Configuration

### Step 1: Verify Existing Records

1. Log in to Cloudflare dashboard
2. Select domain: `adyela.care`
3. Navigate to **DNS** tab
4. Verify existing record:
   - `staging` → A record → `34.96.108.162` ✅

### Step 2: Add Patient App Subdomain

**Method 1: Using Cloudflare Dashboard**

1. Click **Add record**
2. Configure:
   - **Type**: `CNAME`
   - **Name**: `patient.staging`
   - **Target**: `staging.adyela.care`
   - **Proxy status**: ☁️ Proxied (orange cloud)
   - **TTL**: Auto
3. Click **Save**

**Method 2: Using Cloudflare API**

```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "patient.staging",
    "content": "staging.adyela.care",
    "ttl": 1,
    "proxied": true
  }'
```

**Method 3: Using Terraform** (Recommended)

```hcl
resource "cloudflare_record" "patient_staging" {
  zone_id = var.cloudflare_zone_id
  name    = "patient.staging"
  value   = "staging.adyela.care"
  type    = "CNAME"
  proxied = true
}
```

### Step 3: Add Professional App Subdomain

**Method 1: Using Cloudflare Dashboard**

1. Click **Add record**
2. Configure:
   - **Type**: `CNAME`
   - **Name**: `professional.staging`
   - **Target**: `staging.adyela.care`
   - **Proxy status**: ☁️ Proxied (orange cloud)
   - **TTL**: Auto
3. Click **Save**

**Method 2: Using Cloudflare API**

```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "professional.staging",
    "content": "staging.adyela.care",
    "ttl": 1,
    "proxied": true
  }'
```

**Method 3: Using Terraform** (Recommended)

```hcl
resource "cloudflare_record" "professional_staging" {
  zone_id = var.cloudflare_zone_id
  name    = "professional.staging"
  value   = "staging.adyela.care"
  type    = "CNAME"
  proxied = true
}
```

### Step 4: Verify API Subdomain

Ensure API subdomain exists (should already be configured):

```bash
# Check if api.staging.adyela.care exists
dig api.staging.adyela.care +short

# Should return: staging.adyela.care or 34.96.108.162
```

If not configured, add it:

**Cloudflare Dashboard:**

- Type: `CNAME`
- Name: `api.staging`
- Target: `staging.adyela.care`
- Proxy: ☁️ Proxied

---

## ✅ Verification

### DNS Propagation Check

```bash
# Check patient subdomain
dig patient.staging.adyela.care +short
# Expected: staging.adyela.care or Cloudflare IP

# Check professional subdomain
dig professional.staging.adyela.care +short
# Expected: staging.adyela.care or Cloudflare IP

# Check API subdomain
dig api.staging.adyela.care +short
# Expected: staging.adyela.care or Cloudflare IP
```

### Online DNS Tools

- [DNS Checker](https://dnschecker.org/) - Global DNS propagation
- [What's My DNS](https://www.whatsmydns.net/) - Multi-location check
- [MX Toolbox](https://mxtoolbox.com/DNSLookup.aspx) - DNS lookup tool

### SSL Certificate Verification

After DNS propagation (5-15 minutes), GCP will automatically provision SSL
certificates for the new subdomains.

**Check certificate status:**

```bash
gcloud compute ssl-certificates describe adyela-staging-web-ssl-cert \
  --project=adyela-staging \
  --format="table(name,managed.domains,managed.status)"
```

**Expected output:**

```
NAME                          DOMAINS                                                STATUS
adyela-staging-web-ssl-cert   staging.adyela.care                                    ACTIVE
                             api.staging.adyela.care                                 ACTIVE
                             patient.staging.adyela.care                             ACTIVE (or PROVISIONING)
                             professional.staging.adyela.care                        ACTIVE (or PROVISIONING)
```

**Status meanings:**

- `PROVISIONING`: Certificate is being created (~15 minutes)
- `ACTIVE`: Certificate is ready and serving HTTPS
- `FAILED_PERMANENT`: DNS issue or domain verification failed

---

## 🔒 Cloudflare Settings

### Recommended Cloudflare Configuration

#### SSL/TLS Settings

- **SSL/TLS encryption mode**: `Full (strict)`
  - Path: SSL/TLS → Overview → Encryption mode
  - Ensures end-to-end encryption between Cloudflare and GCP

#### Page Rules (Optional)

Configure page rules for optimization:

1. **Always Use HTTPS**
   - URL: `*adyela.care/*`
   - Setting: Always Use HTTPS

2. **Cache Everything (Static Assets)**
   - URL: `*.staging.adyela.care/assets/*`
   - Settings:
     - Cache Level: Cache Everything
     - Edge Cache TTL: 1 month

3. **Bypass Cache (API)**
   - URL: `api.staging.adyela.care/*`
   - Setting: Bypass Cache

#### Firewall Rules (Optional)

Create WAF rules if needed:

```
Description: Rate limit API calls
Expression: (http.host eq "api.staging.adyela.care")
Action: Challenge (Rate limit: 100 requests/minute)
```

---

## 🎭 Production Environment

For production, replicate the same structure:

| Subdomain      | Type  | Target        | TTL  | Proxy Status | Purpose              |
| -------------- | ----- | ------------- | ---- | ------------ | -------------------- |
| `www` or `@`   | A     | `PROD_LB_IP`  | Auto | ☁️ Proxied   | Admin web app        |
| `patient`      | CNAME | `adyela.care` | Auto | ☁️ Proxied   | Patient web app      |
| `professional` | CNAME | `adyela.care` | Auto | ☁️ Proxied   | Professional web app |
| `api`          | CNAME | `adyela.care` | Auto | ☁️ Proxied   | Backend APIs         |

**Important**: Update Terraform with production load balancer IP before
deployment.

---

## 🚨 Troubleshooting

### Issue 1: DNS Not Resolving

**Symptoms**: `dig` returns `NXDOMAIN` or no results

**Solutions**:

1. Check DNS record is created in Cloudflare
2. Wait 5-15 minutes for propagation
3. Clear local DNS cache:

   ```bash
   # macOS
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

   # Linux
   sudo systemd-resolve --flush-caches

   # Windows
   ipconfig /flushdns
   ```

### Issue 2: SSL Certificate Not Provisioning

**Symptoms**: Certificate stuck in `PROVISIONING` status for >30 minutes

**Solutions**:

1. Verify DNS records are correct
2. Check Cloudflare proxy is enabled (orange cloud)
3. Verify load balancer is healthy:
   ```bash
   gcloud compute forwarding-rules describe adyela-staging-web-https-forwarding-rule \
     --project=adyela-staging --global
   ```
4. Check certificate logs:
   ```bash
   gcloud logging read "resource.type=gce_ssl_certificate" \
     --project=adyela-staging --limit=50
   ```

### Issue 3: HTTPS Not Working

**Symptoms**: Browser shows "Not Secure" or SSL error

**Solutions**:

1. Verify SSL certificate is `ACTIVE`
2. Check Cloudflare SSL mode is `Full (strict)`
3. Test direct GCP Cloud Run URL (should have valid cert)
4. Clear browser cache and try incognito mode

### Issue 4: Wrong App Served

**Symptoms**: Visiting `patient.staging.adyela.care` shows admin app

**Solutions**:

1. Verify load balancer URL map configuration:
   ```bash
   gcloud compute url-maps describe adyela-staging-web-url-map \
     --project=adyela-staging --global \
     --format=yaml
   ```
2. Check host rules include patient and professional subdomains
3. Apply Terraform changes:
   ```bash
   cd infra/environments/staging
   terraform plan
   terraform apply
   ```

---

## 📊 Monitoring

### DNS Health Checks

Set up monitoring for DNS resolution:

```bash
# Create a cron job for DNS monitoring
*/5 * * * * dig patient.staging.adyela.care +short | grep -q . || echo "DNS DOWN: patient.staging" | mail -s "DNS Alert" devops@adyela.care
```

### Uptime Monitoring

Configure uptime checks in GCP (already configured by Terraform):

- `https://staging.adyela.care` - Admin app
- `https://patient.staging.adyela.care` - Patient app
- `https://professional.staging.adyela.care` - Professional app
- `https://api.staging.adyela.care/health` - API health

---

## 📋 Checklist

### Pre-Deployment

- [ ] Load balancer deployed with updated configuration
- [ ] Cloud Run services deployed for patient and professional apps
- [ ] Terraform plan shows URL map with all subdomains
- [ ] Docker images built and pushed to Artifact Registry

### DNS Configuration

- [ ] `patient.staging.adyela.care` CNAME record created
- [ ] `professional.staging.adyela.care` CNAME record created
- [ ] `api.staging.adyela.care` CNAME record verified
- [ ] All records proxied through Cloudflare (orange cloud)
- [ ] DNS propagation verified with `dig`

### SSL Certificates

- [ ] Certificate includes all 4 domains
- [ ] Certificate status is `ACTIVE` (not `PROVISIONING`)
- [ ] HTTPS works for all subdomains
- [ ] No mixed content warnings in browser console

### Application Testing

- [ ] Admin app loads at `https://staging.adyela.care`
- [ ] Patient app loads at `https://patient.staging.adyela.care`
- [ ] Professional app loads at `https://professional.staging.adyela.care`
- [ ] API responds at `https://api.staging.adyela.care/health`
- [ ] CORS works from Flutter apps to API
- [ ] Authentication works across all apps

### Monitoring

- [ ] Uptime checks configured
- [ ] Alert policies created
- [ ] DNS monitoring enabled
- [ ] Application logs showing traffic

---

## 🔗 Related Documentation

- [Terraform Operations Runbook](./terraform-operations-runbook.md)
- [GitOps Workflow](./gitops-workflow.md)
- [GCP Setup Guide](./gcp-setup.md)
- [Deployment Strategy](../../DEPLOYMENT_STRATEGY.md)

---

## 📝 Revision History

| Version | Date       | Author | Changes                                 |
| ------- | ---------- | ------ | --------------------------------------- |
| 1.0.0   | 2025-10-19 | Claude | Initial DNS configuration documentation |

---

**Questions?** Contact infrastructure team or Slack #infrastructure-team

**Cloudflare Support**: https://dash.cloudflare.com/ **GCP Console**:
https://console.cloud.google.com/net-services/loadbalancing
