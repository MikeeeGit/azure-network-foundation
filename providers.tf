provider "azurerm" {
  features {}
  # Register required resource providers during subscription bootstrap, not every deployment.
  resource_provider_registrations = "none"
}
