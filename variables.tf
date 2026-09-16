variable "name" {
  description = "Exact name for the virtual network."
  type        = string
}
variable "resource_group_name" {
  description = "Name of the resource group created by this deployment."
  type        = string
}
variable "location" {
  description = "Azure region for network resources."
  type        = string
}
variable "address_space" {
  description = "Virtual network CIDR ranges."
  type        = list(string)
}
variable "dns_servers" {
  description = "Custom DNS server IPs; empty uses Azure-provided DNS."
  type        = list(string)
  default     = []
}
variable "tags" {
  description = "Tags applied to resources supporting tags."
  type        = map(string)
  default     = {}
}
variable "ddos_protection_plan_id" {
  description = "Existing DDoS plan ID, or null to omit association."
  type        = string
  default     = null
}
variable "log_analytics_workspace_id" {
  description = "Existing workspace ID, or null to omit VNet diagnostic settings."
  type        = string
  default     = null
}
variable "subnets" {
  description = "Subnets keyed by exact Azure names. Rules and routes are explicit typed values."
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(set(string), [])
    default_outbound_access_enabled   = optional(bool, false)
    private_endpoint_network_policies = optional(string, "Disabled")
    network_security_group = optional(object({
      name = string
      rules = optional(map(object({
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = optional(string, "*")
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = optional(string, "*")
        description                = optional(string)
      })), {})
    }))
    route_table = optional(object({
      name                          = string
      bgp_route_propagation_enabled = optional(bool, true)
      routes = optional(map(object({
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string)
      })), {})
    }))
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }))
  }))
  default  = {}
  nullable = false
}
variable "private_dns_zones" {
  description = "Private DNS zones to create and link to this VNet with auto-registration disabled."
  type        = set(string)
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for zone in var.private_dns_zones : can(regex("^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$", zone)) && length(split(".", zone)) > 1])
    error_message = "Each private DNS zone must be a domain name with at least two labels."
  }
}
variable "peerings" {
  description = "Local-side peerings keyed by peering name. Remote-side peering is separately managed."
  type = map(object({
    remote_virtual_network_id    = string
    triggers                     = optional(map(string), {})
    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
  }))
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for p in values(var.peerings) : can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", p.remote_virtual_network_id)) && !(p.allow_gateway_transit && p.use_remote_gateways)])
    error_message = "Peerings require a VNet resource ID and cannot both offer and use gateway transit."
  }
  validation {
    condition     = length([for p in values(var.peerings) : p if p.use_remote_gateways]) <= 1
    error_message = "Only one peering can use a remote gateway."
  }
}
variable "private_endpoints" {
  description = "Private endpoints into an owned subnet; optional zone names must appear in private_dns_zones."
  type = map(object({
    subnet_name            = string
    target_resource_id     = string
    subresource_names      = list(string)
    private_dns_zone_names = optional(set(string), [])
    is_manual_connection   = optional(bool, false)
    request_message        = optional(string)
  }))
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for ep in values(var.private_endpoints) : ep.request_message == null ? true : ep.is_manual_connection && length(ep.request_message) <= 140])
    error_message = "Request messages are for manual connections only and must be at most 140 characters."
  }
  validation {
    condition     = alltrue([for ep in values(var.private_endpoints) : try(var.subnets[ep.subnet_name].delegation == null, false)])
    error_message = "Private endpoints require a non-delegated subnet."
  }
  validation {
    condition     = alltrue([for ep in values(var.private_endpoints) : contains(keys(var.subnets), ep.subnet_name)])
    error_message = "Every private endpoint must reference a subnet defined in subnets."
  }
  validation {
    condition     = alltrue([for ep in values(var.private_endpoints) : length(setsubtract(ep.private_dns_zone_names, var.private_dns_zones)) == 0])
    error_message = "Private endpoint DNS zones must be created by this module."
  }
  validation {
    condition     = alltrue([for ep in values(var.private_endpoints) : length(ep.subresource_names) > 0 && alltrue([for name in ep.subresource_names : trimspace(name) != ""]) && can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/.+$", ep.target_resource_id))])
    error_message = "Private endpoints require an Azure resource ID and nonempty service subresource names."
  }
}
