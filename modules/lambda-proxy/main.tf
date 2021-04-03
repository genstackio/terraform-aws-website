module "lambda" {
  source            = "genstackio/lambda/aws"
  version           = "0.1.5"
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

// following log group modules are only enable if region is present in var.log_regions.
// due to a limitation in Terraform, we can not do a loop/for_each on providers.

locals {
  lg_us           = contains(var.log_group_regions, "us")
  lg_eu           = contains(var.log_group_regions, "eu")
  lg_af           = contains(var.log_group_regions, "af")
  lg_ap           = contains(var.log_group_regions, "ap")
  lg_me           = contains(var.log_group_regions, "me")
  lg_sa           = contains(var.log_group_regions, "sa")
  lg_ca           = contains(var.log_group_regions, "ca")
  lg_us-east      = contains(var.log_group_regions, "us-east")
  lg_us-west      = contains(var.log_group_regions, "us-west")
  lg_eu-west      = contains(var.log_group_regions, "eu-west")
  lg_eu-central   = contains(var.log_group_regions, "eu-central")
  lg_eu-south     = contains(var.log_group_regions, "eu-south")
  lg_eu-north     = contains(var.log_group_regions, "eu-north")
  lg_me-south     = contains(var.log_group_regions, "me-south")
  lg_sa-east      = contains(var.log_group_regions, "sa-east")
  lg_af-south     = contains(var.log_group_regions, "af-south")
  lg_ap-east      = contains(var.log_group_regions, "ap-east")
  lg_ap-south     = contains(var.log_group_regions, "ap-south")
  lg_ap-northeast = contains(var.log_group_regions, "ap-northeast")
  lg_ap-southeast = contains(var.log_group_regions, "ap-southeast")
  lg_ca-central   = contains(var.log_group_regions, "ca-central")
}

locals {
  lg_us-east-1      = contains(var.log_group_regions, "us-east-1") || local.lg_us-east || local.lg_us
  lg_us-east-2      = contains(var.log_group_regions, "us-east-2") || local.lg_us-east || local.lg_us
  lg_us-west-1      = contains(var.log_group_regions, "us-west-1") || local.lg_us-west || local.lg_us
  lg_us-west-2      = contains(var.log_group_regions, "us-west-2") || local.lg_us-west || local.lg_us
  lg_af-south-1     = contains(var.log_group_regions, "af-south-1") || local.lg_af-south || local.lg_af
  lg_ap-east-1      = contains(var.log_group_regions, "ap-east-1") || local.lg_ap-east || local.lg_ap
  lg_ap-south-1     = contains(var.log_group_regions, "ap-south-1") || local.lg_ap-south || local.lg_ap
  lg_ap-northeast-1 = contains(var.log_group_regions, "ap-northeast-1") || local.lg_ap-northeast || local.lg_ap
  lg_ap-northeast-2 = contains(var.log_group_regions, "ap-northeast-2") || local.lg_ap-northeast || local.lg_ap
  lg_ap-northeast-3 = contains(var.log_group_regions, "ap-northeast-3") || local.lg_ap-northeast || local.lg_ap
  lg_ap-southeast-1 = contains(var.log_group_regions, "ap-southeast-1") || local.lg_ap-southeast || local.lg_ap
  lg_ap-southeast-2 = contains(var.log_group_regions, "ap-southeast-2") || local.lg_ap-southeast || local.lg_ap
  lg_eu-west-1      = contains(var.log_group_regions, "eu-west-1") || local.lg_eu-west || local.lg_eu
  lg_eu-west-2      = contains(var.log_group_regions, "eu-west-2") || local.lg_eu-west || local.lg_eu
  lg_eu-west-3      = contains(var.log_group_regions, "eu-west-3") || local.lg_eu-west || local.lg_eu
  lg_eu-south-1     = contains(var.log_group_regions, "eu-south-1") || local.lg_eu-south || local.lg_eu
  lg_eu-north-1     = contains(var.log_group_regions, "eu-north-1") || local.lg_eu-north || local.lg_eu
  lg_eu-central-1   = contains(var.log_group_regions, "eu-central-1") || local.lg_eu-central || local.lg_eu
  lg_ca-central-1   = contains(var.log_group_regions, "ca-central-1") || local.lg_ca-central || local.lg_ca
  lg_me-south-1     = contains(var.log_group_regions, "me-south-1") || local.lg_me-south || local.lg_me
  lg_sa-east-1      = contains(var.log_group_regions, "sa-east-1") || local.lg_sa-east || local.lg_sa
}

// us-east-1 is already done via lambda creation

module "log-group-us-east-2" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_us-east-2
  name    = var.name
  providers = { aws = aws.us-east-2 }
}
module "log-group-us-west-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_us-west-1
  name    = var.name
  providers = { aws = aws.us-west-1 }
}
module "log-group-us-west-2" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_us-west-2
  name    = var.name
  providers = { aws = aws.us-west-2 }
}
/*
module "log-group-af-south-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_af-south-1
  name    = var.name
  providers = { aws = aws.af-south-1 }
}
module "log-group-ap-east-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_ap-east-1
  name    = var.name
  providers = { aws = aws.ap-east-1 }
}
*/
module "log-group-ap-south-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_ap-south-1
  name    = var.name
  providers = { aws = aws.ap-south-1 }
}
module "log-group-ap-northeast-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_ap-northeast-1
  name    = var.name
  providers = { aws = aws.ap-northeast-1 }
}
module "log-group-ap-northeast-2" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_ap-northeast-2
  name    = var.name
  providers = { aws = aws.ap-northeast-2 }
}
module "log-group-ap-northeast-3" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_ap-northeast-3
  name    = var.name
  providers = { aws = aws.ap-northeast-3 }
}
module "log-group-ap-southeast-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_ap-southeast-1
  name    = var.name
  providers = { aws = aws.ap-southeast-1 }
}
module "log-group-ap-southeast-2" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_ap-southeast-2
  name    = var.name
  providers = { aws = aws.ap-southeast-2 }
}
module "log-group-ca-central-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_ca-central-1
  name    = var.name
  providers = { aws = aws.ca-central-1 }
}
module "log-group-eu-central-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_eu-central-1
  name    = var.name
  providers = { aws = aws.eu-central-1 }
}
module "log-group-eu-west-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_eu-west-1
  name    = var.name
  providers = { aws = aws.eu-west-1 }
}
module "log-group-eu-west-2" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_eu-west-2
  name    = var.name
  providers = { aws = aws.eu-west-2 }
}
module "log-group-eu-west-3" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_eu-west-3
  name    = var.name
  providers = { aws = aws.eu-west-3 }
}
/*
module "log-group-eu-south-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_eu-south-1
  name    = var.name
  providers = { aws = aws.eu-south-1 }
}
*/
module "log-group-eu-north-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_eu-north-1
  name    = var.name
  providers = { aws = aws.eu-north-1 }
}
/*
module "log-group-me-south-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_me-south-1
  name    = var.name
  providers = { aws = aws.me-south-1 }
}
*/
module "log-group-sa-east-1" {
  source  = "genstackio/lambda/aws//modules/log-group"
  version = "0.1.5"
  enabled = local.lg_sa-east-1
  name    = var.name
  providers = { aws = aws.sa-east-1 }
}
