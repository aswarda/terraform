resource "azurerm_route" "route" {
  name                = "internet-route"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.rt.name

  address_prefix = "0.0.0.0/0"
  next_hop_type  = "Internet"
}
