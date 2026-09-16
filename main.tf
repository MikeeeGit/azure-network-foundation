resource "azurerm_resource_group" "network" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "git::https://github.com/MikeeeGit/terraform-azurerm-network-foundation.git?ref=9c3d349fcf07412ede3bc3ddf474f566da27c15e"

  name                       = var.name
  resource_group_name        = azurerm_resource_group.network.name
  location                   = azurerm_resource_group.network.location
  address_space              = var.address_space
  subnets                    = var.subnets
  dns_servers                = var.dns_servers
  tags                       = var.tags
  ddos_protection_plan_id    = var.ddos_protection_plan_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  private_dns_zones          = var.private_dns_zones
  peerings                   = var.peerings
  private_endpoints          = var.private_endpoints
}
