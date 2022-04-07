provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "BackstageRG" {
  name     = "BackstageRG"
  location = "West Europe"
}

resource "azurerm_virtual_network" "BackstageVnet" {
  name                = "BackstageVnet"
  location            = azurerm_resource_group.BackstageRG.location
  resource_group_name = azurerm_resource_group.BackstageRG.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "PostgreSubnet" {
  name                 = "PostgreSubnet"
  resource_group_name  = azurerm_resource_group.BackstageRG.name
  virtual_network_name = azurerm_virtual_network.BackstageVnet.name
  address_prefixes     = ["10.0.2.0/24"]
  delegation {
    name = "flexibleserver"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
resource "azurerm_private_dns_zone" "dnszone" {
  name                = "dnszone.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.BackstageRG.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnetlink" {
  name                  = "BackstageVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.dnszone.name
  virtual_network_id    = azurerm_virtual_network.BackstageVnet.id
  resource_group_name = azurerm_resource_group.BackstageRG.name
}

resource "azurerm_postgresql_flexible_server" "backstage-backend-postgresql-server" {
  name                   = "backstage-backend-postgresql-server"
  resource_group_name    = azurerm_resource_group.BackstageRG.name
  location               = azurerm_resource_group.BackstageRG.location
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.PostgreSubnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.dnszone.id
  administrator_login    = var.PostgreSqlUsername
  administrator_password = var.PostgreSqlPassword

  storage_mb = 32768

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.vnetlink]

}