resource "azurerm_storage_account" "appstorage1" {
  name                     = "storageterraform9876567"
  resource_group_name      = azurerm_resource_group.appgrp.name
  location                 = azurerm_resource_group.appgrp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

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

resource "azurerm_virtual_machine_extension" "vmextension" {
  name                 = "vmextension"
  virtual_machine_id   = azurerm_windows_virtual_machine.VM1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.appstorage1.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS


}

