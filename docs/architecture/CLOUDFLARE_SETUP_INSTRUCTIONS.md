# 🔧 Cloudflare Setup Instructions

## Prerequisites

Before running the Cloudflare Terraform configuration, you need to set up the
following:

### 1. Cloudflare Account Setup

1. **Create Cloudflare Account** (if you don't have one):
   - Go to
     [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
   - Sign up for a free account

2. **Add Domain to Cloudflare**:
   - Go to [https://dash.cloudflare.com/](https://dash.cloudflare.com/)
   - Click "Add a Site"
   - Enter `adyela.care`
   - Choose the **Free** plan
   - Follow the setup instructions

### 2. Create API Token

1. **Go to API Tokens**:
   - Navigate to
     [https://dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)

2. **Create Custom Token**:
   - Click "Create Token"
   - Use "Custom token" template

3. **Set Permissions**:

   ```
   Zone:Zone:Read
   Zone:DNS:Edit
   Zone:Page Rules:Edit
   Zone:Cache Purge:Edit
   Zone:Zone Settings:Edit
   Zone:Zone:Edit
   ```

4. **Set Zone Resources**:
   - Include
   - Specific zone
   - `adyela.care`

5. **Copy the Token**:
   - Save the token securely
   - You'll need it for the next step

### 3. Configure Environment Variables

Set the Cloudflare API token as an environment variable:

```bash
# Set the API token
export CLOUDFLARE_API_TOKEN="your-token-here"

# Verify it's set
echo $CLOUDFLARE_API_TOKEN
```

### 4. Run Setup Script

```bash
# Make the script executable
chmod +x scripts/setup-cloudflare.sh

# Run the setup script
./scripts/setup-cloudflare.sh
```

### 5. Apply Terraform Configuration

```bash
# Navigate to staging environment
cd infra/environments/staging

# Initialize Terraform (if not done already)
terraform init

# Plan the changes
terraform plan

# Apply the changes
terraform apply
```

## Verification

After applying the Terraform configuration, verify the setup:

### 1. Check DNS Records

```bash
# Check if DNS records are created
dig staging.adyela.care
dig api.staging.adyela.care
```

### 2. Test CDN Functionality

```bash
# Test the main site
curl -I https://staging.adyela.care

# Test the API
curl -I https://api.staging.adyela.care/health

# Test static assets
curl -I https://staging.adyela.care/assets/index-CBVomuyO.js
```

### 3. Check Cloudflare Dashboard

1. Go to [https://dash.cloudflare.com/](https://dash.cloudflare.com/)
2. Select `adyela.care`
3. Check the following sections:
   - **DNS**: Verify records are created
   - **Page Rules**: Verify cache rules are active
   - **Security**: Verify WAF rules are active
   - **SSL/TLS**: Verify SSL settings

## Troubleshooting

### Common Issues

1. **API Token Not Working**:
   - Verify the token has correct permissions
   - Check if the token is for the right zone
   - Ensure the token is not expired

2. **DNS Not Propagating**:
   - Wait 24-48 hours for full propagation
   - Check if nameservers are pointing to Cloudflare
   - Use `dig` to check DNS records

3. **SSL Certificate Issues**:
   - Ensure domain is in Cloudflare
   - Check SSL/TLS settings in dashboard
   - Verify DNS records are proxied (orange cloud)

4. **Cache Not Working**:
   - Check page rules configuration
   - Verify cache headers
   - Purge cache if needed

### Support Resources

- [Cloudflare Documentation](https://developers.cloudflare.com/)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare Community](https://community.cloudflare.com/)

## Next Steps

After successful setup:

1. **Monitor Performance**: Check Cloudflare analytics
2. **Optimize Cache**: Adjust page rules as needed
3. **Security Review**: Verify WAF rules are working
4. **Cost Monitoring**: Track bandwidth usage
5. **Migration**: Consider disabling GCP CDN after 24-48 hours
