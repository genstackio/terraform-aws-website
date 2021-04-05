output "cloudfront_id" {
  value = aws_cloudfront_distribution.website.id
}
output "dns" {
  value = aws_cloudfront_distribution.website.domain_name
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