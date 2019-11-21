resource "aws_lb" "application_lb" {
  name                             = "${var.load_balancer_name}-alb"
  internal                         = "${var.load_balancer_is_internal}"
  security_groups                  = "${var.security_groups}"
  subnets                          = "${var.subnets}"
  idle_timeout                     = "${var.idle_timeout}"
  enable_cross_zone_load_balancing = "${var.enable_cross_zone_load_balancing}"
  enable_deletion_protection       = "${var.enable_deletion_protection}"
  enable_http2                     = "${var.enable_http2}"
  ip_address_type                  = "${var.ip_address_type}"
  load_balancer_type               = "application"

  access_logs {
    bucket  = "${var.log_bucket_name}"
    prefix  = "${var.load_balancer_name}-logs"
    enabled = "${var.access_logs}"
  }

  tags = "${var.tags}"

  timeouts {
    create = "${var.load_balancer_create_timeout}"
    delete = "${var.load_balancer_delete_timeout}"
    update = "${var.load_balancer_update_timeout}"
  }

  #count = "${var.logging_enabled ? 1 : 0}"
}

resource "aws_lb_target_group" "lb_target_grp" {
  name                 = "${lookup(var.target_groups[count.index], "name")}"
  vpc_id               = "${var.vpc_id}"
  port                 = "${lookup(var.target_groups[count.index], "backend_port")}"
  protocol             = "${upper(lookup(var.target_groups[count.index], "backend_protocol"))}"
  deregistration_delay = "${lookup(var.target_groups[count.index], "deregistration_delay", lookup(local.target_groups_defaults, "deregistration_delay"))}"
  target_type          = "${lookup(var.target_groups[count.index], "target_type", lookup(local.target_groups_defaults, "target_type"))}"
  slow_start           = "${lookup(var.target_groups[count.index], "slow_start", lookup(local.target_groups_defaults, "slow_start"))}"

  health_check {
    interval            = "${lookup(var.target_groups[count.index], "health_check_interval", lookup(local.target_groups_defaults, "health_check_interval"))}"
    path                = "${lookup(var.target_groups[count.index], "health_check_path", lookup(local.target_groups_defaults, "health_check_path"))}"
    port                = "${lookup(var.target_groups[count.index], "health_check_port", lookup(local.target_groups_defaults, "health_check_port"))}"
    healthy_threshold   = "${lookup(var.target_groups[count.index], "health_check_healthy_threshold", lookup(local.target_groups_defaults, "health_check_healthy_threshold"))}"
    unhealthy_threshold = "${lookup(var.target_groups[count.index], "health_check_unhealthy_threshold", lookup(local.target_groups_defaults, "health_check_unhealthy_threshold"))}"
    timeout             = "${lookup(var.target_groups[count.index], "health_check_timeout", lookup(local.target_groups_defaults, "health_check_timeout"))}"
    protocol            = "${upper(lookup(var.target_groups[count.index], "healthcheck_protocol", lookup(var.target_groups[count.index], "backend_protocol")))}"
    matcher             = "${lookup(var.target_groups[count.index], "health_check_matcher", lookup(local.target_groups_defaults, "health_check_matcher"))}"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = "${lookup(var.target_groups[count.index], "cookie_duration", lookup(local.target_groups_defaults, "cookie_duration"))}"
    enabled         = "${lookup(var.target_groups[count.index], "stickiness_enabled", lookup(local.target_groups_defaults, "stickiness_enabled"))}"
  }

  tags       = "${merge(var.tags, map("Name", lookup(var.target_groups[count.index], "name")))}"
  count      = "${var.target_groups_count}"
  depends_on = ["aws_lb.application_lb"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "frontend_http_listner" {
  load_balancer_arn = "${element(concat(aws_lb.application_lb.*.arn, list("")), 0)}"
  port              = "${lookup(var.http_tcp_listeners[count.index], "port")}"
  protocol          = "${upper(lookup(var.http_tcp_listeners[count.index], "protocol"))}"
  certificate_arn   = "${upper(lookup(var.http_tcp_listeners[count.index], "protocol")) == "HTTPS" ? lookup(var.http_tcp_listeners[count.index], "certificate_arn") : ""}"
  ssl_policy        = "${upper(lookup(var.http_tcp_listeners[count.index], "protocol")) == "HTTPS" ? lookup(var.http_tcp_listeners[count.index], "ssl_policy", var.listener_ssl_policy_default) : ""}"
  count             = "${var.http_tcp_listeners_count}"

  default_action {
    target_group_arn = "${aws_lb_target_group.lb_target_grp.*.id[lookup(var.http_tcp_listeners[count.index], "target_group_index", 0)]}"
    type             = "forward"
  }
}
