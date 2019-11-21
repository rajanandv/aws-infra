
data "aws_route53_zone" "route_zone" {
  count = "${length(local.zones)}"
  name  = "${local.zones[count.index]}"
}

resource "aws_route53_record" "route_record" {
  count = "${length(local.records) * length(var.record_types)}"

  name = "${element(local.records, floor(count.index / local.type_count))}"

  zone_id = "${
    element(matchkeys(
      data.aws_route53_zone.route_zone.*.id,
      data.aws_route53_zone.route_zone.*.name,
      local.record_map[element(local.records, floor(count.index / local.type_count))]
    ), 0)
  }"

  
  type = "${element(var.record_types, count.index % local.type_count)}"

  alias {
    name                   = "${var.alias_domain_name}"
    zone_id                = "${var.alias_hosted_zone_id}"
    evaluate_target_health = false
  }
}