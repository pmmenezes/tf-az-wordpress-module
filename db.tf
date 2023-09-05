resource "azurerm_private_dns_zone" "db" {
  name                = "${var.project}${var.env}.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "db" {
  name                  =  "link-${var.env}-${azurerm_virtual_network.vnet.name}"
  resource_group_name = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.db.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
tags = local.tags_default
}

resource "random_password" "pass_admin_db" {
  length           = 16
  special          = true
  override_special = "#$%&()-_=+[]{}<>"
}

output "pass_admin_db" {
  value = random_password.pass_admin_db.result
  sensitive = true
}

resource "azurerm_mysql_flexible_server" "db" {
  name                   =  "mysql-${var.project}-${local.resource_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location               = var.region
  administrator_login    = var.administrator_login
  administrator_password =  random_password.pass_admin_db.result
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.snets["db"].id
  private_dns_zone_id    = azurerm_private_dns_zone.db.id
  sku_name               = var.vm_type
  tags = local.tags_default
  depends_on = [azurerm_private_dns_zone_virtual_network_link.db]
  zone = 1
}

resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db.name
  value               = "OFF"
}

# Create a database for the WordPress application on the MySQL Flexible Server
resource "azurerm_mysql_flexible_database" "web_database" {
  name                = "db-${var.project}-${local.resource_name}"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db.name
  charset             = "utf8"
  collation           = "utf8_general_ci"

  depends_on = [
    azurerm_mysql_flexible_server_configuration.require_secure_transport
  ]
}
