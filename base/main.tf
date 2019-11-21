data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ami" "current" {
  # executable_users = ["self"]  
  most_recent = true

  # name_regex       = "^djis-${local.aws_account_type}-pnp-app-01-\\d{8}[.]\\d{2}"
  owners = ["063491364108"]

  # filter {
  #   name   = "name"
  #   values = ["djis-${local.aws_account_type}-pnp-app-01-*"]
  # }

  # filter {
  #   name   = "root-device-type"
  #   values = ["ebs"]
  # }
  # filter {
  #   name   = "virtualization-type"
  #   values = ["hvm"]
  # }
  tags = {
    Name = "test-private"
  }
}

###### Module for fetching Network configuration #############################################
module "metadata" {
  # source = "git::https://github.dowjones.net/ent-devops/terraform-metadata.git"
  source = "../modules/metadata"
}

data "aws_subnet" "private_subnets" {
  count = "${length(local.private_subnet_ids_list)}"
  id    = "${element(local.private_subnet_ids_list, count.index)}"
}
###### Module for creating tagging and naming standards for the application ##################
module "pnpapp_nomenclature" {
  source            = "git::https://github.dowjones.net/ent-devops/terraform-nomenclature.git"
  bu                = "${local.businee_unit_name}"
  component         = "sharsvc"
  environment       = "${var.environment}"
  owner             = "${local.business_owner}"
  product           = "pnp"
  terraform_version = "${local.terraform_version}"
  jenkins_job       = "pnp-infra"
  project           = "${local.project_name}"
}

###### ALB generic security group ############################################################

module "alb_sg" {
  source              = "../modules/security-group"
  public              = true
  allow_https         = true
  security_group_name = "${local.shrsvc_app_service_name}-alb-sg"
  vpc_id              = "${module.metadata.vpc_id}"
  tags                = module.pnpapp_nomenclature.tags
}

resource "aws_security_group_rule" "internal_egress_https_port" {
  security_group_id        = "${module.alb_sg.security_group_id}"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = "8443"
  to_port                  = "8443"
  source_security_group_id = "${module.default_shrsvc_sg.security_group_id}"
}

module "default_shrsvc_sg" {
  source              = "../modules/security-group"
  security_group_name = "${local.shrsvc_app_service_name}-sg"
  vpc_id              = "${module.metadata.vpc_id}"
  ingress_rules       = "${concat(lookup(local.default_pnp_shrsvc_security_group_rules, "ingress_rules", []), var.shrsvc_ingress_rules)}"
  egress_rules        = "${concat(lookup(local.default_pnp_shrsvc_security_group_rules, "egress_rules", []), var.shrsvc_egress_rules)}"
  tags                = module.pnpapp_nomenclature.tags
}

resource "aws_security_group_rule" "internal_ingress_https_port" {
  security_group_id        = "${module.default_shrsvc_sg.security_group_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "8443"
  to_port                  = "8443"
  source_security_group_id = "${module.alb_sg.security_group_id}"
}

###### Creating EFS Storage ##################################################################
module "efs_storage" {
  source             = "../modules/efs"
  subnets            = module.metadata.protected_subnet_ids
  vpc_id             = "${module.metadata.vpc_id}"
  name               = "${module.pnpapp_nomenclature.servicename}"
  security_group_ids = local.security_groups
  tags               = module.pnpapp_nomenclature.tags
}

###### Creating DynamoDb resources ##########################################################
module "shopurl_dynamodb" {
  source               = "../modules/dynamodb"
  table_name = "${lookup(local.shopurl_dynamodb_config, "table_name")}"
  hash_key = "${lookup(local.shopurl_dynamodb_config, "hash_key")}"
  stream_enabled = "${lookup(local.shopurl_dynamodb_config, "stream_enabled")}"
  # global_table_locations = lookup(local.shopurl_dynamodb_config, "global_table_locations")
  attributes = "${lookup(local.shopurl_dynamodb_config, "attributes")}"
  global_secondary_indexes = lookup(local.shopurl_dynamodb_config, "global_secondary_indexes")

  # tags                 = module.pnpapp_nomenclature.tags
}

