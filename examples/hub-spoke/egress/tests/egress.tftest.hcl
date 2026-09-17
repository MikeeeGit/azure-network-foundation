mock_provider "azurerm" {
  alias = "hub"
  mock_resource "azurerm_public_ip" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/publicIPAddresses/example-pip" } }
  mock_resource "azurerm_firewall_policy" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/firewallPolicies/example-policy" } }
  mock_resource "azurerm_firewall" {
    defaults = { ip_configuration = { private_ip_address = "10.80.1.4" } }
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

run "firewall_first_without_route_attachment" {
  command = apply
  assert {
    condition     = azurerm_firewall.egress.sku_name == "AZFW_VNet" && azurerm_firewall.egress.sku_tier == "Standard" && azurerm_public_ip.firewall.sku == "Standard" && one(azurerm_firewall.egress.ip_configuration).subnet_id == var.hub.firewall_subnet_id && azurerm_firewall.egress.firewall_policy_id == azurerm_firewall_policy.egress.id && azurerm_firewall_policy.egress.dns[0].proxy_enabled
    error_message = "The example must create an actual Standard firewall with DNS proxy in the dedicated hub subnet."
  }
  assert {
    condition     = length(azurerm_subnet_route_table_association.pprd_aks) == 0 && length(azurerm_subnet_route_table_association.prd_aks) == 0 && length(output.associated_aks_subnet_ids) == 0 && length(azurerm_route_table.pprd) == 2 && length(azurerm_route_table.prd) == 2
    error_message = "First deployment must prepare four AKS route tables without attaching routes before the network prerequisites are ready."
  }
  assert {
    condition     = output.firewall_private_ip == "10.80.1.4" && alltrue(flatten([for table in concat(values(azurerm_route_table.pprd), values(azurerm_route_table.prd)) : [for route in table.route : route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == output.firewall_private_ip]])) && alltrue([for table in values(azurerm_route_table.pprd) : toset([for route in table.route : route.address_prefix]) == toset(["0.0.0.0/0", "10.82.0.0/16"])]) && alltrue([for table in values(azurerm_route_table.prd) : toset([for route in table.route : route.address_prefix]) == toset(["0.0.0.0/0", "10.81.0.0/16"])])
    error_message = "Default and opposite-spoke routes must use the firewall's actual computed private IP."
  }
  assert {
    condition     = length(azurerm_firewall_policy_rule_collection_group.aks.network_rule_collection) == 0 && length(azurerm_firewall_policy_rule_collection_group.aks.application_rule_collection[0].rule) == 1 && toset(azurerm_firewall_policy_rule_collection_group.aks.application_rule_collection[0].rule[0].source_addresses) == toset(["10.81.0.0/22", "10.81.4.0/22", "10.82.0.0/22", "10.82.4.0/22"]) && toset(azurerm_firewall_policy_rule_collection_group.aks.application_rule_collection[0].rule[0].destination_fqdn_tags) == toset(["AzureKubernetesService"])
    error_message = "Defaults must allow only AKS platform application rules from AKS ranges, without cross-spoke, legacy NTP or extra registry rules."
  }
}
run "explicit_optional_https_and_registry_policy" {
  command = plan
  variables {
    allow_cross_spoke_https   = true
    allow_legacy_ntp          = true
    additional_registry_fqdns = ["ghcr.io", "pkg-containers.githubusercontent.com"]
  }
  assert {
    condition     = length(azurerm_firewall_policy_rule_collection_group.aks.network_rule_collection[0].rule) == 3 && alltrue([for rule in azurerm_firewall_policy_rule_collection_group.aks.network_rule_collection[0].rule : !contains(rule.source_addresses, "*") && !contains(rule.destination_ports, "9000") && !contains(rule.destination_ports, "1194")]) && length([for rule in azurerm_firewall_policy_rule_collection_group.aks.network_rule_collection[0].rule : rule if rule.name == "pprd-to-prd" && toset(rule.destination_addresses) == toset(["10.82.0.0/22", "10.82.4.0/22"]) && toset(rule.destination_ports) == toset(["443"])]) == 1 && length([for rule in azurerm_firewall_policy_rule_collection_group.aks.network_rule_collection[0].rule : rule if rule.name == "prd-to-pprd" && toset(rule.destination_addresses) == toset(["10.81.0.0/22", "10.81.4.0/22"]) && toset(rule.destination_ports) == toset(["443"])]) == 1
    error_message = "Cross-spoke access must be reciprocal targeted HTTPS; legacy NTP must not introduce public AKS control-plane ports or wildcard sources."
  }
  assert {
    condition     = length([for rule in azurerm_firewall_policy_rule_collection_group.aks.application_rule_collection[0].rule : rule if rule.name == "explicit-additional-registries" && toset(rule.destination_fqdns) == toset(["ghcr.io", "pkg-containers.githubusercontent.com"]) && length(rule.protocols) == 1 && rule.protocols[0].type == "Https" && rule.protocols[0].port == 443]) == 1
    error_message = "Additional registries must be explicit HTTPS destinations, including caller-selected auth/CDN hosts."
  }
}
run "reject_unrestricted_registry_wildcard" {
  command = plan
  variables { additional_registry_fqdns = ["*"] }
  expect_failures = [var.additional_registry_fqdns]
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
run "reject_wrong_hub_subnet" {
  command = plan
  variables {
    hub = {
      subscription_id     = "00000000-0000-0000-0000-000000000002"
      resource_group_name = "example-hub-rg"
      firewall_subnet_id  = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-hub-rg/providers/Microsoft.Network/virtualNetworks/example-hub-vnet/subnets/GatewaySubnet"
    }
  }
  expect_failures = [var.hub]
}
