data "archive_file" "noti_deploy" {
  type        = "zip"
  source_file = "noti_deploy.py"
  output_path = "noti_deploy.zip"
}


resource "aws_lambda_function" "noti_deploy" {
  function_name    = "${local.project}-lambda-noti-deploy-${local.env}"
  handler          = "noti_deploy.lambda_handler"
  role             = aws_iam_role.noti_deploy.arn
  runtime          = "python3.9"
  filename         = "noti_deploy.zip"
  source_code_hash = data.archive_file.noti_deploy.output_base64sha256
  environment {
    variables = {
      SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/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"
      SLACK_CHANNEL     = "dev-nhub-aws"
    }
  }
}

resource "aws_iam_role" "noti_deploy" {
  name = "${local.project}-role-noti-deploy-${local.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "noti_deploy_lambda_basic_execution" {
  role       = aws_iam_role.noti_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_sns_topic" "noti_deploy" {
  name = "${local.project}-snstopic-noti-deploy-${local.env}"
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn = aws_sns_topic.noti_deploy.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowCodePipelineToPublish"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.noti_deploy.arn
        Principal = {
          Service = "codestar-notifications.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_permission" "noti_deploy" {
  statement_id  = "AllowSNSInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.noti_deploy.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.noti_deploy.arn
}

resource "aws_sns_topic_subscription" "noti_deploy" {
  topic_arn = aws_sns_topic.noti_deploy.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.noti_deploy.arn
}

