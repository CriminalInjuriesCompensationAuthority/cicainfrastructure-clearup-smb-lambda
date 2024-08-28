data "aws_caller_identity" "current" {}




#IAM Role used by Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-clearup-smb-role"

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

resource "aws_iam_policy" "lambda_secret_policy" {
  name        = "lambda_smb_secret_policy"
  path        = "/"
  description = "Policy to allow Lambda to read secret. NB this cannot be attached to anything else. Exclusive through terraform"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.lambda_smb_secrets.arn
      },
    ]
  })
}

resource aws_iam_role_policy_attachment "get_secret_attachment" {
  role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_secret_policy.arn
}
#Attach AWS managed policy to allow lambda to write to cloudwatch logs.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "function.py"
  output_path = "lambda_function_payload.zip"
}

#Lambda function
resource "aws_lambda_function" "clearup_smb_lambda" {
  depends_on    = [data.archive_file.lambda]
  filename      = "lambda_function_payload.zip"
  function_name = "Clearup-SMB-Lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 120
  layers = [aws_lambda_layer_version.smbconnection_layer.arn]
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {environment = var.environment}
  }

  vpc_config {
    subnet_ids = data.aws_subnets.subnets.ids
    security_group_ids = [aws_security_group.clearup_smb_lambda_sg.id]
  }
}

resource "aws_lambda_layer_version" "smbconnection_layer" {
  filename = "layer_content.zip"
  layer_name = "smbconnection"
  compatible_runtimes = ["python3.12"] 
  source_code_hash = filebase64sha256("layer_content.zip")
}

resource "aws_security_group" "clearup_smb_lambda_sg" {
  name = "clearup_smb_lambda_sg"
  description = "Security group for lambda function that connects to smb shares"
  vpc_id = local.vpcssm_values[var.environment]
}

resource "aws_vpc_security_group_ingress_rule" "allow_inbound" {
  security_group_id = aws_security_group.clearup_smb_lambda_sg.id
  cidr_ipv4 = "10.0.0.0/8"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.clearup_smb_lambda_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

locals {
  vpcssm_values = jsondecode(data.aws_ssm_parameter.vpcssm.value)
}

data "aws_ssm_parameter" "vpcssm" {
  name     = "VPC"
  provider = aws.sharedservices
}


data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpcssm_values[var.environment]]
  }
  tags = {
    Type = "App"
  }
}

data "aws_subnet" "app_subnet" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
}
#Create Dummy secrets, to be replaced in console with correct values

resource "aws_secretsmanager_secret" "lambda_smb_secrets" {
  name = "lambda-smb-secrets"
}

resource aws_secretsmanager_secret_version  "lambda_smb_secrets_version" {
  secret_id = aws_secretsmanager_secret.lambda_smb_secrets.id
  secret_string = jsonencode(var.secret_string)
  lifecycle {
    ignore_changes = [ secret_string ]
  }
}