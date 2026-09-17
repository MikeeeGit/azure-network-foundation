variable "location" {
  description = "Azure region where resources will be deployed (e.g., uksouth, ukwest)."
  type        = string
}

variable "location_abbreviated" {
  description = "Shortened name for the Azure region (e.g., uks for uksouth)."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.location_abbreviated))
    error_message = "Use a lowercase region code such as uks or ukw."
  }
}

variable "company_abbreviation" {
  description = "Abbreviation for the company name to be used in resource naming."
  type        = string
  default     = ""
}

variable "dns_zone_name" {
  description = "Name of the DNS zone to be used in the environment."
  type        = string
  default     = ""
}

variable "ddos_plan_id" {
  description = "The ID of the DDoS Protection Plan to attach to the Virtual Network (VNet)."
  type        = string
  default     = ""
}

variable "subscription_id_map" {
  description = "Mapping of subscription aliases to subscription IDs (e.g., hub, pprd, prd)."
  type        = map(string)

  validation {
    condition     = contains(keys(var.subscription_id_map), "hub") && contains(keys(var.subscription_id_map), var.subscription)
    error_message = "subscription_id_map must include hub and the selected subscription alias."
  }
  validation {
    condition     = alltrue([for id in values(var.subscription_id_map) : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])
    error_message = "Subscription IDs must be UUIDs. Replace the synthetic example IDs before deployment."
  }
  validation {
    condition     = alltrue([for alias, id in var.subscription_id_map : try(lower(jsondecode(file("${path.root}/delivery.azure.json")).subscriptions[alias]) == lower(id), false)])
    error_message = "subscription_id_map must match the subscriptions in delivery.azure.json. Update both together to prevent helper/provider target drift."
  }
}

variable "subscription" {
  description = "Subscription alias selected for this environment in delivery.azure.json."
  type        = string
  validation {
    condition     = try(jsondecode(file("${path.root}/delivery.azure.json")).environments[var.environment].subscription_alias == var.subscription, false)
    error_message = "subscription must match the environment subscription_alias in delivery.azure.json."
  }
}

variable "environment" {
  description = "Environment name (e.g., hub, nprd, dev, test, prd)."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,19}$", var.environment))
    error_message = "Use a lowercase environment name with letters, digits and hyphens."
  }
}

variable "global_tags" {
  description = "Global tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "environment_tags" {
  description = "Environment-specific tags applied to resources."
  type        = map(string)
  default     = {}
}

variable "environment_number" {
  description = "Compatibility metadata; existing resource names retain the fixed 01 suffix."
  type        = string
  default     = "01"
}

variable "private_dns_zones" {
  description = "Additional empty private DNS zones. Use private_dns for zones with records."
  type        = list(string)
  default     = []
}

variable "diag_log_workspace" {
  description = "Log Analytics workspace resource ID. Null disables VNet diagnostics; no workspace is created by this stack."
  type        = string
  default     = null
}

variable "backend_container_suffix" {
  description = "Suffix used by remote-state containers for hub/spoke peering state lookups."
  type        = string
  default     = "azdo-tfstate"
}

variable "remote_state_container_suffix_map" {
  description = "Optional per-backend override for remote-state container suffixes."
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "List of subnets to be created within the Virtual Network (VNet)."
  type = list(object({
    name                                          = string
    address_prefix                                = string
    security_group                                = string
    endpoints                                     = list(string)
    default_outbound_access_enabled               = optional(bool)
    private_endpoint_network_policies             = optional(string)
    private_link_service_network_policies_enabled = optional(bool)
    service_endpoint_policy_ids                   = optional(list(string), [])
    bgp_route_propagation_enabled                 = optional(bool, true)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }))
  }))
}

variable "dns" {
  description = "DNS configuration for multiple zones, each with multiple records."
  type = list(object({
    zone_name = string
    a_records = list(object({
      name = string
      ip   = string
    }))
    cname_records = list(object({
      name   = string
      target = string
    }))
    mx_records = list(object({
      preference = number
      exchange   = string
    }))
  }))
  default = []
}

variable "private_dns" {
  description = "Private DNS configuration for multiple zones, each with multiple records."
  type = list(object({
    zone_name = string
    a_records = list(object({
      name = string
      ip   = string
    }))
    cname_records = list(object({
      name   = string
      target = string
    }))
    mx_records = list(object({
      preference = number
      exchange   = string
    }))
  }))
  default = []
}

variable "azvdc_network" {
  description = "Compatibility metadata for firewall/custom DNS configuration; resources do not consume this map."
  type = map(object({
    azfw_nic           = string
    custom_dns_servers = list(string)
  }))
  default = {}
}

variable "vnet_ip_range" {
  description = "CIDR block for the Virtual Network (VNet) IP range."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.vnet_ip_range))
    error_message = "vnet_ip_range must be a valid IPv4 CIDR block."
  }
}

variable "dns_servers" {
  description = "List of IP addresses for DNS servers to be used within the VNet."
  type        = list(string)
  default     = []
}

variable "secondary_region" {
  description = "Short region code for the secondary region and shared backend location (for example ukw)."
  type        = string
}

variable "primary_region" {
  description = "Short region code for the primary deployment region (for example uks)."
  type        = string
}

variable "acr_config" {
  description = "Configuration for Azure Container Registry (ACR)."
  type = object({
    enabled                  = bool
    name                     = string
    sku                      = string
    admin_enabled            = bool
    georeplication_locations = optional(list(string), []) # Only used when SKU is Premium
  })
  default = {
    enabled                  = false
    name                     = ""
    sku                      = "Standard"
    admin_enabled            = false
    georeplication_locations = []
  }
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_config.sku)
    error_message = "ACR SKU must be Basic, Standard or Premium."
  }
  validation {
    condition     = length(var.acr_config.georeplication_locations) == 0 || var.acr_config.sku == "Premium"
    error_message = "ACR georeplication requires Premium SKU."
  }
  validation {
    condition     = !var.acr_config.enabled || can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_config.name))
    error_message = "An enabled ACR requires a globally unique, 5-50 character alphanumeric name."
  }
}

variable "private_endpoints" {
  description = "List of private endpoints to be created in the VNet."
  type = list(object({
    name                  = string
    resource_id           = string
    service_connection    = string
    private_dns_zone_name = string
    subnet_name           = string
  }))
  default = []
  validation {
    condition     = length(distinct([for endpoint in var.private_endpoints : endpoint.name])) == length(var.private_endpoints)
    error_message = "Private endpoint names must be unique."
  }
  validation {
    condition     = alltrue([for endpoint in var.private_endpoints : contains([for subnet in var.subnets : subnet.name], endpoint.subnet_name)])
    error_message = "Each private endpoint must reference a logical name from subnets."
  }
}
