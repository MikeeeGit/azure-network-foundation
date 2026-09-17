terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  backend "azurerm" { use_azuread_auth = true }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.33.0, < 5.0.0"
    }
  }
}
provider "azurerm" {
  alias                           = "hub"
  tenant_id                       = var.tenant_id
  subscription_id                 = try(split("/", var.firewall_id)[2], "00000000-0000-0000-0000-000000000002")
  resource_provider_registrations = "none"
  features {}
}
provider "azurerm" {
  alias                           = "pprd"
  tenant_id                       = var.tenant_id
  subscription_id                 = var.pprd.subscription_id
  resource_provider_registrations = "none"
  features {}
}
provider "azurerm" {
  alias                           = "prd"
  tenant_id                       = var.tenant_id
  subscription_id                 = var.prd.subscription_id
  resource_provider_registrations = "none"
  features {}
}
