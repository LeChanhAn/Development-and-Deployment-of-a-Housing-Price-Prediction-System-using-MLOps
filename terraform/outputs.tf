# Link URL 
output "website_url" {
  description = "Truy cập ứng dụng tại đường link này"
  value       = "http://${aws_lb.main.dns_name}"
}

output "github_oidc_cicd_role_arn" {
  description = "ARN của IAM Role mà GitHub Actions sẽ assume để deploy CI/CD"
  value       = module.github_oidc_role.role_arn
}

output "github_oidc_terraform_role_arn" {
  description = "ARN của IAM Role mà GitHub Actions sẽ assume để quản lý Terraform state"
  value       = module.github_oidc_role_terraform.role_arn
}