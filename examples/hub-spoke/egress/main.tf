# The firewall and all its policies belong to the separate azure-firewall state.
# Reading Azure prevents a stale copied IP from silently becoming the next hop.
data "azurerm_firewall" "egress" {
  provider            = azurerm.hub
  name                = try(split("/", var.firewall_id)[8], "invalid")
  resource_group_name = try(split("/", var.firewall_id)[4], "invalid")
  lifecycle {
    postcondition {
      condition     = self.sku_name == "AZFW_VNet" && length(distinct(compact([for config in self.ip_configuration : config.private_ip_address]))) == 1
      error_message = "The selected firewall must be an applied VNet firewall with one actual private next-hop address."
    }
  }
}
locals {
  firewall_private_ip = try(one(distinct(compact([for config in data.azurerm_firewall.egress.ip_configuration : config.private_ip_address]))), "")
}
