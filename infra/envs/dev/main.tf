resource "azurerm_resource_group" "rg_platform" {
  name     = "${var.prefix}-rg-platform"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "rg_network" {
  name     = "${var.prefix}-rg-network"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_platform.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "${var.prefix}-vnet-hub"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "hub_shared" {
  name                 = "snet-hub-shared"
  resource_group_name  = azurerm_resource_group.rg_network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "spoke_clienta" {
  name                = "${var.prefix}-vnet-clienta"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  address_space       = ["10.10.0.0/16"]
  tags                = merge(var.tags, { Client = "ClientA" })
}

resource "azurerm_subnet" "clienta_app" {
  name                 = "snet-clienta-app"
  resource_group_name  = azurerm_resource_group.rg_network.name
  virtual_network_name = azurerm_virtual_network.spoke_clienta.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "clienta_app_nsg" {
  name                = "${var.prefix}-nsg-clienta-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { Client = "ClientA" })

  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "clienta_app_assoc" {
  subnet_id                 = azurerm_subnet.clienta_app.id
  network_security_group_id = azurerm_network_security_group.clienta_app_nsg.id
}

resource "azurerm_virtual_network_peering" "hub_to_clienta" {
  name                      = "peer-hub-to-clienta"
  resource_group_name       = azurerm_resource_group.rg_network.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_clienta.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "clienta_to_hub" {
  name                      = "peer-clienta-to-hub"
  resource_group_name       = azurerm_resource_group.rg_network.name
  virtual_network_name      = azurerm_virtual_network.spoke_clienta.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}
