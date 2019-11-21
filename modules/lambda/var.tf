variable "execute_program_path" {
  description = "Provide path for packing program name"
  type        = "string"
  default = ""
}

variable "include_paths" {
  type        = "list"
  description = "Additional files and directories which should be part of of the package .zip file within the local filesystem."
  default     = []
}

variable "output_path" {
  default     = ""
  description = "The path of the package .zip file within the local filesystem."
}

variable "name" {
  description = "Name to be used on all the resources as identifier."
}

variable "description" {
  default     = ""
  description = "Description of what your Lambda Function does."
}

variable "handler" {
  description = "The function entrypoint in your code. "
}

variable "runtime" {
  description = "The function runtime to use. (nodejs, nodejs4.3, nodejs6.10, nodejs8.10, java8, python2.7, python3.6, dotnetcore1.0, dotnetcore2.0, dotnetcore2.1, nodejs4.3-edge, go1.x)"
  default     = "nodejs8.10"
}

variable "role" {
  default     = ""
  description = "This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details."
}

variable "role_name" {
  default     = ""
  description = "The name of the IAM role which will be created for the Lambda Function."
}

variable "policy" {
  default     = ""
  description = "IAM policy attached to the Lambda Function role."
}

variable "policy_arn" {
  default     = ""
  description = "IAM policy ARN attached to the Lambda Function role."
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "A mapping of tags to assign to the object."
}

variable "package_path" {
  description = "The path to the function's deployment package within the local filesystem."
}

variable "package_hash" {
  default     = ""
  description = "Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename."
}

variable "lambda_name_suffix" {
  default     = ""
  type        = "string"
  description = "Table name suffix for certain scenarion like blue"
}

variable "timeout" {
  description = "Lambda timeout"
  default     = 3
}

variable "enable" {
  default     = true
  description = "Lambda creation enable or disable"
}

variable "publish" {
  default     = false
  description = "Lambda deployment enable or disable"
}
