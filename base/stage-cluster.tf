locals {
  stgsvc_app_service_name = "${replace(module.stgsvc_nomenclature.servicename, "/", "-")}-${module.stgsvc_nomenclature.environment}"
}

data "template_file" "stg_app_userdata" {
  template = "${file("${path.module}/scripts/user_data.sh")}"

  vars = {
    environment             = "${var.environment}"
    efs_file_sytem_dns_name = "${module.efs_storage.file_system_dns_name}"
  }

  # vars {
  #   name                 = "${var.ec2_host_stg_app-name}"
  #   env                  = "${var.env}"
  #   jfrog_user_name      = "${var.jfrog_user_name}"
  #   jfrog_password       = "${var.jfrog_password}"
  #   jfrog_art_base_url   = "${var.jfrog_art_base_url}"
  #   chef_tar_file_uri    = "${var.chef_tar_file_uri}"
  #   secrets_tar_file_uri    = "${var.secrets_tar_file_uri}"
  #   app_instance_name    = "stgsvc1c"
  #   app_cluster_type     = "stg"
  # app_launching_type = "manual"

  #   subnet_zone1         = "${var.subnet_zone1}"
  # }
}

#### Module for tagging and naming conventions
module "stgsvc_nomenclature" {
  source            = "git::https://github.dowjones.net/ent-devops/terraform-nomenclature.git"
  bu                = "${local.businee_unit_name}"
  component         = "stgsvc"
  environment       = "${var.environment}"
  owner             = "${local.business_owner}"
  product           = "pnp"
  terraform_version = "${local.terraform_version}"
  jenkins_job       = "pnp-infra"
  project           = "${local.project_name}"
}

#### Creating ALB for Stage cluster ######################################
module "stg_svc_alb" {
  source                    = "../modules/alb"
  load_balancer_name        = "${local.stgsvc_app_service_name}-alb"
  load_balancer_is_internal = "${lookup(local.stgsvc_cluster, "alb_internal")}"
  subnets                   = "${module.metadata.protected_subnet_ids}"
  security_groups           = "${local.security_groups}"
  vpc_id                    = "${module.metadata.vpc_id}"
}

module "stg_svc_asg" {
  source = "../modules/autoscaling"

  name          = "${local.stgsvc_app_service_name}-asg"
  image_id      = "${local.ami_image_id}"
  instance_type = "${lookup(local.stgsvc_cluster, "instance_type")}"
  iam_instance_profile = "${aws_iam_role.ec2_iam_role.name}"
  # user_data     = "${data.template_file.stg_app_userdata.rendered}"

  security_groups   = local.security_groups
  vpc_subnet_ids    = module.metadata.protected_subnet_ids
  load_balancers    = "${list(module.stg_svc_alb.load_balancer_id)}"
  min_size          = "${lookup(local.stgsvc_cluster, "asg_min_size")}"
  desired_capacity  = "${lookup(local.stgsvc_cluster, "asg_desired_capacity")}"
  max_size          = "${lookup(local.stgsvc_cluster, "asg_max_size")}"
  health_check_type = ""

  tags = module.stgsvc_nomenclature.tags
}

