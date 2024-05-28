# Lambda Function
output "lambda_function_arn" {
  description = "The ARN of the Lambda Function"
  value       = module.submit_lambda_function.lambda_function_arn
}

output "lambda_function_source_code_size" {
  description = "The size in bytes of the function .zip file"
  value       = module.submit_lambda_function.lambda_function_source_code_size
}

# CloudWatch Log Group
output "lambda_cloudwatch_log_group_arn" {
  description = "The ARN of the Cloudwatch Log Group"
  value       = module.submit_lambda_function.lambda_cloudwatch_log_group_arn
}
