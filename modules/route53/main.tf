# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  count = var.create_hosted_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "${var.project_name}-${var.environment}-hosted-zone"
    Environment = var.environment
    Domain      = var.domain_name
  }
}

# Data source for existing hosted zone (if not creating one)
data "aws_route53_zone" "existing" {
  count        = var.create_hosted_zone ? 0 : 1
  name         = var.domain_name
  private_zone = false
}

locals {
  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
  # Combine default subdomains with custom ones
  all_subdomains = concat(var.subdomain_records, var.custom_subdomains)
}

# Root domain A record pointing to ALB
resource "aws_route53_record" "root" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Subdomain records pointing to ALB
resource "aws_route53_record" "subdomains" {
  count   = length(local.all_subdomains)
  zone_id = local.zone_id
  name    = "${local.all_subdomains[count.index].name}.${var.domain_name}"
  type    = local.all_subdomains[count.index].type

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Health check for the domain
resource "aws_route53_health_check" "main" {
  fqdn                            = var.domain_name
  port                            = 80
  type                            = "HTTP"
  resource_path                   = "/"
  failure_threshold               = 5
  request_interval                = 30
  cloudwatch_logs_region          = "ap-south-1"
  cloudwatch_alarm_region         = "ap-south-1"
  insufficient_data_health_status = "Failure"

  tags = {
    Name        = "${var.project_name}-${var.environment}-health-check"
    Environment = var.environment
    Domain      = var.domain_name
  }
}