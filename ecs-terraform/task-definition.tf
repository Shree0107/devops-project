resource "aws_ecs_task_definition" "app" {

  family = "fastapi-task"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  cpu = "256"

  memory = "512"


  execution_role_arn = aws_iam_role.ecs_task_execution.arn


  container_definitions = jsonencode([

    {

      name = "fastapi-container"


      image = "${aws_ecr_repository.app.repository_url}:latest"


      essential = true


      portMappings = [

        {

          containerPort = 8080

          hostPort = 8080

          protocol = "tcp"

        }

      ]


      logConfiguration = {

        logDriver = "awslogs"

        options = {

          awslogs-group = aws_cloudwatch_log_group.fastapi.name

          awslogs-region = "eu-west-3"

          awslogs-stream-prefix = "ecs"

        }

      }

    }

  ])

}
