variable "location" {
  type = string
  description = "(Required). Location."
}

variable "prefix" {
  type = string
  description = "The prefix. Required when resource_group_name is not set"
  default = null
}

variable "resource_group_name" {
  description = "Resource group name. Required when prefix is not set"
  type = string
  default = null
}

variable "key_vault_name" {
  description = "KeyVault name. Required when prefix is not set"
  type = string
  default = null
}

variable "tags" {
  type = map(string)
  description = "(Optional). A map of key value pairs to tag resources"
}
