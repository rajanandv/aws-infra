locals {
  ca_app_service_name  = "${replace(module.ca_nomenclature.servicename, "/", "-")}-${module.ca_nomenclature.environment}"
  ca_lock_service_name = "${replace(module.calock_nomenclature.servicename, "/", "-")}-${module.calock_nomenclature.environment}"
}

module "ca_nomenclature" {
  source            = "git::https://github.dowjones.net/ent-devops/terraform-nomenclature.git"
  bu                = "${local.businee_unit_name}"
  component         = "caweb"
  environment       = "${var.environment}"
  owner             = "${local.business_owner}"
  product           = "pnp"
  terraform_version = "${local.terraform_version}"
  jenkins_job       = "pnp-infra"
  project           = "${local.project_name}"
}

module "calock_nomenclature" {
  source            = "git::https://github.dowjones.net/ent-devops/terraform-nomenclature.git"
  bu                = "${local.businee_unit_name}"
  component         = "calock"
  environment       = "${var.environment}"
  owner             = "${local.business_owner}"
  product           = "pnp"
  terraform_version = "${local.terraform_version}"
  jenkins_job       = "pnp-infra"
  project           = "${local.project_name}"
}

####################################
##  CA WEB ALB                    ##
####################################
module "ca_web_alb" {
  source                    = "../modules/alb"
  load_balancer_name        = "pnp-ca-web-alb"
  load_balancer_is_internal = "${lookup(local.ca_cluster, "alb_internal")}"
  subnets                   = "${module.metadata.protected_subnet_ids}"
  security_groups           = ["${module.alb_sg.security_group_id}"]
  vpc_id                    = "${module.metadata.vpc_id}"
}

####################################
##  CA SVC ALB                    ##
####################################
module "ca_svc_alb" {
  source                    = "../modules/alb"
  load_balancer_name        = "pnp-ca-svc-alb"
  load_balancer_is_internal = "${lookup(local.ca_cluster, "alb_internal")}"
  subnets                   = "${module.metadata.protected_subnet_ids}"
  security_groups           = ["${module.alb_sg.security_group_id}"]
  vpc_id                    = "${module.metadata.vpc_id}"
}

## CA ASG 
data "template_file" "ca_asg_userdata" {
  template = "${file("${path.module}/scripts/user_data.sh")}"

  vars = {
    environment             = "${var.environment}"
    efs_file_sytem_dns_name = "${module.efs_storage.file_system_dns_name}"
  }

  # vars {
  #   #   name                 = "${var.ec2_host_ps_app-name}"
  #   #   env                  = "${var.env}"
  #   #   jfrog_user_name      = "${var.jfrog_user_name}"
  #   #   jfrog_password       = "${var.jfrog_password}"
  #   #   jfrog_art_base_url   = "${var.jfrog_art_base_url}"
  #   #   chef_tar_file_uri    = "${var.chef_tar_file_uri}"
  #   #   secrets_tar_file_uri = "${var.secrets_tar_file_uri}"
  #   #   app_instance_name    = "ca"
  #   #   app_cluster_type     = "ca"
  #   #   count                = "${var.count}"
  #   app_launching_type = "auto"

  #   #   subnet_zone1         = "${var.subnet_zone1}"
  # }
}

####################################
##  CA server autoscaling         ##
####################################
module "ca_asg" {
  source            = "../modules/autoscaling"
  name              = "${local.ca_app_service_name}"
  image_id          = "${local.ami_image_id}"
  instance_type     = "${lookup(local.ca_cluster, "instance_type")}"
  security_groups   = local.security_groups
  user_data         = "${data.template_file.ca_asg_userdata.rendered}"
  vpc_subnet_ids    = module.metadata.protected_subnet_ids
  load_balancers    = "${list(module.ca_web_alb.load_balancer_id, module.ca_svc_alb.load_balancer_id)}"
  min_size          = "${lookup(local.ca_cluster, "asg_min_size")}"
  desired_capacity  = "${lookup(local.ca_cluster, "asg_desired_capacity")}"
  max_size          = "${lookup(local.ca_cluster, "asg_max_size")}"
  health_check_type = ""

  tags = module.ca_nomenclature.tags
}

####################################
##  Prod lock server autoscaling  ##
####################################
module "ca_lock_asg" {
  source            = "../modules/autoscaling"
  name              = "${local.ca_lock_service_name}"
  image_id          = "${local.ami_image_id}"
  instance_type     = "${lookup(local.calock_cluster, "instance_type")}"
  security_groups   = local.security_groups
  vpc_subnet_ids    = module.metadata.protected_subnet_ids
  min_size          = "${lookup(local.calock_cluster, "asg_min_size")}"
  desired_capacity  = "${lookup(local.calock_cluster, "asg_desired_capacity")}"
  max_size          = "${lookup(local.calock_cluster, "asg_max_size")}"
  health_check_type = ""

  tags = module.calock_nomenclature.tags
}
