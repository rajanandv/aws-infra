locals {
  zones      = "${keys(var.domains)}"
  records    = "${keys(transpose(var.domains))}"
  record_map = "${transpose(var.domains)}"
  type_count = "${length(var.record_types)}"
}