resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_list
  security_group_ids  = [aws_security_group.ecr_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_list
  security_group_ids  = [aws_security_group.ecr_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_list
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_list
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.ecr_endpoint_sg.id]
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_list
  security_group_ids  = [aws_security_group.ecr_endpoint_sg.id]
  private_dns_enabled = true
}