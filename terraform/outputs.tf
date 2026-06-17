# Link URL 
output "website_url" {
  description = "Truy cập ứng dụng tại đường link này"
  value       = "http://${aws_lb.main.dns_name}"
}

# OIDC Role ARN for GitHub Actions
output "github_oidc_role_arn" {
  description = "ARN của IAM Role mà GitHub Actions sẽ assume để deploy"
  value       = module.github_oidc_role.role_arn
}