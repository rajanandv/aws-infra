resource "aws_efs_file_system" "default" {
  count            = "${var.enabled ? 1 : 0}"
  performance_mode = "${var.performance_mode}"
  encrypted        = "${var.encrypted}"
  kms_key_id       = "${var.encrypted ? var.kms_key_id : ""}"
  tags             = var.tags
}

resource "aws_efs_mount_target" "default" {
  count           = "${var.enabled ? length(var.subnets) : 0}"
  file_system_id  = "${element(aws_efs_file_system.default.*.id, 0)}"
  subnet_id       = "${element(var.subnets, count.index)}"
  security_groups = var.security_group_ids
}

resource "aws_security_group" "default" {
  count       = "${length(var.security_group_ids) == 0 ? 1 : 0}"
  name        = "${var.name}-efs-sg"
  description = "EFS Access"
  vpc_id      = "${var.vpc_id}"
  tags        = "${var.tags}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress" {
  count                    = "${length(var.security_group_ids) == 0 ? 1 : 0}"
  type                     = "ingress"
  from_port                = "2049"
  to_port                  = "2049"
  protocol                 = "tcp"
  source_security_group_id = "${element(var.security_group_ids, count.index)}"
  security_group_id        = "${element(aws_security_group.default.*.id, 0)}" #TODO need to revist
}

resource "aws_security_group_rule" "ingress_cidr" {
  count             = "${length(compact(var.ingress_cidr)) > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = "2049"
  to_port           = "2049"
  protocol          = "tcp"
  cidr_blocks       = ["${var.ingress_cidr}"]
  security_group_id = "${element(aws_security_group.default.*.id, 0)}" #TODO need to revist
}

resource "aws_security_group_rule" "egress" {
  count             = "${length(var.security_group_ids) == 0 ? 1 : 0}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${element(aws_security_group.default.*.id, 0)}" #TODO need to revist
}
