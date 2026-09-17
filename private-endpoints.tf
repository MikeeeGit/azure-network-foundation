# Zones remain centrally owned by the hub subscription, as in the original stack.
data "azurerm_private_dns_zone" "endpoints" {
  provider            = azurerm.hub
  for_each            = { for endpoint in var.private_endpoints : endpoint.name => endpoint.private_dns_zone_name if !contains(local.owned_endpoint_zones, endpoint.private_dns_zone_name) }
  name                = each.value
  resource_group_name = local.hub_resource_group
}

resource "azurerm_private_endpoint" "endpoints" {
  for_each            = { for endpoint in var.private_endpoints : endpoint.name => endpoint }
  name                = each.value.name
  location            = var.location
  resource_group_name = azurerm_resource_group.vnet.name
  subnet_id           = local.subnet_name_to_id[each.value.subnet_name]

  private_service_connection {
    name                           = "${each.value.name}-connection"
    is_manual_connection           = false
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.service_connection]
  }
  private_dns_zone_group {
    name                 = "${each.value.name}-dns-group"
    private_dns_zone_ids = [local.endpoint_zone_ids[each.key]]
  }
  tags = local.tags
}

# Opt in when this stack owns the spoke links. Additional named zones support
# private AKS APIs and internal application names before any private endpoint exists.
resource "azurerm_private_dns_zone_virtual_network_link" "endpoint_spoke" {
  provider              = azurerm.hub
  for_each              = setsubtract(setunion(var.hub_private_dns_zone_names, var.link_endpoint_dns_zones ? local.endpoint_dns_zones : toset([])), local.owned_endpoint_zones)
  name                  = "${local.label}-${replace(each.value, ".", "-")}"
  resource_group_name   = local.hub_resource_group
  private_dns_zone_name = each.value
  virtual_network_id    = module.vnet.vnet.id
  registration_enabled  = false
  tags                  = local.tags

  lifecycle {
    precondition {
      condition     = var.environment != "hub"
      error_message = "Hub zone links are owned by the VNet module. Configure additional hub zone links only for spoke environments."
    }
  }
}
