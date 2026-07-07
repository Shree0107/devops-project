resource "aws_lb" "fastapi" {
  name               = "fastapi-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_2.id

  ]
}

resource "aws_lb_target_group" "fastapi" {
  name        = "fastapi-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"

  vpc_id = aws_vpc.main.id

  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.fastapi.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fastapi.arn
  }
}

