resource "aws_ecr_repository" "backend" {
  name                 = "${local.project}-ecr-backend-${local.env}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_codepipeline" "backend" {
  name     = "${local.project}-pipeline-backend-${local.env}"
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
        FullRepositoryId     = "nvirworld/nhub-backend"
        BranchName           = "prod"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }
  stage {
    name = "Build"
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
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      category        = "Deploy"
      name            = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["BuildArtifact"]
      configuration = {
        ClusterName       = aws_ecs_cluster.main.name
        ServiceName       = aws_ecs_service.backend.name
        DeploymentTimeout = "15"
      }
    }
  }
}


resource "aws_codebuild_project" "backend" {
  name         = "${local.project}-build-backend-${local.env}"
  service_role = aws_iam_role.codebuild.arn
  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPO_URI"
      value = aws_ecr_repository.backend.repository_url
    }
    environment_variable {
      name  = "ECR_TAG"
      value = "${local.project}-backend-${local.env}"
    }
    environment_variable {
      name  = "TARGET_ECS_CONTAINER"
      value = "${local.project}-backend-${local.env}"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("backend_buildspec.yaml")
  }
  artifacts {
    type = "CODEPIPELINE"
  }
}


resource "aws_codestarnotifications_notification_rule" "backend" {
  detail_type = "FULL"
  event_type_ids = [
    "codepipeline-pipeline-stage-execution-succeeded",
    "codepipeline-pipeline-stage-execution-resumed",
    "codepipeline-pipeline-stage-execution-canceled",
    "codepipeline-pipeline-stage-execution-failed",
  ]
  name     = "${local.project}-noti-pipeline-backend-${local.env}"
  resource = aws_codepipeline.backend.arn
  target {
    type    = "SNS"
    address = aws_sns_topic.noti_deploy.arn
  }
}
