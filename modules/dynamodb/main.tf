
resource "aws_dynamodb_table" "ddb_table_with_out_global_tables" {
  count = "${(var.enable && length(var.global_table_locations) == 0) ? 1 : 0}"
  name           = "${var.table_name}${var.table_name_suffix}"
  billing_mode = "${var.billing_mode}"
  read_capacity  = "${var.read_capacity_units}"
  write_capacity = "${var.write_capacity_units}"

  hash_key       = "${var.hash_key}"
  stream_enabled = "${var.stream_enabled}"
  stream_view_type = "${var.stream_enabled == true ? local.stream_view_type : ""}"

  dynamic "attribute" {
    for_each = [for attrib in var.attributes : {
      name = attrib.name
      type = attrib.type
    }]
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = [for gsi in var.global_secondary_indexes : {
      name               = lookup(gsi, "name")
      hash_key           = lookup(gsi, "hash_key")
      range_key          = lookup(gsi, "range_key", null)
      read_capacity      = lookup(gsi, "read_capacity")
      write_capacity     = lookup(gsi, "write_capacity")
      projection_type    = lookup(gsi, "projection_type", "KEYS_ONLY")
      non_key_attributes = lookup(gsi, "non_key_attributes", [])
    }]
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      read_capacity      = global_secondary_index.value.read_capacity
      write_capacity     = global_secondary_index.value.write_capacity
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
    }
  }

  dynamic "local_secondary_index" {
    for_each = [for gsi in var.local_secondary_indexes : {
      name               = lookup(gsi, "name", "NoIndexName?")
      range_key          = lookup(gsi, "range_key", null)
      projection_type    = lookup(gsi, "projection_type", "KEYS_ONLY")
      non_key_attributes = lookup(gsi, "non_key_attributes", [])
    }]
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = local_secondary_index.value.non_key_attributes
    }
  }

  ttl {
    enabled = "${var.ttl_enable}"
    attribute_name = "${var.ttl_enable ? var.ttl_attribute_name : ""}"
  }

  server_side_encryption {
    enabled = "${var.server_side_encryption_enable}"

  }
  # tags = var.tags
}

resource "aws_dynamodb_table" "ddb_table_with_global_tables" {
  count = "${(var.enable && length(var.global_table_locations) > 0) ? length(var.global_table_locations) : 0}"

  # provider = "aws.${element(var.global_table_locations, count.index)}"
  # provider = format("aws.%s", element(var.global_table_locations, count.index))
  # provider {
  #   alias  = "${element(var.global_table_locations, count.index)}"
  #   region = "${element(var.global_table_locations, count.index)}"
  # }
  # provider = "aws.us-east-1"
  # provider {
  #   region = "${element(var.global_table_locations, count.index)}"
  # }
  

  name           = "${var.table_name}${var.table_name_suffix}"
  billing_mode = "${var.billing_mode}"
  read_capacity  = "${var.read_capacity_units}"
  write_capacity = "${var.write_capacity_units}"

  hash_key       = "${var.hash_key}"
  stream_enabled = "${var.stream_enabled}"
  stream_view_type = "${var.stream_enabled == true ? local.stream_view_type : ""}"

  dynamic "attribute" {
    for_each = [for attrib in var.attributes : {
      name = attrib.name
      type = attrib.type
    }]
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = [for gsi in var.global_secondary_indexes : {
      name               = lookup(gsi, "name")
      hash_key           = lookup(gsi, "hash_key")
      range_key          = lookup(gsi, "range_key", null)
      read_capacity      = lookup(gsi, "read_capacity")
      write_capacity     = lookup(gsi, "write_capacity")
      projection_type    = lookup(gsi, "projection_type", "KEYS_ONLY")
      non_key_attributes = lookup(gsi, "non_key_attributes", [])
    }]
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      read_capacity      = global_secondary_index.value.read_capacity
      write_capacity     = global_secondary_index.value.write_capacity
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
    }
  }

  dynamic "local_secondary_index" {
    for_each = [for gsi in var.local_secondary_indexes : {
      name               = lookup(gsi, "name", "NoIndexName?")
      range_key          = lookup(gsi, "range_key", null)
      projection_type    = lookup(gsi, "projection_type", "KEYS_ONLY")
      non_key_attributes = lookup(gsi, "non_key_attributes", [])
    }]
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = local_secondary_index.value.non_key_attributes
    }
  }

  ttl {
    enabled = "${var.ttl_enable}"
    attribute_name = "${var.ttl_enable ? var.ttl_attribute_name : ""}"
  }

  server_side_encryption {
    enabled = "${var.server_side_encryption_enable}"
  }
  # tags = var.tags
}

resource "aws_dynamodb_global_table" "ddb_global_table" {
  count = "${(var.enable && length(var.global_table_locations) > 0) ? 1 : 0}"
  depends_on = [ "aws_dynamodb_table.ddb_table_with_global_tables" ]
  
  name       = "${var.table_name}${var.table_name_suffix}"

  dynamic "replica" {
    for_each = [for region_name in var.global_table_locations : {
      region_name   = region_name
      
    }]
    content {
      region_name  =  replica.value.region_name
    }
  }
}