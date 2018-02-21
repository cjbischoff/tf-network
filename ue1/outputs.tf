output "vpc_id" {
  value = "${aws_vpc.primary_vpc.id}"
}

output "cidr_vpc" {
  value = "${var.cidr_vpc}"
}

output "cidr_dmz" {
  value = "${var.cidr_dmz}"
}

output "cidr_app" {
  value = "${var.cidr_app}"
}

output "cidr_data" {
  value = "${var.cidr_data}"
}

output "dmz_subnet_id" {
  value = "${join(",", aws_subnet.dmz_subnet.*.id)}"
}

output "app_subnet_id" {
  value = "${join(",", aws_subnet.app_subnet.*.id)}"
}

output "data_subnet_id" {
  value = "${join(",", aws_subnet.data_subnet.*.id)}"
}
