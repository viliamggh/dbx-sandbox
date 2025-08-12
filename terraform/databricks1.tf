
# Data sources for existing resources

locals {
    num = "1"
}

resource azurerm_resource_group "main1" {
    name = "${var.project_name}-rg${local.num}"
    location = var.location
}


# Virtual Network for Databricks workspace injection
resource "azurerm_virtual_network" "databricks" {
  name                = "${var.project_name}-databricks-vnet"
  address_space       = var.vnet_address_space
  location           = azurerm_resource_group.main1.location
  resource_group_name = azurerm_resource_group.main1.name
}

# Public subnet for Databricks workers
resource "azurerm_subnet" "databricks_public" {
  name                 = "${var.project_name}-databricks-public-subnet"
  resource_group_name  = azurerm_resource_group.main1.name
  virtual_network_name = azurerm_virtual_network.databricks.name
  address_prefixes     = [var.public_subnet_address_prefix]

  # Databricks requires subnet delegation
  delegation {
    name = "databricks-delegation"
    
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", 
                 "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
                 "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

# Private subnet for Databricks workers
resource "azurerm_subnet" "databricks_private" {
  name                 = "${var.project_name}-databricks-private-subnet"
  resource_group_name  = azurerm_resource_group.main1.name
  virtual_network_name = azurerm_virtual_network.databricks.name
  address_prefixes     = [var.private_subnet_address_prefix]

  # Databricks requires subnet delegation
  delegation {
    name = "databricks-delegation"
    
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", 
                 "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
                 "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

# Network Security Group for public subnet
resource "azurerm_network_security_group" "databricks_public" {
  name                = "${var.project_name}-databricks-public-nsg"
  location           = azurerm_resource_group.main1.location
  resource_group_name = azurerm_resource_group.main1.name

}

# Network Security Group for private subnet
resource "azurerm_network_security_group" "databricks_private" {
  name                = "${var.project_name}-databricks-private-nsg"
  location           = azurerm_resource_group.main1.location
  resource_group_name = azurerm_resource_group.main1.name

}

# Associate NSG with public subnet
resource "azurerm_subnet_network_security_group_association" "databricks_public" {
  subnet_id                 = azurerm_subnet.databricks_public.id
  network_security_group_id = azurerm_network_security_group.databricks_public.id
}

# Associate NSG with private subnet
resource "azurerm_subnet_network_security_group_association" "databricks_private" {
  subnet_id                 = azurerm_subnet.databricks_private.id
  network_security_group_id = azurerm_network_security_group.databricks_private.id
}


# Databricks Workspace with VNet injection
resource "azurerm_databricks_workspace" "main" {
  name                         = "${var.project_name}-databricks"
  resource_group_name          = azurerm_resource_group.main1.name
  location                    = azurerm_resource_group.main1.location
  sku                         = var.databricks_sku
  managed_resource_group_name = "${var.project_name}-databricks-managed-rg"
  
  # Enable public network access
  public_network_access_enabled = var.public_network_access_enabled
  
  # Custom parameters for VNet injection
  custom_parameters {
    virtual_network_id                                   = azurerm_virtual_network.databricks.id
    public_subnet_name                                  = azurerm_subnet.databricks_public.name
    private_subnet_name                                 = azurerm_subnet.databricks_private.name
    public_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.databricks_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.databricks_private.id
    
    # Configure whether public IPs are allowed for cluster nodes
    no_public_ip = var.no_public_ip
    
    # Optional: Custom storage account name (if not specified, Azure will generate one)
    storage_account_name = "${var.project_name_nodash}dbxstorage"
    storage_account_sku_name = "Standard_LRS"
  }


  # Ensure NSG associations are created before the workspace
  depends_on = [
    azurerm_subnet_network_security_group_association.databricks_public,
    azurerm_subnet_network_security_group_association.databricks_private
  ]
}
