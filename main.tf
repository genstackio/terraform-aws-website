resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  acl    = "public-read"
  website {
    index_document = var.index_document
    error_document = ("" == var.error_document) ? var.index_document : var.error_document
  }
  tags = {
    Website = var.name
  }
  dynamic "cors_rule" {
    for_each = (var.bucket_cors == true) ? {cors: true} : {}
    content {
      allowed_headers = ["*"]
      allowed_methods = ["POST", "GET", "PUT", "DELETE"]
      allowed_origins = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  }

}
resource "aws_s3_bucket" "website_redirect_apex" {
  count = var.apex_redirect ? 1 : 0
  bucket = "www.${var.bucket_name}"
  acl    = "public-read"
  website {
    redirect_all_requests_to = "https://${var.dns}"
  }
  tags = {
    Website = var.name
  }
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name         = aws_s3_bucket.website.website_endpoint
    origin_id           = "website-${var.name}-s3"
    custom_origin_config {
      // These are all the defaults.
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Website ${var.name} Distribution"
  default_root_object = "index.html"

  aliases = [var.dns]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "website-${var.name}-s3"

    dynamic "forwarded_values" {
      for_each = var.cache_policy_id ? {} : {x: true}
      content {
        query_string = var.forward_query_string
        cookies {
          forward = "none"
        }
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    cache_policy_id        = var.cache_policy_id

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
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  dynamic "custom_error_response" {
    for_each = toset(("" == var.error_403_page_path) ? [] : [var.error_403_page_path])
    content {
      error_code    = 403
      response_code = 200
      response_page_path = custom_error_response.value
    }
  }

  dynamic "custom_error_response" {
    for_each = toset(("" == var.error_404_page_path) ? [] : [var.error_404_page_path])
    content {
      error_code    = 404
      response_code = 200
      response_page_path = custom_error_response.value
    }
  }
}
resource "aws_cloudfront_distribution" "website_redirect_apex" {
  count = var.apex_redirect ? 1 : 0
  origin {
    domain_name         = aws_s3_bucket.website_redirect_apex[count.index].website_endpoint
    origin_id           = "website-${var.name}-s3"
    custom_origin_config {
      // These are all the defaults.
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Website ${var.name} Redirect to Apex Distribution"

  aliases = ["www.${var.dns}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "website-${var.name}-s3"

    forwarded_values {
      query_string = var.forward_query_string

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
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only"
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
  count = var.apex_redirect ? 1 : 0
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
  domain_name       = var.dns
  validation_method = "DNS"
  provider          = aws.acm
  subject_alternative_names = var.apex_redirect ? [local.www_dns] : null

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
resource "aws_s3_bucket_policy" "website_redirect_apex" {
  count = var.apex_redirect ? 1 : 0
  bucket = aws_s3_bucket.website_redirect_apex[count.index].id
  policy = data.aws_iam_policy_document.s3_website_redirect_apex_policy[count.index].json
}
