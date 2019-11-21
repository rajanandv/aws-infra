
variable "enable" {
  description = "Enable the creatig the dynamo db resource"
  default     = true
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput and how you manage capacity"
  default = "PROVISIONED"
}


variable "global_table_locations" {
  type = "list"
  description = "Region ids where global tables need to be created"
  default = []
}

variable "table_name" {
  type = "string"
  description = "DynamoDB table name"
}


variable "table_name_suffix" {
  type        = "string"
  description = "DynamoDb Table name suffix"
  default     = ""
}

variable "read_capacity_units" {
  description = "DynamoDb table read capacity units"
  default = 1
}

variable "write_capacity_units" {
  description = "DynamoDb table write capacity units"
  default = 1
}

variable "hash_key" {
  type = "string"
  description = "Primary hash key for dynamodb table"
}

variable "stream_enabled" {
  description = "Stream is enable/disabled"
  default = false
}

variable "attributes" {
  type = "list"
  description = "Attributes list of objects for indexing columns with column name and type. ex:- name='emp_id' and type=S/N/B"
  default = []
}

variable "global_secondary_indexes" {
  type = "list"
  description = "Global secondary indexes objects as a list of map"
  # default = []
}

variable "local_secondary_indexes" {
  type = "list"
  description = "Global secondary indexes objects as a map"
  default = []
}

variable "ttl_enable" {
  description = "Time to live enable/disable"
  default = false
}

variable "ttl_attribute_name" {
  description = "Time to live attribute name"
  default = ""
}

variable "server_side_encryption_enable" {
  description = "Server side encryption enable/disbale"
  default = false
}

variable "stream_view_type" {
  type = "string"
  description = "DynamoDb stream type should be either KEYS_ONLY,NEW_IMAGE, OLD_IMAGE or NEW_AND_OLD_IMAGES."
  default = ""
}


variable "tags" {
  type        = "list"
  default     = []
  description = "List of tags objects."
}
