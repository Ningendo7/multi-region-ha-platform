variable "project_name" {
  description = "Logical project name used for naming global resources."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID."
  type        = string
}

variable "app_domain" {
  description = "Application DNS name."
  type        = string
}

variable "region_targets" {
  description = "Map of region targets with ALB DNS name and zone ID."
  type = map(object({
    dns_name = string
    zone_id  = string
  }))
}
