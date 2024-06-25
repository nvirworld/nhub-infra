resource "aws_ecs_cluster" "main" {
  name = "${local.project}-ecscluster-main-${local.env}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}