mock_provider "azurerm" {
  alias = "hub"
  mock_data "azurerm_firewall" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/azureFirewalls/example-firewall"
      sku_name = "AZFW_VNet"
      ip_configuration = [{
        name                 = "primary"
        private_ip_address   = "10.80.1.4"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/publicIPAddresses/example-pip"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/virtualNetworks/example-hub-vnet/subnets/AzureFirewallSubnet"
      }]
    }
  }
}
mock_provider "azurerm" {
  alias = "pprd"
  mock_resource "azurerm_route_table" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example-pprd-rg/providers/Microsoft.Network/routeTables/example-rt" } }
}
mock_provider "azurerm" {
  alias = "prd"
  mock_resource "azurerm_route_table" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000004/resourceGroups/example-prd-rg/providers/Microsoft.Network/routeTables/example-rt" } }
}

run "reviewed_hub_routing_configuration" {
  command = plan
  assert {
    condition     = var.environment == "hub" && var.location_abbreviated == "uks" && !var.enable_aks_routes && length(azurerm_route_table.pprd) == 2 && length(azurerm_route_table.prd) == 2
    error_message = "The layered delivery target must stage all four AKS tables before association."
  }
}
