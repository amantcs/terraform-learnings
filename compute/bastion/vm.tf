

locals {
  resource_group_name = "terraform-grp"
  location = "East US"
  common_tags = {
    created_by = "terraform"
    course = "Alan"
  }
  subnets = [
    {
      name           = "subnet1"
      address_prefix = "10.0.0.0/24"
    },
    {
      name           = "subnet2"
      address_prefix = "10.0.1.0/24"
    #security_group = azurerm_network_security_group.example.id
    }
  ]
}

# Create a resource group
resource "azurerm_resource_group" "appgrp" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "terraform-network"
  location            = azurerm_resource_group.appgrp.location
  resource_group_name = azurerm_resource_group.appgrp.name
  address_space       = ["10.0.0.0/16"]
  #dns_servers         = ["10.0.0.4", "10.0.0.5"]

  
  tags = local.common_tags
}

resource "azurerm_subnet" "subnet1" {
  name                 = local.subnets[0].name
  resource_group_name  = azurerm_resource_group.appgrp.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [local.subnets[0].address_prefix]
}

resource "azurerm_subnet" "subnet2" {
  name                 = local.subnets[1].name
  resource_group_name  = azurerm_resource_group.appgrp.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [local.subnets[1].address_prefix]
}

resource "azurerm_network_interface" "terraforminterface" {
  name                = "terraform-nic"
  location            = azurerm_resource_group.appgrp.location
  resource_group_name = azurerm_resource_group.appgrp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

#network security group

resource "azurerm_network_security_group" "nsg1" {
  name                = "terra-nsg"
  location            = azurerm_resource_group.appgrp.location
  resource_group_name = azurerm_resource_group.appgrp.name

  security_rule {
    name                       = "RDPRule"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

#nsg association

resource "azurerm_subnet_network_security_group_association" "subnet-nsg-link" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}


#get key vault value

data "azurerm_key_vault" "terraformkeyvault2345454" {
  name                = "terraformkeyvault2345454"
  resource_group_name = "new-grp"
}

data "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  key_vault_id = data.azurerm_key_vault.terraformkeyvault2345454.id
}

#virtual machine

resource "azurerm_windows_virtual_machine" "VM1" {
  name                = "terraform-vm"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = data.azurerm_key_vault_secret.vmpassword.value
  network_interface_ids = [
    azurerm_network_interface.terraforminterface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "datadisk1" {
  name                 = "terraform-data-disk1"
  location             = azurerm_resource_group.appgrp.location
  resource_group_name  = azurerm_resource_group.appgrp.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

}

resource "azurerm_virtual_machine_data_disk_attachment" "diskattach1" {
  managed_disk_id    = azurerm_managed_disk.datadisk1.id
  virtual_machine_id = azurerm_windows_virtual_machine.VM1.id
  lun                = "10"
  caching            = "ReadWrite"
}