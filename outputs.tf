output "network-rg" {
  description = "The name of the network resource group."
  value       = azurerm_resource_group.network.name
}

output "vnet-rg" {
  description = "The name of the VNet resource group."
  value       = azurerm_resource_group.vnet.name
}

output "private_dns_zone_ids" {
  value = local.endpoint_zone_ids
}

output "subnet_name_to_id" {
  value = local.subnet_name_to_id
}

output "vnet" {
  description = "vNet Resource"
  value       = module.vnet.vnet
}

output "vnet_id" {
  description = "The ID of the VNet"
  value       = module.vnet.vnet.id
}

output "subnets" {
  description = "Subnet Map"
  value       = module.subnets.subnets
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value       = { for k, v in module.subnets.subnets : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet address prefixes"
  value       = { for k, v in module.subnets.subnets : k => v.address_prefixes[0] }
}

output "dns_debug" {
  value = var.dns
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = length(azurerm_container_registry.acr) > 0 ? azurerm_container_registry.acr[0].name : ""
}

output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = length(azurerm_container_registry.acr) > 0 ? azurerm_container_registry.acr[0].id : ""
}

output "private_endpoints" {
  description = "The created Private Endpoints"
  value       = azurerm_private_endpoint.endpoints
}

output "subnets_file_paths" {
  value = module.subnets.file_paths
}

output "rootpath" {
  value = module.subnets.rootpath
}

output "subnets_subnet_nsg_rules" {
  value = module.subnets.subnet_nsg_rules
}

output "route_table_file_paths" {
  value = module.subnets.route_table_file_paths
}

output "subnet_route_table_rules" {
  value = module.subnets.subnet_route_table_rules
}
