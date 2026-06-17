resource "aws_security_group" "ecr_endpoint_sg" {
  name        = "ecr-endpoint-sg"
  description = "Security group for ECR VPC endpoints"
  vpc_id      = var.vpc_id
  ingress {
    description = "Allow HTTPS from entirely VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}