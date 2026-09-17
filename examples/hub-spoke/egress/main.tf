locals {
  aks_prefixes        = concat([for subnet in var.pprd.aks_subnets : subnet.address_prefix], [for subnet in var.prd.aks_subnets : subnet.address_prefix])
  firewall_private_ip = one(azurerm_firewall.egress.ip_configuration).private_ip_address
}
resource "azurerm_public_ip" "firewall" {
  provider            = azurerm.hub
  name                = "${var.name_prefix}-pip"
  location            = var.location
  resource_group_name = var.hub.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}
resource "azurerm_firewall_policy" "egress" {
  provider                 = azurerm.hub
  name                     = "${var.name_prefix}-policy"
  location                 = var.location
  resource_group_name      = var.hub.resource_group_name
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"
  dns { proxy_enabled = true }
  tags = var.tags
}
resource "azurerm_firewall" "egress" {
  provider            = azurerm.hub
  name                = "${var.name_prefix}-fw"
  location            = var.location
  resource_group_name = var.hub.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.egress.id
  ip_configuration {
    name                 = "primary"
    subnet_id            = var.hub.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
  tags = var.tags
}
resource "azurerm_firewall_policy_rule_collection_group" "aks" {
  provider           = azurerm.hub
  name               = "aks-egress"
  firewall_policy_id = azurerm_firewall_policy.egress.id
  priority           = 100
  application_rule_collection {
    name     = "aks-platform"
    priority = 200
    action   = "Allow"
    rule {
      name                  = "aks-required-endpoints"
      source_addresses      = local.aks_prefixes
      destination_fqdn_tags = ["AzureKubernetesService"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
    dynamic "rule" {
      for_each = length(var.additional_registry_fqdns) > 0 ? [1] : []
      content {
        name              = "explicit-additional-registries"
        source_addresses  = local.aks_prefixes
        destination_fqdns = sort(tolist(var.additional_registry_fqdns))
        protocols {
          type = "Https"
          port = 443
        }
      }
    }
  }
  dynamic "network_rule_collection" {
    for_each = var.allow_legacy_ntp || var.allow_cross_spoke_https ? [1] : []
    content {
      name     = "explicit-optional-network-rules"
      priority = 100
      action   = "Allow"
      dynamic "rule" {
        for_each = var.allow_legacy_ntp ? [1] : []
        content {
          name              = "legacy-time"
          protocols         = ["UDP"]
          source_addresses  = local.aks_prefixes
          destination_fqdns = ["ntp.ubuntu.com"]
          destination_ports = ["123"]
        }
      }
      dynamic "rule" {
        for_each = var.allow_cross_spoke_https ? {
          pprd-to-prd = { sources = [for subnet in var.pprd.aks_subnets : subnet.address_prefix], destinations = [for subnet in var.prd.aks_subnets : subnet.address_prefix] }
          prd-to-pprd = { sources = [for subnet in var.prd.aks_subnets : subnet.address_prefix], destinations = [for subnet in var.pprd.aks_subnets : subnet.address_prefix] }
        } : {}
        content {
          name                  = rule.key
          protocols             = ["TCP"]
          source_addresses      = rule.value.sources
          destination_addresses = rule.value.destinations
          destination_ports     = ["443"]
        }
      }
    }
  }
}
