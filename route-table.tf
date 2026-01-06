resource "azurerm_route_table" "rt" {
  name                = "tf-demo-rt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  disable_bgp_route_propagation = false
}
