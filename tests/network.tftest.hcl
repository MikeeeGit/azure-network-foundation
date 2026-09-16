# These are provider-mocked plans. They never contact Azure or remote state.
mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
  }
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

variables {
  location             = "uksouth"
  location_abbreviated = "uks"
  environment          = "pprd"
  subscription         = "pprd"
  primary_region       = "uks"
  secondary_region     = "ukw"
  subscription_id_map = {
    hub  = "00000000-0000-0000-0000-000000000002"
    pprd = "00000000-0000-0000-0000-000000000003"
    prd  = "00000000-0000-0000-0000-000000000004"
  }
  vnet_ip_range    = "10.61.0.0/16"
  global_tags      = { ManagedBy = "Terraform", Owner = "platform-team@example.com" }
  environment_tags = { Environment = "pprd", Owner = "environment-team@example.com" }
  subnets = [{
    name           = "web"
    address_prefix = "10.61.1.0/24"
    security_group = "nsg"
    endpoints      = []
  }]
}

run "bootstrap_preserves_names_csv_and_two_resource_groups" {
  command = plan

  variables {
    remote_networks = {
      hub = {
        backend = {
          subscription_id      = "00000000-0000-0000-0000-000000000002"
          resource_group_name  = "not-created-yet"
          storage_account_name = "examplestatenotcreated"
          container_name       = "tfstate"
          key                  = "missing.tfstate"
        }
      }
    }
  }

  assert {
    condition     = azurerm_resource_group.network.name == "uks-pprd-netw-rg-01" && azurerm_resource_group.vnet.name == "uks-pprd-vnet-rg-01"
    error_message = "Preserve both original resource-group roles and convention-derived names."
  }
  assert {
    condition     = output.vnet.name == "uks-pprd-vnet-01" && output.subnets["web"].name == "uks-pprd-web"
    error_message = "The direct module calls must preserve VNet naming and logical subnet keys."
  }
  assert {
    condition     = azurerm_resource_group.vnet.tags["Owner"] == "environment-team@example.com"
    error_message = "Environment tags must override global tags."
  }
  assert {
    condition     = length(data.terraform_remote_state.networks) == 0 && length(azurerm_virtual_network_peering.peers) == 0
    error_message = "Bootstrap must not read missing remote states or create peerings."
  }
  assert {
    condition     = endswith(output.subnets_file_paths["web"], "config/uks/pprd/pprd_web_nsg.csv")
    error_message = "The deployment root must retain the region/environment CSV discovery contract."
  }
}

run "explicit_topology_reads_only_enabled_peers" {
  command = plan
  variables {
    enable_peerings = true
    remote_networks = {
      hub = {
        backend = {
          subscription_id      = "00000000-0000-0000-0000-000000000002"
          resource_group_name  = "example-backend"
          storage_account_name = "examplestate"
          container_name       = "tfstate"
          key                  = "azure-network-foundation-hub-uks.tfstate"
        }
      }
    }
  }
  override_data {
    target = data.terraform_remote_state.networks["hub"]
    values = {
      outputs = {
        vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/uks-hub-vnet-01"
        vnet = {
          name                = "uks-hub-vnet-01"
          address_space       = ["10.60.0.0/16"]
          resource_group_name = "uks-hub-vnet-rg-01"
        }
      }
    }
  }
  assert {
    condition     = length(azurerm_virtual_network_peering.peers) == 1 && azurerm_virtual_network_peering.peers["hub"].allow_forwarded_traffic
    error_message = "The explicit topology must preserve forwarded traffic and create its configured local side."
  }
  assert {
    condition     = azurerm_virtual_network_peering.peers["hub"].triggers["remote_address_space"] == sha256(jsonencode(["10.60.0.0/16"]))
    error_message = "Remote address-space changes must trigger peering synchronization."
  }
  assert {
    condition     = length(azurerm_virtual_network_peering.reverse_hub) == 0
    error_message = "Reciprocal ownership must be explicit."
  }
}

run "central_private_endpoint_dns_with_optional_spoke_link" {
  command = plan
  variables {
    link_endpoint_dns_zones = true
    private_endpoints = [{
      name                  = "web-storage"
      resource_id           = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example/providers/Microsoft.Storage/storageAccounts/examplestorage"
      service_connection    = "blob"
      private_dns_zone_name = "privatelink.blob.core.windows.net"
      subnet_name           = "web"
    }]
  }
  assert {
    condition     = data.azurerm_private_dns_zone.endpoints["web-storage"].resource_group_name == "uks-hub-vnet-rg-01"
    error_message = "Endpoint DNS must remain centrally owned in the hub resource group."
  }
  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.endpoint_spoke) == 1
    error_message = "The opt-in DNS resolution path must link the spoke to its central zone."
  }
}

