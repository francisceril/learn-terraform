provider "azurerm" {
  features {
  }
}

# Create resource group
resource "azurerm_resource_group" "capstone-rg" {
  location = "West Europe"
  name     = "tf-capstone-rg"

  tags = {
    "environment" = "dev"
  }
}

# vnet
resource "azurerm_virtual_network" "capstone-vnet" {
  address_space       = ["10.100.0.0/16"]
  location            = azurerm_resource_group.capstone-rg.location
  name                = "tf-capstone-vnet"
  resource_group_name = azurerm_resource_group.capstone-rg.name

  tags = {
    "envinronment" = "dev"
  }
}

# subnet for apps
resource "azurerm_subnet" "capstone-subnet-apps" {
  address_prefixes     = ["10.100.1.0/24"]
  name                 = "tf-capstone-subnet-apps"
  resource_group_name  = azurerm_resource_group.capstone-rg.name
  virtual_network_name = azurerm_virtual_network.capstone-vnet.name
}

# subnet for databases
resource "azurerm_subnet" "capstone-subnet-databases" {
  address_prefixes     = ["10.100.2.0/24"]
  name                 = "tf-capstone-subnet-databases"
  resource_group_name  = azurerm_resource_group.capstone-rg.name
  virtual_network_name = azurerm_virtual_network.capstone-vnet.name
}
