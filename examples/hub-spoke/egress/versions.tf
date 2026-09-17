terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.33.0, < 5.0.0"
    }
  }
}
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub.subscription_id
  features {}
}
provider "azurerm" {
  alias           = "pprd"
  subscription_id = var.pprd.subscription_id
  features {}
}
provider "azurerm" {
  alias           = "prd"
  subscription_id = var.prd.subscription_id
  features {}
}
