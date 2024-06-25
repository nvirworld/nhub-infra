resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.api_443.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  # condition {
  #   host_header {
  #     values = ["v2-backend.n-hub.io"]
  #   }
  # }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "${local.project}-tg-backend-${local.env}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path = "/health"
  }
}


resource "aws_secretsmanager_secret" "backend" {
  name = "${local.project}-secret-backend-${local.env}"
}

resource "aws_sqs_queue" "backend" {
  name = "${local.project}-sqs-api-backend-bridge-${local.env}.fifo"
  fifo_queue = true
  message_retention_seconds = 1209600
  visibility_timeout_seconds = 300

}

resource "aws_ecs_service" "backend" {
  name             = "${local.project}-service-backend-${local.env}"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.backend.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  network_configuration {
    subnets = [
      aws_subnet.main_public_a.id,
      aws_subnet.main_public_c.id,
    ]
    security_groups = [
      aws_security_group.backend.id,
    ]
    assign_public_ip = true
  }
  deployment_controller {
    type = "ECS"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "${local.project}-backend-${local.env}"
    container_port   = 80
  }
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.project}-taskdef-backend-${local.env}"
  cpu                      = "1024"
  memory                   = "2048"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.backend.arn
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  container_definitions = jsonencode([
    {
      name        = "${local.project}-backend-${local.env}"
      image       = "${local.aws_account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/${local.project}-ecr-backend-${local.env}:latest"
      essential   = true
      cpu         = 0
      mountPoints = []
      volumesFrom = []
      environment = [
        {
          name  = "NODE_ENV"
          value = local.env
        },
        {
          name  = "AWS_SECRET"
          value = aws_secretsmanager_secret.backend.name
        }
      ]
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_backend.name
          awslogs-region        = local.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs_backend" {
  name = "/ecs/${local.project}-ecs-backend-${local.env}"
}
