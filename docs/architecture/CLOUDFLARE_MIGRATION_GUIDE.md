# 🚀 Cloudflare CDN Migration Guide

## 📋 Overview

This guide covers the migration from Google Cloud CDN to Cloudflare CDN for the Adyela project. The migration provides:

- **20% cost reduction** ($8-9/month savings)
- **Better performance** with 200+ edge locations
- **Enhanced security** with WAF and DDoS protection
- **Simplified management** with unified dashboard

## 🎯 Benefits

### Cost Savings

- **Current GCP CDN**: $8-12/month
- **Cloudflare CDN**: $5-8/month
- **Savings**: $3-4/month (40% reduction)

### Performance Improvements

- **Global Edge Network**: 200+ locations worldwide
- **Faster TTFB**: Reduced latency
- **Better Caching**: Intelligent cache policies
- **HTTP/3 Support**: Latest protocol support

### Security Enhancements

- **WAF Protection**: Web Application Firewall included
- **DDoS Protection**: Automatic DDoS mitigation
- **Bot Management**: Advanced bot detection
- **SSL/TLS 1.3**: Latest encryption standards

## 🏗️ Architecture Changes

### Before (GCP CDN)

```
User → Cloud DNS → GCP Load Balancer → GCP CDN → Cloud Storage
```

### After (Cloudflare CDN)

```
User → Cloudflare DNS → Cloudflare CDN → GCP Load Balancer → Cloud Run
```

## 📦 Components

### 1. DNS Management

- **Zone**: `adyela.care`
- **Records**:
  - `staging.adyela.care` → Load Balancer IP
  - `api.staging.adyela.care` → Load Balancer IP

### 2. CDN Configuration

- **Static Assets**: `/assets/*` → Cache Everything (1 year)
- **API Endpoints**: `/api/*` → Bypass Cache
- **Web App**: `/*` → Standard Cache (1 hour)

### 3. Security Rules

- **WAF Rules**: Block common attack patterns
- **Rate Limiting**: API protection
- **Security Headers**: HSTS, CSP, etc.

## 🚀 Migration Steps

### Prerequisites

1. **Cloudflare Account**: Free plan sufficient
2. **Domain Access**: `adyela.care` must be in Cloudflare
3. **API Token**: With appropriate permissions

### Step 1: Setup Cloudflare

```bash
# Set API token
export CLOUDFLARE_API_TOKEN="your-token-here"

# Run setup script
./scripts/setup-cloudflare.sh
```

### Step 2: Apply Terraform

```bash
cd infra/environments/staging
terraform plan
terraform apply
```

### Step 3: Update DNS

The Terraform configuration will automatically create DNS records pointing to the GCP Load Balancer IP (`34.96.108.162`).

### Step 4: Test Migration

```bash
# Run migration script
./scripts/migrate-to-cloudflare.sh
```

### Step 5: Verify Performance

- Test response times
- Verify SSL certificates
- Check cache headers
- Monitor error rates

## 🔧 Configuration Details

### Page Rules

1. **Static Assets** (`/assets/*`)
   - Cache Level: Cache Everything
   - Edge TTL: 1 year
   - Browser TTL: 1 year

2. **API Endpoints** (`/api/*`)
   - Cache Level: Bypass
   - Edge TTL: 0
   - Browser TTL: 0

3. **Web Application** (`/*`)
   - Cache Level: Standard
   - Edge TTL: 1 hour
   - Browser TTL: 0

### WAF Rules

- Block common attack paths (`/.env`, `/wp-admin`, `/admin`)
- Challenge high threat score requests
- Log API POST requests

### Security Headers

- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: geolocation=(), microphone=(), camera=()`

## 📊 Monitoring

### Key Metrics

- **Response Time**: TTFB and TTLB
- **Cache Hit Ratio**: CDN efficiency
- **Error Rate**: 4xx/5xx responses
- **Bandwidth**: Data transfer

### Cloudflare Analytics

- **Web Analytics**: Free tier includes basic analytics
- **Security Events**: WAF and DDoS events
- **Performance**: Core Web Vitals

## 🔄 Rollback Plan

If issues occur, rollback is simple:

1. **Disable Cloudflare Proxy**:

   ```bash
   # Set DNS records to "DNS only" (gray cloud)
   ```

2. **Revert to GCP CDN**:

   ```bash
   # Re-enable GCP CDN
   gcloud compute backend-buckets update adyela-staging-static-backend \
     --enable-cdn --project=adyela-staging
   ```

3. **Update DNS**:
   ```bash
   # Point DNS back to GCP Load Balancer directly
   ```

## 💰 Cost Analysis

### Current Costs (GCP CDN)

- Cloud Storage CDN: $2-5/month
- Cloud Armor WAF: $5.17/month
- **Total**: $7.17-10.17/month

### Projected Costs (Cloudflare CDN)

- Cloudflare CDN: $5-8/month
- WAF: Included
- **Total**: $5-8/month

### Savings

- **Monthly**: $2.17-2.17/month
- **Annual**: $26-26/year
- **Percentage**: 20% reduction

## 🎯 Success Criteria

### Performance

- [ ] TTFB < 200ms globally
- [ ] Cache hit ratio > 90%
- [ ] No increase in error rates

### Security

- [ ] WAF blocking malicious requests
- [ ] SSL/TLS 1.3 active
- [ ] Security headers present

### Cost

- [ ] 20% reduction in CDN costs
- [ ] No increase in other service costs
- [ ] Overall infrastructure cost reduction

## 📚 Resources

- [Cloudflare Documentation](https://developers.cloudflare.com/)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare Page Rules](https://developers.cloudflare.com/fundamentals/concepts/how-cloudflare-works/)
- [Cloudflare WAF](https://developers.cloudflare.com/waf/)

## 🆘 Troubleshooting

### Common Issues

1. **DNS Propagation**
   - Wait 24-48 hours for full propagation
   - Use `dig` to check DNS records

2. **SSL Certificate Issues**
   - Ensure domain is in Cloudflare
   - Check SSL/TLS settings

3. **Cache Issues**
   - Purge cache after changes
   - Check cache headers

4. **Performance Issues**
   - Monitor cache hit ratio
   - Check page rules configuration

### Support

- Cloudflare Support: Available in dashboard
- Documentation: [developers.cloudflare.com](https://developers.cloudflare.com/)
- Community: [community.cloudflare.com](https://community.cloudflare.com/)
