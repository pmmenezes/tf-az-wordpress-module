resource "azurerm_resource_group" "rg" {
  name     = "rg--${var.name}-${var.env}-${lower(replace(var.region, "/\\W|_|\\s/", ""))}"
  location = var.region
}