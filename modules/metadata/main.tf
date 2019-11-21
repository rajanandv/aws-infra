data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "current" {
  #   tags = "${var.vpc_tags}" TODO :: need to set the tags for vpc
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.current.id}"

  tags = {
    tier = "private"
  }
}

data "aws_subnet_ids" "protected" {
  vpc_id = "${data.aws_vpc.current.id}"

  tags = {
    tier = "protected"
  }

}

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.current.id}"

  tags = {
    tier = "public"
  }
}

# locals {
#   private_subnet_ids_string = join(",", data.aws_subnet_ids.private_subnet_ids.ids)
#   private_subnet_ids_list   = split(",", local.private_subnet_ids_string)

#   protected_subnet_ids_string = join(",", data.aws_subnet_ids.protected_subnet_ids.ids)
#   protected_subnet_ids_list   = split(",", local.subnet_ids_string)

#   public_subnet_ids_string = join(",", data.aws_subnet_ids.public_subnet_ids.ids)
#   public_subnet_ids_list   = split(",", local.subnet_ids_string)
# }

# data "aws_subnet" "public_subnets" {
#   vpc_id = "${data.aws_vpc.current.id}"

#   tags = {
#     tier = "public"
#   }
# }

# data "aws_subnet" "protected_subnets" {
#   vpc_id = "${data.aws_vpc.current.id}"

#   tags = {
#     tier = "protected"
#   }
# }

# data "aws_subnet" "private_subnets" {
#   vpc_id = "${data.aws_vpc.current.id}"

#   tags = {
#     tier = "private"
#   }
# }

