variable "name" {
  type = string
}
variable "target" {
  type = string
}
variable "zone" {
  type = string
}
variable "dns" {
  type = string
}
variable "geolocations" {
  type    = list(string)
  default = []
}
variable "price_class" {
  type    = string
  default = "PriceClass_100"
}
variable "apex_redirect" {
  type    = bool
  default = false
}
