resource "azurerm_subnet" "bastionsubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.appgrp.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.10.0/24"]
}


resource "azurerm_public_ip" "terraform-pub-ip" {
  name                    = "terra-ip"
  location                = azurerm_resource_group.appgrp.location
  resource_group_name     = azurerm_resource_group.appgrp.name
  allocation_method       = "Static"
  sku                     = "Standard"    
}

resource "azurerm_bastion_host" "example" {
  name                = "examplebastion"
  location            = azurerm_resource_group.appgrp.location
  resource_group_name = azurerm_resource_group.appgrp.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastionsubnet.id
    public_ip_address_id = azurerm_public_ip.terraform-pub-ip.id
  }
}