locals {
  this_launch_configuration_id                     = "${var.launch_configuration == "" && var.create_launch_config ? element(concat(aws_launch_configuration.this.*.id, list("")), 0) : var.launch_configuration}"
  this_launch_configuration_name                   = "${var.launch_configuration == "" && var.create_launch_config ? element(concat(aws_launch_configuration.this.*.name, list("")), 0) : ""}"
  this_autoscaling_group_id                        = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.id, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.id), list("")), 0)}"
  this_autoscaling_group_name                      = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.name, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.name), list("")), 0)}"
  this_autoscaling_group_arn                       = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.arn, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.arn), list("")), 0)}"
  this_autoscaling_group_min_size                  = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.min_size, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.min_size), list("")), 0)}"
  this_autoscaling_group_max_size                  = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.max_size, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.max_size), list("")), 0)}"
  this_autoscaling_group_desired_capacity          = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.desired_capacity, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.desired_capacity), list("")), 0)}"
  this_autoscaling_group_default_cooldown          = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.default_cooldown, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.default_cooldown), list("")), 0)}"
  this_autoscaling_group_health_check_grace_period = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.health_check_grace_period, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.health_check_grace_period), list("")), 0)}"
  this_autoscaling_group_health_check_type         = "${element(concat(coalescelist(aws_autoscaling_group.autoscaling_group.*.health_check_type, aws_autoscaling_group.this_with_initial_lifecycle_hook.*.health_check_type), list("")), 0)}"
}

output "this_launch_configuration_id" {
  description = "The ID of the launch configuration"
  value       = "${local.this_launch_configuration_id}"
}

output "this_launch_configuration_name" {
  description = "The name of the launch configuration"
  value       = "${local.this_launch_configuration_name}"
}

output "this_autoscaling_group_id" {
  description = "The autoscaling group id"
  value       = "${local.this_autoscaling_group_id}"
}

output "this_autoscaling_group_name" {
  description = "The autoscaling group name"
  value       = "${local.this_autoscaling_group_name}"
}

output "this_autoscaling_group_arn" {
  description = "The ARN for this AutoScaling Group"
  value       = "${local.this_autoscaling_group_arn}"
}

output "this_autoscaling_group_min_size" {
  description = "The minimum size of the autoscale group"
  value       = "${local.this_autoscaling_group_min_size}"
}

output "this_autoscaling_group_max_size" {
  description = "The maximum size of the autoscale group"
  value       = "${local.this_autoscaling_group_max_size}"
}

output "this_autoscaling_group_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  value       = "${local.this_autoscaling_group_desired_capacity}"
}

output "this_autoscaling_group_default_cooldown" {
  description = "Time between a scaling activity and the succeeding scaling activity"
  value       = "${local.this_autoscaling_group_default_cooldown}"
}

output "this_autoscaling_group_health_check_grace_period" {
  description = "Time after instance comes into service before checking health"
  value       = "${local.this_autoscaling_group_health_check_grace_period}"
}

output "this_autoscaling_group_health_check_type" {
  description = "EC2 or ELB. Controls how health checking is done"
  value       = "${local.this_autoscaling_group_health_check_type}"
}

output "my_test" {
  value = "${var.create_launch_config}"
}
