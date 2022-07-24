resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  tags = {
    Website = var.name
  }
}
resource "aws_s3_bucket_acl" "website" {
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.bucket

  index_document {
    suffix = var.index_document
  }
  error_document {
    key = ("" == var.error_document) ? var.index_document : var.error_document
  }
}
resource "aws_s3_bucket_cors_configuration" "website" {
  count  = (var.bucket_cors == true) ? 1 : 0
  bucket = aws_s3_bucket.website.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "GET", "PUT", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
resource "aws_s3_bucket" "website_redirect_apex" {
  count  = var.apex_redirect ? 1 : 0
  bucket = "www.${var.bucket_name}"
  tags = {
    Website = var.name
  }
}
resource "aws_s3_bucket_acl" "website_redirect_apex" {
  count  = var.apex_redirect ? 1 : 0
  bucket = aws_s3_bucket.website_redirect_apex[0].id
  acl    = "public-read"
}
resource "aws_s3_bucket_website_configuration" "website_redirect_apex" {
  count  = var.apex_redirect ? 1 : 0
  bucket = aws_s3_bucket.website_redirect_apex[0].bucket

  redirect_all_requests_to {
    host_name = var.dns
    protocol  = "https"
  }
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket.website.website_endpoint
    origin_id   = local.origin_target_id
    custom_origin_config {
      // These are all the defaults.
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
    dynamic "custom_header" {
      for_each = var.custom_origin_headers
      content {
        name  = custom_header.value.name
        value = custom_header.value.value
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Website ${var.name} Distribution"
  default_root_object = var.default_root_object

  aliases = [var.dns]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_target_id

    dynamic "forwarded_values" {
      for_each = (null != var.cache_policy_id) ? {} : { x : true }
      content {
        query_string = var.forward_query_string
        cookies {
          forward = "none"
        }
        headers = var.forwarded_headers
      }
    }

    viewer_protocol_policy     = "redirect-to-https"
    min_ttl                    = 0
    default_ttl                = 3600
    max_ttl                    = 86400
    compress                   = true
    cache_policy_id            = var.cache_policy_id
    origin_request_policy_id   = var.origin_request_policy_id
    response_headers_policy_id = var.response_headers_policy_id

    dynamic "lambda_function_association" {
      for_each = toset(var.lambdas)
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lambda_function_association.value.include_body
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.custom_behaviors != null ? var.custom_behaviors : []
    content {
      path_pattern               = ordered_cache_behavior.value["path_pattern"]
      allowed_methods            = lookup(ordered_cache_behavior.value, "allowed_methods", ["GET", "HEAD"])
      cached_methods             = lookup(ordered_cache_behavior.value, "cached_methods", ["GET", "HEAD"])
      target_origin_id           = lookup(ordered_cache_behavior.value, "target_origin_id", local.origin_target_id)
      compress                   = lookup(ordered_cache_behavior.value, "compress", true)
      viewer_protocol_policy     = lookup(ordered_cache_behavior.value, "viewer_protocol_policy", "redirect-to-https")
      origin_request_policy_id   = lookup(ordered_cache_behavior.value, "origin_request_policy_id", null)
      cache_policy_id            = lookup(ordered_cache_behavior.value, "cache_policy_id", null)
      response_headers_policy_id = lookup(ordered_cache_behavior.value, "response_headers_policy_id", null)
    }
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = length(var.geolocations) == 0 ? "none" : "whitelist"
      locations        = length(var.geolocations) == 0 ? null : var.geolocations
    }
  }

  tags = {
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  dynamic "custom_error_response" {
    for_each = toset(("" == var.error_403_page_path) ? [] : [var.error_403_page_path])
    content {
      error_code         = 403
      response_code      = var.error_403_page_code
      response_page_path = custom_error_response.value
    }
  }

  dynamic "custom_error_response" {
    for_each = toset(("" == var.error_404_page_path) ? [] : [var.error_404_page_path])
    content {
      error_code         = 404
      response_code      = var.error_404_page_code
      response_page_path = custom_error_response.value
    }
  }
}
resource "aws_cloudfront_distribution" "website_redirect_apex" {
  count = var.apex_redirect ? 1 : 0
  origin {
    domain_name = aws_s3_bucket.website_redirect_apex[count.index].website_endpoint
    origin_id   = local.origin_target_id
    custom_origin_config {
      // These are all the defaults.
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Website ${var.name} Redirect to Apex Distribution"

  aliases = ["www.${var.dns}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_target_id

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forwarded_headers
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}

resource "aws_route53_record" "website" {
  zone_id = var.zone
  name    = var.dns
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "website_redirect_apex" {
  count   = var.apex_redirect ? 1 : 0
  zone_id = var.zone
  name    = "www.${var.dns}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_redirect_apex[count.index].domain_name
    zone_id                = aws_cloudfront_distribution.website_redirect_apex[count.index].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.dns
  validation_method         = "DNS"
  provider                  = aws.acm
  subject_alternative_names = var.apex_redirect ? [local.www_dns] : null

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = var.can_overwrite
  name            = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_name
  type            = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_type
  zone_id         = var.zone
  records         = [element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_value]
  ttl             = 60
}
resource "aws_route53_record" "cert_validation_alt" {
  allow_overwrite = var.can_overwrite
  count           = var.apex_redirect ? 1 : 0
  name            = element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_name
  type            = element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_type
  zone_id         = var.zone
  records         = [element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_value]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.acm
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = var.apex_redirect ? [aws_route53_record.cert_validation.fqdn, aws_route53_record.cert_validation_alt[0].fqdn] : [aws_route53_record.cert_validation.fqdn]
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_website_policy.json
}
resource "aws_s3_bucket_policy" "website_redirect_apex" {
  count  = var.apex_redirect ? 1 : 0
  bucket = aws_s3_bucket.website_redirect_apex[count.index].id
  policy = data.aws_iam_policy_document.s3_website_redirect_apex_policy[count.index].json
}
