data "archive_file" "lambda-code" {
  type        = "zip"
  output_path = "${path.module}/lambda-code.zip"
  source {
    content  = file("${path.module}/code/index.js")
    filename = "index.js"
  }
  source {
    content  = file("${path.module}/code/utils.js")
    filename = "utils.js"
  }
  source {
    content  = file(("" == var.config_file) ? "${path.module}/code/config.js" : var.config_file)
    filename = "config.js"
  }
}