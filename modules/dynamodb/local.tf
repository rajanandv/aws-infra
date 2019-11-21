locals {
  stream_view_type = "${var.stream_view_type == "" ? "NEW_AND_OLD_IMAGES" : var.stream_view_type}"

  provider_names = var.global_table_locations
}
