# Synthetic complete hub/spoke scenario. Deploy hub first, then both spokes.
location                   = "uksouth"
location_abbreviated       = "uks"
subscription               = "hub"
environment                = "hub"
environment_tags           = { Environment = "hub", Scenario = "hub-spoke" }
vnet_ip_range              = "10.80.0.0/16"
dns_servers                = []
private_dns_zones          = ["internal.example", "privatelink.uksouth.azmk8s.io", "privatelink.vaultcore.azure.net", "privatelink.azurecr.io", "privatelink.blob.core.windows.net"]
hub_private_dns_zone_names = []
subnets = [
  { name = "GatewaySubnet", address_prefix = "10.80.0.0/24", security_group = "", endpoints = [] },
  { name = "AzureFirewallSubnet", address_prefix = "10.80.1.0/26", security_group = "", endpoints = [] },
  { name = "shared", address_prefix = "10.80.2.0/24", security_group = "nsg", endpoints = [] },
]

# Enable only after all three network states exist.
enable_peerings = false
remote_networks = {
  pprd = {
    backend = {
      subscription_id      = "00000000-0000-0000-0000-000000000002"
      resource_group_name  = "ukw-pprd-tfstate-rsg"
      storage_account_name = "ukwpprdexampletfstatesa"
      container_name       = "ukw-pprd-azdo-tfstate"
      key                  = "azure-network-foundation-pprd-uks.tfstate"
    }
    allow_gateway_transit   = false
    use_remote_gateways     = false
    allow_forwarded_traffic = true
  }
  prd = {
    backend = {
      subscription_id      = "00000000-0000-0000-0000-000000000002"
      resource_group_name  = "ukw-prd-tfstate-rsg"
      storage_account_name = "ukwprdexampletfstatesa"
      container_name       = "ukw-prd-azdo-tfstate"
      key                  = "azure-network-foundation-prd-uks.tfstate"
    }
    allow_gateway_transit   = false
    use_remote_gateways     = false
    allow_forwarded_traffic = true
  }
}

# Shared sample image registry; replace this globally unique name before deployment.
# Standard uses authenticated public endpoints. Private-link registry designs need Premium.
acr_config = {
  enabled       = true
  name          = "exampleplatformacr"
  sku           = "Standard"
  admin_enabled = false
}
