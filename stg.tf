
//https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "azurerm_storage_account" "sa" {
  name                      = "sawebserver${lower(var.name)}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = var.region
  account_tier              = "Premium"
  account_kind              =  "FileStorage"
  account_replication_type  ="LRS"
  enable_https_traffic_only = false
  min_tls_version           = "TLS1_2"
  tags = var.tags_default
}

data "http" "current_ip" {
  url = "https://api.ipify.org/?format=json"
}

//https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules
resource "azurerm_storage_account_network_rules" "sa" {
  storage_account_id = azurerm_storage_account.sa.id
  default_action     = "Deny"
  ip_rules           = ["${jsondecode(data.http.current_ip.response_body).ip}"]
  bypass             =   [ "Metrics", "Logging", "AzureServices",  ]
  virtual_network_subnet_ids = [ azurerm_subnet.snet["vm"].id, azurerm_subnet.snet["ep"].id, azurerm_subnet.snet["db"].id ]
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share
resource "azurerm_storage_share" "nfs_share" {
  name                 = "webserver"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 100
  enabled_protocol     = "NFS"
  depends_on = [
    azurerm_storage_account_network_rules.sa
  ]
    tags = var.tags_default

}
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/private_dns_zone

resource "azurerm_private_dns_zone" "storage_share_private_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags_default

}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_share_private_zone" {
  name                  = "link-${azurerm_virtual_network.vnet.name}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_share_private_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
  tags = var.tags_default

}

// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "storage_share_endpoint" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = "East US 2"
  name                = "pep-webserver-pablo-dev-eastus2"
  subnet_id           = azurerm_subnet.ep.id
  tags = var.tags_default
}

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_share_private_zone.id]
  }

  private_service_connection {
    name                           = azurerm_storage_account.sa.name
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }