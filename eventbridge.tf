resource "aws_scheduler_schedule" "lambda_scheduler" {
  name       = "lambda-clearup-smb-schedule"
  

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(5 minutes)"

  target {
    arn      = aws_lambda_function.clearup_smb_lambda.arn
    role_arn = aws_iam_role.lambda_clearup_smb_schedule_role.arn
  }
}

resource "aws_iam_role" "lambda_clearup_smb_schedule_role" {
    name = "lambda-clearup-smb-schedule-role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement =  [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "scheduler.amazonaws.com"
            }           
        },
    ]
    })
}

resource "aws_iam_role_policy" "lambda_clearup_smb_schedule_policy" {
  name = "lambda-clearup-smb-policy"
  role = aws_iam_role.lambda_clearup_smb_schedule_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = "${aws_lambda_function.clearup_smb_lambda.arn}"
      },
    ]
  })
}



