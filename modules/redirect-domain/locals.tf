locals {
  is_www          = "www." == substr(var.dns, 0, 4)
  dns_0           = var.dns
  dns_1           = var.apex_redirect ? (local.is_www ? substr(var.dns, 4, length(var.dns) - 4) : "www.${var.dns}") : null
  bucket_name_0   = local.dns_0
  bucket_name_1   = local.dns_1
  target_tokens   = split("://", var.target)
  target_protocol = element(target_tokens, 0)
  target_domain   = element(split("/", element(target_tokens, 1)), 0)
}