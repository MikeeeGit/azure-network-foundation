output "firewall_private_ip" {
  description = "Actual firewall private IP. Set this as the VNet DNS server in the network-root states before deploying AKS."
  value       = local.firewall_private_ip
}
output "firewall_id" { value = data.azurerm_firewall.egress.id }
output "route_table_ids" {
  description = "Per-subnet UDR table IDs for AKS cluster identity permissions and verification."
  value = {
    pprd = { for name, table in azurerm_route_table.pprd : name => table.id }
    prd  = { for name, table in azurerm_route_table.prd : name => table.id }
  }
}
output "associated_aks_subnet_ids" {
  value = concat([for association in azurerm_subnet_route_table_association.pprd_aks : association.subnet_id], [for association in azurerm_subnet_route_table_association.prd_aks : association.subnet_id])
}
