
resource "aws_security_group" "backend" {
  vpc_id = aws_vpc.main.id
  name   = "${local.project}-sg-backend-${local.env}"
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [
      aws_security_group.api_alb.id,
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${local.project}-sg-backend-${local.env}"
  }
}