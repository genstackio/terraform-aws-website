variable "name" {
  type = string
}
variable "bucket_name" {
  type = string
}
variable "zone" {
  type = string
}
variable "dns" {
  type = string
}
variable "index_document" {
  type    = string
  default = "index.html"
}
variable "error_document" {
  type    = string
  default = ""
}
variable "error_403_page_path" {
  type    = string
  default = ""
}
variable "error_404_page_path" {
  type    = string
  default = ""
}
variable "error_403_page_code" {
  type    = number
  default = 200
}
variable "error_404_page_code" {
  type    = number
  default = 200
}
variable "geolocations" {
  type    = list(string)
  default = ["FR", "BE", "LU", "IT", "ES", "CH", "NL", "GB", "PT", "MC"]
}
variable "price_class" {
  type    = string
  default = "PriceClass_100"
}
variable "apex_redirect" {
  type    = bool
  default = false
}
variable "bucket_cors" {
  type    = bool
  default = false
}
variable "forward_query_string" {
  type    = bool
  default = false
}
variable "lambdas" {
  type = list(object({
    event_type   = string
    lambda_arn   = string
    include_body = bool
  }))
  default = []
}
variable "cache_policy_id" {
  type    = string
  default = null
}
variable "origin_request_policy_id" {
  type    = string
  default = null
}
variable "response_headers_policy_id" {
  type    = string
  default = null
}
variable "forwarded_headers" {
  type    = list(string)
  default = null
}
variable "custom_origin_headers" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
variable "custom_behaviors" {
  type    = list(any)
  default = null
}
variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "can_overwrite" {
  type        = bool
  default     = false
  description = "Allow overwriting route53 records for pre-existing CNAME/certificates"
}
