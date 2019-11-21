variable "enabled" {
  description = "Is enable for EFS resrource creation"
  default     = true
}

variable "subnets" {
  type        = "list"
  description = "Subnet ids for the efs mount targets"
  default     = []
}

variable "security_group_ids" {
  type        = "list"
  description = "Security group ids for alloing the connectivity for EFS"

  # default     = []
}

variable "encrypted" {
  description = "Whether efs is encrypted or not"
  default     = false
}

variable "kms_key_id" {
  type        = "string"
  description = "KMS key id for the encrypting the data"
  default     = ""
}

variable "performance_mode" {
  description = "EFS performance mode generalPurpose or maxIO"
  type        = "string"
  default     = "generalPurpose"
}

variable "vpc_id" {
  type        = "string"
  description = "VPC ID need to provide for EFS"
}

variable "tags" {
  description = "Tags for EFS resource"
  type        = "map"
}

variable "ingress_cidr" {
  description = "Ingress CIDR block range"
  default     = []
}

variable "name" {
  type        = "string"
  description = "efs resource name"
}
