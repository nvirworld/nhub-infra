
resource "aws_codebuild_project" "webapp_stg" {
  name         = "${local.project}-build-webapp-stg"
  service_role = aws_iam_role.codebuild.arn
  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "DEPLOY_TARGET_S3_URI"
      value = "s3://${aws_s3_bucket.webapp_stg.id}/"
    }
    environment_variable {
      name  = "DEPLOY_CLOUDFRONT_DIST_ID"
      value = aws_cloudfront_distribution.webapp_stg.id
    }
    environment_variable {
      name  = "NODE_ENV"
      value = local.env
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("webapp_buildspec.yaml")
  }
  artifacts {
    type = "CODEPIPELINE"
  }
}