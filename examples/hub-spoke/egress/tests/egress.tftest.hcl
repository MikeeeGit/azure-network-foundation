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

run "prepare_tables_before_attachment" {
  command = plan
  assert {
    condition     = length(azurerm_route_table.pprd) == 2 && length(azurerm_route_table.prd) == 2 && length(azurerm_subnet_route_table_association.pprd_aks) == 0 && length(azurerm_subnet_route_table_association.prd_aks) == 0
    error_message = "Prepare four AKS route tables before explicitly enabling association."
  }
  assert {
    condition     = output.firewall_private_ip == "10.80.1.4" && alltrue(flatten([for table in concat(values(azurerm_route_table.pprd), values(azurerm_route_table.prd)) : [for route in table.route : route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == output.firewall_private_ip]])) && alltrue([for table in values(azurerm_route_table.pprd) : toset([for route in table.route : route.address_prefix]) == toset(["0.0.0.0/0", "10.82.0.0/16"])]) && alltrue([for table in values(azurerm_route_table.prd) : toset([for route in table.route : route.address_prefix]) == toset(["0.0.0.0/0", "10.81.0.0/16"])])
    error_message = "Default/opposite-spoke routes must follow the actual firewall read from Azure."
  }
}
run "attach_only_aks_subnets" {
  command = apply
  variables { enable_aks_routes = true }
  assert {
    condition     = length(output.associated_aks_subnet_ids) == 4 && toset(output.associated_aks_subnet_ids) == toset(concat([for subnet in var.pprd.aks_subnets : subnet.id], [for subnet in var.prd.aks_subnets : subnet.id])) && alltrue([for name, association in azurerm_subnet_route_table_association.pprd_aks : association.route_table_id == azurerm_route_table.pprd[name].id]) && alltrue([for name, association in azurerm_subnet_route_table_association.prd_aks : association.route_table_id == azurerm_route_table.prd[name].id])
    error_message = "Attach each AKS subnet's own table and leave all other subnets untouched."
  }
}
run "reject_wrong_resource_type" {
  command = plan
  variables {
    firewall_id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/virtualNetworks/example-vnet"
  }
  expect_failures = [var.firewall_id]
}
run "reject_virtual_hub_firewall" {
  command = plan
  override_data {
    target = data.azurerm_firewall.egress
    values = { sku_name = "AZFW_Hub" }
  }
  expect_failures = [data.azurerm_firewall.egress]
}
run "reject_application_gateway_masquerading_as_aks" {
  command = plan
  variables {
    pprd = {
      subscription_id     = "00000000-0000-0000-0000-000000000003"
      resource_group_name = "example-pprd-rg"
      vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example-pprd-rg/providers/Microsoft.Network/virtualNetworks/example-pprd-vnet"
      address_space       = ["10.81.0.0/16"]
      aks_subnets = {
        aks01 = { id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example-pprd-rg/providers/Microsoft.Network/virtualNetworks/example-pprd-vnet/subnets/example-appgateway", address_prefix = "10.81.8.0/24" }
        aks02 = { id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example-pprd-rg/providers/Microsoft.Network/virtualNetworks/example-pprd-vnet/subnets/example-pprd-aks02", address_prefix = "10.81.4.0/22" }
      }
    }
  }
  expect_failures = [var.pprd]
}

run "reject_unreviewed_tenant" {
  command = plan
  variables { tenant_id = "00000000-0000-0000-0000-000000000099" }
  expect_failures = [terraform_data.delivery_contract]
}
run "reject_mismatched_region" {
  command = plan
  variables { location = "ukwest" }
  expect_failures = [terraform_data.delivery_contract]
}
