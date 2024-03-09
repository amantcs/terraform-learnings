resource "azurerm_storage_account" "appstorage1" {
  name                     = "storageterraform9876567"
  resource_group_name      = azurerm_resource_group.appgrp.name
  location                 = azurerm_resource_group.appgrp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["152.58.106.206"]
    virtual_network_subnet_ids = [azurerm_subnet.subnet1.id]
  }

  tags = {
    environment = "terraform-testing"
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.appstorage1.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "blob1" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = azurerm_storage_account.appstorage1.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  source                 = "IIS_Config.ps1"
}

