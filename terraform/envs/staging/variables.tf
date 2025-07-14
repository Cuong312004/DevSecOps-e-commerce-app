variable "location" {
  default = "eastasia"
}

variable "resource_group_name" {
  default = "rg-staging"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "admin_username" {}
variable "admin_password" {}

variable "public_key_path" {
  type = string
}
