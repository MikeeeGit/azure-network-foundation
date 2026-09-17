mock_provider "azurerm" {
  alias = "hub"
  mock_data "azurerm_firewall" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/azureFirewalls/example-firewall"
      sku_name = "AZFW_VNet"
      ip_configuration = [{
        name                 = "primary"
        private_ip_address   = "10.80.1.5"
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

variables {
  # Synthetic shape only. Replace all IDs and prefixes with actual network outputs.
  firewall_id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/azureFirewalls/example-firewall"
  pprd = {
    subscription_id     = "00000000-0000-0000-0000-000000000003"
    resource_group_name = "example-pprd-rg"
    vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example-pprd-rg/providers/Microsoft.Network/virtualNetworks/example-pprd-vnet"
    address_space       = ["10.81.0.0/16"]
    aks_subnets = {
      aks01 = { id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example-pprd-rg/providers/Microsoft.Network/virtualNetworks/example-pprd-vnet/subnets/example-pprd-aks01", address_prefix = "10.81.0.0/22" }
      aks02 = { id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example-pprd-rg/providers/Microsoft.Network/virtualNetworks/example-pprd-vnet/subnets/example-pprd-aks02", address_prefix = "10.81.4.0/22" }
    }
  }
  prd = {
    subscription_id     = "00000000-0000-0000-0000-000000000004"
    resource_group_name = "example-prd-rg"
    vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000004/resourceGroups/example-prd-rg/providers/Microsoft.Network/virtualNetworks/example-prd-vnet"
    address_space       = ["10.82.0.0/16"]
    aks_subnets = {
      aks01 = { id = "/subscriptions/00000000-0000-0000-0000-000000000004/resourceGroups/example-prd-rg/providers/Microsoft.Network/virtualNetworks/example-prd-vnet/subnets/example-prd-aks01", address_prefix = "10.82.0.0/22" }
      aks02 = { id = "/subscriptions/00000000-0000-0000-0000-000000000004/resourceGroups/example-prd-rg/providers/Microsoft.Network/virtualNetworks/example-prd-vnet/subnets/example-prd-aks02", address_prefix = "10.82.4.0/22" }
    }
  }
  enable_aks_routes = false

}

run "follow_changed_applied_firewall_address" {
  command = plan
  assert {
    condition     = output.firewall_private_ip == "10.80.1.5" && alltrue(flatten([for table in concat(values(azurerm_route_table.pprd), values(azurerm_route_table.prd)) : [for route in table.route : route.next_hop_in_ip_address == "10.80.1.5"]]))
    error_message = "Every route must follow the firewall address read from Azure, not a copied constant."
  }
}
