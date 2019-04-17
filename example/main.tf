provider "azurerm" {
  version = "=1.25"
}
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}
