output "name" {
  value = var.name
}
output "arn" {
  value = module.lambda.arn
}
output "invoke_arn" {
  value = module.lambda.invoke_arn
}
output "role_arn" {
  value = module.lambda.arn
}
output "role_name" {
  value = module.lambda.name
}
output "qualified_arn" {
  value = module.lambda.qualified_arn
}
output "version" {
  value = module.lambda.version
}