resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  address_space       = var.cidr
  name                = "vnet-${local.resource_name}"
}

locals {
  subnets = {
    vm = { address_prefixes = ["10.0.1.0/24"], service_endpoints = ["Microsoft.Storage"], service_delegations = {} },
    ep = { address_prefixes = ["10.0.2.0/24"], service_endpoints = ["Microsoft.Storage"], service_delegations = {} },
    db = { address_prefixes = ["10.0.3.0/24"], service_endpoints = ["Microsoft.Storage"], service_delegations = {
      mysqlfs = {
        "Microsoft.DBforMySQL/flexibleServers" = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      },
      },
  } }
}

resource "azurerm_subnet" "snets" {
  for_each = local.subnets
  name = "snet-${each.key}-${local.resource_name}"
  address_prefixes = each.value.address_prefixes
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  service_endpoints = try(each.value.service_endpoints, [])
  private_endpoint_network_policies_enabled = true
  dynamic "delegation" {
    for_each = each.value.service_delegations
    content {
        name = delegation.key
        dynamic "service_delegation" {
          for_each = delegation.value
          content {
            name = service_delegation.key
            actions = service_delegation.value
          }
        }
    }
    }    
  }



#resource "azurerm_subnet" "vm" {
#  name                                      = "snet-vms-${local.resource_name}"
#  resource_group_name                       = azurerm_resource_group.rg.name
#  virtual_network_name                      = azurerm_virtual_network.vnet.name
#  address_prefixes                          = ["10.0.1.0/24"]
#  service_endpoints                         = ["Microsoft.Storage"]
#  private_endpoint_network_policies_enabled = true
#}
#
#resource "azurerm_subnet" "ep" {
#  name                                      = "snet-ep-pablo-dev-eastus2"
#  resource_group_name                       = azurerm_resource_group.rg.name
#  virtual_network_name                      = azurerm_virtual_network.vnet.name
#  address_prefixes                          = ["10.0.2.0/24"]
#  service_endpoints                         = ["Microsoft.Storage"]
#  private_endpoint_network_policies_enabled = true
#}
#
#resource "azurerm_subnet" "db" {
#  name                                      = "snet-db-pablo-dev-eastus2"
#  resource_group_name                       = azurerm_resource_group.rg.name
#  virtual_network_name                      = azurerm_virtual_network.vnet.name
#  address_prefixes                          = ["10.0.3.0/24"]
#  service_endpoints                         = ["Microsoft.Storage"]
#  private_endpoint_network_policies_enabled = true
#  delegation {
#    name = "mysqlfs"
#    service_delegation {
#      name    = "Microsoft.DBforMySQL/flexibleServers"
#      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
#    }
#  }
#}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-pablo-dev-eastus2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "AcessoSSH"
  description                 = "Acesso via SSH"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "AcessoHTTP"
  description                 = "Acesso via HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg" {
  subnet_id                 = azurerm_subnet.snets["vm"].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

/*
Bloco referente a configuração de loadbalance
*/

resource "azurerm_public_ip" "pip" {
  name                = "pip-pablo-dev-eastus2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "lb-pablo-dev-eastus2"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "lb" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "http-probe"
  port            = 80
}

resource "azurerm_lb_rule" "lb_rule_http" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "HTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.lb.id
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.lb.id
  ]
}

resource "azurerm_lb_nat_rule" "lb_nat_rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "AcessoSSH"
  protocol                       = "Tcp"
  frontend_port_start            = 2222
  frontend_port_end              = 2225
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb.id
}

