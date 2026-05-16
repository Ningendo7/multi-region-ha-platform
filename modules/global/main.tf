resource "aws_route53_health_check" "region" {
  for_each = var.region_targets

  fqdn              = each.value.dns_name
  type              = "HTTPS"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3
}

resource "aws_route53_record" "app" {
  for_each = var.region_targets

  zone_id = var.hosted_zone_id
  name    = var.app_domain
  type    = "A"

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.zone_id
    evaluate_target_health = true
  }

  set_identifier  = each.key
  weighted_routing_policy {
    
         weight          = 100
  }
  health_check_id = aws_route53_health_check.region[each.key].id
}
