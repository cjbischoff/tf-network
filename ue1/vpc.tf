variable "azs" {}
variable "cidr_vpc" {}
variable "cidr_app" {}
variable "cidr_dmz" {}
variable "cidr_data" {}
variable "enable_dns_hostnames" {}
variable "enable_dns_support" {}
variable "label_env" {}
variable "label_identifier" {}
variable "label_region_short" {}
variable "label_system" {}

resource "aws_vpc" "primary_vpc" {
  cidr_block = "${var.cidr_vpc}"

  tags {
    Name = "${lower(var.label_identifier)}-${var.label_region_short}-${var.label_env}-${var.label_system}_vpc"
  }

  enable_dns_support   = "${var.enable_dns_support}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
}

resource "aws_internet_gateway" "primary_ig" {
  vpc_id = "${aws_vpc.primary_vpc.id}"
}

resource "aws_eip" "primary_eip" {
  vpc   = true
  count = 1

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "dmz_subnet" {
  vpc_id            = "${aws_vpc.primary_vpc.id}"
  cidr_block        = "${element(split(",", var.cidr_dmz), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count             = "${length(split(",", var.cidr_dmz))}"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name = "${lower(var.label_identifier)}-${var.label_region_short}-${var.label_env}-${var.label_system}_dmz-subnet-${count.index}"
  }
}

resource "aws_subnet" "app_subnet" {
  vpc_id            = "${aws_vpc.primary_vpc.id}"
  cidr_block        = "${element(split(",", var.cidr_app), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count             = "${length(split(",", var.cidr_app))}"

  tags {
    Name = "${lower(var.label_identifier)}-${var.label_region_short}-${var.label_env}-${var.label_system}_app-subnet-${count.index}"
  }
}

resource "aws_subnet" "data_subnet" {
  vpc_id            = "${aws_vpc.primary_vpc.id}"
  cidr_block        = "${element(split(",", var.cidr_data), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count             = "${length(split(",", var.cidr_data))}"

  tags {
    Name = "${lower(var.label_identifier)}-${var.label_region_short}-${var.label_env}-${var.label_system}_data-subnet-${count.index}"
  }
}

resource "aws_db_subnet_group" "data_subnet_group" {
  depends_on  = ["aws_subnet.data_subnet"]
  name        = "${lower(var.label_identifier)}-${var.label_region_short}-${var.label_env}-${var.label_system}_db-subnet-group"
  description = "Managed by Terraform"
  subnet_ids  = ["${aws_subnet.data_subnet.0.id}", "${aws_subnet.data_subnet.1.id}"]
}

resource "aws_nat_gateway" "primary_ngw" {
  allocation_id = "${aws_eip.primary_eip.id}"
  subnet_id     = "${aws_subnet.dmz_subnet.0.id}"
  depends_on    = ["aws_internet_gateway.primary_ig"]
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.primary_vpc.id}"

  tags {
    Name = "${lower(var.label_identifier)}-${var.label_region_short}-${var.label_env}-${var.label_system}_public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.primary_vpc.id}"

  tags {
    Name = "${lower(var.label_identifier)}-${var.label_region_short}-${var.label_env}-${var.label_system}_private-route-table"
  }
}

resource "aws_route_table_association" "dmz_association" {
  subnet_id      = "${element(aws_subnet.dmz_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
  count          = "${length(split(",", var.cidr_dmz))}"
}

resource "aws_route_table_association" "app_association" {
  subnet_id      = "${element(aws_subnet.app_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
  count          = "${length(split(",", var.cidr_app))}"
}

resource "aws_route_table_association" "data_association" {
  subnet_id      = "${element(aws_subnet.data_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
  count          = "${length(split(",", var.cidr_data))}"
}

resource "aws_route" "public_to_world_route" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.primary_ig.id}"
  depends_on             = ["aws_internet_gateway.primary_ig"]
}

resource "aws_route" "private_to_world_route" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.primary_ngw.id}"
  depends_on             = ["aws_nat_gateway.primary_ngw"]
}
