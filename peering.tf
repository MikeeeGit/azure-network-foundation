# Phase 1 creates networks with enable_peerings=false. Phase 2 reads their states.
# Each environment normally owns its local side of a peering. A secondary hub can
# explicitly own the reverse hub side too, using the hub provider.
data "terraform_remote_state" "networks" {
  for_each = local.active_peers
  backend  = "azurerm"
  config = {
    subscription_id      = each.value.backend.subscription_id
    resource_group_name  = each.value.backend.resource_group_name
    storage_account_name = each.value.backend.storage_account_name
    container_name       = each.value.backend.container_name
    key                  = each.value.backend.key
    use_azuread_auth     = true
  }
}

resource "azurerm_virtual_network_peering" "peers" {
  for_each                  = local.active_peers
  name                      = coalesce(each.value.name, "${var.environment}-to-${each.key}")
  resource_group_name       = azurerm_resource_group.vnet.name
  virtual_network_name      = module.vnet.vnet.name
  remote_virtual_network_id = data.terraform_remote_state.networks[each.key].outputs.vnet_id

  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
  triggers = {
    remote_address_space = sha256(jsonencode(sort(tolist(data.terraform_remote_state.networks[each.key].outputs.vnet.address_space))))
  }
}

resource "azurerm_virtual_network_peering" "reverse_hub" {
  provider = azurerm.hub
  for_each = { for key, peer in local.active_peers : key => peer if peer.create_reverse_hub_peering }

  name                         = coalesce(each.value.reverse_name, "${each.key}-to-${var.environment}-${var.location_abbreviated}")
  resource_group_name          = data.terraform_remote_state.networks[each.key].outputs.vnet.resource_group_name
  virtual_network_name         = data.terraform_remote_state.networks[each.key].outputs.vnet.name
  remote_virtual_network_id    = module.vnet.vnet.id
  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.reverse_allow_gateway_transit
  use_remote_gateways          = false
  triggers = {
    remote_address_space = sha256(jsonencode(sort(tolist(module.vnet.vnet.address_space))))
  }

  lifecycle {
    precondition {
      condition     = lower(split("/", data.terraform_remote_state.networks[each.key].outputs.vnet_id)[2]) == lower(var.subscription_id_map["hub"])
      error_message = "Reverse hub peerings must target a VNet in subscription_id_map.hub. Other subscriptions own their local peering side."
    }
  }
}

output "peering_ids" {
  description = "Local peering IDs keyed by the configured remote network."
  value       = { for key, peer in azurerm_virtual_network_peering.peers : key => peer.id }
}
