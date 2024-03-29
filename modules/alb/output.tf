output "dns_name" {
  description = "The DNS name of the load balancer."
  value       = "${element(aws_lb.application_lb.*.dns_name, 0)}"
}

# output "http_tcp_listener_arns" {
#   description = "The ARN of the TCP and HTTP load balancer listeners created."
#   value       = "${slice(aws_lb_listener.frontend_http_tcp.*.arn, 0, var.http_tcp_listeners_count)}"
# }

# output "http_tcp_listener_ids" {
#   description = "The IDs of the TCP and HTTP load balancer listeners created."
#   value       = "${slice(aws_lb_listener.frontend_http_tcp.*.id, 0, var.http_tcp_listeners_count)}"
# }

output "load_balancer_arn_suffix" {
  description = "ARN suffix of our load balancer - can be used with CloudWatch."
  value       = "${element(aws_lb.application_lb.*.arn_suffix, 0)}"
}

output "load_balancer_id" {
  description = "The ID and ARN of the load balancer we created."
  value       = "${element(aws_lb.application_lb.*.id, 0)}"
}

output "load_balancer_zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records."
  value       = "${element(aws_lb.application_lb.*.zone_id, 0)}"
}

output "target_group_arns" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
  value       = "${slice(aws_lb_target_group.lb_target_grp.*.arn, 0, var.target_groups_count)}"
}

output "target_group_arn_suffixes" {
  description = "ARN suffixes of our target groups - can be used with CloudWatch."
  value       = "${slice(aws_lb_target_group.lb_target_grp.*.arn_suffix, 0, var.target_groups_count)}"
}

output "target_group_names" {
  description = "Name of the target group. Useful for passing to your CodeDeploy Deployment Group."
  value       = "${slice(aws_lb_target_group.lb_target_grp.*.name, 0, var.target_groups_count)}"
}
