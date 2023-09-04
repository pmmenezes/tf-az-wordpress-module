resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_name}"
  location = var.region
}