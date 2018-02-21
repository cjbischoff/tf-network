variable "azs" {}
variable "enable_dns_hostnames" {}
variable "enable_dns_support" {}
variable "env_name" {}
variable "public_subnet" {}
variable "shared_key_name" {}
variable "subnet_app_1" {}
variable "subnet_app_2" {}
variable "subnet_data_1" {}
variable "subnet_data2" {}
variable "subnet_dmz_1" {}
variable "subnet_dmz_2" {}
variable "type" {}
variable "vpc_cidr" {}



resource "aws_vpc" "primary_vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags {
      Name = "${lower(var.label_identifier)}-${var.label_region_short}-${var.label_env}-${var.label_system}_vpc"
  }
  enable_dns_support = "${var.enable_dns_support}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
}

resource "aws_internet_gateway" "primary_ig" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_eip" "primary_eip" {
  vpc = true
  count = 1
  lifecycle {
      prevent_destroy = true
    }
}

resource "aws_subnet" "primary_subnet_dmz_1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.public_subnet}"
  availability_zone = "${var.azs}"
  tags {
      Name = "${lower(var.env_name)}-${var.type}_public-subnet"
  }
}

resource "aws_subnet" "primary_subnet_app_1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.app_server_subnet}"
  availability_zone = "${var.azs}"
  tags {
      Name = "${lower(var.env_name)}-${var.type}_app-server-private-subnet"
  }
}

resource "aws_nat_gateway" "primary_ngw" {
  allocation_id = "${aws_eip.elastic_ip.id}"
  subnet_id     = "${aws_subnet.public_subnet.id}"
  depends_on    = ["aws_internet_gateway.main"]
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
  route {
    cidr_block = "${var.mgmt_vpc_cidr}"
    gateway_id = "${aws_vpc_peering_connection.mgmt.id}"
  }
  tags {
      Name = "${lower(var.env_name)}-${var.type}_public-route-table"
  }
}


resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_nat_gateway.git_production_ngw.id}"
  }
  route {
      cidr_block = "${var.mgmt_vpc_cidr}"
      gateway_id = "${aws_vpc_peering_connection.mgmt.id}"
  }
  tags {
      Name = "${lower(var.env_name)}-${var.type}_private-route-table"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "app_server_association" {
  subnet_id = "${aws_subnet.app_server_subnet.id}"
  route_table_id = "${aws_route_table.private.id}"
}
