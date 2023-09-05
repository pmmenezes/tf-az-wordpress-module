#resource "azurerm_linux_virtual_machine_scale_set" "webserver" {
#  name                            = "vmss-webserver-pablo-dev-eastus2"
#  resource_group_name             = azurerm_resource_group.rg.name
#  location                        = "East US 2"
#  sku                             =  "Standard_B1ms"
#  instances                       = 2
#  admin_username                  = "adminuser"
#  admin_password                  = "senha.123#$$#"
#  disable_password_authentication = false
#  overprovision                   = false
#    tags = {
#    projeto = "webserver"
#    ambiente = "dev"
#    gerenciado_por = "terraform"
#  }
#
#  source_image_reference {
#    publisher = "Canonical"
#    offer     =  "0001-com-ubuntu-server-focal"
#    sku       = "20_04-LTS"
#    version   =  "latest"
#  }
#
#  os_disk {
#    storage_account_type = "Standard_LRS"
#    caching              = "ReadWrite"
#  }
#
#  network_interface {
#    name    = "nic-vmss-pablo-dev-eastus2"
#    primary = true
#
#    ip_configuration {
#      name      = "internal"
#      primary   = true
#      subnet_id = azurerm_subnet.vm.id
#      load_balancer_backend_address_pool_ids = [
#        azurerm_lb_backend_address_pool.lb.id
#      ]
#    }
#  }
#
#  user_data = base64encode(templatefile("vmss-cloudinit.tftpl", {
#    tmpl_file_share = "${azurerm_storage_account.sa.name}.file.core.windows.net:/${azurerm_storage_account.sa.name}/${azurerm_storage_share.nfs_share.name}"
#  }))
#
#  depends_on = [
#    azurerm_linux_virtual_machine.admin_vm,
#    azurerm_network_interface_backend_address_pool_association.admin_vm
#  ]
#
#}
#

