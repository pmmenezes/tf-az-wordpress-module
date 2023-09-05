output " administrator_password" {
  value = azurerm_mysql_flexible_server.db.administrator_password
  sensitive = true
}