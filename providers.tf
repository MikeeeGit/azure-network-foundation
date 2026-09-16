provider "azurerm" {
  subscription_id                 = var.subscription_id_map[var.subscription]
  resource_provider_registrations = "none"
  features {}
}

# Private endpoint DNS and explicitly requested reverse hub peerings use this subscription.
provider "azurerm" {
  alias                           = "hub"
  subscription_id                 = var.subscription_id_map["hub"]
  resource_provider_registrations = "none"
  features {}
}
