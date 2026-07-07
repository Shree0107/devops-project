resource "aws_cloudwatch_log_group" "fastapi" {

  name = "/ecs/fastapi"

  retention_in_days = 7

  tags = {
    Name = "fastapi-log-group"
  }
}