run "premium_acr_preserves_optional_georeplication" {
  command = plan
  variables {
    acr_config = {
      enabled                  = true
      name                     = "examplefoundationregistry"
      sku                      = "Premium"
      admin_enabled            = false
      georeplication_locations = ["ukwest"]
    }
  }
  assert {
    condition     = length(azurerm_container_registry.acr[0].georeplications) == 1 && !azurerm_container_registry.acr[0].admin_enabled
    error_message = "Configured Premium georeplication must reach the optional registry resource."
  }
}

run "rejects_georeplication_without_premium" {
  command = plan
  variables {
    acr_config = {
      enabled                  = true
      name                     = "examplefoundationregistry"
      sku                      = "Standard"
      admin_enabled            = false
      georeplication_locations = ["ukwest"]
    }
  }
  expect_failures = [var.acr_config]
}

run "rejects_unknown_endpoint_subnet" {
  command = plan
  variables {
    private_endpoints = [{
      name                  = "bad-subnet"
      resource_id           = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example/providers/Microsoft.Storage/storageAccounts/examplestorage"
      service_connection    = "blob"
      private_dns_zone_name = "privatelink.blob.core.windows.net"
      subnet_name           = "missing"
    }]
  }
  expect_failures = [var.private_endpoints]
}

run "preserves_prefix_inside_logical_subnet_key" {
  command = plan
  variables {
    subnets = [{
      name           = "uks-pprd-web"
      address_prefix = "10.61.1.0/24"
      security_group = ""
      endpoints      = []
    }]
    private_endpoints = [{
      name                  = "prefixed-key-storage"
      resource_id           = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example/providers/Microsoft.Storage/storageAccounts/examplestorage"
      service_connection    = "blob"
      private_dns_zone_name = "privatelink.blob.core.windows.net"
      subnet_name           = "uks-pprd-web"
    }]
  }
  assert {
    condition     = contains(keys(output.subnet_name_to_id), "uks-pprd-web") && length(azurerm_private_endpoint.endpoints) == 1
    error_message = "Logical subnet keys must not be rewritten merely because they contain the naming prefix."
  }
}

run "forwards_explicit_subnet_network_policy" {
  command = plan
  variables {
    subnets = [{
      name                              = "web"
      address_prefix                    = "10.61.1.0/24"
      security_group                    = "nsg"
      endpoints                         = []
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Enabled"
    }]
  }
  assert {
    condition     = !output.subnets["web"].default_outbound_access_enabled && output.subnets["web"].private_endpoint_network_policies == "Enabled"
    error_message = "Explicit subnet egress and private-endpoint policies must survive the root input schema."
  }
}

run "hub_can_create_zone_and_endpoint_in_one_plan" {
  command = plan
  variables {
    environment       = "hub"
    subscription      = "hub"
    vnet_ip_range     = "10.60.0.0/16"
    private_dns_zones = ["privatelink.blob.core.windows.net"]
    subnets = [{
      name           = "shared"
      address_prefix = "10.60.3.0/24"
      security_group = "nsg"
      endpoints      = []
    }]
    private_endpoints = [{
      name                  = "hub-storage"
      resource_id           = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example/providers/Microsoft.Storage/storageAccounts/examplestorage"
      service_connection    = "blob"
      private_dns_zone_name = "privatelink.blob.core.windows.net"
      subnet_name           = "shared"
    }]
  }
  assert {
    condition     = length(data.azurerm_private_dns_zone.endpoints) == 0 && output.private_dns_zone_ids["hub-storage"] == module.vnet.private_dns_zone_ids["privatelink.blob.core.windows.net"]
    error_message = "A hub-owned zone must be consumed through the module dependency, without an early external lookup."
  }
}

run "rejects_subscription_map_drift_from_delivery_configuration" {
  command = plan
  variables {
    subscription_id_map = {
      hub  = "00000000-0000-0000-0000-000000000002"
      pprd = "00000000-0000-0000-0000-000000000099"
      prd  = "00000000-0000-0000-0000-000000000004"
    }
  }
  expect_failures = [var.subscription_id_map]
}
