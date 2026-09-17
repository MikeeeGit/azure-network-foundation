variable "name_prefix" {
  description = "Prefix for resources owned by this separate egress state."
  type        = string
  default     = "example-aks-egress"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,39}$", var.name_prefix))
    error_message = "Use 3-40 lowercase letters, digits and hyphens, starting with a letter."
  }
}
variable "location" {
  description = "Azure region of the two existing spoke networks."
  type        = string
  default     = "uksouth"
}
variable "firewall_id" {
  description = "Applied azure-firewall output firewall_id. This stack reads the actual firewall; it never accepts a guessed next-hop IP."
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}/resourceGroups/[^/]+/providers/Microsoft.Network/azureFirewalls/[^/]+$", var.firewall_id))
    error_message = "Supply the full Azure Firewall resource ID from the applied firewall stack."
  }
}
variable "enable_aks_routes" {
  description = "Attach the four AKS subnet route tables only after hub/spoke peerings, firewall DNS and NSGs have been reviewed."
  type        = bool
  default     = false
}
variable "tags" {
  description = "Tags on resources created by this example."
  type        = map(string)
  default     = { Scenario = "hub-spoke-aks-egress", ManagedBy = "Terraform" }
}

variable "pprd" {
  description = "Existing pprd network outputs. Only the two dedicated AKS subnets are eligible for association."
  type = object({
    subscription_id     = string
    resource_group_name = string
    vnet_id             = string
    address_space       = list(string)
    aks_subnets         = map(object({ id = string, address_prefix = string }))
  })
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.pprd.subscription_id)) && startswith(lower(var.pprd.vnet_id), "/subscriptions/${lower(var.pprd.subscription_id)}/resourcegroups/") && can(regex("/providers/microsoft.network/virtualnetworks/[^/]+$", lower(var.pprd.vnet_id)))
    error_message = "Use an actual VNet resource ID in the specified pprd subscription."
  }
  validation {
    condition     = toset(keys(var.pprd.aks_subnets)) == toset(["aks01", "aks02"]) && alltrue([for name, subnet in var.pprd.aks_subnets : startswith(lower(subnet.id), "${lower(var.pprd.vnet_id)}/subnets/") && can(regex("(^|[-_])${name}($|[-_])", lower(element(reverse(split("/", subnet.id)), 0))))])
    error_message = "Provide only aks01 and aks02, with actual subnet IDs under this VNet whose names contain the matching AKS label. AppGateway and other subnets are excluded."
  }
  validation {
    condition     = length(var.pprd.address_space) > 0 && alltrue([for cidr in concat(var.pprd.address_space, [for subnet in var.pprd.aks_subnets : subnet.address_prefix]) : can(cidrnetmask(cidr))])
    error_message = "VNet and AKS subnet ranges must be valid IPv4 CIDRs."
  }
}

variable "prd" {
  description = "Existing prd network outputs. Only the two dedicated AKS subnets are eligible for association."
  type = object({
    subscription_id     = string
    resource_group_name = string
    vnet_id             = string
    address_space       = list(string)
    aks_subnets         = map(object({ id = string, address_prefix = string }))
  })
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.prd.subscription_id)) && startswith(lower(var.prd.vnet_id), "/subscriptions/${lower(var.prd.subscription_id)}/resourcegroups/") && can(regex("/providers/microsoft.network/virtualnetworks/[^/]+$", lower(var.prd.vnet_id)))
    error_message = "Use an actual VNet resource ID in the specified prd subscription."
  }
  validation {
    condition     = toset(keys(var.prd.aks_subnets)) == toset(["aks01", "aks02"]) && alltrue([for name, subnet in var.prd.aks_subnets : startswith(lower(subnet.id), "${lower(var.prd.vnet_id)}/subnets/") && can(regex("(^|[-_])${name}($|[-_])", lower(element(reverse(split("/", subnet.id)), 0))))])
    error_message = "Provide only aks01 and aks02, with actual subnet IDs under this VNet whose names contain the matching AKS label. AppGateway and other subnets are excluded."
  }
  validation {
    condition     = length(var.prd.address_space) > 0 && alltrue([for cidr in concat(var.prd.address_space, [for subnet in var.prd.aks_subnets : subnet.address_prefix]) : can(cidrnetmask(cidr))])
    error_message = "VNet and AKS subnet ranges must be valid IPv4 CIDRs."
  }
}
