data "aws_iam_policy_document" "s3_cdn_redirect_policy" {
  count = var.apex_redirect ? 1 : 0
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cdn_redirect.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.cdn_redirect.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
data "aws_iam_policy_document" "s3_cdn_redirect_apex_policy" {
  count = var.apex_redirect ? 1 : 0
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cdn_redirect_apex[count.index].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.cdn_redirect_apex[count.index].arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
