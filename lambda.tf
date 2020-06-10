provider "aws" {
  region = "us-east-1"
}

variable "app_version" {
}


variable "function_name" {
}

resource "aws_s3_bucket" "s3bucket" {
  bucket = "${var.function_name}-andrade0"
  acl    = "private"

  tags = {
    Name        = "${var.function_name}-andrade0"
    Environment = "Dev"
  }

  #provisioner "local-exec"{
  #  command = "aws s3 cp ./nodejs/dist/dist.zip s3://${aws_s3_bucket.s3bucket.bucket}/v${var.app_version}/v${var.function_name}.zip"
  #}
}

resource "aws_s3_bucket_object" "lambda_s3_object" {
  key        = "v${var.app_version}/v${var.function_name}.zip"
  bucket     = "${aws_s3_bucket.s3bucket.id}"
  source     = "./nodejs/dist/dist.zip"
}



resource "aws_lambda_function" "lambda_function" {
  depends_on = [
     aws_s3_bucket_object.lambda_s3_object
  ]

  function_name = "${var.function_name}-function"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = aws_s3_bucket.s3bucket.bucket
  s3_key = "v${var.app_version}/v${var.function_name}.zip"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.server"
  runtime = "nodejs10.x"

  role = aws_iam_role.lambda_exec.arn
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}_lambda_function"

  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Action": "sts:AssumeRole",
       "Principal": {
         "Service": "lambda.amazonaws.com"
       },
       "Effect": "Allow",
       "Sid": ""
     }
   ]
 }
EOF

}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "${var.function_name}-api-getway"
  description = "Terraform Serverless Application ${var.function_name}"
}


resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
   parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
   rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
   resource_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
 }

resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
   stage_name  = "production"
}

resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.lambda_function.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}"
}

output "version" {
  value = var.app_version
}
