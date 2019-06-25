variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "tenant_id" {}

variable "location" {
  default = "West Europe"
}

provider "azure" {
    client_id = "${var.azure_client_id}"
    client_secret = "${var.azure_client_secret}"
    tenant_id = "${var.tenant_id}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  location            = "${var.location}"
  resource_group_name = "hybridrg"
  address_space       = ["172.16.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  resource_group_name  = "hybridrg"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "172.16.1.0/24"
}

resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = "hybridrg"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "172.16.2.0/28"
}

resource "azurerm_public_ip" "gwpip" {
  name                    = "vnetvgwpip1"
  location                = "${var.location}"
  resource_group_name     = "hybridrg"
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_virtual_network_gateway" "vng" {
  name                = "myvng1"
  location            = "${var.location}"
  resource_group_name = "hybridrg"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.gwpip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.GatewaySubnet.id}"
  }

}

resource "azurerm_local_network_gateway" "lngw1" {
  name                = "azlngw1"
  resource_group_name = "hybridrg"
  location            = "${var.location}"
  gateway_address     = "${aws_vpn_connection.main.tunnel2_address}"
  address_space       = ["${aws_vpc.vpc1.cidr_block}"]
}

resource "azurerm_local_network_gateway" "lngw2" {
  name                = "azlngw2"
  resource_group_name = "hybridrg"
  location            = "${var.location}"
  gateway_address     = "${aws_vpn_connection.main.tunnel1_address}"
  address_space       = ["${aws_vpc.vpc1.cidr_block}"]
}

resource "azurerm_virtual_network_gateway_connection" "vngc1" {
  name                = "vngc1"
  location            = "${var.location}"
  resource_group_name = "hybridrg"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vng.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.lngw1.id}"

  shared_key = "${aws_vpn_connection.main.tunnel2_preshared_key}"
}

resource "azurerm_virtual_network_gateway_connection" "vngc2" {
  name                = "vngc2"
  location            = "${var.location}"
  resource_group_name = "hybridrg"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vng.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.lngw2.id}"

  shared_key = "${aws_vpn_connection.main.tunnel1_preshared_key}"
}


resource "azurerm_route_table" "route" {
  name                          = "awsroute"
  location                      = "${var.location}"
  resource_group_name           = "hybridrg"

  route {
    name           = "awsroute"
    address_prefix = "${aws_vpc.vpc1.cidr_block}"
    next_hop_type  = "VirtualNetworkGateway"
  }

}