locals {
  is_www         = "www." == substr(var.dns, 0, 4)
  dns_0          = var.dns
  dns_1          = var.apex_redirect ? (local.is_www ? substr(var.dns, 4, length(var.dns) - 4) : "www.${var.dns}") : null
  custom_headers = (null != var.headers) ? var.headers : null
  functions      = { for k, v in var.functions : lookup(v, "name", k) => v }
  edge_lambdas   = { for i, l in var.edge_lambdas : "lambda-${i}" => l }
}