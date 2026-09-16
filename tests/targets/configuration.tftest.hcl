# These are provider-mocked plans. They never contact Azure or remote state.
mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/uks-pprd-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/uks-pprd-vnet-01"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/uks-pprd-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/uks-pprd-vnet-01/subnets/uks-pprd-web"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/uks-pprd-vnet-rg-01/providers/Microsoft.Network/networkSecurityGroups/uks-pprd-web-nsg"
    }
  }
  mock_resource "azurerm_route_table" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/uks-pprd-vnet-rg-01/providers/Microsoft.Network/routeTables/uks-pprd-web-rt"
    }
  }
}
mock_provider "azurerm" {
  alias           = "hub"
  override_during = plan

  mock_data "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
  }
}

# CI supplies the real global and selected environment tfvars to this test suite.
run "example_configuration" {
  command = plan

  assert {
    condition     = output.vnet.name == "${var.location_abbreviated}-${var.environment}-vnet-01"
    error_message = "The selected example must retain convention-derived VNet naming."
  }
  assert {
    condition     = length(output.vnet.address_space) == 1 && contains(output.vnet.address_space, var.vnet_ip_range)
    error_message = "The selected example's network range must reach the VNet module."
  }
  assert {
    condition     = length(output.subnets) == length(var.subnets) && length(output.subnets_file_paths) == length(var.subnets)
    error_message = "Every configured logical subnet must have an output and a CSV lookup path."
  }
  assert {
    condition     = !var.enable_peerings && length(data.terraform_remote_state.networks) == 0
    error_message = "Published examples must start in the backend-independent topology bootstrap phase."
  }
}
