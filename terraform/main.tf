
data "aws_region" "current" {}

data "aws_caller_identity" "this" {}

data "aws_ecr_authorization_token" "token" {}

locals {
  app_name    = "shell-hub"
}

resource "aws_s3_bucket" "main" {
  bucket = "${local.app_name}-lorne"

  tags = {
    App        = "${local.app_name}"
  }
}

module "submit_lambda_function" {
  depends_on = [ aws_s3_bucket.main ]
  source = "terraform-aws-modules/lambda/aws"
  
  function_name = "${local.app_name}-submit"
  handler       = "lambda_handler_submit.lambda_handler"
  runtime       = "python3.12"
  description   = "Submit shell commands"

  source_path = "${path.module}/src"
  
  store_on_s3 = true
  s3_bucket   = aws_s3_bucket.main.bucket
  
  environment_variables = {
    Serverless = "Terraform"
  }
  
  tags = {
    Name = "${local.app_name}-submit"
  }
}
