output "file_system_id" {
  value = "${aws_efs_file_system.default.0.id}"
}

output "file_system_arn" {
  value = "${aws_efs_file_system.default.0.arn}"
}

output "file_system_dns_name" {
  value = "${aws_efs_file_system.default.0.dns_name}"
}
