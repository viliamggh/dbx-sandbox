# Variables for Databricks workspace deployment
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "francecentral"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "uc-vg"
}

variable "project_name_nodash" {
  description = "Project name without dashes for storage account naming"
  type        = string
  default     = "ucvg"
}

variable "databricks_sku" {
  description = "Databricks workspace SKU"
  type        = string
  default     = "premium"
  validation {
    condition     = contains(["standard", "premium", "trial"], var.databricks_sku)
    error_message = "The databricks_sku must be one of: standard, premium, trial."
  }
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_address_prefix" {
  description = "Address prefix for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_address_prefix" {
  description = "Address prefix for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_network_access_enabled" {
  description = "Allow public access for accessing workspace"
  type        = bool
  default     = true
}

variable "no_public_ip" {
  description = "Are public IP Addresses not allowed for clusters"
  type        = bool
  default     = false
}
