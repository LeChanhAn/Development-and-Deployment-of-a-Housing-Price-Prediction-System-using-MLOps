# DATA SOURCES (Lấy thông tin môi trường)
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# ========================================================
# 2. ECR REGISTRY (GIỮ LẠI ĐỂ KHÔNG PHẢI BUILD LẠI DOCKER)
# ========================================================
module "ecr" {
  source = "./modules/ecr"

  repository_names      = ["housing-api", "housing-ui"]
  scan_on_push          = true
  image_tag_mutability  = "MUTABLE"
  force_delete          = true
  allow_push_principals = [data.aws_caller_identity.current.arn]
  allow_pull_principals = [data.aws_caller_identity.current.arn]
}

# ========================================================
# ẨN (COMMENT) TOÀN BỘ PHẦN DƯỚI ĐÂY ĐỂ TRÁNH TỐN PHÍ
# ========================================================
/*
# 1. NETWORK (VPC & Subnets)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false # Chạy nhiều NAT để đảm bảo HA
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true
  enable_dns_support     = true
}

# 3. APPLICATION LOAD BALANCER (ALB)
# Tường lửa cho ALB: Internet
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cho phép Load Balancer gọi vào trong các container ở mọi port
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Khởi tạo Load Balancer nằm ở Public Subnets
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}

# Đích đến 1: Nhóm các container API
resource "aws_lb_target_group" "api_tg" {
  name        = "${var.project_name}-api-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/docs"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

# Đích đến 2: Nhóm các container UI (Streamlit)
resource "aws_lb_target_group" "ui_tg" {
  name        = "${var.project_name}-ui-tg"
  port        = 8501
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/_stcore/health" # Đường dẫn check sức khỏe chuẩn của Streamlit
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

# Listener: Nếu truy cập /predict thì vào API, còn lại vào Web
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Mặc định: Đẩy vào Web Streamlit
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui_tg.arn
  }
}

resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }

  condition {
    path_pattern {
      values = ["/predict*", "/docs*", "/openapi.json"]
    }
  }
}

# 4. ECS FARGATE
module "ecs" {
  source = "./modules/ecs"

  cluster_name    = "${var.project_name}-cluster"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  alb_security_group_id = aws_security_group.alb_sg.id
  api_target_group_arn  = aws_lb_target_group.api_tg.arn
  ui_target_group_arn   = aws_lb_target_group.ui_tg.arn

  api_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/housing-api:latest"
  ui_image  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/housing-ui:latest"

  s3_bucket_name = "housing-regression-data-mlops-khaipd18"
  alb_dns_name = aws_lb.main.dns_name
}

# Link URL 
output "website_url" {
  description = "Truy cập ứng dụng tại đường link này"
  value       = "http://${aws_lb.main.dns_name}"
}
*/