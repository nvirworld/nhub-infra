resource "aws_codepipeline" "webapp" {
  name     = "${local.project}-pipeline-webapp-${local.env}"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.codeartifact.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      category         = "Source"
      name             = "Source"
      namespace        = "SourceVariables"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        ConnectionArn        = local.github_connection_arn
        FullRepositoryId     = "nvirworld/nhub-webapp"
        BranchName           = "prod"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }
  stage {
    name = "DeployStg"
    action {
      category         = "Build"
      name             = "Build"
      namespace        = "BuildVariablesStg"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifactStg"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.webapp_stg.id
      }
    }
  }
  stage {
    name = "Approval"
    action {
      category = "Approval"
      name     = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }
  stage {
    name = "DeployProd"
    action {
      category         = "Build"
      name             = "Build"
      namespace        = "BuildVariables"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.webapp.id
      }
    }
  }
}

resource "aws_codebuild_project" "webapp" {
  name         = "${local.project}-build-webapp-${local.env}"
  service_role = aws_iam_role.codebuild.arn
  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "DEPLOY_TARGET_S3_URI"
      value = "s3://${aws_s3_bucket.webapp.id}/"
    }
    environment_variable {
      name  = "DEPLOY_CLOUDFRONT_DIST_ID"
      value = aws_cloudfront_distribution.webapp.id
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

resource "aws_codestarnotifications_notification_rule" "webapp" {
  detail_type = "FULL"
  event_type_ids = [
    "codepipeline-pipeline-stage-execution-started",
    "codepipeline-pipeline-stage-execution-succeeded",
    "codepipeline-pipeline-stage-execution-resumed",
    "codepipeline-pipeline-stage-execution-canceled",
    "codepipeline-pipeline-stage-execution-failed",
  ]

  name     = "${local.project}-noti-webapp-${local.env}"
  resource = aws_codepipeline.webapp.arn
  target {
    type    = "SNS"
    address = aws_sns_topic.noti_deploy.arn
  }
}

