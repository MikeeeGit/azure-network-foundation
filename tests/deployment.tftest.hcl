mock_provider "azurerm" {}

override_module {
  target = module.network
  outputs = {
    vnet_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example"
    subnet_ids           = {}
    private_dns_zone_ids = {}
    private_endpoint_ids = {}
  }
}

variables {
  name                = "vnet-example"
  resource_group_name = "rg-example"
  location            = "uksouth"
  address_space       = ["10.40.0.0/16"]
  tags                = { Environment = "example", ManagedBy = "Terraform" }
}

run "owns_exact_resource_group" {
  command = plan
  assert {
    condition     = azurerm_resource_group.network.name == "rg-example" && azurerm_resource_group.network.location == "uksouth"
    error_message = "The root deployment must use the explicit resource group name and location."
  }
  assert {
    condition     = azurerm_resource_group.network.tags["Environment"] == "example"
    error_message = "Resource group tags must carry the supplied environment."
  }
  assert {
    condition     = output.vnet_id == module.network.vnet_id
    error_message = "The root must expose the composed network ID."
  }
}
