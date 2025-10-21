# DNS Module for Cloud Workstations

This module configures Cloud DNS to enable custom domain access for Cloud Workstations.

## Features

- Creates a Cloud DNS managed zone
- Sets up A records for workstation access
- Configures wildcard DNS for subdomain access
- Provides CNAME records for common aliases (workstation, dev, ide, code)
- Supports additional custom DNS records
- DNSSEC enabled by default

## Usage

```hcl
module "dns" {
  source = "./modules/dns"
  
  project_id     = "your-project-id"
  environment    = "dev"
  domain_name    = "midnight-dev.example.com"
  enable_dns     = true
  workstation_ip = "34.56.78.90"  # Or use NAT IP from networking module
  
  dns_records = [
    {
      name = "api"
      type = "A"
      ttl  = 300
      data = ["10.0.0.1"]
    }
  ]
}
```

## Configuration Steps

### 1. Enable DNS in Terraform

In your `terraform.tfvars`:
```hcl
enable_custom_domain = true
custom_domain       = "midnight-dev.yourdomain.com"
# Leave custom_domain_ip empty to use the NAT IP automatically
```

### 2. Apply Terraform

```bash
terraform apply
```

### 3. Update Domain Registrar

After applying, get the name servers:
```bash
terraform output dns_name_servers
```

Update your domain registrar to point to these Google Cloud DNS name servers.

### 4. Verify DNS

Wait for DNS propagation (can take up to 48 hours), then verify:
```bash
# Check DNS resolution
nslookup midnight-dev.yourdomain.com

# Test workstation access
curl -I https://midnight-dev.yourdomain.com
```

## Access URLs

Once configured, workstations will be accessible at:
- `https://midnight-dev.yourdomain.com` - Main access
- `https://workstation.midnight-dev.yourdomain.com` - Workstation alias
- `https://ide.midnight-dev.yourdomain.com` - IDE alias
- `https://code.midnight-dev.yourdomain.com` - Code editor alias
- `https://*.midnight-dev.yourdomain.com` - Wildcard for any subdomain

## Important Notes

1. **DNS Propagation**: DNS changes can take 24-48 hours to propagate globally
2. **HTTPS Certificates**: Cloud Workstations automatically handles SSL certificates
3. **Firewall Rules**: Ensure your firewall rules allow HTTPS traffic
4. **NAT IP**: If not specified, uses the NAT IP from the networking module
5. **DNSSEC**: Enabled by default for security

## Troubleshooting

### DNS Not Resolving
- Verify name servers are updated at registrar
- Check zone exists: `gcloud dns managed-zones list`
- Verify records: `gcloud dns record-sets list --zone=midnight-dev-zone`

### Cannot Access Workstation
- Check workstation is running: `gcloud workstations list`
- Verify firewall rules allow HTTPS
- Ensure workstation config uses public access

### SSL Certificate Issues
- Cloud Workstations manages certificates automatically
- May take a few minutes after DNS setup for certificates to provision