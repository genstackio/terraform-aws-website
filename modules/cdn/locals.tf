locals {
  is_www = "www." == substr(var.dns, 0, 4)
  dns_0 = var.dns
  dns_1 = var.apex_redirect ? (local.is_www ? substr(var.dns, length(var.dns) - 4) : "www.${var.dns}") : null
}