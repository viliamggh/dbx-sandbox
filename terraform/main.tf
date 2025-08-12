# Configure Terraform
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    databricks = {
    source  = "databricks/databricks"
    version = "~> 1.0"
  }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  backend "azurerm" {
    resource_group_name  = "uc-vg-rg"
    storage_account_name = "ucvgst"
    container_name      = "terraform-state"
    key                 = "databricks.tfstate"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "59ded65e-7c57-44bb-b9b1-83d8b7fa1c32"
}
