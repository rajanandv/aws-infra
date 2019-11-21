####################################
# Autoscaling Launch configuration
####################################
resource "aws_launch_configuration" "this" {
  count = "${var.create_launch_config ? 1 : 0}"

  name_prefix                 = "${var.name}-asg-lc"
  image_id                    = "${var.image_id}"
  instance_type               = "${var.instance_type}"
  iam_instance_profile        = "${var.iam_instance_profile}"
  key_name                    = "${var.key_name}"
  security_groups             = var.security_groups
  associate_public_ip_address = "${var.assign_public_ip_address}"
  user_data                   = "${var.user_data}"
  enable_monitoring           = "${var.enable_monitoring}"
  ebs_optimized               = "${var.ebs_optimized}"



  dynamic "root_block_device" {
    for_each = [for ebs_vol in var.root_block_device : {
      volume_type           = lookup(ebs_vol, "volume_type", "standard")
      volume_size           = lookup(ebs_vol, "volume_size", "10")
      iops                  = (lookup(ebs_vol, "volume_type", "standard") == "io1" ? lookup(ebs_vol, "iops") : "")
      delete_on_termination = lookup(ebs_vol, "delete_on_termination", true)
    }]
    content {
      volume_type           = root_block_device.value.volume_type
      volume_size           = root_block_device.value.volume_size
      iops                  = root_block_device.value.iops
      delete_on_termination = root_block_device.value.delete_on_termination
    }
  }

  dynamic "ebs_block_device" {
    for_each = [for ebs_vol in var.ebs_block_device : {
      device_name           = lookup(ebs_vol, "device_name", "/dev/sdg")
      volume_type           = lookup(ebs_vol, "volume_type", "standard")
      volume_size           = lookup(ebs_vol, "volume_size", "10")
      iops                  = lookup(ebs_vol, "iops", "")
      delete_on_termination = lookup(ebs_vol, "delete_on_termination", true)
      encrypted             = lookup(ebs_vol, "encrypted", "false")
    }]
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = ebs_block_device.value.iops
      delete_on_termination = ebs_block_device.value.delete_on_termination
      encrypted             = ebs_block_device.value.encrypted
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

####################
# Autoscaling group
####################
resource "aws_autoscaling_group" "autoscaling_group" {
  count = "${var.create_asg && ! var.create_asg_with_initial_lifecycle_hook ? 1 : 0}"

  name_prefix = "${var.name}-asg-"

  # launch_configuration = "${var.create_launch_config ? element(concat(aws_launch_configuration.this.*.name, list("")), 0) : var.launch_configuration}"
  launch_configuration = "${element(concat(aws_launch_configuration.this.*.name, list("")), 0)}"
  vpc_zone_identifier  = var.vpc_subnet_ids
  max_size             = "${var.max_size}"
  min_size             = "${var.min_size}"
  desired_capacity     = "${var.desired_capacity}"

  load_balancers            = "${var.load_balancers}"
  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type         = "${var.health_check_type}"

  min_elb_capacity          = "${var.min_elb_capacity}"
  wait_for_elb_capacity     = "${var.wait_for_elb_capacity}"
  target_group_arns         = "${var.target_group_arns}"
  default_cooldown          = "${var.default_cooldown}"
  force_delete              = "${var.force_delete}"
  termination_policies      = "${var.termination_policies}"
  suspended_processes       = "${var.suspended_processes}"
  placement_group           = "${var.placement_group}"
  enabled_metrics           = "${var.enabled_metrics}"
  metrics_granularity       = "${var.metrics_granularity}"
  wait_for_capacity_timeout = "${var.wait_for_capacity_timeout}"
  protect_from_scale_in     = "${var.protect_from_scale_in}"

  tags = ["${var.tags}"]


  lifecycle {
    create_before_destroy = true
  }
}

################################################
# Autoscaling group with initial lifecycle hook
################################################
resource "aws_autoscaling_group" "this_with_initial_lifecycle_hook" {
  count = "${var.create_asg && var.create_asg_with_initial_lifecycle_hook ? 1 : 0}"

  name_prefix          = "${var.name}-asg-"
  launch_configuration = "${var.create_launch_config ? element(aws_launch_configuration.this.*.name, 0) : var.launch_configuration}"
  vpc_zone_identifier  = "${var.vpc_subnet_ids}"
  max_size             = "${var.max_size}"
  min_size             = "${var.min_size}"
  desired_capacity     = "${var.desired_capacity}"

  load_balancers            = "${var.load_balancers}"
  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type         = "${var.health_check_type}"

  min_elb_capacity          = "${var.min_elb_capacity}"
  wait_for_elb_capacity     = "${var.wait_for_elb_capacity}"
  target_group_arns         = "${var.target_group_arns}"
  default_cooldown          = "${var.default_cooldown}"
  force_delete              = "${var.force_delete}"
  termination_policies      = "${var.termination_policies}"
  suspended_processes       = "${var.suspended_processes}"
  placement_group           = "${var.placement_group}"
  enabled_metrics           = "${var.enabled_metrics}"
  metrics_granularity       = "${var.metrics_granularity}"
  wait_for_capacity_timeout = "${var.wait_for_capacity_timeout}"
  protect_from_scale_in     = "${var.protect_from_scale_in}"

  initial_lifecycle_hook {
    name                    = "${var.initial_lifecycle_hook_name}"
    lifecycle_transition    = "${var.initial_lifecycle_hook_lifecycle_transition}"
    notification_metadata   = "${var.initial_lifecycle_hook_notification_metadata}"
    heartbeat_timeout       = "${var.initial_lifecycle_hook_heartbeat_timeout}"
    notification_target_arn = "${var.initial_lifecycle_hook_notification_target_arn}"
    role_arn                = "${var.initial_lifecycle_hook_role_arn}"
    default_result          = "${var.initial_lifecycle_hook_default_result}"
  }

  tags = ["${var.tags}"]

  lifecycle {
    create_before_destroy = true
  }
}
