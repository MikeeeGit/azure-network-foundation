# Synthetic example; customize before a trusted plan.
location             = "uksouth"
location_abbreviated = "uks"
subscription         = "pprd"
environment          = "pprd"
environment_tags     = { Environment = "pprd", Region = "uks" }
vnet_ip_range        = "10.61.0.0/16"
dns_servers          = []
ddos_plan_id         = ""
subnets = [
  {
    name           = "web"
    address_prefix = "10.61.1.0/24"
    security_group = "nsg"
    endpoints      = []
  },
  {
    name           = "app"
    address_prefix = "10.61.2.0/24"
    security_group = "nsg"
    endpoints      = []
  },
  {
    name           = "data"
    address_prefix = "10.61.3.0/24"
    security_group = "nsg"
    endpoints      = []
  },
  {
    name           = "private-endpoints"
    address_prefix = "10.61.4.0/24"
    security_group = "nsg"
    endpoints      = []
  },
  {
    name           = "services"
    address_prefix = "10.61.5.0/24"
    security_group = "nsg"
    endpoints      = []
  },
  {
    name           = "management"
    address_prefix = "10.61.6.0/24"
    security_group = "nsg"
    endpoints      = []
  },
  {
    name           = "integration"
    address_prefix = "10.61.7.0/24"
    security_group = "nsg"
    endpoints      = []
  }
]
dns                     = []
private_dns             = []
private_dns_zones       = []
private_endpoints       = []
link_endpoint_dns_zones = false

# Apply all five networks once with this false. Then enable and apply their peerings.
# Update EVERY backend below to match your chosen delivery.azure.json values.
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
    allow_gateway_transit      = false
    create_reverse_hub_peering = false
  }
}
