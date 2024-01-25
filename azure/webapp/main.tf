terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}

# Configure the Microsoft Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "tf-webapp-rg" {
  name     = "tf-webapp-rg"
  location = "West Europe"

  tags = {
    environment = "dev"
  }
}

# Generate a random integer to create a globally unique name
resource "random_integer" "tf_randomint" {
  min = 10000
  max = 99999
}

# Create service plan
resource "azurerm_service_plan" "tf-webapp-serviceplan" {
  name                = "tf-webapp-serviceplan-${random_integer.tf_randomint.result}"
  location            = azurerm_resource_group.tf-webapp-rg.location
  resource_group_name = azurerm_resource_group.tf-webapp-rg.name
  os_type             = "Linux"
  sku_name            = "F1"
}

# Create the app
resource "azurerm_linux_web_app" "tf-webapp-linux" {
  name                = "tf-webapp-${random_integer.tf_randomint.result}"
  location            = azurerm_resource_group.tf-webapp-rg.location
  resource_group_name = azurerm_resource_group.tf-webapp-rg.name
  service_plan_id     = azurerm_service_plan.tf-webapp-serviceplan.id
  https_only          = true

  site_config {
    minimum_tls_version = "1.2"
    # application_stack {
    #   # node_version = "16-lts"
    # }
  }
}