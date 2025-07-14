variable "name" {
  type    = string
  default = "ingress-nginx"
}

variable "namespace" {
  type    = string
  default = "ingress-nginx"
}

variable "chart_version" {
  type    = string
  default = "4.10.1"
}
