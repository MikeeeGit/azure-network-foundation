mock_provider "azurerm" {
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example/subnets/application"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/networkSecurityGroups/nsg-example"
    }
  }
  mock_resource "azurerm_route_table" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/routeTables/rt-example"
    }
  }
  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
  }
}
variables {
  name                = "vnet-example"
  resource_group_name = "rg-example"
  location            = "uksouth"
  address_space       = ["10.40.0.0/16"]
  subnets = {
    application = {
      address_prefixes = ["10.40.1.0/24"]
      network_security_group = {
        name = "nsg-example"
        rules = {
          allow-https = {
            priority               = 100
            direction              = "Inbound"
            access                 = "Allow"
            protocol               = "Tcp"
            source_address_prefix  = "10.40.0.0/16"
            destination_port_range = "443"
          }
        }
      }
      route_table = {
        name = "rt-example"
        routes = {
          deny-internet = { address_prefix = "0.0.0.0/0", next_hop_type = "None" }
        }
      }
    }
  }
  private_dns_zones = ["privatelink.blob.core.windows.net"]
  private_endpoints = {
    pe-example = {
      subnet_name            = "application"
      target_resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.Storage/storageAccounts/example"
      subresource_names      = ["blob"]
      private_dns_zone_names = ["privatelink.blob.core.windows.net"]
      is_manual_connection   = true
      request_message        = "Synthetic test request"
    }
  }
}
run "composes_real_child_modules_with_mocked_azure" {
  command = apply
  assert {
    condition     = length(output.subnet_ids) == 1 && contains(keys(output.subnet_ids), "application")
    error_message = "The real child-module wiring must expose the named subnet."
  }
  assert {
    condition     = length(output.private_dns_zone_ids) == 1 && length(output.private_endpoint_ids) == 1
    error_message = "The actual module composition must create the requested DNS and endpoint resources."
  }
}
