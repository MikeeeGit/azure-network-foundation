# Synthetic complete hub/spoke scenario. Deploy hub first, then both spokes.
location                   = "uksouth"
location_abbreviated       = "uks"
subscription               = "pprd"
environment                = "pprd"
environment_tags           = { Environment = "pprd", Scenario = "hub-spoke" }
vnet_ip_range              = "10.81.0.0/16"
dns_servers                = []
private_dns_zones          = []
hub_private_dns_zone_names = ["internal.example", "privatelink.uksouth.azmk8s.io", "privatelink.vaultcore.azure.net", "privatelink.azurecr.io", "privatelink.blob.core.windows.net"]
subnets = [
  { name = "aks01", address_prefix = "10.81.0.0/22", security_group = "nsg", endpoints = [] },
  { name = "aks02", address_prefix = "10.81.4.0/22", security_group = "nsg", endpoints = [] },
  { name = "appgateway", address_prefix = "10.81.8.0/24", security_group = "nsg", endpoints = [] },
  { name = "private-endpoints", address_prefix = "10.81.9.0/24", security_group = "nsg", endpoints = [] },
  { name = "services", address_prefix = "10.81.10.0/24", security_group = "nsg", endpoints = [] },
]

# Enable only after all three network states exist.
enable_peerings = false
remote_networks = {
  hub = {
    backend = {
      subscription_id      = "00000000-0000-0000-0000-000000000002"
      resource_group_name  = "ukw-hub-tfstate-rsg"
      storage_account_name = "ukwhubexampletfstatesa"
      container_name       = "ukw-hub-azdo-tfstate"
      key                  = "azure-network-foundation-hub-uks.tfstate"
    }
    allow_gateway_transit   = false
    use_remote_gateways     = false
    allow_forwarded_traffic = true
  }
}
