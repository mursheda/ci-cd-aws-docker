data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "msd-group-name"
    values = ["default"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "msd-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "msd-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "msd-app"
    image = "${aws_ecr_repository.main.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
  }])
}

resource "aws_ecs_service" "main" {
  name            = "msd-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = data.aws_subnet_ids.default.ids
    security_groups = [data.aws_security_group.default.id]
  }
}

resource "aws_ecr_repository" "main" {
  name = "msd-app"
}