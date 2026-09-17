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
  description = "Azure region of all three existing networks."
  type        = string
  default     = "uksouth"
}
variable "hub" {
  description = "Existing hub subscription, resource group and dedicated AzureFirewallSubnet ID, taken from network outputs."
  type = object({
    subscription_id     = string
    resource_group_name = string
    firewall_subnet_id  = string
  })
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.hub.subscription_id)) && startswith(lower(var.hub.firewall_subnet_id), "/subscriptions/${lower(var.hub.subscription_id)}/resourcegroups/") && endswith(lower(var.hub.firewall_subnet_id), "/subnets/azurefirewallsubnet")
    error_message = "Hub must identify its actual subscription and a subnet named AzureFirewallSubnet in that subscription."
  }
}
variable "enable_aks_routes" {
  description = "Attach the four AKS subnet route tables only after hub/spoke peerings, firewall DNS and NSGs have been reviewed."
  type        = bool
  default     = false
}
variable "allow_cross_spoke_https" {
  description = "Allow TCP443 between the dedicated PPRD and PRD AKS subnet ranges through the firewall. Defaults to no cross-environment firewall access."
  type        = bool
  default     = false
}
variable "allow_legacy_ntp" {
  description = "Optional UDP123 to ntp.ubuntu.com for legacy nodes. Modern private AKS nodes do not require this rule."
  type        = bool
  default     = false
}
variable "additional_registry_fqdns" {
  description = "Explicit extra registry/authentication/CDN hostnames for HTTPS image pulls. AKS platform endpoints come from the AzureKubernetesService tag. No arbitrary wildcard Internet rule."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for fqdn in var.additional_registry_fqdns : can(regex("^(\\*\\.)?[a-zA-Z0-9][a-zA-Z0-9.-]*\\.[a-zA-Z]{2,}$", fqdn))])
    error_message = "Use hostnames (optionally a leading *. subdomain wildcard), without schemes, paths, ports or an unrestricted *."
  }
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
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.pprd.subscription_id)) && startswith(lower(var.pprd.vnet_id), "/subscriptions/${lower(var.pprd.subscription_id)}/resourcegroups/") && can(regex("/providers/microsoft.network/virtualnetworks/[^/]+$", lower(var.pprd.vnet_id)))
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
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.prd.subscription_id)) && startswith(lower(var.prd.vnet_id), "/subscriptions/${lower(var.prd.subscription_id)}/resourcegroups/") && can(regex("/providers/microsoft.network/virtualnetworks/[^/]+$", lower(var.prd.vnet_id)))
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
