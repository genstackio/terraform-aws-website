output "cloudfront_id" {
  value = aws_cloudfront_distribution.website.id
}
output "dns" {
  value = var.dns
}