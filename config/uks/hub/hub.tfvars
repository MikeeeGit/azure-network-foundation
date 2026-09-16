# Synthetic example; customize before a trusted plan.
location             = "uksouth"
location_abbreviated = "uks"
subscription         = "hub"
environment          = "hub"
environment_tags     = { Environment = "hub", Region = "uks" }
vnet_ip_range        = "10.60.0.0/16"
dns_servers          = []
ddos_plan_id         = ""
subnets = [
  {
    name           = "GatewaySubnet"
    address_prefix = "10.60.1.0/24"
    security_group = ""
    endpoints      = []
  },
  {
    name           = "AzureFirewallSubnet"
    address_prefix = "10.60.2.0/24"
    security_group = ""
    endpoints      = []
  },
  {
    name           = "shared"
    address_prefix = "10.60.3.0/24"
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
  pprd = {
    backend = {
      subscription_id      = "00000000-0000-0000-0000-000000000002"
      resource_group_name  = "ukw-pprd-tfstate-rsg"
      storage_account_name = "ukwpprdexampletfstatesa"
      container_name       = "ukw-pprd-azdo-tfstate"
      key                  = "azure-network-foundation-pprd-uks.tfstate"
    }
    allow_gateway_transit      = true
    create_reverse_hub_peering = false
  }
  prd = {
    backend = {
      subscription_id      = "00000000-0000-0000-0000-000000000002"
      resource_group_name  = "ukw-prd-tfstate-rsg"
      storage_account_name = "ukwprdexampletfstatesa"
      container_name       = "ukw-prd-azdo-tfstate"
      key                  = "azure-network-foundation-prd-uks.tfstate"
    }
    allow_gateway_transit      = true
    create_reverse_hub_peering = false
  }
}
