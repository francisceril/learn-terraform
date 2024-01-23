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
resource "azurerm_resource_group" "tf_rg" {
  name     = "tf_rg"
  location = "West Europe"

  tags = {
    environment = "dev"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "tf_vnet" {
  name                = "tf_vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.tf_rg.location
  resource_group_name = azurerm_resource_group.tf_rg.name

  tags = {
    environment = "dev"
  }
}

# Subnet
resource "azurerm_subnet" "tf_subnet" {
  name                 = "tf_subnet"
  resource_group_name  = azurerm_resource_group.tf_rg.name
  virtual_network_name = azurerm_virtual_network.tf_vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "tf_nsg" {
  name                = "tf_nsg"
  resource_group_name = azurerm_resource_group.tf_rg.name
  location            = azurerm_resource_group.tf_rg.location

  tags = {
    environment = "dev"
  }
}

# Security Rules
resource "azurerm_network_security_rule" "tf_sec_rule" {
  name                        = "tf_sec_rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tf_rg.name
  network_security_group_name = azurerm_network_security_group.tf_nsg.name
}

# Network Segurity Group Subnet Association
resource "azurerm_subnet_network_security_group_association" "tf_nsg_subnet_assoc" {
  subnet_id                 = azurerm_subnet.tf_subnet.id
  network_security_group_id = azurerm_network_security_group.tf_nsg.id
}

# Public IP
resource "azurerm_public_ip" "tf_public_ip" {
  name                = "tf_public_ip"
  location            = azurerm_resource_group.tf_rg.location
  resource_group_name = azurerm_resource_group.tf_rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

# Network Interface
resource "azurerm_network_interface" "tf_nic" {
  name                = "tf_nic"
  location            = azurerm_resource_group.tf_rg.location
  resource_group_name = azurerm_resource_group.tf_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf_public_ip.id
  }

  tags = {
    environment = "dev"
  }
}

# Virtual Machine - Linux
resource "azurerm_linux_virtual_machine" "tf_vm" {
  name                  = "tf_linux_vm"
  resource_group_name   = azurerm_resource_group.tf_rg.name
  location              = azurerm_resource_group.tf_rg.location
  size                  = "Standard_B1s"
  computer_name         = "devcontainer"
  admin_username        = "tfadmin"
  network_interface_ids = [azurerm_network_interface.tf_nic.id]

  custom_data = filebase64("custom-data.tpl")

  admin_ssh_key {
    username   = "tfadmin"
    public_key = file("~/.ssh/terraform_azure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "dev"
  }
}

# Generate a random integer to create a globally unique name
resource "random_integer" "tf_randomint" {
  min = 10000
  max = 99999
}

# Create Linux App Service Plan
resource "azurerm_service_plan" "tf_appserviceplan" {
  name                = "tf_${random_integer.tf_randomint.result}"
  location            = azurerm_resource_group.tf_rg.location
  resource_group_name = azurerm_resource_group.tf_rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "tf_webapp" {
  name                = "tf-webapp-${random_integer.tf_randomint.result}"
  location            = azurerm_resource_group.tf_rg.location
  resource_group_name = azurerm_resource_group.tf_rg.name
  service_plan_id     = azurerm_service_plan.tf_appserviceplan.id
  https_only          = true
  site_config {
    minimum_tls_version = "1.2"
  }
}

# Deploy sample app from Github repo
resource "azurerm_app_service_source_control" "tf_sourcecontrol" {
  app_id                 = azurerm_linux_web_app.tf_webapp.id
  repo_url               = "https://github.com/Azure-Samples/nodejs-docs-hello-world"
  branch                 = "main"
  use_manual_integration = true
  use_mercurial          = false
}