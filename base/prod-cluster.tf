locals {
  prdsvc_service_name  = "${replace(module.prdsvc_nomenclature.servicename, "/", "-")}-${module.prdsvc_nomenclature.environment}"
  prdaux_service_name  = "${replace(module.prdaux_nomenclature.servicename, "/", "-")}-${module.prdaux_nomenclature.environment}"
  prdlock_service_name = "${replace(module.prdlock_nomenclature.servicename, "/", "-")}-${module.prdlock_nomenclature.environment}"
}

module "prdsvc_nomenclature" {
  source            = "git::https://github.dowjones.net/ent-devops/terraform-nomenclature.git"
  bu                = "${local.businee_unit_name}"
  component         = "prdsvc"
  environment       = "${var.environment}"
  owner             = "${local.business_owner}"
  product           = "pnp"
  terraform_version = "${local.terraform_version}"
  jenkins_job       = "pnp-infra"
  project           = "${local.project_name}"
}

module "prdaux_nomenclature" {
  source            = "git::https://github.dowjones.net/ent-devops/terraform-nomenclature.git"
  bu                = "${local.businee_unit_name}"
  component         = "prdaux"
  environment       = "${var.environment}"
  owner             = "${local.business_owner}"
  product           = "pnp"
  terraform_version = "${local.terraform_version}"
  jenkins_job       = "pnp-infra"
  project           = "${local.project_name}"
}

module "prdlock_nomenclature" {
  source            = "git::https://github.dowjones.net/ent-devops/terraform-nomenclature.git"
  bu                = "${local.businee_unit_name}"
  component         = "prdlock"
  environment       = "${var.environment}"
  owner             = "${local.business_owner}"
  product           = "pnp"
  terraform_version = "${local.terraform_version}"
  jenkins_job       = "pnp-infra"
  project           = "${local.project_name}"
}

#######################
##  Prod Service ALB ##
#######################
module "prd_svc_alb" {
  source                    = "../modules/alb"
  load_balancer_name        = "${local.prdsvc_service_name}-alb"
  load_balancer_is_internal = "${lookup(local.prdsvc_cluster, "alb_internal")}"
  subnets                   = "${module.metadata.protected_subnet_ids}"
  security_groups           = "${list("", "")}"
  vpc_id                    = "${module.metadata.vpc_id}"
}

################################
##  Prod Service autoscaling  ##
################################
module "prd_svc_asg" {
  source = "../modules/autoscaling"

  name              = "${local.prdsvc_service_name}-asg"
  image_id          = "${local.ami_image_id}"
  instance_type     = "${lookup(local.prdsvc_cluster, "instance_type")}"
  security_groups   = local.security_groups
  vpc_subnet_ids    = module.metadata.protected_subnet_ids
  load_balancers    = "${list(module.prd_svc_alb.load_balancer_id)}"
  min_size          = "${lookup(local.prdsvc_cluster, "asg_min_size")}"
  desired_capacity  = "${lookup(local.prdsvc_cluster, "asg_desired_capacity")}"
  max_size          = "${lookup(local.prdsvc_cluster, "asg_max_size")}"
  health_check_type = ""

  tags = module.prdsvc_nomenclature.tags
}

####################################
##  Prod aux server autoscaling  ##
####################################
module "prd_aux_asg" {
  source            = "../modules/autoscaling"
  name              = "${local.prdaux_service_name}-asg"
  image_id          = "${local.ami_image_id}"
  instance_type     = "${lookup(local.prdaux_cluster, "instance_type")}"
  security_groups   = local.security_groups
  vpc_subnet_ids    = module.metadata.protected_subnet_ids
  min_size          = "${lookup(local.prdaux_cluster, "asg_min_size")}"
  desired_capacity  = "${lookup(local.prdaux_cluster, "asg_desired_capacity")}"
  max_size          = "${lookup(local.prdaux_cluster, "asg_max_size")}"
  health_check_type = ""
  tags              = module.prdaux_nomenclature.tags
}

####################################
##  Prod lock server autoscaling  ##
####################################
module "prd_lock_asg" {
  source           = "../modules/autoscaling"
  name             = "${local.prdlock_service_name}-asg"
  image_id         = "${local.ami_image_id}"
  instance_type    = "${lookup(local.prdlock_cluster, "instance_type")}"
  security_groups  = local.security_groups
  vpc_subnet_ids   = module.metadata.protected_subnet_ids
  min_size         = "${lookup(local.prdlock_cluster, "asg_min_size")}"
  desired_capacity = "${lookup(local.prdlock_cluster, "asg_desired_capacity")}"
  max_size         = "${lookup(local.prdlock_cluster, "asg_max_size")}"

  health_check_type = ""

  tags = module.prdlock_nomenclature.tags
}
