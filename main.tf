# Derived from AZ-TF-azvdc. Resource ownership and module interfaces are retained.

resource "azurerm_resource_group" "network" {
  name     = "${local.label}-netw-rg-01"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "vnet" {
  name     = "${local.label}-vnet-rg-01"
  location = var.location
  tags     = local.tags
}

module "vnet" {
  source = "git::https://github.com/MikeeeGit/terraform-azurerm-vnet.git?ref=v0.2.0"

  label               = local.label
  resource_group_name = azurerm_resource_group.vnet.name
  location            = var.location
  vnet_ip_range       = [var.vnet_ip_range]
  dns_servers         = var.dns_servers
  dns                 = var.dns
  private_dns         = local.private_dns
  vnet_suffix         = "vnet-01"
  tags                = local.tags
  ddos_plan_id        = var.ddos_plan_id
  diag_log_workspace  = var.diag_log_workspace
  dns_zone_name       = var.dns_zone_name
}

module "subnets" {
  source = "git::https://github.com/MikeeeGit/terraform-azurerm-subnets.git?ref=v0.2.0"

  resource_group_name  = azurerm_resource_group.vnet.name
  location             = var.location
  vnet_name            = module.vnet.vnet.name
  subnets              = var.subnets
  label                = local.label
  location_abbreviated = local.location_abbreviated
  environment          = var.environment
  vnet_suffix          = ""
  tags                 = local.tags
}

resource "azurerm_container_registry" "acr" {
  count = var.acr_config.enabled ? 1 : 0

  name                = var.acr_config.name
  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  sku                 = var.acr_config.sku
  admin_enabled       = var.acr_config.admin_enabled

  dynamic "georeplications" {
    for_each = toset(var.acr_config.georeplication_locations)
    content {
      location = georeplications.value
    }
  }

  tags = local.tags
}
