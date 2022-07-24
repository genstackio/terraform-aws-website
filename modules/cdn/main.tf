resource "aws_cloudfront_function" "function" {
  for_each = local.functions
  name     = "${var.name}-${each.key}"
  runtime  = "cloudfront-js-1.0"
  comment  = "${each.key} function"
  publish  = true
  code     = lookup(each.value, "code", null)
}

resource "aws_s3_bucket" "cdn_redirect_apex" {
  count  = (null != local.dns_1) ? 1 : 0
  bucket = local.dns_1
  tags = {
    Website = var.name
  }
}
resource "aws_s3_bucket_acl" "cdn_redirect_apex" {
  count  = (null != local.dns_1) ? 1 : 0
  bucket = aws_s3_bucket.cdn_redirect_apex[0].id
  acl    = "public-read"
}
resource "aws_s3_bucket_website_configuration" "cdn_redirect_apex" {
  count  = (null != local.dns_1) ? 1 : 0
  bucket = aws_s3_bucket.cdn_redirect_apex[0].bucket

  redirect_all_requests_to {
    host_name = var.dns
    protocol  = "https"
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = var.origin
    origin_id   = "origin-external"
    dynamic "custom_header" {
      for_each = local.custom_headers
      content {
        name  = custom_header.key
        value = custom_header.value
      }
    }
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    dynamic "custom_header" {
      for_each = var.edge_lambdas_variables
      content {
        name  = "x-lambda-var-${replace(lower(custom_header.key), "_", "-")}"
        value = custom_header.value
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Website ${var.name} Distribution"
  default_root_object = var.default_root

  aliases = [local.dns_0]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-external"

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forwarded_headers
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 86400
    compress               = true

    dynamic "lambda_function_association" {
      for_each = toset(var.lambdas)
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lambda_function_association.value.include_body
      }
    }
    dynamic "function_association" {
      for_each = local.functions
      content {
        event_type   = lookup(function_association.value, "event_type", null)
        function_arn = aws_cloudfront_function.function[function_association.key].arn
      }
    }

    dynamic "lambda_function_association" {
      for_each = local.edge_lambdas
      content {
        event_type   = lookup(lambda_function_association.value, "event_type", null)
        lambda_arn   = lookup(lambda_function_association.value, "lambda_arn", null)
        include_body = lookup(lambda_function_association.value, "include_body", null)
      }
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
      response_code      = 200
      response_page_path = custom_error_response.value
    }
  }

  dynamic "custom_error_response" {
    for_each = toset(("" == var.error_404_page_path) ? [] : [var.error_404_page_path])
    content {
      error_code         = 404
      response_code      = 200
      response_page_path = custom_error_response.value
    }
  }
}

resource "aws_cloudfront_distribution" "cdn_redirect_apex" {
  count = (null != local.dns_1) ? 1 : 0
  origin {
    domain_name = aws_s3_bucket.cdn_redirect_apex[0].website_endpoint
    origin_id   = "origin-s3"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Website ${var.name} Distribution"

  aliases = [local.dns_1]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-s3"

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forwarded_headers
      cookies {
        forward = "all"
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
      response_code      = 200
      response_page_path = custom_error_response.value
    }
  }

  dynamic "custom_error_response" {
    for_each = toset(("" == var.error_404_page_path) ? [] : [var.error_404_page_path])
    content {
      error_code         = 404
      response_code      = 200
      response_page_path = custom_error_response.value
    }
  }
}

resource "aws_route53_record" "cdn" {
  zone_id = var.zone
  name    = var.dns
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cdn_redirect_apex" {
  count   = (null != local.dns_1) ? 1 : 0
  zone_id = var.zone
  name    = local.dns_1
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn_redirect_apex[count.index].domain_name
    zone_id                = aws_cloudfront_distribution.cdn_redirect_apex[count.index].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.dns
  validation_method         = "DNS"
  provider                  = aws.acm
  subject_alternative_names = (null != local.dns_1) ? [local.dns_1] : null

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_name
  type    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_type
  zone_id = var.zone
  records = [element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_value]
  ttl     = 60
}
resource "aws_route53_record" "cert_validation_alt" {
  count   = var.apex_redirect ? 1 : 0
  name    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_name
  type    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_type
  zone_id = var.zone
  records = [element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.acm
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = var.apex_redirect ? [aws_route53_record.cert_validation.fqdn, aws_route53_record.cert_validation_alt[0].fqdn] : [aws_route53_record.cert_validation.fqdn]
}

resource "aws_s3_bucket_policy" "cdn_redirect_apex" {
  count  = var.apex_redirect ? 1 : 0
  bucket = aws_s3_bucket.cdn_redirect_apex[count.index].id
  policy = data.aws_iam_policy_document.s3_cdn_redirect_apex_policy[count.index].json
}
