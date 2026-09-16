locals {
  tags                 = merge(var.global_tags, var.environment_tags)
  location_abbreviated = var.location_abbreviated
  label                = "${var.location_abbreviated}-${var.environment}"
  hub_resource_group   = coalesce(var.hub_dns_resource_group_name, "${var.location_abbreviated}-hub-vnet-rg-01")

  private_dns = concat(var.private_dns, [
    for zone in var.private_dns_zones : {
      zone_name     = zone
      a_records     = []
      cname_records = []
      mx_records    = []
    } if !contains([for item in var.private_dns : item.zone_name], zone)
  ])
  subnet_name_to_id = {
    for name, subnet in module.subnets.subnets :
    name => subnet.id
  }
  owned_endpoint_zones = var.subscription_id_map[var.subscription] == var.subscription_id_map["hub"] && azurerm_resource_group.vnet.name == local.hub_resource_group ? toset([for zone in local.private_dns : zone.zone_name]) : toset([])
  endpoint_zone_ids = {
    for endpoint in var.private_endpoints : endpoint.name => contains(local.owned_endpoint_zones, endpoint.private_dns_zone_name) ? module.vnet.private_dns_zone_ids[endpoint.private_dns_zone_name] : data.azurerm_private_dns_zone.endpoints[endpoint.name].id
  }
  endpoint_dns_zones = toset([for endpoint in var.private_endpoints : endpoint.private_dns_zone_name])
  active_peers       = var.enable_peerings ? var.remote_networks : {}
}
