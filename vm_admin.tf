resource "azurerm_network_interface" "admin_vm" {
  name                = "nic-webserver-pablo-dev-eastus2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "East US 2"
  tags                = {
    projeto = "webserver"
    ambiente = "dev"
    gerenciado_por = "terraform"
  }

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "admin_vm" {
  name                            ="vmadmin-webserver-pablo-dev-eastus2"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = "East US 2"
  size                            = "Standard_B1ms"
  admin_username                  = "adminuser"
  admin_password                  = "senha.123#$$#"
  disable_password_authentication = false
  tags                            = {
    projeto = "webserver"
    ambiente = "dev"
    gerenciado_por = "terraform"
  }

  network_interface_ids = [
    azurerm_network_interface.admin_vm.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher =  "Canonical"
    offer     =  "0001-com-ubuntu-server-focal"
    sku       = "20_04-LTS"
    version   = "latest"


}

  user_data = data.template_cloudinit_config.webadmin.rendered

}

data "template_cloudinit_config" "webadmin" {
  gzip          = false
  base64_encode = true
  part {
  filename = "wadmin-cloudinit.yml"
  content_type = "text/cloud-config"    
  content = templatefile("${path.module}/vm-admin-cloudinit.yml", 
   {
    tmpl_database_username = "${azurerm_mysql_flexible_server.db.administrator_login}",
    tmpl_database_password = "${azurerm_mysql_flexible_server.db.administrator_password}",
    tmpl_database_hostname = "${azurerm_mysql_flexible_server.db.name}.mysql.database.azure.com",
    tmpl_database_name     = "${azurerm_mysql_flexible_database.web_database.name}",
    tmpl_file_share        = "${azurerm_storage_account.sa.name}.file.core.windows.net:/${azurerm_storage_account.sa.name}/${azurerm_storage_share.nfs_share.name}",
    tmpl_wordpress_url     = "http://${azurerm_public_ip.pip.ip_address}",
    tmpl_wp_title          = "WebServer LDC & ITSolutions",
    tmpl_wp_admin_user     = "admin",
    tmpl_wp_admin_password = "senha.123#$$#",
    tmpl_wp_admin_email    = "admin@test.com",
  })
}
}
resource "azurerm_network_interface_backend_address_pool_association" "admin_vm" {
  network_interface_id    = azurerm_network_interface.admin_vm.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb.id
}