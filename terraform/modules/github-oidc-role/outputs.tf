output "role_arn" {
  description = "The ARN of the IAM role created for GitHub OIDC authentication"
  value       = aws_iam_role.this.arn
}