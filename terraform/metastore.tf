# Configure Databricks Provider for Account Level
provider "databricks" {
  alias = "accounts"
  host  = "https://accounts.azuredatabricks.net"
  account_id = "92a38d09-b2d1-429f-a34f-6b396c96fcea"
  # Use Azure CLI authentication or set environment variables:
  # DATABRICKS_HOST and DATABRICKS_TOKEN
}

# Data source to get current Azure client configuration
data "azurerm_client_config" "current" {}

# Local variables for naming and configuration


# Resource Group for all Unity Catalog resources
resource "azurerm_resource_group" "unity_catalog" {
  name     = "${var.project_name}-metastore-rg"
  location = var.location
}

# Storage Account for Unity Catalog Metastore
resource "azurerm_storage_account" "unity_catalog" {
  name                     = "${replace(var.project_name_nodash, "-", "")}catalogst"
  resource_group_name      = azurerm_resource_group.unity_catalog.name
  location                 = azurerm_resource_group.unity_catalog.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled          = true  # Required for Unity Catalog
  
}

# Storage Container for Unity Catalog
resource "azurerm_storage_container" "unity_catalog" {
  name                  = "unity-catalog"
  storage_account_id    = azurerm_storage_account.unity_catalog.id
  container_access_type = "private"
}


#Unity Catalog Metastore
resource "databricks_metastore" "unity_catalog" {
  provider = databricks.accounts
  
  name         = "${var.project_name_nodash}-metastore"
  region       = var.location
  storage_root = "abfss://${azurerm_storage_container.unity_catalog.name}@${azurerm_storage_account.unity_catalog.name}.dfs.core.windows.net/"
  owner        = "viliam.gago@bighub.cz"
  
}