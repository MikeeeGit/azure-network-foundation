variable "tenant_id" {
  description = "Tenant must match the reviewed delivery configuration."
  type        = string
  default     = "00000000-0000-0000-0000-000000000001"
}
variable "environment" {
  description = "This cross-subscription routing state is delivered as the hub target."
  type        = string
  default     = "hub"
}
variable "location_abbreviated" {
  description = "Reviewed regional delivery selector."
  type        = string
  default     = "uks"
}
locals {
  delivery           = jsondecode(file("${path.root}/delivery.azure.json"))
  delivery_locations = { uks = "uksouth", ukw = "ukwest" }
}
resource "terraform_data" "delivery_contract" {
  lifecycle {
    precondition {
      condition     = lower(var.tenant_id) == lower(local.delivery.tenant_id) && var.environment == "hub" && contains(local.delivery.regions, var.location_abbreviated) && try(local.delivery_locations[var.location_abbreviated] == var.location, false)
      error_message = "Tenant, hub environment and Azure region must match delivery.azure.json."
    }
    precondition {
      condition     = try(lower(split("/", var.firewall_id)[2]) == lower(local.delivery.subscriptions.hub), false) && lower(var.pprd.subscription_id) == lower(local.delivery.subscriptions.pprd) && lower(var.prd.subscription_id) == lower(local.delivery.subscriptions.prd)
      error_message = "The firewall and both workload subscriptions must match the reviewed hub/pprd/prd aliases."
    }
  }
}
