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
  requires_compatibilities = ["EC2"]
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
  launch_type     = "EC2"
  network_configuration {
    subnets         = data.aws_subnet_ids.default.ids
    security_groups = [data.aws_security_group.default.id]
  }
}

resource "aws_instance" "ecs_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet_ids.default.ids
  security_groups = [data.aws_security_group.default.id]

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              EOF
}