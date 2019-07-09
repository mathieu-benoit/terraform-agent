provider "azurerm" {
  version = "=1.31.0"
}
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}
