output "endpoint_sg_id" {
  value       = aws_security_group.ecr_endpoint_sg.id
  description = "Security group ID for ECR VPC endpoints"
}

output "interface_endpoint_ids" {
  value       = [aws_vpc_endpoint.ecr_api_endpoint.id, aws_vpc_endpoint.ecr_dkr_endpoint.id]
  description = "IDs of the interface VPC endpoints for ECR API and ECR DKR"
}

output "s3_gateway_id" {
  value       = aws_vpc_endpoint.s3_endpoint.id
  description = "ID of the gateway VPC endpoint for S3"
}

output "ecr_endpoint_sg_id" {
  value       = aws_security_group.ecr_endpoint_sg.id
  description = "Security group ID for ECR VPC endpoints"
}