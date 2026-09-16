output "resource_group_name" {
  description = "Created network resource group."
  value       = azurerm_resource_group.network.name
}
output "vnet_id" {
  description = "Virtual network resource ID."
  value       = module.network.vnet_id
}
output "subnet_ids" {
  description = "Subnet IDs keyed by exact Azure name."
  value       = module.network.subnet_ids
}
output "private_dns_zone_ids" {
  description = "Private DNS zone IDs keyed by domain."
  value       = module.network.private_dns_zone_ids
}
output "private_endpoint_ids" {
  description = "Private endpoint IDs keyed by name."
  value       = module.network.private_endpoint_ids
}
