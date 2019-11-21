locals {
  businee_unit_name = "djis"
  business_owner    = "paul.kaiser@dowjones.com"
  project_name      = "Product and Pricing"
  terraform_version = "0.11.14"
  aws_account_type  = "${var.environment == "prod" ? "prod" : "dev"}"
  ami_image_id      = "${var.ami_id != "" ? var.ami_id : data.aws_ami.current.image_id}"

  # security_groups       = "${length(var.security_groups) == 0 ? list("sg-1234", "sg-4567") : var.security_groups}"

  security_groups = concat(var.additional_security_group_ids, list(module.default_shrsvc_sg.security_group_id))

  default_instance_type = "t2.micro"

  shrsvc_app_service_name = "${replace(module.pnpapp_nomenclature.servicename, "/", "-")}-${module.pnpapp_nomenclature.environment}"

  private_subnet_ids_list = split(",", join(",", module.metadata.private_subnet_ids))

  lambda_cache_inv_config = {
    enable_blue_environment = "${var.lambda_cache_inv_enable_blue_environment}"
    lambda_function_name    = "djispnp_shopurlcfcacheinv_function"
    timeout                 = "120"
    deploy_lambda           = true
    package_path            = "${path.module}"
  }


  ca_cluster = {
    "instance_type"        = "${var.ca_ec2_instance_type == "" ? local.default_instance_type : var.ca_ec2_instance_type}"
    "asg_min_size"         = "2"
    "asg_max_size"         = "2"
    "asg_desired_capacity" = "2"
    "alb_internal"         = true
  }

  calock_cluster = {
    "instance_type"        = "${var.calock_ec2_instance_type == "" ? local.default_instance_type : var.calock_ec2_instance_type}"
    "asg_min_size"         = "2"
    "asg_max_size"         = "2"
    "asg_desired_capacity" = "2"
  }

  prdsvc_cluster = {
    "instance_type"        = "${var.prdsvc_ec2_instance_type == "" ? local.default_instance_type : var.prdsvc_ec2_instance_type}"
    "asg_min_size"         = "1"
    "asg_max_size"         = "4"
    "asg_desired_capacity" = "1"
    "alb_internal"         = true
  }

  prdlock_cluster = {
    "instance_type"        = "${var.prdlock_ec2_instance_type == "" ? local.default_instance_type : var.prdlock_ec2_instance_type}"
    "asg_min_size"         = "2"
    "asg_max_size"         = "2"
    "asg_desired_capacity" = "2"
  }

  prdaux_cluster = {
    "instance_type"        = "${var.prdaux_ec2_instance_type == "" ? local.default_instance_type : var.prdaux_ec2_instance_type}"
    "asg_min_size"         = "1"
    "asg_max_size"         = "1"
    "asg_desired_capacity" = "1"
  }

  stgsvc_cluster = {
    "instance_type"        = "${var.stgsvc_ec2_instance_type == "" ? local.default_instance_type : var.stgsvc_ec2_instance_type}"
    "asg_min_size"         = "2"
    "asg_max_size"         = "2"
    "asg_desired_capacity" = "2"
    "alb_internal"         = true
  }

  shopurl_dynamodb_config = {
      "table_name"           = "djcmpnp_shopurls_ddbtable_${var.environment}"
      "read_capacity_units"  = "96"
      "write_capacity_units" = "36"
      "hash_key"             = "Uri"
      "stream_enabled"       = true
      "global_table_locations" = "${var.dynamo_global_table_enable ? ["us-east-1", "us-west-1"] : []}"
      "attributes" = [
        {
          "name" = "Uri"
          "type" = "S"
        },
        {
          name = "DatesUsed"
          type = "S"
        },
        {
          name = "PnpId"
          type = "S"
        },
      ]
      "global_secondary_indexes" = [
        {
          "name"            = "VanityUrlPnpIdIndex"
          "hash_key"       = "PnpId"
          "read_capacity"   = "96"
          "write_capacity"  = "36"
          "projection_type" = "KEYS_ONLY"
          "non_key_attributes" = []
        },
        {
          "name"               = "VanityUrlDatesUsedIndex"
          "hash_key"           = "DatesUsed"
          "read_capacity"      = "96"
          "write_capacity"     = "36"
          "projection_type"    = "INCLUDE"
          "non_key_attributes" = ["ActualUrl", "FallbackUrl", "StartDateTime", "EndDateTime"]
        },
      ]
    }
 vanityurl_dynamodb_config = {
      "table_name"           = "djcmpnp_vanityurls_ddbtable_${var.environment}"
      "read_capacity_units"  = "96"
      "write_capacity_units" = "36"
      "hash_key"             = "Uri"
      "stream_enabled"       = true
      "global_table_locations" = "${var.dynamo_global_table_enable ? ["us-east-1", "us-west-1"] : []}"
      "attributes" = [
        {
          name = "Uri"
          type = "S"
        },
        {
          name = "DatesUsed"
          type = "S"
        },
        {
          name = "PnpId"
          type = "S"
        },
      ]
      "global_secondary_indexes" = [
        {
          "name"            = "VanityUrlPnpIdIndex"
          "hash_key"        = "PnpId"
          "read_capacity"   = "96"
          "write_capacity"  = "36"
          "projection_type" = "KEYS_ONLY"
          "non_key_attributes" = []
        },
        {
          "name"               = "VanityUrlDatesUsedIndex"
          "hash_key"           = "DatesUsed"
          "read_capacity"      = "96"
          "write_capacity"     = "36"
          "projection_type"    = "INCLUDE"
          "non_key_attributes" = ["ActualUrl", "FallbackUrl", "StartDateTime", "EndDateTime"]
        },
      ]
  }


  default_pnp_shrsvc_security_group_rules = {
    "ingress_rules" = [
      { "protocol" = "ssh", "from_port" = "22", "to_port" = "22", "cidr_blocks" = ["10.0.0.0/8", "172.26.0.0/16"], "self" = false },
      { "protocol" = "https", "from_port" = "8443", "to_port" = "8443", "cidr_blocks" = ["10.0.0.0/8", "172.26.0.0/16"], "self" = false },
      { "protocol" = "tcp", "from_port" = "9010", "to_port" = "9010", "cidr_blocks" = [], "self" = true },
      { "protocol" = "tcp", "from_port" = "9011", "to_port" = "9011", "cidr_blocks" = [], "self" = true },
      { "protocol" = "tcp", "from_port" = "9012", "to_port" = "9012", "cidr_blocks" = [], "self" = true }, //TODO
      { "protocol" = "tcp", "from_port" = "8810", "to_port" = "8810", "cidr_blocks" = [], "self" = true },
      { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35001", "cidr_blocks" = [], "self" = true },
      { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35002", "cidr_blocks" = [], "self" = true }, //TODO
      { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35003", "cidr_blocks" = [], "self" = true }, //TODO
      { "protocol" = "tcp", "from_port" = "8860", "to_port" = "8860", "cidr_blocks" = [], "self" = true },   //TODO

    ]
    "egress_rules" = [
      { "protocol" = "tcp", "from_port" = "2484", "to_port" = "2484", "cidr_blocks" = data.aws_subnet.private_subnets.*.cidr_block, "self" = false },
      { "protocol" = "tcp", "from_port" = "8089", "to_port" = "8089", "cidr_blocks" = [], "self" = false },
      { "protocol" = "tcp", "from_port" = "9010", "to_port" = "9010", "cidr_blocks" = [], "self" = true },
      { "protocol" = "tcp", "from_port" = "9011", "to_port" = "9011", "cidr_blocks" = [], "self" = true },
      { "protocol" = "tcp", "from_port" = "9012", "to_port" = "9012", "cidr_blocks" = [], "self" = true }, //TODO
      { "protocol" = "tcp", "from_port" = "8810", "to_port" = "8810", "cidr_blocks" = [], "self" = true },
      { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35001", "cidr_blocks" = [], "self" = true },
      { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35002", "cidr_blocks" = [], "self" = true }, //TODO
      { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35003", "cidr_blocks" = [], "self" = true }, //TODO
      { "protocol" = "tcp", "from_port" = "8860", "to_port" = "8860", "cidr_blocks" = [], "self" = true },

    ]
  }

  default_stage_cluster_security_group_rules = {
    "ingress_rules" = [
      { "protocol" = "tcp", "from_port" = "9011", "to_port" = "9011", "cidr_blocks" = [], "self" = true, "source_security_group_id" = "" },                                   //TODO
      { "protocol" = "tcp", "from_port" = "8810", "to_port" = "8810", "cidr_blocks" = [], "self" = true, "source_security_group_id" = "" },                                   //TODO
      { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35002", "cidr_blocks" = [], "self" = true, "source_security_group_id" = "" },                                 //TODO
      { "protocol" = "tcp", "from_port" = "8860", "to_port" = "8860", "cidr_blocks" = [], "self" = true, "source_security_group_id" = "" },                                   //TODO
      { "protocol" = "tcp", "from_port" = "8443", "to_port" = "8443", "cidr_blocks" = [], "self" = false, "source_security_group_id" = "${module.alb_sg.security_group_id}" } #${module.alb_sg.security_group_id}
    ]
    "egress_rules" = [
      { "protocol" = "tcp", "from_port" = "9011", "to_port" = "9011", "cidr_blocks" = [], "self" = false, "source_security_group_id" = "" },   //TODO
      { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35002", "cidr_blocks" = [], "self" = false, "source_security_group_id" = "" }, //TODO
    ]
  }


  # default_stage_cluster_security_group_egress_rules = [
  #   { "protocol" = "tcp", "from_port" = "9011", "to_port" = "9011", "cidr_blocks" = [""] },   //TODO
  #   { "protocol" = "tcp", "from_port" = "35002", "to_port" = "35002", "cidr_blocks" = [""] }, //TODO
  # ]

  # default_ca_cluster_security_group_rules = {
  #   "ingress_rules" = [
  #     {protocol = "tcp" from_port = "8810" to_port = "8810" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "8860" to_port = "8860" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "35001" to_port = "35001" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "35002"  to_port = "35002" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "35003"  to_port = "35003" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "8443"  to_port = "8443" source_security_group_id = "${module.alb_sg.security_group_id}" }
  #   ]
  #   "egress_rules" = [
  #     {protocol = "tcp" from_port = "9011" to_port = "9011" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "35002" to_port = "35002" cidr_blocks = [""] }, //TODO
  #   ]
  # }

  # default_calock_cluster_security_group_rules = {
  #   "ingress_rules" = [
  #     {protocol = "tcp" from_port = "9011" to_port = "9011" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "8810" to_port = "8810" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "35002" to_port = "35002" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "8860"  to_port = "8860" cidr_blocks = [""] } //TODO
  #   ]
  #   "egress_rules" = [
  #     {protocol = "tcp" from_port = "9011" to_port = "9011" cidr_blocks = [""] }, //TODO
  #     {protocol = "tcp" from_port = "35002" to_port = "35002" cidr_blocks = [""] }, //TODO
  #   ]
  # }
}
