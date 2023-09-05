locals {
  resource_name = "${var.name}-${var.env}-${lower(replace(var.region, "/\\W|_|\\s/", ""))}"
    tags_default = {
    projeto = var.project
    ambiente = var.env
    gerenciado_por = "terraform"
  }
}
variable "name" {}
variable "env" {}
variable "region" {}
variable "cidr" {
  default = ["10.0.0.0/16"]
}
variable "project" {
  
}
variable "trusted_ip" {
type = list
}
