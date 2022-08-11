resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name_0
  tags = {
    Website = var.name
  }
}
resource "aws_s3_bucket_acl" "cdn_redirect_apex" {
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.bucket

  redirect_all_requests_to {
    host_name = local.target_domain
    protocol  = local.target_protocol
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
resource "aws_s3_bucket" "website_1" {
  count  = var.apex_redirect ? 1 : 0
  bucket = local.bucket_name_1
  tags = {
    Website = var.name
  }
}
resource "aws_s3_bucket_acl" "website_1" {
  count  = (null != local.dns_1) ? 1 : 0
  bucket = aws_s3_bucket.website_1[0].id
  acl    = "public-read"
}
resource "aws_s3_bucket_website_configuration" "website_1" {
  count  = (null != local.dns_1) ? 1 : 0
  bucket = aws_s3_bucket.website_1[0].bucket

  redirect_all_requests_to {
    host_name = local.target_domain
    protocol  = local.target_protocol
  }
}
resource "aws_s3_bucket_cors_configuration" "website_1" {
  count  = (var.bucket_cors == true) ? 1 : 0
  bucket = aws_s3_bucket.website_1.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "GET", "PUT", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket.website.website_endpoint
    origin_id   = "website-${var.name}-s3"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Website ${var.name} Distribution - Redirect to ${var.target}"

  aliases = [var.dns]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "website-${var.name}-s3"

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forwarded_headers
      cookies {
        forward = "none"
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
resource "aws_cloudfront_distribution" "website_1" {
  count = var.apex_redirect ? 1 : 0
  origin {
    domain_name = aws_s3_bucket.website_1[count.index].website_endpoint
    origin_id   = "website-${var.name}-s3"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Website ${var.name} Redirect to Apex Distribution - Redirect to ${var.target}"

  aliases = [local.dns_1]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "website-${var.name}-s3"

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forwarded_headers
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
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
resource "aws_route53_record" "website_1" {
  count   = var.apex_redirect ? 1 : 0
  zone_id = var.zone
  name    = local.dns_1
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_1[count.index].domain_name
    zone_id                = aws_cloudfront_distribution.website_1[count.index].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.dns
  validation_method         = "DNS"
  provider                  = aws.acm
  subject_alternative_names = var.apex_redirect ? [local.dns_1] : null

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

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_website_policy.json
}
resource "aws_s3_bucket_policy" "website_1" {
  count  = var.apex_redirect ? 1 : 0
  bucket = aws_s3_bucket.website_1[count.index].id
  policy = data.aws_iam_policy_document.s3_website_redirect_apex_policy[count.index].json
}
