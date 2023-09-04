locals {
  resource_name = "${var.name}-${var.env}-${lower(replace(var.region, "/\\W|_|\\s/", ""))}"
}
variable "name" {}
variable "env" {}
variable "region" {}
variable "cidr" {
  default = ["10.0.0.0/16"]
}
