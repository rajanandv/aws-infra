
variable "security_group_name" {
  type        = "string"
  description = "Security Group Name"
}

variable "vpc_id" {
  type        = "string"
  description = "VPC id need to associate the security group"

}


variable "tags" {
  type = "map"
}

variable "suffix" {
  description = "Used to further differentiate multiple load balancers in same namespace"
  type        = "string"
  default     = ""
}

variable "type" {
  description = ""
  type        = "string"
  default     = "application"
}

variable "public" {
  description = ""
  type        = "string"
  default     = false
}

variable "allow_http" {
  description = ""
  type        = "string"
  default     = false
}

variable "allow_https" {
  description = ""
  type        = "string"
  default     = true
}

variable "public_cidrs" {
  description = ""
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "internal_cidrs" {
  description = ""
  type        = "list"
  default     = ["10.0.0.0/8", "172.26.0.0/16"]
}

variable "certificate_arn" {
  description = ""
  type        = "string"
  default     = ""
}

variable "vpc_tags" {
  description = "Optional tags to use when looking up the VPC"
  type        = "map"
  default     = {}
}

variable "ingress_rules" {
  description = "Ingress rules for specific vpc"
  type        = "list"
  default     = []
}

variable "egress_rules" {
  description = "Ingress rules for specific vpc"
  type        = "list"
  default     = []
}