module "shopurl_dynamodb_blue" {
  source               = "../modules/dynamodb"
  enable               = "${var.enable_blue_environment}"
  table_name = "${lookup(local.shopurl_dynamodb_config, "table_name")}"
  table_name_suffix    = "${var.enable_blue_environment ? "-blue" : ""}"
  hash_key = "${lookup(local.shopurl_dynamodb_config, "hash_key")}"
  stream_enabled = "${lookup(local.shopurl_dynamodb_config, "stream_enabled")}"
  # global_table_locations = lookup(local.shopurl_dynamodb_config, "global_table_locations")
  attributes = "${lookup(local.shopurl_dynamodb_config, "attributes")}"
  global_secondary_indexes = lookup(local.shopurl_dynamodb_config, "global_secondary_indexes")
  # tags                 = module.pnpapp_nomenclature.tags
}

# module "vanityurl_dynamodb" {
#   source               = "../modules/dynamodb"
#   table_name = "${lookup(local.vanityurl_dynamodb_config, "table_name")}"
#   hash_key = "${lookup(local.vanityurl_dynamodb_config, "hash_key")}"
#   stream_enabled = "${lookup(local.vanityurl_dynamodb_config, "stream_enabled")}"
#   global_table_locations = lookup(local.vanityurl_dynamodb_config, "global_table_locations")
#   attributes = "${lookup(local.vanityurl_dynamodb_config, "attributes")}"
#   global_secondary_indexes = lookup(local.vanityurl_dynamodb_config, "global_secondary_indexes")

#   # tags                 = module.pnpapp_nomenclature.tags
# }

# module "vanityurl_dynamodb_blue" {
#   source               = "../modules/dynamodb"
#   enable               = "${var.enable_blue_environment}"
#   table_name = "${lookup(local.vanityurl_dynamodb_config, "table_name")}"
#   table_name_suffix    = "${var.enable_blue_environment ? "-blue" : ""}"
#   hash_key = "${lookup(local.vanityurl_dynamodb_config, "hash_key")}"
#   stream_enabled = "${lookup(local.vanityurl_dynamodb_config, "stream_enabled")}"
#   global_table_locations = lookup(local.vanityurl_dynamodb_config, "global_table_locations")
#   attributes = "${lookup(local.vanityurl_dynamodb_config, "attributes")}"
#   global_secondary_indexes = lookup(local.vanityurl_dynamodb_config, "global_secondary_indexes")
#   # tags                 = module.pnpapp_nomenclature.tags
# }

###### Create Lambda resources #############################################################

data "archive_file" "deploy_shopurlcfcacheinv" {
  type        = "zip"
  source_dir  = "${path.module}/functions/build/cfcacheinv/"
  output_path = "${path.module}/functions/output/djcmpnp_shopurlcfcacheinv_function.zip"
  # depends_on = [ "null_resource.build_shopurlcfcacheinv" ]
}

module "lambda_cache_invalidator" {
  source  = "../modules/lambda"
  name    = "${lookup(local.lambda_cache_inv_config, "lambda_function_name")}_${var.environment}"
  description = "Shop and Vanity cache invalidator lambda"
  handler = "${lookup(local.lambda_cache_inv_config, "lambda_function_name")}.invalidate_cache"
  timeout = "${lookup(local.lambda_cache_inv_config, "timeout")}"
  publish = "${lookup(local.lambda_cache_inv_config, "deploy_lambda")}"
  package_path = "${lookup(local.lambda_cache_inv_config, "package_path")}"
  # execute_program_path = "${lookup(local.lambda_cache_inv_config, "")}"
  # path = "${lookup(local.lambda_cache_inv_config, "package_path")}"
  package_hash = "${data.archive_file.deploy_shopurlcfcacheinv.output_base64sha256}"
  tags = module.pnpapp_nomenclature.tags
}

module "lambda_cache_invalidator_blue" {
  source  = "../modules/lambda"
  enable  = "${var.enable_blue_environment}"
  name    = "${lookup(local.lambda_cache_inv_config, "lambda_function_name")}_${var.environment}"
  lambda_name_suffix    = "${var.enable_blue_environment ? "-blue" : ""}"
  description = "Shop and Vanity cache invalidator lambda"
  handler = "${lookup(local.lambda_cache_inv_config, "lambda_function_name")}.invalidate_cache"
  timeout = "${lookup(local.lambda_cache_inv_config, "timeout")}"
  publish = "${lookup(local.lambda_cache_inv_config, "deploy_lambda")}"
  package_path = "${lookup(local.lambda_cache_inv_config, "package_path")}"

  # execute_program_path = "${lookup(local.lambda_cache_inv_config, "")}"
  # path = "${lookup(local.lambda_cache_inv_config, "package_path")}"
  package_hash = "${data.archive_file.deploy_shopurlcfcacheinv.output_base64sha256}"
  tags = module.pnpapp_nomenclature.tags
}

