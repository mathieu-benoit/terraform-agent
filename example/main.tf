provider "azurerm" {
  version = "~>1.24"
}

provider "azuread" {
  version = "=0.2.0"
}

provider "random" {
  version = "~>2.1.0"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

locals {
  numberOfServicePrincipals = 10
}

resource "azuread_application" "application" {
  count = "${local.numberOfServicePrincipals}"
  name  = "test-application-key-vault-${count.index}"
}

resource "azuread_service_principal" "service_principal" {
  count          = "${local.numberOfServicePrincipals}"
  application_id = "${azuread_application.application.*.application_id[count.index]}"
}

resource "random_string" "service_principal_password" {
  count   = "${local.numberOfServicePrincipals}"
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "aks_service_principal" {
  count                = "${local.numberOfServicePrincipals}"
  end_date             = "${timeadd(timestamp(), "${24 * 365 * 2}h")}"
  service_principal_id = "${azuread_service_principal.service_principal.*.id[count.index]}"
  value                = "${random_string.service_principal_password.*.result[count.index]}"
}

resource "azurerm_key_vault" "keyvault" {
  count               = "${local.numberOfServicePrincipals}"
  name                = "test-key-vault-${count.index}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  tenant_id           = "${local.tenantId}"
  sku {
    name = "standard"
  }
}

resource "azurerm_key_vault_access_policy" "policy" {
  count               = "${local.numberOfServicePrincipals}"
  object_id           = "${azuread_service_principal.service_principal.*.id[count.index]}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  tenant_id           = "${local.tenantId}"
  vault_name          = "${azurerm_key_vault.keyvault.*.name[count.index]}"

  key_permissions = [
    "get",
    "list",
    "wrapKey",
    "unwrapKey",
  ]

  secret_permissions = [
    "get",
    "list",
  ]
}

resource "azurerm_role_assignment" "reader" {
  count                = "${local.numberOfServicePrincipals}"
  principal_id         = "${azuread_service_principal.service_principal.*.id[count.index]}"
  scope                = "${azurerm_key_vault.keyvault.*.id[count.index]}"
  role_definition_name = "Reader"
}

