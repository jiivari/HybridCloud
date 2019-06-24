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
resource "aws_vpc" "vpc2" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "New VPC"
    }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id            = "${aws_vpc.vpc2.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc2.cidr_block, 4, 1)}"
  tags = {
    Name = "main"
  }
}
