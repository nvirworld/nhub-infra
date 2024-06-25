resource "aws_lb" "api" {
  name               = "${local.project}-alb-api-${local.env}"
  internal           = false
  load_balancer_type = "application"
  idle_timeout       = 60
  subnets = [
    aws_subnet.main_public_a.id,
    aws_subnet.main_public_c.id,
  ]
  security_groups = [
    aws_security_group.api_alb.id,
  ]
  enable_deletion_protection = true
}

resource "aws_lb_listener" "api_80" {
  load_balancer_arn = aws_lb.api.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "api_443" {
  load_balancer_arn = aws_lb.api.arn
  # port              = "80"
  # protocol          = "HTTP"
  port            = "443"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = local.acm_nhub_io_arn
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_security_group" "api_alb" {
  vpc_id = aws_vpc.main.id
  name   = "${local.project}-sg-alb-api-${local.env}"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${local.project}-sg-api-alb-${local.env}"
  }
}