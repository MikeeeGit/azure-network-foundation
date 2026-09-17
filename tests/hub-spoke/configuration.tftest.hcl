mock_provider "azurerm" {
  override_during = plan
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example" }
  }
}
mock_provider "azurerm" {
  alias           = "hub"
  override_during = plan
}
variables {
  subnet_config_root = "examples/hub-spoke/config"
}
run "complete_network_configuration" {
  command = plan
  assert {
    condition     = length(output.subnet_ids) == (var.environment == "hub" ? 3 : 5)
    error_message = "The hub reserves shared services; each spoke has both AKS subnets and a dedicated gateway subnet."
  }
  assert {
    condition     = length(azurerm_virtual_network_peering.peers) == 0
    error_message = "Bootstrap must not require remote state before networks exist."
  }
  assert {
    condition     = var.environment == "hub" ? length(output.managed_private_dns_zone_ids) == 5 : length(output.hub_private_dns_zone_link_ids) == 5
    error_message = "The hub owns all shared zones; each spoke links them without needing private endpoints."
  }
  assert {
    condition     = length(output.subnet_route_table_rules) == length(output.subnet_ids) && alltrue([for rules in values(output.subnet_route_table_rules) : length(rules) == 0])
    error_message = "No default route may point to a firewall before the egress stack creates one."
  }
}
