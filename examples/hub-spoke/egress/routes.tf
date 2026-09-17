# One table per AKS subnet leaves room for cluster-specific routes. No CSV or
# Application Gateway subnet associations are owned by this state.
resource "azurerm_route_table" "pprd" {
  provider                      = azurerm.pprd
  for_each                      = var.pprd.aks_subnets
  name                          = "${var.name_prefix}-pprd-${each.key}-rt"
  location                      = var.location
  resource_group_name           = var.pprd.resource_group_name
  bgp_route_propagation_enabled = true
  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.firewall_private_ip
  }
  dynamic "route" {
    for_each = { for index, cidr in var.prd.address_space : "prd-${index}" => cidr }
    content {
      name                   = "${route.key}-via-firewall"
      address_prefix         = route.value
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.firewall_private_ip
    }
  }
  tags = var.tags
}
resource "azurerm_subnet_route_table_association" "pprd_aks" {
  provider       = azurerm.pprd
  for_each       = var.enable_aks_routes ? var.pprd.aks_subnets : {}
  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.pprd[each.key].id
}


# One table per AKS subnet leaves room for cluster-specific routes. No CSV or
# Application Gateway subnet associations are owned by this state.
resource "azurerm_route_table" "prd" {
  provider                      = azurerm.prd
  for_each                      = var.prd.aks_subnets
  name                          = "${var.name_prefix}-prd-${each.key}-rt"
  location                      = var.location
  resource_group_name           = var.prd.resource_group_name
  bgp_route_propagation_enabled = true
  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.firewall_private_ip
  }
  dynamic "route" {
    for_each = { for index, cidr in var.pprd.address_space : "pprd-${index}" => cidr }
    content {
      name                   = "${route.key}-via-firewall"
      address_prefix         = route.value
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.firewall_private_ip
    }
  }
  tags = var.tags
}
resource "azurerm_subnet_route_table_association" "prd_aks" {
  provider       = azurerm.prd
  for_each       = var.enable_aks_routes ? var.prd.aks_subnets : {}
  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.prd[each.key].id
}
