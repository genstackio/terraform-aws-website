output "cloudfront_id" {
  value = aws_cloudfront_distribution.cdn.id
}
output "dns" {
  value = var.dns
}