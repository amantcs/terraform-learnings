terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.88.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "953c0ff7-b528-47d0-8ee7-ff9262368d59"
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "appgrp" {
  name     = "terraform-grp"
  location = "East US"
}

resource "random_uuid" "test" {
}

output "random" {
  value = substr(random_uuid.test.result,0,8)
  
}

resource "azurerm_storage_account" "appstorage1" {
  name                     = lower(join("",["${var.storage_account_prefix}",substr(random_uuid.test.result,0,8)]))
  resource_group_name      = azurerm_resource_group.appgrp.name
  location                 = azurerm_resource_group.appgrp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "terraform-testing"
  }
}

resource "azurerm_storage_container" "container1" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.appstorage1.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "blob1" {
  name                   = "main.tf"
  storage_account_name   = azurerm_storage_account.appstorage1.name
  storage_container_name = azurerm_storage_container.container1.name
  type                   = "Block"
  source                 = "main.tfplan"
}