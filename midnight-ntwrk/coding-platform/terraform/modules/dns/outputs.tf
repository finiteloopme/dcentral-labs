output "dns_zone_name" {
  description = "Name of the DNS zone"
  value       = var.enable_dns ? google_dns_managed_zone.workstation_zone[0].name : ""
}

output "dns_name_servers" {
  description = "Name servers for the DNS zone"
  value       = var.enable_dns ? google_dns_managed_zone.workstation_zone[0].name_servers : []
}

output "domain_name" {
  description = "The domain name configured"
  value       = var.domain_name
}

output "workstation_urls" {
  description = "URLs for accessing workstations"
  value = var.enable_dns ? {
    main      = "https://${var.domain_name}"
    wildcard  = "https://*.${var.domain_name}"
    workstation = "https://workstation.${var.domain_name}"
    ide       = "https://ide.${var.domain_name}"
    code      = "https://code.${var.domain_name}"
  } : {}
}