variable "role_name" {
  description = "The name of the IAM role to create for GitHub OIDC authentication"
  type        = string
}

variable "github_repo" {
  description = "The GitHub repository in the format 'owner/repo' that will be allowed to assume the role"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for GitHub in AWS IAM"
  type        = string
}

variable "ecr_repository_arns" {
  description = "A list of ECR repository ARNs that the role will have permissions to access"
  type        = list(string)
}

variable "custom_policy_arns" {
  description = "A list of additional IAM policy ARNs to attach to the role for extra permissions beyond ECR access"
  type        = list(string)
  default     = []
}