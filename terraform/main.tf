data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

# Use an existing ECR repository
data "aws_ecr_repository" "existing" {
  name = "msd-app"
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
    image = "${data.aws_ecr_repository.existing.repository_url}:latest"
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
    subnets         = data.aws_subnets.default.ids
    security_groups = [data.aws_security_group.default.id]
  }
}

data "aws_ami" "amazon-linux-2" {
 most_recent = true


 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }


 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_instance" "ecs_instance" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  # subnet_id     = data.aws_subnets.default.ids
  for_each      = toset(data.aws_subnets.default.ids)
  subnet_id     = each.value
  security_groups = [data.aws_security_group.default.id]

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              EOF
}