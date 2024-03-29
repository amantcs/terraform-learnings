

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
    public_ip_address_id          = azurerm_public_ip.terraform-pub-ip.id
  }
}


resource "azurerm_public_ip" "terraform-pub-ip" {
  name                    = "terra-ip"
  location                = azurerm_resource_group.appgrp.location
  resource_group_name     = azurerm_resource_group.appgrp.name
  allocation_method       = "Static"

}

#network security group

resource "azurerm_network_security_group" "nsg1" {
  name                = "terra-nsg"
  location            = azurerm_resource_group.appgrp.location
  resource_group_name = azurerm_resource_group.appgrp.name

  security_rule {
    name                       = "SSHRule"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

#nsg association

resource "azurerm_subnet_network_security_group_association" "subnet-nsg-link" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}


# RSA key of size 4096 bits
resource "tls_private_key" "linuxkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "linuxkeypem" {
  content  = tls_private_key.linuxkey.private_key_pem
  filename = "linuxkey.pem"
}


#virtual machine

resource "azurerm_linux_virtual_machine" "linuxvm1" {
  name                = "terraform-linux-vm"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location
  size                = "Standard_D2s_V3"
  admin_username      = "adminuser"
  admin_password      = "Azure@123"
  network_interface_ids = [
    azurerm_network_interface.terraforminterface.id
  ]

  admin_ssh_key {
    username = "adminuser"
    public_key = tls_private_key.linuxkey.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

