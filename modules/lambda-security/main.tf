module "lambda" {
  source            = "genstackio/lambda/aws"
  version           = "0.1.0"
  name              = var.name
  file              = data.archive_file.lambda-code.output_path
  runtime           = var.runtime
  timeout           = var.timeout
  memory_size       = var.memory_size
  handler           = var.handler
  variables         = var.variables
  publish           = true
  assume_role_identifiers = ["edgelambda.amazonaws.com"]
  policy_statements = var.policy_statements
  providers = {
    aws = aws.central
  }
}