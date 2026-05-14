output "repository_urls" {
  description = "The URLs of the ECR repositories"
  value       = [for repo in aws_ecr_repository.ecr_repository : repo.repository_url]
}

output "repository_arns" {
  description = "The ARNs of the ECR repositories"
  value       = [for repo in aws_ecr_repository.ecr_repository : repo.arn]
}

output "repository_names" {
  description = "The names of the ECR repositories"
  value       = [for repo in aws_ecr_repository.ecr_repository : repo.name]
}

output "registry_ids" {
  description = "The registry IDs associated with the repositories"
  value       = [for repo in aws_ecr_repository.ecr_repository : repo.registry_id]
}