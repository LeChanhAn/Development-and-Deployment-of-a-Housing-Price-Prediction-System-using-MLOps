# DATA SOURCES (Lấy thông tin môi trường)
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# 1. ECR REGISTRY 
module "ecr" {
  source = "./modules/ecr"

  repository_names      = var.ecr_repository_names
  scan_on_push          = var.ecr_scan_on_push
  image_tag_mutability  = var.ecr_image_tag_mutability
  force_delete          = var.ecr_force_delete
  allow_push_principals = [data.aws_caller_identity.current.arn]
  allow_pull_principals = [data.aws_caller_identity.current.arn]
}


# 2. NETWORK (VPC & Subnets)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
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

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400 # Gắn session trong 1 ngày (tính bằng giây)
    enabled         = true
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

# 4. EKS
module "eks" {
  source       = "./modules/eks"
  cluster_name = var.eks_cluster_name

  k8s_version = var.eks_k8s_version

  vpc_id = module.vpc.vpc_id

  vpc_config = local.eks_vpc_conf_finals

  capacity_type = var.eks_node_group_capacity_type

  instance_type = var.eks_node_group_instance_type

  ami_type = var.eks_node_group_ami_type

  disk_size = var.eks_node_group_disk_size

  node_scaling_config = var.eks_node_group_scaling_config

  cni_version = var.eks_cni_version

  coredns_version = var.eks_coredns_version

  kube_proxy_version = var.eks_kube_proxy_version

  depends_on = [module.vpc]
}

# 5. OIDC ROLE FOR GITHUB ACTIONS (CI/CD)
# This module creates an IAM role that can be assumed by GitHub Actions using OIDC
resource "aws_iam_openid_connect_provider" "github_core" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# The policy document for CI/CD permissions (ECR + ECS)
data "aws_iam_policy_document" "github_actions_permissions" {
  # 1. Common permissions for Docker to login (Resource is required to be "*")
  statement {
    sid       = "GetAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # 2. Pull and push permissions for the specified ECR repositories
  statement {
    sid    = "AllowPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = module.ecr.repository_arns
  }

  # 3. ECS Permissions to restart services
  # Cấp quyền để chạy lệnh aws ecs update-service --force-new-deployment
  statement {
    sid    = "AllowECSUpdateService"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_cicd_policy" {
  name        = "GitHubActions-CICD-Policy"
  description = "Permissions for GitHub Actions to manage ECR images and deploy to ECS"
  policy      = data.aws_iam_policy_document.github_actions_permissions.json
}

module "github_oidc_role" {
  source              = "./modules/github-oidc-role"
  role_name           = "github-actions-cicd-oidc-mlops-housing-project-role"
  github_repo         = var.github_repo
  oidc_provider_arn   = aws_iam_openid_connect_provider.github_core.arn
  ecr_repository_arns = module.ecr.repository_arns
  custom_policy_arns  = [aws_iam_policy.github_actions_cicd_policy.arn]
}

data "aws_iam_policy_document" "terraform_state_permissions" {
  statement {
    sid     = "AllowS3StateManagement"
    effect  = "Allow"
    actions = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::dacn-project-tf-state",
      "arn:aws:s3:::dacn-project-tf-state/*"
    ]
  }

  statement {
    sid       = "AllowDynamoDBLocking"
    effect    = "Allow"
    actions   = ["dynamodb:DescribeTable", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:ap-southeast-1:770353436964:table/dacn-terraform-state-lock"]
  }
}

resource "aws_iam_policy" "terraform_state_policy" {
  name        = "GitHubActions-Terraform-State-Policy"
  description = "Permissions for GitHub Actions to manage Terraform state in S3 and DynamoDB"
  policy      = data.aws_iam_policy_document.terraform_state_permissions.json
}

module "github_oidc_role_terraform" {
  source              = "./modules/github-oidc-role"
  role_name           = "github-actions-terraform-oidc-role"
  github_repo         = var.github_repo
  oidc_provider_arn   = aws_iam_openid_connect_provider.github_core.arn
  ecr_repository_arns = []
  custom_policy_arns = [
    aws_iam_policy.terraform_state_policy.arn,
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}

# 6. VPC ENDPOINTS 
module "vpc_endpoints" {
  source              = "./modules/vpc-endpoints"
  region              = var.aws_region
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_subnet_list = module.vpc.private_subnets
  route_table_list    = module.vpc.private_route_table_ids
  depends_on          = [module.vpc]
}