# Synthetic example; customize before a trusted plan.
location             = "ukwest"
location_abbreviated = "ukw"
subscription         = "hub"
environment          = "hub"
environment_tags     = { Environment = "hub", Region = "ukw" }
vnet_ip_range        = "10.70.0.0/16"
dns_servers          = []
ddos_plan_id         = ""
subnets = [
  {
    name           = "GatewaySubnet"
    address_prefix = "10.70.1.0/24"
    security_group = ""
    endpoints      = []
  },
  {
    name           = "AzureFirewallSubnet"
    address_prefix = "10.70.2.0/24"
    security_group = ""
    endpoints      = []
  },
  {
    name           = "shared"
    address_prefix = "10.70.3.0/24"
    security_group = "nsg"
    endpoints      = []
  }
]
dns                     = []
private_dns             = []
private_dns_zones       = ["privatelink.blob.core.windows.net", "privatelink.file.core.windows.net", "privatelink.vaultcore.azure.net", "privatelink.azurewebsites.net", "privatelink.database.windows.net"]
private_endpoints       = []
link_endpoint_dns_zones = false

# Apply all five networks once with this false. Then enable and apply their peerings.
# Update EVERY backend below to match your chosen delivery.azure.json values.
enable_peerings = false
remote_networks = {
  bcdr = {
    backend = {
      subscription_id      = "00000000-0000-0000-0000-000000000002"
      resource_group_name  = "ukw-prd-tfstate-rsg"
      storage_account_name = "ukwprdexampletfstatesa"
      container_name       = "ukw-prd-azdo-tfstate"
      key                  = "azure-network-foundation-bcdr-ukw.tfstate"
    }
    allow_gateway_transit      = true
    create_reverse_hub_peering = false
  }
  primary-hub = {
    backend = {
      subscription_id      = "00000000-0000-0000-0000-000000000002"
      resource_group_name  = "ukw-hub-tfstate-rsg"
      storage_account_name = "ukwhubexampletfstatesa"
      container_name       = "ukw-hub-azdo-tfstate"
      key                  = "azure-network-foundation-hub-uks.tfstate"
    }
    allow_gateway_transit      = false
    create_reverse_hub_peering = true
  }
}
