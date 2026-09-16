variable "enable_peerings" {
  description = "Enable remote-state reads and peerings after every referenced network has state. False supports an empty-estate first deployment."
  type        = bool
  default     = false
}

variable "remote_networks" {
  description = "Explicit topology map. Each entry identifies another stack's backend and local peering settings. Configure reciprocal spoke sides in that stack."
  type = map(object({
    backend = object({
      subscription_id      = string
      resource_group_name  = string
      storage_account_name = string
      container_name       = string
      key                  = string
    })
    name                          = optional(string)
    allow_virtual_network_access  = optional(bool, true)
    allow_forwarded_traffic       = optional(bool, true)
    allow_gateway_transit         = optional(bool, false)
    use_remote_gateways           = optional(bool, false)
    create_reverse_hub_peering    = optional(bool, false)
    reverse_name                  = optional(string)
    reverse_allow_gateway_transit = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for peer in values(var.remote_networks) : !(peer.allow_gateway_transit && peer.use_remote_gateways)])
    error_message = "A local peering cannot both provide gateway transit and use a remote gateway."
  }
  validation {
    condition     = length([for peer in values(var.remote_networks) : peer if peer.use_remote_gateways]) <= 1
    error_message = "A VNet can use a remote gateway through at most one configured peering."
  }
}

variable "hub_dns_resource_group_name" {
  description = "Override the central DNS resource group. Null retains <region>-hub-vnet-rg-01."
  type        = string
  default     = null
}

variable "link_endpoint_dns_zones" {
  description = "Create spoke VNet links in central endpoint DNS zones. Requires hub permissions; false assumes existing links or resolver forwarding."
  type        = bool
  default     = false
}
