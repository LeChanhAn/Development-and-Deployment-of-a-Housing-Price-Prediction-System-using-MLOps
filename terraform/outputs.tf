output "ecr_repository_arns" {
  description = "ARNs của các repository ECR được tạo ra"
  value       = module.ecr.repository_arns
}

output "eks_cluster_name" {
  description = "Tên của EKS Cluster"
  value       = module.eks.cluster_name
}

output "aws_lb_controller_role_arn" {
  description = "ARN IAM balancer cho the AWS Load Balancer Controller trên EKS (IRSA)"
  value       = module.aws_load_balancer_controller_irsa_role.iam_role_arn
}

output "github_oidc_cicd_role_arn" {
  description = "ARN của IAM Role mà GitHub Actions sẽ assume để deploy CI/CD"
  value       = module.github_oidc_role.role_arn
}

output "github_oidc_terraform_role_arn" {
  description = "ARN của IAM Role mà GitHub Actions sẽ assume để quản lý Terraform state"
  value       = module.github_oidc_role_terraform.role_arn
}

output "github_oidc_ct_role_arn" {
  description = "ARN của IAM Role mà GitHub Actions sẽ assume để quản lý Continuous Training"
  value       = module.github_oidc_role_ct.role_arn
}