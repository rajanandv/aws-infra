# Network Load Balancers do not have their own security groups

resource "aws_security_group" "default" {
  count  = "${var.type == "application" ? 1 : 0}"
  name   = "${var.security_group_name}"
  vpc_id = "${var.vpc_id}"
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.security_group_name}",
      "preserve", "${var.public && var.allow_http ? "true" : "false"}"
    )
  )}"
  lifecycle {
    ignore_changes = ["tags"]
  }
}

# ------------------------------------------------------------------------------
#
#   HTTP
#
# ------------------------------------------------------------------------------

resource "aws_security_group_rule" "ingress_public_http" {
  count             = "${var.type == "application" && var.public && var.allow_http ? 1 : 0}"
  type              = "ingress"
  security_group_id = "${aws_security_group.default.0.id}"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = "${var.public_cidrs}"
}

resource "aws_security_group_rule" "ingress_internal_http" {
  count             = "${var.type == "application" && ! var.public && var.allow_http ? 1 : 0}"
  type              = "ingress"
  security_group_id = "${aws_security_group.default.0.id}"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = "${var.internal_cidrs}"
}

# ------------------------------------------------------------------------------
#
#   HTTPS
#
# ------------------------------------------------------------------------------

resource "aws_security_group_rule" "ingress_public_https" {
  count             = "${var.type == "application" && var.public && var.allow_https ? 1 : 0}"
  type              = "ingress"
  security_group_id = "${aws_security_group.default.0.id}"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = "${var.public_cidrs}"
}

resource "aws_security_group_rule" "ingress_internal_https" {
  count             = "${var.type == "application" && ! var.public && var.allow_https ? 1 : 0}"
  type              = "ingress"
  security_group_id = "${aws_security_group.default.0.id}"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = "${var.internal_cidrs}"
}

###### Note: protocol = "all" or protocol = -1 will make all ports open ###############

resource "aws_security_group_rule" "ingress_internal" {
  count                    = "${length(var.ingress_rules) == 0 ? 0 : length(var.ingress_rules)}"
  type                     = "ingress"
  security_group_id        = "${aws_security_group.default.0.id}"
  protocol                 = "${lookup(element(var.ingress_rules, count.index), "protocol")}"
  from_port                = "${lookup(element(var.ingress_rules, count.index), "from_port")}"
  to_port                  = "${lookup(element(var.ingress_rules, count.index), "from_port")}"
  cidr_blocks              = "${contains(keys(element(var.ingress_rules, count.index)), "cidr_blocks") ? lookup(element(var.ingress_rules, count.index), "cidr_blocks", []) : []}"
  self                     = "${lookup(element(var.ingress_rules, count.index), "self", false)}"
  source_security_group_id = "${lookup(element(var.ingress_rules, count.index), "source_security_group_id", "")}"
}
resource "aws_security_group_rule" "egress_internal" {
  count                    = "${length(var.egress_rules) == 0 ? 0 : length(var.egress_rules)}"
  type                     = "egress"
  security_group_id        = "${aws_security_group.default.0.id}"
  protocol                 = "${lookup(element(var.egress_rules, count.index), "protocol")}"
  from_port                = "${lookup(element(var.egress_rules, count.index), "from_port")}"
  to_port                  = "${lookup(element(var.egress_rules, count.index), "from_port")}"
  cidr_blocks              = "${(!lookup(element(var.egress_rules, count.index), "self", false) && lookup(element(var.egress_rules, count.index), "source_security_group_id", "") == "") ? lookup(element(var.egress_rules, count.index), "cidr_blocks", []) : []}"
  self                     = "${lookup(element(var.egress_rules, count.index), "self", false)}"
  source_security_group_id = "${lookup(element(var.egress_rules, count.index), "self", false) ? "" : lookup(element(var.egress_rules, count.index), "source_security_group_id", "")}"
}
