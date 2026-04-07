terraform {
  required_version = ">= 1.12.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.59.0"
    }

    #    aws = {
    #      source = "hashicorp/aws"
    #      version = "= 3.0"
    #    }
    #
    #    kubernetes = {
    #      source = "hashicorp/kubernetes"
    #      version = ">= 2.0.0"
    #    }
  }
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "alz2" {
  name     = "rg-alz2-${var.environment}"
  location = var.location
  tags = var.tags
}

# Network
resource "azurerm_network_security_group" "nsg-alz-2" {
  name                = "nsg-alz-2-${var.environment}"
  location            = azurerm_resource_group.alz2.location
  resource_group_name = azurerm_resource_group.alz2.name
}

resource "azurerm_virtual_network" "vnet-alz-2" {
  name                = "vnet-alz-2-${var.environment}"
  location            = azurerm_resource_group.alz2.location
  resource_group_name = azurerm_resource_group.alz2.name
  address_space       = var.address_space

  tags = var.tags
}

resource "azurerm_subnet" "vnet-alz-2-subnet-1" {
  name                 = "app-subnet-1"
  resource_group_name = azurerm_resource_group.alz2.name
  virtual_network_name = azurerm_virtual_network.vnet-alz-2.name
  address_prefixes     = var.address_prefixes_1
}

resource "azurerm_subnet" "vnet-alz-2-subnet-2" {
  name                 = "db-subnet-1"
  resource_group_name = azurerm_resource_group.alz2.name
  virtual_network_name = azurerm_virtual_network.vnet-alz-2.name
  address_prefixes     = var.address_prefixes_2
  
}

resource "azurerm_subnet_network_security_group_association" "subnet-1-assoc" {
  subnet_id                 = azurerm_subnet.vnet-alz-2-subnet-1.id
  network_security_group_id = azurerm_network_security_group.nsg-alz-2.id

  depends_on = [
    azurerm_subnet.vnet-alz-2-subnet-1,
    azurerm_network_security_group.nsg-alz-2
  ]

}

resource "azurerm_subnet_network_security_group_association" "subnet-2-assoc" {
  subnet_id                 = azurerm_subnet.vnet-alz-2-subnet-2.id
  network_security_group_id = azurerm_network_security_group.nsg-alz-2.id

  depends_on = [
    azurerm_subnet.vnet-alz-2-subnet-2,
    azurerm_network_security_group.nsg-alz-2
  ]
}

## VNET Peering
data "azurerm_virtual_network" "terraform-hub" {
  name                = "terraform-hub-vnet"
  resource_group_name = "terraform-test"
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub-alz2-${var.environment}"
  resource_group_name       = azurerm_resource_group.alz2.name
  virtual_network_name      = azurerm_virtual_network.vnet-alz-2.name
  remote_virtual_network_id = data.azurerm_virtual_network.terraform-hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke-alz2-${var.environment}"
  resource_group_name       = data.azurerm_virtual_network.terraform-hub.resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.terraform-hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-alz-2.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network_peering.spoke_to_hub]
}

# Test VM 1
resource "azurerm_network_interface" "nic-vm-app-1" {
  name                = "nic-app-vm-1-${var.environment}"
  location            = azurerm_resource_group.alz2.location
  resource_group_name = azurerm_resource_group.alz2.name

  ip_configuration {
    name                          = "vm-nic-configuration"
    subnet_id                     = azurerm_subnet.vnet-alz-2-subnet-1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm-app-1" {
  name                  = "vm-app-1-${var.environment}"
  location              = azurerm_resource_group.alz2.location
  resource_group_name   = azurerm_resource_group.alz2.name
  network_interface_ids = [azurerm_network_interface.nic-vm-app-1.id]
  vm_size               = "Standard_B4as_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  identity {
    type = "SystemAssigned"
  }

  #tags = var.tags
  tags = {
    env = "dev"
    app = "alz2"
    test = "1"
    tt = "2"
  }
}

## MySQL DB
data "azurerm_private_dns_zone" "mysql-pdz" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = "terraform-test"
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql-pdz-link-alz-2" {
  name                  = "mysql-pdz-to-vnet-alz-2-${var.environment}"
  resource_group_name   = data.azurerm_private_dns_zone.mysql-pdz.resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.mysql-pdz.name
  virtual_network_id    = azurerm_virtual_network.vnet-alz-2.id
}

resource "azurerm_mysql_flexible_server" "db-mysql" {
  name                   = "db-alz2-mysql-${var.environment}"
  resource_group_name    = azurerm_resource_group.alz2.name
  location               = azurerm_resource_group.alz2.location
  version                = var.mysql_version
  zone                   = 1
  administrator_login    = var.mysql_admin
  administrator_password = var.mysql_pwd
  backup_retention_days  = var.mysql_backup_retention_days
  geo_redundant_backup_enabled = false
#  private_dns_zone_id    = data.azurerm_private_dns_zone.mysql-pdz.id
  sku_name               = var.mysql_sku_name
  public_network_access  = "Disabled"

  high_availability {
    mode = "ZoneRedundant"
    standby_availability_zone = 3
  }

  storage {
    auto_grow_enabled = true
    io_scaling_enabled = true
    size_gb = var.mysql_storage_size_gb
  }

  maintenance_window {
    day_of_week  = 1
    start_hour   = 0
    start_minute = 0
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql-pdz-link-alz-2]
}

resource "azurerm_private_endpoint" "db-mysql-pe" {
  name                  = "db-alz2-mysql-pe-${var.environment}"
  location              = azurerm_resource_group.alz2.location
  resource_group_name   = azurerm_resource_group.alz2.name
  subnet_id             = azurerm_subnet.vnet-alz-2-subnet-2.id

  private_service_connection {
    name                           = "db-alz2-mysql-subnet-pe"
    private_connection_resource_id = azurerm_mysql_flexible_server.db-mysql.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

    private_dns_zone_group {
    name                 = "mysql-pdz-gp"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.mysql-pdz.id]
  }

  tags = var.tags
}