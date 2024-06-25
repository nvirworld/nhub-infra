


resource "aws_iam_role" "backend" {
  name = "${local.project}-role-backend-${local.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
          AWS     = "arn:aws:iam::${local.aws_account_id}:root"
        }
      }
    ]
  })
  inline_policy {
    name = "sqs-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "*",
          ]
          Resource = [
            "arn:aws:sqs:ap-northeast-2:797127116500:nhub-sqs-api-backend-bridge-prod.fifo",
          ]
        },
      ]
    })
  }
  inline_policy {
    name = "sm-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
          ]
          Resource = [
            aws_secretsmanager_secret.backend.arn,
          ]
        },
      ]
    })
  }
  inline_policy {
    name = "sqs-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sqs:*",
          ]
          Resource = [
            aws_sqs_queue.backend.arn,
          ]
        },
      ]
    })
  }
}

resource "aws_iam_user" "backend" {
  name = "${local.project}-user-backend-${local.env}"
  path = "/"
}

resource "aws_iam_user_policy" "backend" {
  name = "${local.project}-userpolicy-backend-${local.env}"
  user = aws_iam_user.backend.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect = "Allow"
        Resource = [
          aws_iam_role.backend.arn,
        ]
      },
    ]
  })
}
