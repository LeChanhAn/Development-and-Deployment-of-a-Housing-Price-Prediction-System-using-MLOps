resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

# 1. FASTAPI BACKEND
resource "aws_ecs_task_definition" "api" {
  family                   = "housing-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "housing-api"
      image        = var.api_image
      essential    = true
      portMappings = [{ containerPort = 8000 }]
      environment = [
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "AWS_REGION", value = "ap-southeast-1" }
      ]
    }
  ])
}

resource "aws_ecs_service" "api_service" {
  name            = "housing-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.api_target_group_arn
    container_name   = "housing-api"
    container_port   = 8000
  }
}

# 2. STREAMLIT FRONTEND
resource "aws_ecs_task_definition" "ui" {
  family                   = "housing-ui-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # Giao diện nhẹ nên cần ít tài nguyên hơn
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "housing-ui"
      image        = var.ui_image
      essential    = true
      portMappings = [{ containerPort = 8501 }]
      environment = [
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "AWS_REGION", value = "ap-southeast-1" },
        { name = "API_URL", value = "http://${var.alb_dns_name}/predict" }
      ]
    }
  ])
}

resource "aws_ecs_service" "ui_service" {
  name            = "housing-ui-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ui.arn
  desired_count   = 2 # Đảm bảo High Availability
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.ui_target_group_arn
    container_name   = "housing-ui"
    container_port   = 8501
  }
}