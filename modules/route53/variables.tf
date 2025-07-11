variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name to create hosted zone for"
  type        = string
}

variable "create_hosted_zone" {
  description = "Whether to create a hosted zone for the domain"
  type        = bool
  default     = true
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  type        = string
}

variable "subdomain_records" {
  description = "List of subdomain records to create"
  type = list(object({
    name = string
    type = string
  }))
  default = [
    {
      name = "www"
      type = "A"
    },
    {
      name = "api"
      type = "A"
    }
  ]
}

variable "custom_subdomains" {
  description = "List of additional custom subdomain records to create"
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "ttl" {
  description = "TTL for DNS records"
  type        = number
  default     = 300
}