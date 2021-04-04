module "lambda" {
  source            = "genstackio/lambda/aws"
  version           = "0.1.6"
  name              = var.name
  file              = data.archive_file.lambda-code.output_path
  runtime           = var.runtime
  timeout           = var.timeout
  memory_size       = var.memory_size
  handler           = var.handler
  variables         = var.variables
  publish           = true
  assume_role_identifiers = ["edgelambda.amazonaws.com"]
  policy_statements = concat(
    [
      {
        effect    = "Allow"
        resources = ["arn:aws:logs:*:*:*"]
        actions   = ["logs:CreateLogGroup"]
      }
    ],
    var.policy_statements
  )
  providers = {
    aws = aws.us-east-1
  }
}

module "regional-log-groups" {
  source  = "genstackio/lambda/aws//modules/regional-log-groups"
  version = "0.1.6"
  name    = var.name
  regions = var.log_group_regions
  providers = {
    aws = aws.us-east-1
  }
}