mock_provider "azurerm" {
  alias = "hub"
  mock_resource "azurerm_public_ip" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/publicIPAddresses/example-pip" } }
  mock_resource "azurerm_firewall_policy" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/firewallPolicies/example-policy" } }
  mock_resource "azurerm_firewall" {
    defaults = { ip_configuration = { private_ip_address = "10.80.1.5" } }
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
  hub = {
    subscription_id     = "00000000-0000-0000-0000-000000000002"
    resource_group_name = "example-hub-rg"
    firewall_subnet_id  = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/virtualNetworks/example-hub-vnet/subnets/AzureFirewallSubnet"
  }
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
  enable_aks_routes         = false
  allow_cross_spoke_https   = false
  allow_legacy_ntp          = false
  additional_registry_fqdns = []

}

run "attach_only_aks_subnets_and_follow_actual_firewall_address" {
  command = apply
  variables {
    enable_aks_routes = true
    name_prefix       = "changed-firewall"
  }
  assert {
    condition     = length(output.associated_aks_subnet_ids) == 4 && toset(output.associated_aks_subnet_ids) == toset(concat([for subnet in var.pprd.aks_subnets : subnet.id], [for subnet in var.prd.aks_subnets : subnet.id])) && alltrue([for name, association in azurerm_subnet_route_table_association.pprd_aks : association.route_table_id == azurerm_route_table.pprd[name].id]) && alltrue([for name, association in azurerm_subnet_route_table_association.prd_aks : association.route_table_id == azurerm_route_table.prd[name].id])
    error_message = "Attachment must target each AKS subnet's own table, never Application Gateway, private endpoints, services or firewall subnets."
  }
  assert {
    condition     = output.firewall_private_ip == "10.80.1.5" && alltrue(flatten([for table in concat(values(azurerm_route_table.pprd), values(azurerm_route_table.prd)) : [for route in table.route : route.next_hop_in_ip_address == "10.80.1.5"]]))
    error_message = "Every next hop must follow a changed computed firewall address rather than a hardcoded sample IP."
  }
}
