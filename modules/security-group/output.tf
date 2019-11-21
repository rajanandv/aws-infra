output "security_group_id" {
  value = "${length(aws_security_group.default.*.id) > 0 ? element(aws_security_group.default.*.id, 0) : ""}"
}
