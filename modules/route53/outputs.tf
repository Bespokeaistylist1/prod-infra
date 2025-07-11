output "hosted_zone_id" {
  description = "ID of the Route 53 hosted zone"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

output "hosted_zone_name_servers" {
  description = "Name servers for the hosted zone"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].name_servers : data.aws_route53_zone.existing[0].name_servers
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}

output "root_record_fqdn" {
  description = "FQDN of the root domain record"
  value       = aws_route53_record.root.fqdn
}

output "subdomain_record_fqdns" {
  description = "FQDNs of subdomain records"
  value       = aws_route53_record.subdomains[*].fqdn
}

output "health_check_id" {
  description = "ID of the Route 53 health check"
  value       = aws_route53_health_check.main.id
}