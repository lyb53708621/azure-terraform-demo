variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type = map(string)
}

# VNET Variable
variable "address_space" {
  type        = list(string)
  description = "VNet address space"
}

variable "address_prefixes_1" {
  type        = list(string)
  description = "address space for subnet 1"
}

variable "address_prefixes_2" {
  type        = list(string)
  description = "address space for subnet 2"
}

# MySQL Variables
variable "mysql_admin" {
  type    = string
  default = "sqladmin"
}

variable "mysql_pwd" {
  type    = string
  default = "Testceph123!"
}

variable "mysql_version" {
  type    = string
  default = "8.0.21"
}

variable "mysql_sku_name" {
  type    = string
  default = "GP_Standard_D2ads_v5"
}

variable "mysql_storage_size_gb" {
  type    = number
  default = 80
}

variable "mysql_backup_retention_days" {
  type    = number
  default = 7
}
