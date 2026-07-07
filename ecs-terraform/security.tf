resource "aws_security_group" "alb" {
  name   = "fastapi-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "fastapi-alb-sg"
  }
}


resource "aws_security_group" "ecs" {
  name   = "fastapi-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"

    security_groups = [
      aws_security_group.alb.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fastapi-ecs-sg"
  }
}
