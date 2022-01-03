output "cloudfront_id" {
  value = aws_cloudfront_distribution.website.id
}
output "cloudfront_arn" {
  value = aws_cloudfront_distribution.website.arn
}
output "dns" {
  value = var.dns
}
output "bucket_arn" {
  value = aws_s3_bucket.website.arn
}
output "bucket_id" {
  value = aws_s3_bucket.website.id
}
output "bucket_name" {
  value = aws_s3_bucket.website.bucket
}