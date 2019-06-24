variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "region" {
    default = "eu-west-1"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    version = "~> 2.0"
    region  = "${var.region}"
}

# Create a VPC
resource "aws_vpc" "vpc1" {
    cidr_block = "192.168.0.0/16"
    tags = {
        Name = "Default VPC"
    }
}

resource "aws_subnet" "main" {
  vpc_id            = "${aws_vpc.vpc1.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc1.cidr_block, 4, 1)}"
  tags = {
    Name = "main"
  }
}

# create customer gateway
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "${azurerm_public_ip.gwpip.ip_address}"
  type       = "ipsec.1"

  tags = {
    Name = "main-customer-gateway"
  }
  depends_on = ["azurerm_public_ip.gwpip"]
}

# create virtual private gateway
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = "${aws_vpc.vpc1.id}"

  tags = {
    Name = "main"
  }
}

# create vpn connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.id}"
  customer_gateway_id = "${aws_customer_gateway.main.id}"
  type                = "ipsec.1"
  static_routes_only  = true
}

# Create vpn connection route to azure
resource "aws_vpn_connection_route" "azure" {
  destination_cidr_block = "${azurerm_subnet.subnet.address_prefix}"
  vpn_connection_id      = "${aws_vpn_connection.main.id}"
}

# Create AWS to Azure Route
resource "aws_route" "azureroute" {
  route_table_id            = "${aws_vpc.vpc1.main_route_table_id}"
  destination_cidr_block    = "${azurerm_subnet.subnet.address_prefix}"
  vpc_peering_connection_id = "${aws_vpn_gateway.vpn_gw.id}"
}