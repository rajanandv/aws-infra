variable "domains" {
  type        = "map"
  description = "A map {\"wsj.com.\" = [\"wsj.com\",\"store.zone.com\"],\"barrons.com\" = [\"store.barrons.com\"] } of domains."
}

variable "alias_hosted_zone_id" {
  description = "The hosted_zone_id to alias"
}

variable "alias_domain_name" {
  description = "The domain_name on the hosted_zone_id to alias"
}

variable "record_types" {
  type        = "list"
  description = "The types of records to set. Default is A and CNAME"

  default = [
    "A",
    "CNAME"
  ]
}