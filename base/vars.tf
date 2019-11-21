variable "environment" {
  description = "The name of the current environment"
  type        = "string"
  default     = "devint1"
}

variable "stack" {
  description = "The number of the current stack"
  type        = "string"
  default     = "01"
}

variable "account" {
  description = "The name of the current AWS account"
  type        = "string"
  default     = "dev"
}

variable "region" {
  description = "The number of the current AWS region"
  type        = "string"
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI id for ec2 instance"
  type        = "string"
  default     = ""
}

variable "ca_ec2_instance_type" {
  description = "CA cluster EC2 instance type"
  type        = "string"
  default     = ""
}

variable "calock_ec2_instance_type" {
  description = "CALOCK cluster EC2 insrtance type"
  type        = "string"
  default     = ""
}

variable "prdsvc_ec2_instance_type" {
  description = "PRDSVC cluster EC2 instance type"
  type        = "string"
  default     = ""
}

variable "prdlock_ec2_instance_type" {
  description = "PRDLOCK cluster EC2 instance type"
  type        = "string"
  default     = ""
}

variable "prdaux_ec2_instance_type" {
  description = "PRDAUX cluster EC2 instance type"
  type        = "string"
  default     = ""
}

variable "stgsvc_ec2_instance_type" {
  description = "STGSVC cluster EC2 instance type"
  type        = "string"
  default     = ""
}

variable "security_groups" {
  type        = "list"
  description = "EFS securiry group"
  default     = []
}

variable "enable_blue_environment" {
  description = "Enable blue Environment"
  default     = true
}

variable "lambda_cache_inv_enable_blue_environment" {
  default     = true
  description = "Lambda Cache invalidator enabled for blue environment"
}

variable "additional_security_group_ids" {
  type        = "list"
  description = "Provide if any additional security groups need to be linked to pnp clusters"
  default     = []
}

variable "shrsvc_ingress_rules" {
  type        = "list"
  default     = []
  description = "Shared service ingress rules"
}

variable "shrsvc_egress_rules" {
  type        = "list"
  default     = []
  description = "Shared service ingress rules"
}

variable "cloudfronts_aws_account_map" {
  type = "map"
  description = "AWS Account number for where cloudfronts were hosted"
  default = {
    "devint1" = "510639184942"
    "qa1" = "510639184942"
    "uat" = "510639184942"
    "prod" = "659901582907"
  }
}

variable "dynamo_global_table_enable" {
  type = "string"
  description = "Dynamo global table enable/disable"
  default = true
}

