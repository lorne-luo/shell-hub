
data "aws_region" "current" {
}

data "aws_caller_identity" "current" {}

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

module "lambda_function_submit" {
  depends_on = [ aws_s3_bucket.main ]
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${local.app_name}-submit"
  handler       = "lambda_handler_submit.lambda_handler"
  runtime       = "python3.12"
  description   = "Submit shell commands"

  source_path = "${path.module}/../src"
  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  store_on_s3 = true
  s3_prefix   = "${local.app_name}-submit/"
  s3_bucket   = aws_s3_bucket.main.bucket

  environment_variables = {
    Serverless = "Terraform"
  }

  tags = {
    Name = "${local.app_name}-submit"
  }
}

module "lambda_function_retrieve" {
  depends_on = [ aws_s3_bucket.main ]
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${local.app_name}-retrieve"
  handler       = "lambda_function_retrieve.lambda_handler"
  runtime       = "python3.12"
  description   = "Retrieve shell commands"

  source_path = "${path.module}/../src"
  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  store_on_s3 = true
  s3_prefix   = "${local.app_name}-retrieve/"
  s3_bucket   = aws_s3_bucket.main.bucket

  environment_variables = {
    Serverless = "Terraform"
  }

  tags = {
    Name = "${local.app_name}-retrieve"
  }
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "shell-hub-api"
  description   = "HTTP API Gateway for shell hub"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  # Custom domain
  domain_name                 = "shell.luotao.net"
  domain_name_certificate_arn = "arn:aws:acm:ap-southeast-2:236962861642:certificate/d17655fb-3102-429e-a818-b63d74f60393"

  # Access logs
  # default_stage_access_log_destination_arn = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:debug-shell-hub"
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  # Routes and integrations
  integrations = {
    "POST /submit" = {
      lambda_arn             = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.app_name}-submit"
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "GET /retrieve" = {
      lambda_arn             = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.app_name}-retrieve"
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

#     "GET /some-route-with-authorizer" = {
#       integration_type = "HTTP_PROXY"
#       integration_uri  = "some url"
#       authorizer_key   = "azure"
#     }
#
#     "$default" = {
#       lambda_arn = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:my-default-function"
#     }
#   }
#
#   authorizers = {
#     "azure" = {
#       authorizer_type  = "JWT"
#       identity_sources = "$request.header.Authorization"
#       name             = "azure-auth"
#       audience         = ["d6a38afd-45d6-4874-d1aa-3c5c558aqcc2"]
#       issuer           = "https://sts.windows.net/aaee026e-8f37-410e-8869-72d9154873e4/"
#     }
  }

  tags = {
    Name = "http-apigateway"
  }
}