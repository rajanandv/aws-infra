output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "region" {
  value = "${data.aws_region.current.name}"
}

output "vpc_id" {
  value = "${data.aws_vpc.current.id}"
}

output "private_subnet_ids" {
  value = "${data.aws_subnet_ids.private.ids}"
}

output "protected_subnet_ids" {
  value = "${data.aws_subnet_ids.protected.ids}"
}

output "public_subnet_ids" {
  value = "${data.aws_subnet_ids.public.ids}"
}

output "name" {
  value = "value"
}


# output "private_subnet_cidr_blocks" {
#   value = "${data.aws_subnet.private_subnets.cidr_block}"
# }

# output "protected_subnet_cidr_blocks" {
#   value = "${data.aws_subnet.protected_subnets.cidr_block}"
# }
# output "public_subnet_cidr_blocks" {
#   value = "${data.aws_subnet.public_subnets.cidr_block}"
# }


